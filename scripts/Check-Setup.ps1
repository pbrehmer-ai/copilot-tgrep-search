#requires -Version 5.1
<# Read-only installation/server check. Does not prove Copilot skill activation. #>
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string] $Root)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
. (Join-Path $repository '.github\skills\tgrep-search\scripts\Process.ps1')
$resolved = Resolve-SearchRoot $Root
$skillRoot = Join-Path $env:USERPROFILE '.copilot\skills\tgrep-search'
$issues = New-Object 'Collections.Generic.List[string]'
foreach ($relative in @('SKILL.md', 'scripts\Process.ps1', 'scripts\Search.ps1', 'scripts\Start-Repository.ps1', 'references\advanced.md', 'THIRD_PARTY_NOTICES.md')) {
    $source = Join-Path $repository ('.github\skills\tgrep-search\' + $relative)
    if ($relative -eq 'THIRD_PARTY_NOTICES.md') { $source = Join-Path $repository $relative }
    $destination = Join-Path $skillRoot $relative
    if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { $issues.Add("Missing installed file: $relative"); continue }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash) {
        $issues.Add("Installed file differs from this checkout: $relative")
    }
}
$rulePath = Join-Path $env:USERPROFILE 'copilot-instructions.md'
$expectedRule = ([IO.File]::ReadAllText((Join-Path $repository 'instructions\copilot-tgrep.md')) -replace '\r\n', "`n").Trim()
if (-not (Test-Path -LiteralPath $rulePath -PathType Leaf)) { $issues.Add('Personal instructions are missing.') }
else {
    $actualRule = [IO.File]::ReadAllText($rulePath) -replace '\r\n', "`n"
    if (-not $actualRule.Contains($expectedRule)) { $issues.Add('Current marked search preference is missing or differs.') }
}
$binary = Join-Path $env:LOCALAPPDATA 'Programs\copilot-tgrep\1.0.5\tgrep.exe'
$serverReady = $false
$versionText = $null
if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) { $issues.Add('Pinned tgrep executable is missing.') }
else {
    $version = Invoke-CapturedProcess $binary @('--version') $resolved 10
    $versionText = $version.Stdout.Trim()
    if ($version.TimedOut -or $version.ExitCode -ne 0 -or $versionText -notmatch '\b1\.0\.5\b') { $issues.Add('Pinned tgrep version check failed.') }
    else {
        $status = Invoke-CapturedProcess $binary @('status', '.') $resolved 10
        $serverReady = -not $status.TimedOut -and $status.ExitCode -eq 0 -and
            $status.Stdout -match '(?m)^Server status for ' -and
            $status.Stdout -match '(?m)^\s*Indexing:\s+complete\s*$' -and
            $status.Stdout -match '(?m)^\s*Watcher:\s+active\b'
        if ($status.Stderr) { $issues.Add($status.Stderr.Trim()) }
    }
}
$installationReady = $issues.Count -eq 0
[pscustomobject]@{
    IntegrationVersion = '0.4.1-pilot'; Root = $resolved; TgrepVersion = $versionText
    InstallationMatchesCheckout = $installationReady; ServerInitiallyReady = [bool]$serverReady
    ReadyForChatCheck = ($installationReady -and $serverReady); Issues = @($issues.ToArray())
    NextStep = 'Restart Visual Studio if just installed. In a fresh Agent chat, verify skill activation, an actual query and a completed answer. Initial readiness does not prove freshness or indexed execution.'
} | ConvertTo-Json -Depth 4 -Compress
if (-not $installationReady -or -not $serverReady) { exit 2 }
exit 0
