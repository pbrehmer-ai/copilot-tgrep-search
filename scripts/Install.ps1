#requires -Version 5.1
<#
.SYNOPSIS
Installs the pinned Microsoft tgrep release and this repository's Copilot skill.
.EXAMPLE
.\scripts\Install.ps1 -WhatIf
.EXAMPLE
.\scripts\Install.ps1
.NOTES
Per-user Windows installation. No administrator rights or policy changes required.
This is a pilot installer; Copilot behavior and performance still need validation.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This installer supports Windows only.' }
foreach ($requiredVariable in @('USERPROFILE', 'LOCALAPPDATA', 'TEMP')) {
    if (-not [Environment]::GetEnvironmentVariable($requiredVariable)) {
        throw "Required environment variable is missing: $requiredVariable"
    }
}

$version = '1.0.5'
$osArchitecture = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine')
if (-not $osArchitecture) { $osArchitecture = $env:PROCESSOR_ARCHITEW6432 }
if (-not $osArchitecture) { $osArchitecture = $env:PROCESSOR_ARCHITECTURE }
switch ($osArchitecture) {
    'AMD64' {
        $target = 'x86_64-pc-windows-msvc'
        $archiveHash = '5b6ba08ffddb5bc1b436c5c83b4f0c9e66c70a006b3853ed57daf51e7a75986c'
    }
    'ARM64' {
        $target = 'aarch64-pc-windows-msvc'
        $archiveHash = 'f49b68f97810530688a8fe71282dfc384ed4ff99ffe7a8a769e43e68a7c633fe'
    }
    default { throw "Unsupported Windows architecture: $osArchitecture. Use x64 or ARM64 Windows." }
}

$repository = Split-Path -Parent $PSScriptRoot
$skillSource = Join-Path $repository '.github\skills\tgrep-search\SKILL.md'
$instructionSource = Join-Path $repository 'instructions\copilot-tgrep.md'
$noticeSource = Join-Path $repository 'THIRD_PARTY_NOTICES.md'
foreach ($source in @($skillSource, $instructionSource, $noticeSource)) {
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Source file missing: $source" }
}
$startMarker = '<!-- copilot-tgrep-search:start -->'
$endMarker = '<!-- copilot-tgrep-search:end -->'
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$sourceBlock = [IO.File]::ReadAllText($instructionSource, $utf8).TrimEnd([char[]]"`r`n")
$blockPattern = '(?s)' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker)
if (-not $sourceBlock.StartsWith($startMarker) -or -not $sourceBlock.EndsWith($endMarker) -or
    [regex]::Matches($sourceBlock, [regex]::Escape($startMarker)).Count -ne 1 -or
    [regex]::Matches($sourceBlock, [regex]::Escape($endMarker)).Count -ne 1) {
    throw 'The source instruction file must contain exactly one complete marked block.'
}

# Retain the original encoding and BOM. Refuse text that cannot round-trip exactly.
function Read-PreservedText([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ Text = ''; Encoding = $utf8; Preamble = [byte[]]@(); Existed = $false; OriginalBytes = [byte[]]@() }
    }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $offset = 0
    $encoding = $utf8
    $signature = ''
    if ($bytes.Length -gt 0) { $signature = [BitConverter]::ToString($bytes, 0, [Math]::Min(4, $bytes.Length)) }
    if ($signature.StartsWith('FF-FE-00-00')) { $encoding = [Text.Encoding]::UTF32; $offset = 4 }
    elseif ($signature.StartsWith('00-00-FE-FF')) { $encoding = New-Object System.Text.UTF32Encoding($true, $true, $true); $offset = 4 }
    elseif ($signature.StartsWith('EF-BB-BF')) { $offset = 3 }
    elseif ($signature.StartsWith('FF-FE')) { $encoding = [Text.Encoding]::Unicode; $offset = 2 }
    elseif ($signature.StartsWith('FE-FF')) { $encoding = [Text.Encoding]::BigEndianUnicode; $offset = 2 }
    try { $content = $encoding.GetString($bytes, $offset, $bytes.Length - $offset) }
    catch {
        if ($offset -ne 0) { throw }
        $encoding = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)
        $content = $encoding.GetString($bytes)
    }
    if ($content.Contains([string][char]0)) { throw "Unsupported text encoding in $Path. Convert it to UTF-8 first." }
    $preamble = [byte[]]@()
    if ($offset -gt 0) { $preamble = [byte[]]$bytes[0..($offset - 1)] }
    $roundTrip = [byte[]]($preamble + $encoding.GetBytes($content))
    if ([Convert]::ToBase64String($roundTrip) -cne [Convert]::ToBase64String($bytes)) {
        throw "Cannot preserve the encoding of $Path. Convert it to UTF-8 first."
    }
    return @{ Text = $content; Encoding = $encoding; Preamble = $preamble; Existed = $true; OriginalBytes = $bytes }
}

