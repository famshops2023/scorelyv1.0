Add-Type -AssemblyName System.Drawing

$srcPath = (Get-Item (Join-Path $PSScriptRoot "..\assets\images\scorely_app_icon.png")).FullName
$src = [System.Drawing.Bitmap]::FromFile($srcPath)
$w = $src.Width
$h = $src.Height

# Sample navy background from (512, 100)
$samplePixel = $src.GetPixel(512, 100)
$navR = $samplePixel.R
$navG = $samplePixel.G
$navB = $samplePixel.B
$navyColor = [System.Drawing.Color]::FromArgb(255, $navR, $navG, $navB)

# 1. Flood fill from the 4 corners to replace only the outer border with $navyColor
$cleanedSrc = [System.Drawing.Bitmap]::new($w, $h)
for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $cleanedSrc.SetPixel($x, $y, $src.GetPixel($x, $y))
    }
}

$visited = New-Object 'bool[,]' $w, $h
$queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]

# Enqueue border pixels
for ($x = 0; $x -lt $w; $x++) {
    $queue.Enqueue([System.Drawing.Point]::new($x, 0))
    $queue.Enqueue([System.Drawing.Point]::new($x, $h - 1))
    $visited[$x, 0] = $true
    $visited[$x, $h - 1] = $true
}
for ($y = 0; $y -lt $h; $y++) {
    $queue.Enqueue([System.Drawing.Point]::new(0, $y))
    $queue.Enqueue([System.Drawing.Point]::new($w - 1, $y))
    $visited[0, $y] = $true
    $visited[$w - 1, $y] = $true
}

while ($queue.Count -gt 0) {
    $pt = $queue.Dequeue()
    $px = $pt.X
    $py = $pt.Y
    
    $p = $src.GetPixel($px, $py)
    
    # Check if pixel is dark background or outer border/shadow
    # Dark background has R < 25, G < 35, B < 65
    $isDarkBg = ($p.R -lt 25 -and $p.G -lt 35 -and $p.B -lt 65)
    
    if (-not $isDarkBg) {
        $cleanedSrc.SetPixel($px, $py, $navyColor)
        
        # Check 4 neighbors
        $neighbors = @(
            [System.Drawing.Point]::new($px + 1, $py),
            [System.Drawing.Point]::new($px - 1, $py),
            [System.Drawing.Point]::new($px, $py + 1),
            [System.Drawing.Point]::new($px, $py - 1)
        )
        
        foreach ($n in $neighbors) {
            if ($n.X -ge 0 -and $n.X -lt $w -and $n.Y -ge 0 -and $n.Y -lt $h) {
                if (-not $visited[$n.X, $n.Y]) {
                    $visited[$n.X, $n.Y] = $true
                    $queue.Enqueue($n)
                }
            }
        }
    }
}

# 2. Target canvas 1024x1024 with 0.72 scale
$targetSize = 1024
$dest = [System.Drawing.Bitmap]::new($targetSize, $targetSize)
$g = [System.Drawing.Graphics]::FromImage($dest)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$brush = [System.Drawing.SolidBrush]::new($navyColor)
$g.FillRectangle($brush, 0, 0, $targetSize, $targetSize)

$scale = 0.72
$scaledW = [int]($w * $scale)
$scaledH = [int]($h * $scale)
$offsetX = [int](($targetSize - $scaledW) / 2)
$offsetY = [int](($targetSize - $scaledH) / 2)

$g.DrawImage($cleanedSrc, $offsetX, $offsetY, $scaledW, $scaledH)

$outPath = (Join-Path $PSScriptRoot "..\assets\images\scorely_app_icon_padded.png")
$dest.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)

Write-Host "Generated pristine padded master icon at: $outPath"

$brush.Dispose()
$g.Dispose()
$dest.Dispose()
$cleanedSrc.Dispose()
$src.Dispose()
