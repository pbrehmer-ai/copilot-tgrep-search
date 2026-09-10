#requires -Version 5.1
<#!
Bounded filename discovery for one or more independent queries in one tool call.
Returns JSON with native exit codes and stderr; never hides errors as zero matches.
The helper uses the existing default index/server. It does not start one.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $Root,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]] $Pattern,
    [string[]] $Glob = @(),
    [switch] $Regex,
    [switch] $NoIndex,
    [switch] $CheckReady,
    [switch] $Compact,
    [switch] $IncludeContext,
    [ValidateRange(0, 20)][int] $ContextLines = 6,
    [ValidateRange(1, 10)][int] $MaxMatches = 2,
    [ValidateRange(100, 20000)][int] $MaxEvidenceChars = 6000,
    [ValidateRange(0, 2147483647)][int] $MaxPaths = 5,
    [ValidateRange(1, 300)][int] $TimeoutSeconds = 30
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Process.ps1')
$resolved = Resolve-SearchRoot $Root
$executable = Resolve-TgrepExecutable
$pathLimit = [Math]::Min($MaxPaths, 1000)
$results = @()
$readinessChecked = [bool]($CheckReady -and -not $NoIndex)
$readinessStderr = ''
$evidenceRemaining = $MaxEvidenceChars
$evidenceFailed = $false
if ($readinessChecked) {
    $status = Invoke-CapturedProcess $executable @('status', '.') $resolved 10
    $ready = -not $status.TimedOut -and $status.ExitCode -eq 0 -and
        $status.Stdout -match '(?m)^Server status for ' -and
        $status.Stdout -match '(?m)^\s*Indexing:\s+complete\s*$' -and
        $status.Stdout -match '(?m)^\s*Watcher:\s+active\b'
    if (-not $ready) {
        [pscustomobject]@{
            Root = $resolved; Executable = $executable; SearchMode = 'not-run'; ReadinessChecked = $true
            SetupRequired = $true; Status = $status.Stdout.Trim(); Stderr = $status.Stderr; TimedOut = $status.TimedOut
            RequestedQueries = $Pattern.Count; CompletedQueries = 0; Results = @()
        } | ConvertTo-Json -Depth 4 -Compress
        exit 2
    }
    $readinessStderr = $status.Stderr
}
foreach ($query in $Pattern) {
    $arguments = @('-l', '--color', 'never')
    if (-not $Regex) { $arguments += '-F' }
    if ($NoIndex) { $arguments += '--no-index' }
    foreach ($filter in $Glob) { $arguments += @('-g', $filter) }
    $arguments += @('--', $query, '.')
    $run = Invoke-CapturedProcess -Executable $executable -Arguments $arguments -Root $resolved -TimeoutSeconds $TimeoutSeconds
    [string[]] $paths = @($run.Stdout -split '\r?\n' | Where-Object { $_ -ne '' } | ForEach-Object { ($_ -replace '^\.[\\/]', '').Replace('\', '/') })
    [Array]::Sort($paths, [StringComparer]::OrdinalIgnoreCase)
    $succeeded = -not $run.TimedOut -and $run.ExitCode -in @(0, 1)
    $matchCount = $null
    if ($succeeded) { $matchCount = $paths.Count }
    $result = [pscustomobject]@{
        Pattern = $query; ExitCode = $run.ExitCode; TimedOut = $run.TimedOut
        Succeeded = $succeeded
        Stderr = $run.Stderr; ElapsedMs = $run.ElapsedMs
        MatchFileCount = $matchCount
        ReturnedPathCount = $paths.Count; Paths = @($paths | Select-Object -First $pathLimit)
        PathsTruncated = ($paths.Count -gt $pathLimit)
    }
    if ($IncludeContext -and $succeeded) {
        $evidence = @()
        $evidenceTruncated = $false
        $evidenceErrors = @()
        # A selected file is read directly by tgrep; the broad discovery above stays indexed.
        foreach ($path in $result.Paths) {
            if ($evidenceRemaining -le 0) { $evidenceTruncated = $true; break }
            $full = [IO.Path]::GetFullPath((Join-Path $resolved $path))
            if (-not $full.StartsWith($resolved.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
                $evidenceFailed = $true
                $evidenceErrors += "Rejected path outside root: $path"; continue
            }
            $contentArgs = @('--json', '--no-index', '-m', [string]$MaxMatches, '-C', [string]$ContextLines)
            if (-not $Regex) { $contentArgs += '-F' }
            $contentArgs += @('--', $query, $path)
            $content = Invoke-CapturedProcess $executable $contentArgs $resolved $TimeoutSeconds
            if ($content.TimedOut -or $content.ExitCode -notin @(0, 1)) {
                $evidenceFailed = $true
                $evidenceErrors += "${path}: exit=$($content.ExitCode); timeout=$($content.TimedOut); $($content.Stderr)"
                continue
            }
            if ($content.Stderr) { $evidenceErrors += "${path}: $($content.Stderr)" }
            $lines = @()
            $matchLines = @()
            foreach ($jsonLine in ($content.Stdout -split '\r?\n')) {
                if (-not $jsonLine) { continue }
                $record = $jsonLine | ConvertFrom-Json
                if ($record.type -notin @('match', 'context')) { continue }
                $lineNumber = [int]$record.data.line_number
                $textLine = ([string]$record.data.lines.text).TrimEnd("`r", "`n")
                $rendered = "${lineNumber}: $textLine"
                if ($rendered.Length -gt $evidenceRemaining) { $evidenceTruncated = $true; break }
                $lines += $rendered
                $evidenceRemaining -= $rendered.Length
                if ($record.type -eq 'match') { $matchLines += $lineNumber }
            }
            $evidence += [pscustomobject]@{ Path = $path; MatchLines = $matchLines; Lines = $lines }
        }
        $result | Add-Member NoteProperty Evidence $evidence
        $result | Add-Member NoteProperty EvidenceTruncated $evidenceTruncated
        $result | Add-Member NoteProperty EvidenceErrors $evidenceErrors
    }
    $results += $result
    if ($run.TimedOut) { break }
}
$output = [pscustomobject]@{
    Root = $resolved; Executable = $executable; DirectScanRequested = [bool]$NoIndex
    SearchMode = $(if ($NoIndex) { 'direct-scan-requested' } else { 'index-eligible' })
    PathLimit = $pathLimit
    ReadinessChecked = $readinessChecked; SetupRequired = $false
    ReadinessStderr = $readinessStderr
    RequestedQueries = $Pattern.Count; CompletedQueries = $results.Count; Results = $results
}
if ($Compact) {
    $compactResults = @($results | ForEach-Object {
        $entry = [ordered]@{ Pattern = $_.Pattern; Succeeded = $_.Succeeded; MatchFileCount = $_.MatchFileCount; Paths = $_.Paths; PathsTruncated = $_.PathsTruncated }
        if (-not $_.Succeeded -or $_.Stderr) { $entry.ExitCode = $_.ExitCode; $entry.TimedOut = $_.TimedOut; $entry.Stderr = $_.Stderr }
        if ($IncludeContext -and $_.Succeeded) {
            $entry.Evidence = $_.Evidence; $entry.EvidenceTruncated = $_.EvidenceTruncated
            if ($_.EvidenceErrors.Count) { $entry.EvidenceErrors = $_.EvidenceErrors }
        }
        [pscustomobject]$entry
    })
    $output = [ordered]@{ SearchMode = $output.SearchMode; CompletedQueries = $results.Count; Results = $compactResults }
    if ($readinessStderr) { $output.ReadinessStderr = $readinessStderr }
}
$output | ConvertTo-Json -Depth 8 -Compress
if ($evidenceFailed -or @($results | Where-Object { -not $_.Succeeded }).Count -gt 0) { exit 2 }
exit 0
