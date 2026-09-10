#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param([Parameter(Mandatory = $true)][string] $Root, [ValidateRange(5, 3600)][int] $TimeoutSeconds = 120)
& (Join-Path (Split-Path -Parent $PSScriptRoot) '.github\skills\tgrep-search\scripts\Start-Repository.ps1') @PSBoundParameters
