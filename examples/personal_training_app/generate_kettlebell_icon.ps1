Add-Type -AssemblyName System.Drawing

function Create-KettlebellIcon {
    param (
        [int]$Size,
        [string]$OutputPath
    )

    # Transparent bitmap
    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.Clear([System.Drawing.Color]::Transparent)

    # Scale
    $scale = $Size / 512.0
    $centerX = $Size / 2
    $centerY = $Size / 2 + 24 * $scale

    # Dimensions
    $ballRadius = 100 * $scale
    $flatBottom = 16 * $scale
    $neckWidth = 36 * $scale
    $neckHeight = 24 * $scale
    $handleThickness = 18 * $scale
    $handleWidth = 118 * $scale
    $handleTopY = $centerY - $ballRadius - $neckHeight - 58 * $scale

    # Cast-iron palette
    $darkIron = [System.Drawing.Color]::FromArgb(35, 35, 40)
    $midIron = [System.Drawing.Color]::FromArgb(75, 75, 85)
    $lightIron = [System.Drawing.Color]::FromArgb(165, 165, 175)
    $highlight = [System.Drawing.Color]::FromArgb(210, 235, 235, 240)
    $shadow = [System.Drawing.Color]::FromArgb(150, 10, 10, 15)

    # Soft shadow
    $shadowOffset = 10 * $scale
    $shadowBrush = New-Object System.Drawing.SolidBrush($shadow)
    $shadowRect = [System.Drawing.RectangleF]::new(
        $centerX - $ballRadius + $shadowOffset,
        $centerY - $ballRadius + $shadowOffset,
        $ballRadius * 2,
        $ballRadius * 2 + $flatBottom
    )
    $graphics.FillEllipse($shadowBrush, $shadowRect)

    # Ball with radial shading
    $ballRect = [System.Drawing.RectangleF]::new(
        $centerX - $ballRadius,
        $centerY - $ballRadius,
        $ballRadius * 2,
        $ballRadius * 2
    )
    $ballPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $ballPath.AddEllipse($ballRect)
    $ballGradient = New-Object System.Drawing.Drawing2D.PathGradientBrush($ballPath)
    $ballGradient.CenterPoint = [System.Drawing.PointF]::new($centerX - $ballRadius * 0.33, $centerY - $ballRadius * 0.33)
    $ballGradient.CenterColor = $lightIron
    $ballGradient.SurroundColors = @($darkIron)
    $graphics.FillEllipse($ballGradient, $ballRect)

    # Highlight
    $highlightBrush = New-Object System.Drawing.SolidBrush($highlight)
    $graphics.FillEllipse($highlightBrush,
        $centerX - $ballRadius * 0.62,
        $centerY - $ballRadius * 0.7,
        $ballRadius * 0.9,
        $ballRadius * 0.55)

    # Rim light
    $rimPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(60, 255, 255, 255), 2 * $scale)
    $rimRect = [System.Drawing.RectangleF]::new(
        $centerX - $ballRadius * 0.98,
        $centerY - $ballRadius * 0.98,
        $ballRadius * 1.96,
        $ballRadius * 1.96
    )
    $graphics.DrawEllipse($rimPen, $rimRect)

    # Flat bottom + base shadow
    $flatBrush = New-Object System.Drawing.SolidBrush($darkIron)
    $graphics.FillRectangle($flatBrush,
        $centerX - $ballRadius * 0.7,
        $centerY + $ballRadius - $flatBottom,
        $ballRadius * 1.4,
        $flatBottom * 2)

    $baseShadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 0, 0, 0))
    $graphics.FillRectangle($baseShadow,
        $centerX - $ballRadius * 0.6,
        $centerY + $ballRadius - $flatBottom * 0.4,
        $ballRadius * 1.2,
        $flatBottom * 0.6)

    # Neck
    $neckTopWidth = $neckWidth * 0.65
    $neckPoints = @(
        [System.Drawing.PointF]::new($centerX - $neckWidth/2, $centerY - $ballRadius),
        [System.Drawing.PointF]::new($centerX + $neckWidth/2, $centerY - $ballRadius),
        [System.Drawing.PointF]::new($centerX + $neckTopWidth/2, $centerY - $ballRadius - $neckHeight),
        [System.Drawing.PointF]::new($centerX - $neckTopWidth/2, $centerY - $ballRadius - $neckHeight)
    )
    $neckBrush = New-Object System.Drawing.SolidBrush($midIron)
    $graphics.FillPolygon($neckBrush, $neckPoints)

    # Handle (rounded U-shape)
    $handleBrush = New-Object System.Drawing.SolidBrush($midIron)
    $leftX = $centerX - $handleWidth/2
    $rightX = $centerX + $handleWidth/2 - $handleThickness
    $handleHeight = ($centerY - $ballRadius - $neckHeight) - $handleTopY
    $graphics.FillRectangle($handleBrush, $leftX, $handleTopY + $handleThickness, $handleThickness, $handleHeight)
    $graphics.FillRectangle($handleBrush, $rightX, $handleTopY + $handleThickness, $handleThickness, $handleHeight)
    $graphics.FillRectangle($handleBrush, $leftX, $handleTopY, $handleWidth, $handleThickness)
    $graphics.FillEllipse($handleBrush, $leftX - $handleThickness/2, $handleTopY - $handleThickness/2, $handleThickness, $handleThickness)
    $graphics.FillEllipse($handleBrush, $rightX + $handleThickness/2, $handleTopY - $handleThickness/2, $handleThickness, $handleThickness)

    # Handle highlight + inner shadow
    $handleHighlight = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 230, 230, 240))
    $graphics.FillRectangle($handleHighlight,
        $leftX + 2 * $scale,
        $handleTopY + $handleThickness + 4 * $scale,
        $handleThickness * 0.35,
        $handleHeight * 0.5)

    $innerShadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 0, 0))
    $graphics.FillRectangle($innerShadow,
        $leftX + $handleThickness,
        $handleTopY + $handleThickness * 1.2,
        $handleWidth - $handleThickness * 2,
        $handleThickness * 0.7)

    # Emboss circle
    $embossBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 255, 255, 255))
    $embossRect = [System.Drawing.RectangleF]::new(
        $centerX - $ballRadius * 0.35,
        $centerY - $ballRadius * 0.1,
        $ballRadius * 0.7,
        $ballRadius * 0.7
    )
    $graphics.FillEllipse($embossBrush, $embossRect)

    # Speckle texture
    $random = New-Object System.Random
    $textureBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(12, 255, 255, 255))
    for ($i = 0; $i -lt 35; $i++) {
        $x = $centerX + ($random.NextDouble() - 0.5) * $ballRadius * 1.6
        $y = $centerY + ($random.NextDouble() - 0.5) * $ballRadius * 1.6
        $distance = [Math]::Sqrt([Math]::Pow($x - $centerX, 2) + [Math]::Pow($y - $centerY, 2))
        if ($distance -lt $ballRadius) {
            $graphics.FillEllipse($textureBrush, $x, $y, 1.2 * $scale, 1.2 * $scale)
        }
    }

    # Draw two hands shaking over the kettlebell
    $handColor = [System.Drawing.Color]::FromArgb(220, 180, 160)  # Skin tone
    $darkHandColor = [System.Drawing.Color]::FromArgb(180, 140, 120)  # Darker skin for shading
    $handBrush = New-Object System.Drawing.SolidBrush($handColor)
    $darkHandBrush = New-Object System.Drawing.SolidBrush($darkHandColor)
    
    # Left hand
    $leftHandX = $centerX - $ballRadius * 0.9
    $leftHandY = $centerY - $ballRadius * 1.3
    $forearmLength = $ballRadius * 0.8
    $forearmThickness = $ballRadius * 0.2
    
    # Left forearm (angled)
    $leftForearmPoints = @(
        [System.Drawing.PointF]::new($leftHandX - $forearmLength * 0.8, $leftHandY - $forearmLength * 0.3),
        [System.Drawing.PointF]::new($leftHandX - $forearmLength * 0.6, $leftHandY - $forearmLength * 0.35),
        [System.Drawing.PointF]::new($leftHandX + $forearmLength * 0.1, $leftHandY + $forearmLength * 0.15),
        [System.Drawing.PointF]::new($leftHandX - $forearmLength * 0.1, $leftHandY + $forearmLength * 0.2)
    )
    $graphics.FillPolygon($handBrush, $leftForearmPoints)
    
    # Left hand/fist at top
    $graphics.FillEllipse($handBrush,
        $leftHandX - $ballRadius * 0.15,
        $leftHandY - $ballRadius * 0.35,
        $ballRadius * 0.35,
        $ballRadius * 0.35)
    
    # Right hand
    $rightHandX = $centerX + $ballRadius * 0.9
    $rightHandY = $centerY - $ballRadius * 1.3
    
    # Right forearm (angled mirror)
    $rightForearmPoints = @(
        [System.Drawing.PointF]::new($rightHandX + $forearmLength * 0.8, $rightHandY - $forearmLength * 0.3),
        [System.Drawing.PointF]::new($rightHandX + $forearmLength * 0.6, $rightHandY - $forearmLength * 0.35),
        [System.Drawing.PointF]::new($rightHandX - $forearmLength * 0.1, $rightHandY + $forearmLength * 0.15),
        [System.Drawing.PointF]::new($rightHandX + $forearmLength * 0.1, $rightHandY + $forearmLength * 0.2)
    )
    $graphics.FillPolygon($handBrush, $rightForearmPoints)
    
    # Right hand/fist at top
    $graphics.FillEllipse($handBrush,
        $rightHandX - $ballRadius * 0.2,
        $rightHandY - $ballRadius * 0.35,
        $ballRadius * 0.35,
        $ballRadius * 0.35)
    
    # Hand shading/knuckles
    $graphics.FillEllipse($darkHandBrush,
        $leftHandX - $ballRadius * 0.12,
        $leftHandY - $ballRadius * 0.32,
        $ballRadius * 0.15,
        $ballRadius * 0.12)
    
    $graphics.FillEllipse($darkHandBrush,
        $rightHandX - $ballRadius * 0.18,
        $rightHandY - $ballRadius * 0.32,
        $ballRadius * 0.15,
        $ballRadius * 0.12)

    # Save
    $graphics.Dispose()
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()

    # Dispose
    $shadowBrush.Dispose()
    $ballPath.Dispose()
    $ballGradient.Dispose()
    $highlightBrush.Dispose()
    $rimPen.Dispose()
    $flatBrush.Dispose()
    $baseShadow.Dispose()
    $neckBrush.Dispose()
    $handleBrush.Dispose()
    $handleHighlight.Dispose()
    $innerShadow.Dispose()
    $embossBrush.Dispose()
    $textureBrush.Dispose()

    Write-Host "Created: $OutputPath"
}

# Generate all icon sizes
New-Item -ItemType Directory -Force -Path "web\icons" | Out-Null

Create-KettlebellIcon -Size 192 -OutputPath "web\icons\Icon-192.png"
Create-KettlebellIcon -Size 512 -OutputPath "web\icons\Icon-512.png"
Create-KettlebellIcon -Size 192 -OutputPath "web\icons\Icon-maskable-192.png"
Create-KettlebellIcon -Size 512 -OutputPath "web\icons\Icon-maskable-512.png"

Write-Host "`nTransparent kettlebell icons created!" -ForegroundColor Green
