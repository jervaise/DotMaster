# Download script for Ace3 libraries
$libraries = @(
  @{Path = "LibStub"; File = "LibStub.lua" },
  @{Path = "CallbackHandler-1.0"; File = "CallbackHandler-1.0.lua" },
  @{Path = "AceAddon-3.0"; File = "AceAddon-3.0.lua" },
  @{Path = "AceConsole-3.0"; File = "AceConsole-3.0.lua" },
  @{Path = "AceDB-3.0"; File = "AceDB-3.0.lua" },
  @{Path = "AceDBOptions-3.0"; File = "AceDBOptions-3.0.lua" },
  @{Path = "AceEvent-3.0"; File = "AceEvent-3.0.lua" },
  @{Path = "AceTimer-3.0"; File = "AceTimer-3.0.lua" },
  @{Path = "AceHook-3.0"; File = "AceHook-3.0.lua" },
  @{Path = "AceGUI-3.0"; File = "AceGUI-3.0.lua" },
  @{Path = "AceConfig-3.0"; File = "AceConfig-3.0.lua" }
)

$baseUrl = "https://raw.githubusercontent.com/WoWUIDev/Ace3/master"

foreach ($lib in $libraries) {
  $url = "$baseUrl/$($lib.Path)/$($lib.File)"
  $outputPath = "Libs/$($lib.Path)/$($lib.File)"
    
  Write-Host "Downloading $($lib.File) to $outputPath..."
  Invoke-WebRequest -Uri $url -OutFile $outputPath
  Write-Host "Downloaded successfully."
}

# AceConfig-3.0 has multiple files in its directory
$aceConfigFiles = @("AceConfigCmd-3.0.lua", "AceConfigDialog-3.0.lua", "AceConfigRegistry-3.0.lua")
foreach ($file in $aceConfigFiles) {
  $url = "$baseUrl/AceConfig-3.0/$file"
  $outputPath = "Libs/AceConfig-3.0/$file"
    
  Write-Host "Downloading $file to $outputPath..."
  Invoke-WebRequest -Uri $url -OutFile $outputPath
  Write-Host "Downloaded successfully."
}

Write-Host "All libraries downloaded." 