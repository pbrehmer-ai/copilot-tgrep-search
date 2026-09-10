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
    [ValidateRange(1, 1000)][int] $MaxPaths = 20,
    [ValidateRange(1, 300)][int] $TimeoutSeconds = 30
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Process.ps1')
$resolved = Resolve-SearchRoot $Root
$executable = Resolve-TgrepExecutable
$results = @()
foreach ($query in $Pattern) {
    $arguments = @('-l', '--color', 'never')
    if (-not $Regex) { $arguments += '-F' }
    if ($NoIndex) { $arguments += '--no-index' }
    foreach ($filter in $Glob) { $arguments += @('-g', $filter) }
    $arguments += @('--', $query, '.')
    $run = Invoke-CapturedProcess -Executable $executable -Arguments $arguments -Root $resolved -TimeoutSeconds $TimeoutSeconds
    $paths = @($run.Stdout -split '\r?\n' | Where-Object { $_ -ne '' })
    $results += [pscustomobject]@{
        Pattern = $query; ExitCode = $run.ExitCode; TimedOut = $run.TimedOut
        Succeeded = (-not $run.TimedOut -and $run.ExitCode -in @(0, 1))
        Stderr = $run.Stderr; ElapsedMs = $run.ElapsedMs
        ReturnedPathCount = $paths.Count; Paths = @($paths | Select-Object -First $MaxPaths)
        PathsTruncated = ($paths.Count -gt $MaxPaths)
    }
    if ($run.TimedOut) { break }
}
[pscustomobject]@{
    Root = $resolved; Executable = $executable; DirectScanRequested = [bool]$NoIndex
    RequestedQueries = $Pattern.Count; CompletedQueries = $results.Count; Results = $results
} | ConvertTo-Json -Depth 6
if (@($results | Where-Object { -not $_.Succeeded }).Count -gt 0) { exit 2 }
exit 0
