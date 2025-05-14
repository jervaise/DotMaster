$libraryRepos = @{
  "Ace3"               = "https://github.com/WoWUIDev/Ace3/archive/refs/heads/master.zip"
  "LibSharedMedia-3.0" = "https://github.com/Itarater/LibSharedMedia-3.0/archive/refs/heads/master.zip"
  "LibDataBroker-1.1"  = "https://github.com/tekkub/libdatabroker-1-1/archive/refs/heads/master.zip"
  "LibDBIcon-1.0"      = "https://github.com/AcidWeb/LibDBIcon-1.0/archive/refs/heads/master.zip"
}

$tempDir = Join-Path $env:TEMP "WowLibs"
if (-not (Test-Path $tempDir)) {
  New-Item -ItemType Directory -Path $tempDir | Out-Null
}

$libsDir = Join-Path $PSScriptRoot "Libs"
if (-not (Test-Path $libsDir)) {
  New-Item -ItemType Directory -Path $libsDir | Out-Null
}

foreach ($libraryName in $libraryRepos.Keys) {
  $repoUrl = $libraryRepos[$libraryName]
  $zipPath = Join-Path $tempDir "$libraryName.zip"
  $extractPath = Join-Path $tempDir $libraryName
    
  Write-Host "Downloading $libraryName from $repoUrl"
  try {
    Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -ErrorAction Stop
    
    if (Test-Path $extractPath) {
      Remove-Item -Path $extractPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $extractPath | Out-Null
    
    Write-Host "Extracting $libraryName"
    Expand-Archive -Path $zipPath -DestinationPath $extractPath
    
    $extractedDir = Get-ChildItem -Path $extractPath | Select-Object -First 1
    if ($extractedDir) {
      $sourceDir = $extractedDir.FullName
        
      # For Ace3, we need to copy all the individual libraries
      if ($libraryName -eq "Ace3") {
        Get-ChildItem -Path $sourceDir -Directory | ForEach-Object {
          $destPath = Join-Path $libsDir $_.Name
          if (Test-Path $destPath) {
            Remove-Item -Path $destPath -Recurse -Force
          }
          Write-Host "Installing $($_.Name) to $destPath"
          Copy-Item -Path $_.FullName -Destination $destPath -Recurse
        }
      }
      else {
        # For other libraries, we copy the entire directory
        $destPath = Join-Path $libsDir $libraryName
        if (Test-Path $destPath) {
          Remove-Item -Path $destPath -Recurse -Force
        }
        Write-Host "Installing $libraryName to $destPath"
        Copy-Item -Path $sourceDir -Destination $destPath -Recurse
      }
    }
  }
  catch {
    Write-Host "Error downloading or extracting $libraryName. Error: $_"
  }
}

# Also download AceGUI-3.0-SharedMediaWidgets from a separate repo
try {
  $libraryName = "AceGUI-3.0-SharedMediaWidgets"
  $repoUrl = "https://github.com/Itarater/AceGUI-3.0-SharedMediaWidgets/archive/refs/heads/master.zip"
  $zipPath = Join-Path $tempDir "$libraryName.zip"
  $extractPath = Join-Path $tempDir $libraryName
  
  Write-Host "Downloading $libraryName from $repoUrl"
  Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -ErrorAction Stop
  
  if (Test-Path $extractPath) {
    Remove-Item -Path $extractPath -Recurse -Force
  }
  New-Item -ItemType Directory -Path $extractPath | Out-Null
  
  Write-Host "Extracting $libraryName"
  Expand-Archive -Path $zipPath -DestinationPath $extractPath
  
  $extractedDir = Get-ChildItem -Path $extractPath | Select-Object -First 1
  if ($extractedDir) {
    $sourceDir = $extractedDir.FullName
    $destPath = Join-Path $libsDir $libraryName
    if (Test-Path $destPath) {
      Remove-Item -Path $destPath -Recurse -Force
    }
    Write-Host "Installing $libraryName to $destPath"
    Copy-Item -Path $sourceDir -Destination $destPath -Recurse
  }
}
catch {
  Write-Host "Error downloading or extracting $libraryName. Error: $_"
}

Write-Host "All libraries have been installed successfully!" 