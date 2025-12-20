Add-Type -AssemblyName System.Drawing

# Create a bitmap
$bitmap = New-Object System.Drawing.Bitmap(1024, 1024)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

# Clear to white
$graphics.Clear([System.Drawing.Color]::White)

# Colors
$darkBlue = [System.Drawing.Color]::FromArgb(13, 71, 161)
$lightBlue = [System.Drawing.Color]::FromArgb(79, 195, 247)
$amber = [System.Drawing.Color]::FromArgb(255, 193, 7)
$red = [System.Drawing.Color]::FromArgb(255, 87, 34)
$white = [System.Drawing.Color]::White

# Brushes
$darkBlueBrush = New-Object System.Drawing.SolidBrush($darkBlue)
$lightBlueBrush = New-Object System.Drawing.SolidBrush($lightBlue)
$amberBrush = New-Object System.Drawing.SolidBrush($amber)
$whiteBrush = New-Object System.Drawing.SolidBrush($white)
$redBrush = New-Object System.Drawing.SolidBrush($red)

$whitePen = New-Object System.Drawing.Pen($white, 8)

# Fill background
$graphics.FillRectangle($darkBlueBrush, 0, 0, 1024, 1024)

# Draw main circle background  
$graphics.FillEllipse($lightBlueBrush, 200, 150, 400, 400)
$graphics.DrawEllipse($whitePen, 200, 150, 400, 400)

# Draw location pin - circle
$graphics.FillEllipse($amberBrush, 412, 500, 200, 200)
$graphics.DrawEllipse($whitePen, 412, 500, 200, 200)

# Draw pin center white circle
$graphics.FillEllipse($whiteBrush, 462, 550, 100, 100)

# Draw center red dot
$graphics.FillEllipse($redBrush, 487, 575, 50, 50)

# Save
$bitmap.Save("assets/images/app_icon.png")

# Cleanup
$graphics.Dispose()
$bitmap.Dispose()
$whitePen.Dispose()

Write-Host "Icon created successfully"
