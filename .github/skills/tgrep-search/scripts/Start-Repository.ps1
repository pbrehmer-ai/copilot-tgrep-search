#requires -Version 5.1
<#!
Prepare the default root-local index once per repository/session. Reuses a live
server, never rebuilds or kills one. Supports preview without writes or downloads.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string] $Root,
    [ValidateRange(5, 3600)][int] $TimeoutSeconds = 120
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Process.ps1')
$resolved = Resolve-SearchRoot $Root
$executable = Resolve-TgrepExecutable
$version = Invoke-CapturedProcess $executable @('--version') $resolved 10
if ($version.ExitCode -ne 0 -or $version.TimedOut -or $version.Stdout -notmatch '\b1\.0\.5\b') {
    throw 'This helper requires the reviewed tgrep 1.0.5 executable.'
}
$git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
$gitRoot = $null
if ($git) {
    $probe = Invoke-CapturedProcess $git.Source @('rev-parse', '--show-toplevel') $resolved 10
    if ($probe.ExitCode -eq 0 -and -not $probe.TimedOut) { $gitRoot = $probe.Stdout.Trim() }
}
if ($gitRoot -and [IO.Path]::GetFullPath($gitRoot).TrimEnd('\') -ine $resolved.TrimEnd('\')) {
    throw "Root is inside a Git checkout. Use its source root: $gitRoot"
}
if (-not $PSCmdlet.ShouldProcess($resolved, 'Exclude local .tgrep from Git if needed; start or reuse tgrep server; wait for initial index completion')) { return }

if ($gitRoot) {
    $tracked = Invoke-CapturedProcess $git.Source @('ls-files', '--', '.tgrep') $resolved 10
    if ($tracked.TimedOut -or $tracked.ExitCode -ne 0 -or $tracked.Stdout.Trim()) {
        throw 'Cannot prepare this root: .tgrep may already be tracked, or the Git check failed. Resolve it through your normal Git review first.'
    }
    $ignored = Invoke-CapturedProcess $git.Source @('check-ignore', '-q', '--', '.tgrep/copilot-ignore-probe') $resolved 10
    if ($ignored.TimedOut -or $ignored.ExitCode -notin @(0, 1)) { throw 'Cannot verify the Git index exclusion.' }
    if ($ignored.ExitCode -eq 1) {
        $excludeResult = Invoke-CapturedProcess $git.Source @('rev-parse', '--git-path', 'info/exclude') $resolved 10
        if ($excludeResult.ExitCode -ne 0 -or $excludeResult.TimedOut) { throw 'Cannot locate the local Git exclude file.' }
        $exclude = $excludeResult.Stdout.Trim()
        if (-not [IO.Path]::IsPathRooted($exclude)) { $exclude = Join-Path $resolved $exclude }
        $backup = Join-Path $env:LOCALAPPDATA ('copilot-tgrep-search\repository-backups\' + [Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($backup) | Out-Null
        if (Test-Path -LiteralPath $exclude) { Copy-Item -LiteralPath $exclude -Destination (Join-Path $backup 'exclude.before') }
        [IO.File]::WriteAllText((Join-Path $backup 'root.txt'), $resolved)
        [IO.Directory]::CreateDirectory((Split-Path -Parent $exclude)) | Out-Null
        # Append bytes only; retain all original bytes and rules.
        [IO.File]::AppendAllText($exclude, "`n/.tgrep/`n", (New-Object Text.UTF8Encoding($false)))
        $verify = Invoke-CapturedProcess $git.Source @('check-ignore', '-q', '--', '.tgrep/copilot-ignore-probe') $resolved 10
        if ($verify.ExitCode -ne 0 -or $verify.TimedOut) { throw "Git exclusion is still ineffective. Review $exclude before starting a server." }
        Write-Host "Local Git exclude backup: $backup"
    }
} else { Write-Warning 'Not a Git checkout. Exclude .tgrep from your version-control and backup workflow yourself.' }

$status = Invoke-CapturedProcess $executable @('status', '.') $resolved 10
if ($status.TimedOut -or $status.ExitCode -ne 0) { throw "Cannot read tgrep status: $($status.Stderr)" }
$startedPid = $null
if ($status.Stdout -notmatch '(?m)^Server status for ') {
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $executable; $info.Arguments = 'serve .'; $info.WorkingDirectory = $resolved
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $server = [Diagnostics.Process]::Start($info)
    $startedPid = $server.Id
    $server.Dispose()
    Write-Host "Started tgrep PID $startedPid for $resolved. It remains running after this helper exits."
}
$wait = [Diagnostics.Stopwatch]::StartNew()
do {
    $status = Invoke-CapturedProcess $executable @('status', '.') $resolved 10
    if ($status.ExitCode -ne 0 -or $status.TimedOut) { throw "Status failed; no server was stopped. $($status.Stderr)" }
    if ($status.Stdout -match '(?m)^Server status for ' -and $status.Stdout -match '(?m)^\s*Indexing:\s+complete\s*$') {
        if ($status.Stdout -notmatch '(?m)^\s*Watcher:\s+active\b') { throw 'Index exists but watcher is not active. Review status; no server was stopped.' }
        Write-Output $status.Stdout
        Write-Output 'READY: initial indexing complete, watcher active. This is not a guarantee of current-file freshness.'
        return
    }
    if ($wait.Elapsed.TotalSeconds -ge $TimeoutSeconds) { break }
    Start-Sleep -Seconds 3
} while ($true)
throw "Initial indexing did not complete within $TimeoutSeconds seconds. No server was stopped. Inspect tgrep status at '$resolved'; do not repeat installation or trust partial search results."
