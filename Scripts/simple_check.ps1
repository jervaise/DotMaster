# Simple DotMaster Check Script
Write-Host "Running Simple DotMaster Check"

# Get all Lua files
$luaFiles = Get-ChildItem -Path (Get-Location) -Filter "*.lua" -Recurse | 
Where-Object { $_.FullName -notlike "*/Scripts/*" -and $_.FullName -notlike "*/Docs/*" }

Write-Host "Found $($luaFiles.Count) Lua files to check"
$getSpellInfoIssues = @()

foreach ($file in $luaFiles) {
  $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
  Write-Host "Checking $relativePath"
    
  # Check for GetSpellInfo issues
  $content = Get-Content $file.FullName -Raw
  if ($content -match "GetSpellInfo\s*\(" -and $content -notmatch "C_Spell\.GetSpellInfo\s*\(") {
    $getSpellInfoIssues += $relativePath
  }
}

Write-Host "GetSpellInfo issues found in $($getSpellInfoIssues.Count) files"
if ($getSpellInfoIssues.Count -gt 0) {
  foreach ($file in $getSpellInfoIssues) {
    Write-Host "  - $file"
  }
}

Write-Host "Check complete!" 