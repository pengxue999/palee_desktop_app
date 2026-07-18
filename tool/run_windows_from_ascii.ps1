param(
  [switch]$Build,
  [switch]$Debug,
  [switch]$Release,
  [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$asciiRoot = 'D:\A'
$asciiProjectPath = Join-Path $asciiRoot 'palee_elite_training_center_windows'

function Test-StaleWindowsCmakeCache {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
  )

  $cachePath = Join-Path $ProjectRoot 'build\windows\x64\CMakeCache.txt'
  if (-not (Test-Path $cachePath)) {
    return $false
  }

  $cacheContent = Get-Content -Path $cachePath -Raw
  $expectedBuildDir = (Join-Path $ProjectRoot 'build\windows\x64').Replace('\', '/')
  $expectedSourceDir = (Join-Path $ProjectRoot 'windows').Replace('\', '/')

  return -not (
    $cacheContent.Contains($expectedBuildDir) -and
    $cacheContent.Contains($expectedSourceDir)
  )
}

if (-not (Test-Path $asciiRoot)) {
  New-Item -ItemType Directory -Path $asciiRoot | Out-Null
}

if (Test-Path $asciiProjectPath) {
  $existingItem = Get-Item $asciiProjectPath
  if (-not ($existingItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw "Path '$asciiProjectPath' already exists and is not a junction."
  }
} else {
  New-Item -ItemType Junction -Path $asciiProjectPath -Target $projectPath | Out-Null
}

Push-Location $asciiProjectPath
try {
  $wrapperSource = Join-Path $asciiProjectPath 'windows\flutter\ephemeral\cpp_client_wrapper\core_implementations.cc'
  $hasStaleWindowsCache = Test-StaleWindowsCmakeCache -ProjectRoot $asciiProjectPath

  if ($hasStaleWindowsCache) {
    Write-Host 'Windows CMake cache points to a different project path. Running flutter clean first.'
    flutter clean
  }

  if (-not $Clean -and -not (Test-Path $wrapperSource)) {
    Write-Host 'Windows generated artifacts are missing. Running flutter clean first.'
    flutter clean
  }

  if ($Clean) {
    flutter clean
  }

  if ($Build) {
    flutter build windows
    exit $LASTEXITCODE
  }

  $runArgs = @('run', '-d', 'windows')
  if ($Release) {
    $runArgs += '--release'
  } else {
    $runArgs += '--debug'
  }

  flutter @runArgs
  exit $LASTEXITCODE
}
finally {
  Pop-Location
}