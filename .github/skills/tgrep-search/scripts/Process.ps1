#requires -Version 5.1
# Shared by the setup and search helpers; no shell evaluation of search text.
function Resolve-TgrepExecutable {
    $candidate = Join-Path $env:LOCALAPPDATA 'Programs\copilot-tgrep\1.0.5\tgrep.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    return (Get-Command tgrep -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
}

function ConvertTo-NativeArgument([string] $Value) {
    # Windows CommandLineToArgvW quoting, including quotes and trailing backslashes.
    return '"' + [regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
}

function Invoke-CapturedProcess {
    param([string] $Executable, [string[]] $Arguments, [string] $Root, [int] $TimeoutSeconds = 30)
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $Executable
    $info.Arguments = (($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    $info.WorkingDirectory = $Root
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
    $info.StandardErrorEncoding = New-Object Text.UTF8Encoding($false)
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    $timer = [Diagnostics.Stopwatch]::StartNew()
    try {
        if (-not $process.Start()) { throw 'Could not start the requested executable.' }
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) { $process.Kill(); $process.WaitForExit() }
        $timer.Stop()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode; TimedOut = $timedOut
            Stdout = $outTask.GetAwaiter().GetResult(); Stderr = $errTask.GetAwaiter().GetResult()
            ElapsedMs = [Math]::Round($timer.Elapsed.TotalMilliseconds, 3)
        }
    }
    finally { $process.Dispose() }
}

function Resolve-SearchRoot([string] $Root) {
    $resolved = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).ProviderPath
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) { throw 'Root must be a directory.' }
    if ($resolved.TrimEnd('\', '/') -eq [IO.Path]::GetPathRoot($resolved).TrimEnd('\', '/')) {
        throw 'Select a repository/source directory, not a drive or share root.'
    }
    return $resolved
}
