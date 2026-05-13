# run_tests.apls → duck.db.runAllTests. Dyalog exes on PATH: default dyascript.exe;
# override with $env:DUCKDB_DYALOG_SCRIPT (exe name or full path).
$ErrorActionPreference = 'Stop'$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repo
$apls = (Resolve-Path (Join-Path $repo 'run_tests.apls')).Path
$runner = $env:DUCKDB_DYALOG_SCRIPT
if (-not $runner) { $runner = 'dyascript.exe' }
& $runner $apls
exit $LASTEXITCODE
