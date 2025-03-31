param(
  [Parameter(Mandatory = $true)]
  [string]$LibraryName
)

# Create directory
$dirPath = "Libs\$LibraryName"
mkdir -Force $dirPath | Out-Null

# Download the main library file
$fileName = "$LibraryName.lua"
$url = "https://raw.githubusercontent.com/WoWUIDev/Ace3/master/$LibraryName/$fileName"
$outputPath = "Libs\$LibraryName\$fileName"

Write-Host "Downloading $fileName to $outputPath..."
Invoke-WebRequest -Uri $url -OutFile $outputPath
Write-Host "Downloaded successfully." 