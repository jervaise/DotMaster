# Libraries to download
$libraries = @(
  "LibStub",
  "CallbackHandler-1.0",
  "AceAddon-3.0",
  "AceConsole-3.0",
  "AceDB-3.0",
  "AceDBOptions-3.0",
  "AceEvent-3.0",
  "AceTimer-3.0",
  "AceHook-3.0",
  "AceGUI-3.0",
  "AceConfig-3.0"
)

# Loop through and download each library
foreach ($lib in $libraries) {
  Write-Host "Processing $lib..."
  & .\download_ace_library.ps1 -LibraryName $lib
}

# For AceConfig-3.0, we need to download additional files
$aceConfigDir = "Libs\AceConfig-3.0"
$baseUrl = "https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceConfig-3.0"

# These are part of the same package but not in subdirectories
$additionalFiles = @(
  @{Name = "AceConfigCmd-3.0"; File = "AceConfigCmd-3.0.lua" },
  @{Name = "AceConfigDialog-3.0"; File = "AceConfigDialog-3.0.lua" },
  @{Name = "AceConfigRegistry-3.0"; File = "AceConfigRegistry-3.0.lua" }
)

foreach ($file in $additionalFiles) {
  $url = "$baseUrl/$($file.File)"
  $outputPath = "$aceConfigDir\$($file.File)"
    
  Write-Host "Downloading $($file.File) to $outputPath..."
  Invoke-WebRequest -Uri $url -OutFile $outputPath
  Write-Host "Downloaded successfully."
}

Write-Host "All libraries downloaded." 