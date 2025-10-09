# PowerShell script to fix predefined_games_service.dart
$filePath = "E:\sp\lib\core\services\predefined_games_service.dart"

# Read the file content
$content = Get-Content $filePath -Raw

# Remove topic: parameters (with single quotes)
$content = $content -replace '\s*topic:\s*''[^'']*'',?\s*\r?\n', ''

# Remove subtopic: parameters (with single quotes)  
$content = $content -replace '\s*subtopic:\s*''[^'']*'',?\s*\r?\n', ''

# Remove subtopic: parameters (with conditional expressions)
$content = $content -replace '\s*subtopic:\s*level[^,\r\n]*,?\s*\r?\n', ''

# Remove clickableAreas: parameters
$content = $content -replace '\s*clickableAreas:\s*\[[^\]]*\],?\s*\r?\n', ''

# Write the content back
Set-Content $filePath -Value $content

Write-Host "Fixed parameters in predefined_games_service.dart"