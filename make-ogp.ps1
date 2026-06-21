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

# --- machine illustration (origin ox,oy; scale k of 512-base) ---
function Draw-Machine($g, [single]$ox, [single]$oy, [single]$k){
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#f3efe4'))), (New-RoundRect ($ox+118*$k) ($oy+96*$k) (276*$k) (320*$k) (34*$k)))
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#ff5a3c'))), (New-RoundRect ($ox+140*$k) ($oy+120*$k) (232*$k) (40*$k) (12*$k)))
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#10151c'))), (New-RoundRect ($ox+140*$k) ($oy+180*$k) (150*$k) (190*$k) (14*$k)))
    $cols = @('#ff5a3c','#3aa66b','#4fc3f7','#d4a13a','#ff8a3c','#ffffff')
    $idx = 0
    for($r=0; $r -lt 3; $r++){
        for($c=0; $c -lt 2; $c++){
            $bx = $ox + 152*$k + $c*66*$k
            $by = $oy + 192*$k + $r*60*$k
            $g.FillPath((New-Object System.Drawing.SolidBrush((C $cols[$idx % 6]))), (New-RoundRect $bx $by (52*$k) (46*$k) (8*$k)))
            $idx++
        }
    }
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#c9c2ac'))), (New-RoundRect ($ox+300*$k) ($oy+180*$k) (82*$k) (120*$k) (12*$k)))
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#10151c'))), (New-RoundRect ($ox+316*$k) ($oy+196*$k) (50*$k) (10*$k) (5*$k)))
    $g.FillEllipse((New-Object System.Drawing.SolidBrush((C '#3aa66b'))), ($ox+325*$k), ($oy+234*$k), (32*$k), (32*$k))
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#10151c'))), (New-RoundRect ($ox+140*$k) ($oy+384*$k) (242*$k) (18*$k) (8*$k)))
}

$W = 1200; $H = 630
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# background gradient
$rect = New-Object System.Drawing.RectangleF(0,0,$W,$H)
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, (C '#2b3a4a'), (C '#10151c'), 115)
$g.FillRectangle($grad, $rect)

# machine on the left (scaled to ~ 0.62 of 512 base -> 318px box)
Draw-Machine $g 70 95 0.62

# title text on the right
$titleFont = New-Object System.Drawing.Font('Yu Gothic UI', 76, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$subFont   = New-Object System.Drawing.Font('Yu Gothic UI', 30, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$coin  = New-Object System.Drawing.SolidBrush((C '#ffd980'))
$muted = New-Object System.Drawing.SolidBrush((C '#c9c2ac'))

$g.DrawString('自販機マップ', $titleFont, $white, 470, 215)
# accent dot
$g.FillEllipse((New-Object System.Drawing.SolidBrush((C '#ff5a3c'))), 472, 330, 22, 22)
$g.DrawString('みんなで作る ご近所の自販機データベース', $subFont, $muted, 506, 326)
$g.DrawString('近くの自販機をすぐ見つけて、写真つきで共有', $subFont, $coin, 470, 380)

$out = Join-Path $root 'ogp.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "Saved $out ($W x $H)"
