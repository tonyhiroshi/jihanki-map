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

function Draw-Machine($g, [single]$ox, [single]$oy, [single]$k){
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#fff7f0'))), (New-RoundRect ($ox+118*$k) ($oy+96*$k) (276*$k) (320*$k) (34*$k)))
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#fb6f91'))), (New-RoundRect ($ox+140*$k) ($oy+120*$k) (232*$k) (40*$k) (12*$k)))
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#6b5b7a'))), (New-RoundRect ($ox+140*$k) ($oy+180*$k) (150*$k) (190*$k) (14*$k)))
    $cols = @('#fb6f91','#46c19b','#7fd0e8','#f5a25b','#cdb4f6','#fff7f0')
    $idx = 0
    for($r=0; $r -lt 3; $r++){
        for($c=0; $c -lt 2; $c++){
            $bx = $ox + 152*$k + $c*66*$k
            $by = $oy + 192*$k + $r*60*$k
            $g.FillPath((New-Object System.Drawing.SolidBrush((C $cols[$idx % 6]))), (New-RoundRect $bx $by (52*$k) (46*$k) (8*$k)))
            $idx++
        }
    }
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#e6d9f0'))), (New-RoundRect ($ox+300*$k) ($oy+180*$k) (82*$k) (120*$k) (12*$k)))
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#6b5b7a'))), (New-RoundRect ($ox+316*$k) ($oy+196*$k) (50*$k) (10*$k) (5*$k)))
    $g.FillEllipse((New-Object System.Drawing.SolidBrush((C '#46c19b'))), ($ox+325*$k), ($oy+234*$k), (32*$k), (32*$k))
    $g.FillPath((New-Object System.Drawing.SolidBrush((C '#6b5b7a'))), (New-RoundRect ($ox+140*$k) ($oy+384*$k) (242*$k) (18*$k) (8*$k)))
}

$W = 1200; $H = 630
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$rect = New-Object System.Drawing.RectangleF(0,0,$W,$H)
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, (C '#9a82d6'), (C '#7d63c4'), 115)
$g.FillRectangle($grad, $rect)

Draw-Machine $g 70 95 0.62

$titleFont = New-Object System.Drawing.Font('Yu Gothic UI', 76, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$subFont   = New-Object System.Drawing.Font('Yu Gothic UI', 30, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$coin  = New-Object System.Drawing.SolidBrush((C '#ffe08a'))
$muted = New-Object System.Drawing.SolidBrush((C '#efe6f7'))

$g.DrawString('自販機マップ', $titleFont, $white, 470, 215)
$g.FillEllipse((New-Object System.Drawing.SolidBrush((C '#fb6f91'))), 472, 330, 22, 22)
$g.DrawString('みんなで作る ご近所の自販機データベース', $subFont, $muted, 506, 326)
$g.DrawString('近くの自販機をすぐ見つけて、写真つきで共有', $subFont, $coin, 470, 380)

$out = Join-Path $root 'ogp.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "Saved $out"
