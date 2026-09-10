#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$helpers = Join-Path $repository '.github\skills\tgrep-search\scripts'
. (Join-Path $helpers 'Process.ps1')
function Assert([bool] $Condition, [string] $Message) { if (-not $Condition) { throw $Message } }
$parseFiles = Get-ChildItem -LiteralPath $repository -Recurse -Filter '*.ps1' -File
foreach ($file in $parseFiles) {
    $tokens = $null; $errors = $null
    [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    Assert ($errors.Count -eq 0) "PowerShell parse error: $($file.FullName): $errors"
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('copilot tgrep helper test ' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture) | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false)
$git = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$gitInit = Invoke-CapturedProcess $git @('init', '--quiet') $fixture
Assert ($gitInit.ExitCode -eq 0) 'git init failed'
$excludePath = Join-Path $fixture '.git\info\exclude'
[IO.File]::WriteAllText($excludePath, '# retain this rule', $utf8)
foreach ($name in @('one.cs', 'two with space.cs', 'unicode-é.cs')) {
    [IO.File]::WriteAllText((Join-Path $fixture $name), "OrderService`nliteral `"double`" path\`n", $utf8)
}
[IO.Directory]::CreateDirectory((Join-Path $fixture 'bin')) | Out-Null
[IO.File]::WriteAllText((Join-Path $fixture 'bin\excluded.cs'), 'OrderService', $utf8)
$serverPid = $null
try {
    & (Join-Path $helpers 'Start-Repository.ps1') -Root $fixture -WhatIf
    Assert (-not (Test-Path -LiteralPath (Join-Path $fixture '.tgrep'))) 'WhatIf created an index'
    Assert ([IO.File]::ReadAllText($excludePath) -ceq '# retain this rule') 'WhatIf changed Git exclusions'
    & (Join-Path $helpers 'Start-Repository.ps1') -Root $fixture -TimeoutSeconds 30
    $status = Invoke-CapturedProcess (Resolve-TgrepExecutable) @('status', '.') $fixture
    $serverPid = [int]([regex]::Match($status.Stdout, '(?m)^\s*PID:\s+(\d+)').Groups[1].Value)
    Assert ($serverPid -gt 0) 'No test server PID found'
    & (Join-Path $helpers 'Start-Repository.ps1') -Root $fixture -TimeoutSeconds 10
    $reused = Invoke-CapturedProcess (Resolve-TgrepExecutable) @('status', '.') $fixture
    Assert ($reused.Stdout -match "PID:\s+$serverPid\b") 'Setup did not reuse the server'
    Assert ([IO.File]::ReadAllText($excludePath).StartsWith('# retain this rule')) 'Original exclusion content lost'
    $ignored = Invoke-CapturedProcess $git @('status', '--short', '--untracked-files=all', '--', '.tgrep') $fixture
    Assert ($ignored.ExitCode -eq 0 -and $ignored.Stdout -eq '') 'Index is not excluded from Git'
    $nestedRejected = $false
    try { & (Join-Path $helpers 'Start-Repository.ps1') -Root (Join-Path $fixture 'bin') -WhatIf } catch { $nestedRejected = $true }
    Assert $nestedRejected 'Nested root was not rejected'
    $driveRejected = $false
    try { Resolve-SearchRoot ([IO.Path]::GetPathRoot($fixture)) | Out-Null } catch { $driveRejected = $true }
    Assert $driveRejected 'Drive root was not rejected'
    $batch = (& (Join-Path $helpers 'Search.ps1') -Root $fixture -Pattern @('OrderService', 'missing-unique', 'literal "double" path\') -Glob @('*.cs', '!**/bin/**') -MaxPaths 1 -CheckReady) | ConvertFrom-Json
    Assert ($batch.ReadinessChecked -and -not $batch.SetupRequired) 'Combined readiness/search failed'
    $unready = (& (Join-Path $helpers 'Search.ps1') -Root (Join-Path $fixture 'bin') -Pattern 'OrderService' -CheckReady) | ConvertFrom-Json
    Assert ($unready.SetupRequired -and $unready.CompletedQueries -eq 0 -and $unready.Results.Count -eq 0) 'Unprepared root was searched despite readiness guard'
    Assert ($batch.CompletedQueries -eq 3) 'Batch query lost'
    Assert ($batch.Results[0].ReturnedPathCount -eq 3 -and $batch.Results[0].PathsTruncated) 'Count/truncation/filter failed'
    Assert ($batch.Results[0].MatchFileCount -eq 3 -and $batch.Results[0].Paths[0] -ceq 'one.cs') 'Full count or sorted normalized sample failed'
    Assert ($batch.SearchMode -eq 'index-eligible') 'Default search unexpectedly requests a scan'
    Assert ($batch.Results[1].ExitCode -eq 1 -and $batch.Results[1].Succeeded) 'No-match exit code lost'
    Assert ($batch.Results[2].ReturnedPathCount -eq 3) 'Native argument quoting failed'
    $countOnlyText = & (Join-Path $helpers 'Search.ps1') -Root $fixture -Pattern 'OrderService' -Glob '*.cs','!**/bin/**' -MaxPaths 0
    $countOnly = $countOnlyText | ConvertFrom-Json
    Assert ($countOnly.Results[0].MatchFileCount -eq 3 -and $countOnly.Results[0].Paths.Count -eq 0 -and $countOnly.Results[0].PathsTruncated) 'Counts-only mode failed'
    Assert ($countOnlyText -notmatch '[\r\n]') 'Output is not compact JSON'
    $oversized = (& (Join-Path $helpers 'Search.ps1') -Root $fixture -Pattern 'OrderService' -Glob '*.cs','!**/bin/**' -MaxPaths 100000) | ConvertFrom-Json
    Assert ($oversized.PathLimit -eq 1000 -and $oversized.Results[0].MatchFileCount -eq 3) 'Oversized sample request was not safely capped'
    $bad = (& (Join-Path $helpers 'Search.ps1') -Root $fixture -Pattern '[' -Regex) | ConvertFrom-Json
    Assert ($bad.Results[0].ExitCode -eq 2 -and -not $bad.Results[0].Succeeded -and $bad.Results[0].Stderr) 'Regex error hidden'
    Assert ($null -eq $bad.Results[0].MatchFileCount) 'Error reported an authoritative count'
    [IO.File]::WriteAllText((Join-Path $fixture 'saved.cs'), 'FreshSavedMarker', $utf8)
    $fresh = (& (Join-Path $helpers 'Search.ps1') -Root $fixture -Pattern 'FreshSavedMarker' -NoIndex) | ConvertFrom-Json
    Assert ($fresh.Results[0].ReturnedPathCount -eq 1) 'Direct scan missed saved data'
    Assert ($fresh.SearchMode -eq 'direct-scan-requested') 'Direct scan mode not reported'
    $testProfile = Join-Path $fixture 'isolated-user'
    $testSkill = Join-Path $testProfile '.copilot\skills\tgrep-search'
    [IO.Directory]::CreateDirectory($testSkill) | Out-Null
    Copy-Item -LiteralPath (Join-Path $repository '.github\skills\tgrep-search\SKILL.md') -Destination $testSkill
    Copy-Item -LiteralPath $helpers -Destination $testSkill -Recurse
    Copy-Item -LiteralPath (Join-Path $repository '.github\skills\tgrep-search\references') -Destination $testSkill -Recurse
    Copy-Item -LiteralPath (Join-Path $repository 'THIRD_PARTY_NOTICES.md') -Destination $testSkill
    Copy-Item -LiteralPath (Join-Path $repository 'instructions\copilot-tgrep.md') -Destination (Join-Path $testProfile 'copilot-instructions.md')
    $previousProfile = $env:USERPROFILE
    try {
        $env:USERPROFILE = $testProfile
        $check = (& (Join-Path $repository 'scripts\Check-Setup.ps1') -Root $fixture) | ConvertFrom-Json
        Assert ($check.ReadyForChatCheck -and $check.Issues.Count -eq 0) 'Installed package verification failed'
        [IO.File]::AppendAllText((Join-Path $testSkill 'SKILL.md'), 'fixture mismatch')
        $mismatch = (& (Join-Path $repository 'scripts\Check-Setup.ps1') -Root $fixture) | ConvertFrom-Json
        Assert (-not $mismatch.InstallationMatchesCheckout -and $mismatch.Issues.Count -gt 0) 'Stale installed skill was not detected'
    } finally { $env:USERPROFILE = $previousProfile }
    $shellExe = (Get-Process -Id $PID).Path
    $timeout = Invoke-CapturedProcess $shellExe @('-NoProfile', '-Command', 'Start-Sleep -Seconds 5') $fixture 1
    Assert $timeout.TimedOut 'Client timeout did not trigger'
    [IO.File]::WriteAllText((Join-Path $fixture '.tgrep\tracked-probe'), 'fixture only', $utf8)
    $addProbe = Invoke-CapturedProcess $git @('add', '-f', '--', '.tgrep/tracked-probe') $fixture
    Assert ($addProbe.ExitCode -eq 0) 'Could not prepare tracked-index guard test'
    $trackedRejected = $false
    try { & (Join-Path $helpers 'Start-Repository.ps1') -Root $fixture } catch { $trackedRejected = $true }
    Assert $trackedRejected 'Tracked .tgrep was not rejected'
    Write-Output 'PASS: parsing, preview, readiness, server reuse, Git exclusion, tracked-index guard, root boundaries, batching, filters, truncation, Unicode paths, quoting, errors, no-match, direct freshness, client timeout.'
}
finally {
    if ($serverPid) { Stop-Process -Id $serverPid -ErrorAction SilentlyContinue }
    Write-Host "Test fixture retained for inspection: $fixture"
}
