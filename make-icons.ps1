Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function New-RoundRect([single]$x,[single]$y,[single]$w,[single]$h,[single]$r){
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2*$r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x+$w-$d, $y, $d, $d, 270, 90)
    $p.AddArc($x+$w-$d, $y+$h-$d, $d, $d, 0, 90)
    $p.AddArc($x, $y+$h-$d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}
function C([string]$hex){ return [System.Drawing.ColorTranslator]::FromHtml($hex) }

function Make-Icon([int]$size, [string]$outPath){
    $k = $size / 512.0
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # background gradient (steel)
    $bgRect = New-Object System.Drawing.RectangleF(0,0,$size,$size)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($bgRect, (C '#2b3a4a'), (C '#1a2530'), 90)
    $bgPath = New-RoundRect 0 0 $size $size (96*$k)
    $g.FillPath($grad, $bgPath)

    # machine body
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#f3efe4'))), (New-RoundRect (118*$k) (96*$k) (276*$k) (320*$k) (34*$k)))
    # top neon bar
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#ff5a3c'))), (New-RoundRect (140*$k) (120*$k) (232*$k) (40*$k) (12*$k)))
    # product window
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#10151c'))), (New-RoundRect (140*$k) (180*$k) (150*$k) (190*$k) (14*$k)))

    # drinks grid 3x2
    $cols = @('#ff5a3c','#3aa66b','#4fc3f7','#d4a13a','#ff8a3c','#ffffff')
    $idx = 0
    for($r=0; $r -lt 3; $r++){
        for($c=0; $c -lt 2; $c++){
            $bx = 152*$k + $c*66*$k
            $by = 192*$k + $r*60*$k
            $g.FillPath((New-Object System.Drawing.SolidBrush((C $cols[$idx % 6]))), (New-RoundRect $bx $by (52*$k) (46*$k) (8*$k)))
            $cap = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(64,0,0,0))
            $g.FillPath($cap, (New-RoundRect ($bx+16*$k) ($by+6*$k) (20*$k) (8*$k) (4*$k)))
            $idx++
        }
    }

    # right panel
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#c9c2ac'))), (New-RoundRect (300*$k) (180*$k) (82*$k) (120*$k) (12*$k)))
    # coin slot
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#10151c'))), (New-RoundRect (316*$k) (196*$k) (50*$k) (10*$k) (5*$k)))
    # button
    $g.FillEllipse((New-Object System.Drawing.SolidBrush((C '#3aa66b'))), (325*$k), (234*$k), (32*$k), (32*$k))
    # dispense tray
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#10151c'))), (New-RoundRect (140*$k) (384*$k) (242*$k) (18*$k) (8*$k)))

    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "Saved $outPath ($size px)"
}

Make-Icon 512 (Join-Path $root 'icon-512.png')
Make-Icon 192 (Join-Path $root 'icon-192.png')
Make-Icon 180 (Join-Path $root 'apple-touch-icon.png')
Make-Icon 32  (Join-Path $root 'favicon-32.png')
