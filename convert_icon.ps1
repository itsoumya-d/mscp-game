# Simple approach: Create a placeholder JPG icon
# Since SVG to JPG conversion is complex in PowerShell, we'll create a basic colored square
Add-Type -AssemblyName System.Drawing

# Create a 512x512 bitmap
$bitmap = New-Object System.Drawing.Bitmap(512, 512)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

# Create gradient background
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Point]::new(0, 0),
    [System.Drawing.Point]::new(512, 512),
    [System.Drawing.Color]::FromArgb(102, 126, 234),
    [System.Drawing.Color]::FromArgb(118, 75, 162)
)

$graphics.FillRectangle($brush, 0, 0, 512, 512)

# Add StudyPal text
$font = New-Object System.Drawing.Font("Arial", 48, [System.Drawing.FontStyle]::Bold)
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$text = "SP"
$textSize = $graphics.MeasureString($text, $font)
$x = (512 - $textSize.Width) / 2
$y = (512 - $textSize.Height) / 2
$graphics.DrawString($text, $font, $textBrush, $x, $y)

# Save as JPG
$bitmap.Save("assets\icons\studypal_icon.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)

# Cleanup
$graphics.Dispose()
$bitmap.Dispose()
$brush.Dispose()
$font.Dispose()
$textBrush.Dispose()

Write-Host "StudyPal icon created successfully!"