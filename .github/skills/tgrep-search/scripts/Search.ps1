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
    $results += [pscustomobject]@{
        Pattern = $query; ExitCode = $run.ExitCode; TimedOut = $run.TimedOut
        Succeeded = $succeeded
        Stderr = $run.Stderr; ElapsedMs = $run.ElapsedMs
        MatchFileCount = $matchCount
        ReturnedPathCount = $paths.Count; Paths = @($paths | Select-Object -First $pathLimit)
        PathsTruncated = ($paths.Count -gt $pathLimit)
    }
    if ($run.TimedOut) { break }
}
[pscustomobject]@{
    Root = $resolved; Executable = $executable; DirectScanRequested = [bool]$NoIndex
    SearchMode = $(if ($NoIndex) { 'direct-scan-requested' } else { 'index-eligible' })
    PathLimit = $pathLimit
    ReadinessChecked = $readinessChecked; SetupRequired = $false
    ReadinessStderr = $readinessStderr
    RequestedQueries = $Pattern.Count; CompletedQueries = $results.Count; Results = $results
} | ConvertTo-Json -Depth 6 -Compress
if (@($results | Where-Object { -not $_.Succeeded }).Count -gt 0) { exit 2 }
exit 0
