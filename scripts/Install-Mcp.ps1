#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string[]] $RepositoryRoot,
    [string] $NodePath,
    [switch] $IncludeInvestigator
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\.github\skills\tgrep-search\scripts\Process.ps1')
$roots = @($RepositoryRoot | ForEach-Object { Resolve-SearchRoot $_ } | Select-Object -Unique)
if (-not $NodePath) { $NodePath = (Get-Command node -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source }
$NodePath = (Resolve-Path -LiteralPath $NodePath).ProviderPath
$nodeVersion = & $NodePath --version
if ($LASTEXITCODE -ne 0 -or $nodeVersion -notmatch '^v(\d+)\.' -or [int]$Matches[1] -lt 22) { throw 'Use an approved Node.js 22+ executable.' }
$tgrep = Resolve-TgrepExecutable
$version = & $tgrep --version
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^tgrep 1\.0\.5\b') { throw 'Prepare tgrep 1.0.5 with Install.ps1 first.' }
$destination = Join-Path $env:LOCALAPPDATA 'copilot-tgrep-search\mcp'
$serverFile = Join-Path $destination 'server.mjs'
$configuration = Join-Path $env:USERPROFILE '.mcp.json'
$agentFile = Join-Path $env:USERPROFILE '.github\agents\tgrep-investigator.agent.md'
$repo = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repo 'mcp\server.mjs'
$agentSource = Join-Path $repo 'agents\tgrep-investigator.agent.md'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'Missing MCP server in this package.' }
$config = [pscustomobject]@{ servers = [pscustomobject]@{} }
if (Test-Path -LiteralPath $configuration) { $config = Get-Content -LiteralPath $configuration -Raw | ConvertFrom-Json }
if ($null -eq $config -or $config -is [array] -or $config -isnot [pscustomobject]) { throw 'Expected a JSON object in .mcp.json.' }
if (-not $config.PSObject.Properties['servers']) { $config | Add-Member NoteProperty servers ([pscustomobject]@{}) }
if ($config.servers -isnot [pscustomobject]) { throw 'Expected an object in .mcp.json servers.' }
if ($config.servers.PSObject.Properties['tgrep']) {
    $existing = $config.servers.tgrep
    if (-not $existing.PSObject.Properties['args'] -or $existing.args.Count -eq 0 -or $existing.args[0] -ne $serverFile) {
        throw 'An unrelated tgrep MCP entry exists. Review it before choosing this integration.'
    }
}
$arguments = @($serverFile, '--exe', $tgrep)
foreach ($root in $roots) { $arguments += @('--root', $root) }
$entry = [pscustomobject]@{ type = 'stdio'; command = $NodePath; args = $arguments }
if ($config.servers.PSObject.Properties['tgrep']) { $config.servers.tgrep = $entry }
else { $config.servers | Add-Member NoteProperty tgrep $entry }
if (-not $PSCmdlet.ShouldProcess($configuration, 'Install read-only tgrep MCP adapter and replace its configured root list')) { return }
$backup = Join-Path $env:LOCALAPPDATA ('copilot-tgrep-search\backups\mcp-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$targets = @($configuration, $serverFile)
if ($IncludeInvestigator) { $targets += $agentFile }
$manifest = @()
foreach ($target in $targets) {
    $saved = $null
    if (Test-Path -LiteralPath $target -PathType Leaf) {
        $saved = Join-Path $backup ([string]$manifest.Count + '.backup')
        Copy-Item -LiteralPath $target -Destination $saved
    }
    $manifest += [pscustomobject]@{ Target = $target; Backup = $saved }
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $backup 'manifest.json') -Encoding UTF8
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $serverFile -Force
if ($IncludeInvestigator) {
    New-Item -ItemType Directory -Path (Split-Path $agentFile -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $agentSource -Destination $agentFile -Force
}
[IO.File]::WriteAllText($configuration, ($config | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding($false)))
Write-Output "Configured $($roots.Count) root(s). Recovery manifest: $(Join-Path $backup 'manifest.json')"
Write-Output 'Restart Visual Studio. Enable tgrep in Tools and review any trust prompt yourself. This installer does not grant tool permissions.'
Write-Output 'Prepare each configured root with Start-Repository.ps1 before searching. MCP searches do not build or restart indexes.'