$installDirectory = Join-Path $env:LOCALAPPDATA "Programs\copilot-tgrep\$version"
$executable = Join-Path $installDirectory 'tgrep.exe'
$skillDestination = Join-Path $env:USERPROFILE '.copilot\skills\tgrep-search\SKILL.md'
$noticeDestination = Join-Path (Split-Path -Parent $skillDestination) 'THIRD_PARTY_NOTICES.md'
$instructionDestination = Join-Path $env:USERPROFILE 'copilot-instructions.md'
foreach ($destination in @($executable, $skillDestination, $instructionDestination, $noticeDestination)) {
    if ((Test-Path -LiteralPath $destination) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
        throw "Expected a file at $destination. Resolve the conflict before installing."
    }
}
$existing = Read-PreservedText $instructionDestination
$startCount = [regex]::Matches($existing.Text, [regex]::Escape($startMarker)).Count
$endCount = [regex]::Matches($existing.Text, [regex]::Escape($endMarker)).Count
if ($startCount -gt 1 -or $endCount -gt 1 -or $startCount -ne $endCount -or
    ($startCount -eq 1 -and -not [regex]::IsMatch($existing.Text, $blockPattern))) {
    throw "Malformed or duplicate tgrep markers in $instructionDestination. Resolve them first."
}
$newline = "`r`n"
if ($existing.Text.Contains("`n") -and -not $existing.Text.Contains("`r`n")) { $newline = "`n" }
$sourceBlock = [regex]::Replace($sourceBlock, '\r?\n', $newline)
if ($startCount -eq 1) {
    $match = [regex]::Match($existing.Text, $blockPattern)
    $newInstructions = $existing.Text.Substring(0, $match.Index) + $sourceBlock +
        $existing.Text.Substring($match.Index + $match.Length)
}
else {
    $separator = ''
    if ($existing.Text.Length -gt 0) {
        if (-not $existing.Text.EndsWith("`n")) { $separator += $newline }
        $separator += $newline
    }
    $newInstructions = $existing.Text + $separator + $sourceBlock + $newline
}
$instructionBytes = [byte[]]($existing.Preamble + $existing.Encoding.GetBytes($newInstructions))
if ($existing.Encoding.GetString($existing.Encoding.GetBytes($newInstructions)) -cne $newInstructions) {
    throw 'The existing instruction encoding cannot represent the new text. Convert it to UTF-8 first.'
}
$originalUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$otherPathEntries = @($originalUserPath -split ';' | Where-Object { $_.Trim().TrimEnd('\') -ine $installDirectory.TrimEnd('\') })
$newUserPath = $installDirectory
if ($originalUserPath -and $otherPathEntries.Count -gt 0) { $newUserPath += ';' + ($otherPathEntries -join ';') }
foreach ($base in @($env:USERPROFILE, $repository)) {
    foreach ($relative in @('.claude\skills\tgrep-search\SKILL.md', '.agents\skills\tgrep-search\SKILL.md')) {
        $duplicate = Join-Path $base $relative
        if (Test-Path -LiteralPath $duplicate -PathType Leaf) { Write-Warning "Another tgrep-search skill exists: $duplicate. Resolve duplicate skill discovery before the pilot." }
    }
}
Write-Host 'Prerequisite: Visual Studio 2026 18.5+, Copilot Agent mode, and custom instructions enabled.'
Write-Host "Install: $executable"
Write-Host "Skill:   $skillDestination"
Write-Host "Rules:   $instructionDestination (marked section only)"
if (-not $PSCmdlet.ShouldProcess($env:USERPROFILE, "Download and install Microsoft tgrep $version; install Copilot skill and instructions; update user PATH; save recovery files")) { return }

$runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$backupDirectory = Join-Path $env:LOCALAPPDATA "copilot-tgrep-search\backups\$runId"
$stagingDirectory = Join-Path $env:TEMP "copilot-tgrep-search-$runId"
[IO.Directory]::CreateDirectory($backupDirectory) | Out-Null
[IO.Directory]::CreateDirectory($stagingDirectory) | Out-Null
$recovery = [ordered]@{
    CreatedUtc = [DateTime]::UtcNow.ToString('o'); TgrepVersion = $version
    OriginalUserPath = $originalUserPath; IntendedUserPath = $newUserPath
    Files = @(); Status = 'Preparing'; StagingDirectory = $stagingDirectory
}
$manifestPath = Join-Path $backupDirectory 'recovery.json'
function Save-Recovery {
    [IO.File]::WriteAllText($manifestPath, ($recovery | ConvertTo-Json -Depth 5), $utf8)
}
function Install-Bytes([string] $Destination, [byte[]] $Bytes, [string] $BackupName) {
    $existed = Test-Path -LiteralPath $Destination -PathType Leaf
    if ($existed -and [Convert]::ToBase64String([IO.File]::ReadAllBytes($Destination)) -ceq [Convert]::ToBase64String($Bytes)) { return }
    $backupPath = $null
    if ($existed) {
        $backupPath = Join-Path $backupDirectory $BackupName
        [IO.File]::Copy($Destination, $backupPath, $false)
    }
    $recovery.Files += [ordered]@{ Path = $Destination; Existed = $existed; Backup = $backupPath }
    Save-Recovery
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Destination)) | Out-Null
    [IO.File]::WriteAllBytes($Destination, $Bytes)
}
Save-Recovery
try {
    $archiveName = "tgrep-v$version-$target.zip"
    $archivePath = Join-Path $stagingDirectory $archiveName
    $uri = "https://github.com/microsoft/tgrep/releases/download/v$version/$archiveName"
    $previousTls = [Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol = $previousTls -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $archivePath
    }
    finally { [Net.ServicePointManager]::SecurityProtocol = $previousTls }
    if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ine $archiveHash) {
        throw 'Downloaded archive SHA256 does not match the pinned official release. Nothing was installed.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        # Extract only the expected root executable; never trust arbitrary archive paths.
        $entries = @($archive.Entries | Where-Object { $_.FullName -ceq 'tgrep.exe' })
        if ($entries.Count -ne 1) { throw 'Expected exactly one root tgrep.exe in the official archive.' }
        $extractedPath = Join-Path $stagingDirectory 'tgrep.exe'
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entries[0], $extractedPath, $false)
    }
    finally { $archive.Dispose() }
    # A download or confirmation can take time; do not overwrite intervening user edits.
    $currentInstructionExists = Test-Path -LiteralPath $instructionDestination
    $instructionSnapshotChanged = $currentInstructionExists -ne $existing.Existed
    if (-not $instructionSnapshotChanged -and $currentInstructionExists) {
        if (-not (Test-Path -LiteralPath $instructionDestination -PathType Leaf)) {
            $instructionSnapshotChanged = $true
        }
        else {
            $instructionSnapshotChanged = [Convert]::ToBase64String([IO.File]::ReadAllBytes($instructionDestination)) -cne
                [Convert]::ToBase64String($existing.OriginalBytes)
        }
    }
    $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($instructionSnapshotChanged -or -not [string]::Equals($currentUserPath, $originalUserPath, [StringComparison]::Ordinal)) {
        throw 'Personal instructions or user PATH changed while setup was preparing. No managed files or PATH were updated. Retry setup after saving your changes.'
    }
    Install-Bytes $executable ([IO.File]::ReadAllBytes($extractedPath)) 'tgrep.exe.before'
    Install-Bytes $skillDestination ([IO.File]::ReadAllBytes($skillSource)) 'SKILL.md.before'
    Install-Bytes $noticeDestination ([IO.File]::ReadAllBytes($noticeSource)) 'THIRD_PARTY_NOTICES.md.before'
    Install-Bytes $instructionDestination $instructionBytes 'copilot-instructions.md.before'
    if ($newUserPath -cne $originalUserPath) {
        [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
    }
    $recovery.Status = 'Installed'
    Save-Recovery
    Write-Host "Files installed, including Microsoft tgrep $version; functional validation pending. No server was started or test run."
    Write-Host 'Completely restart Visual Studio and terminals to pick up the user PATH, then follow the README.'
    Write-Host "Recovery manifest and original files: $backupDirectory"
    Write-Host "Verified download retained for inspection: $stagingDirectory"
}
catch {
    $recovery.Status = 'Failed: ' + $_.Exception.Message
    Save-Recovery
    Write-Warning "Setup did not complete. Review $manifestPath before retrying or restoring; partial changes may exist."
    throw
}
