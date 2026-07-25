param(
    [string]$WorkingRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $WorkingRoot) {
    $WorkingRoot = Join-Path $repoRoot 'working\thaumcraft_visual_extract'
}
$sourceRoot = Join-Path $WorkingRoot 'source_selected'
$preparedRoot = Join-Path $WorkingRoot 'prepared'
$directRoot = Join-Path $preparedRoot 'icons_direct'
$compositeRoot = Join-Path $preparedRoot 'icons_composite'
$manifest = @(Import-Csv -LiteralPath (Join-Path $WorkingRoot 'manifest.csv'))

[IO.Directory]::CreateDirectory($directRoot) | Out-Null
[IO.Directory]::CreateDirectory($compositeRoot) | Out-Null

function Get-SourcePath([string]$Suffix) {
    $row = @($manifest | Where-Object { $_.source.EndsWith($Suffix, [StringComparison]::OrdinalIgnoreCase) })
    if ($row.Count -ne 1) {
        throw "Expected one source ending with '$Suffix', found $($row.Count)"
    }
    return Join-Path $sourceRoot ($row[0].relative_path -replace '/', '\')
}

function New-TransparentCanvas([int]$Width, [int]$Height) {
    return [Drawing.Bitmap]::new($Width, $Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function New-Graphics([Drawing.Bitmap]$Bitmap) {
    $graphics = [Drawing.Graphics]::FromImage($Bitmap)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
    return $graphics
}

function Save-Png([Drawing.Bitmap]$Bitmap, [string]$Path) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    $Bitmap.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
}

function Draw-CrystalFrame(
    [Drawing.Graphics]$Graphics,
    [Drawing.RectangleF]$Bounds,
    [Drawing.Color]$Accent
) {
    $points = [Drawing.PointF[]]@(
        [Drawing.PointF]::new($Bounds.Left + $Bounds.Width * 0.50, $Bounds.Top),
        [Drawing.PointF]::new($Bounds.Right, $Bounds.Top + $Bounds.Height * 0.28),
        [Drawing.PointF]::new($Bounds.Right, $Bounds.Top + $Bounds.Height * 0.72),
        [Drawing.PointF]::new($Bounds.Left + $Bounds.Width * 0.50, $Bounds.Bottom),
        [Drawing.PointF]::new($Bounds.Left, $Bounds.Top + $Bounds.Height * 0.72),
        [Drawing.PointF]::new($Bounds.Left, $Bounds.Top + $Bounds.Height * 0.28)
    )
    $fill = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(54, 7, 18, 25))
    $glow = [Drawing.Pen]::new([Drawing.Color]::FromArgb(36, $Accent), 12)
    $line = [Drawing.Pen]::new([Drawing.Color]::FromArgb(220, $Accent), 4)
    $shine = [Drawing.Pen]::new([Drawing.Color]::FromArgb(230, 235, 255, 255), 1.4)
    try {
        $Graphics.FillPolygon($fill, $points)
        $Graphics.DrawPolygon($glow, $points)
        $Graphics.DrawPolygon($line, $points)
        $Graphics.DrawLines($shine, [Drawing.PointF[]]@($points[4], $points[0], $points[1]))
    }
    finally {
        $fill.Dispose()
        $glow.Dispose()
        $line.Dispose()
        $shine.Dispose()
    }
}

function Draw-SourceCentered(
    [Drawing.Graphics]$Graphics,
    [string]$SourcePath,
    [Drawing.RectangleF]$Bounds,
    [single]$Rotation = 0
) {
    $image = [Drawing.Bitmap]::FromFile($SourcePath)
    try {
        if ($image.Width -le 64 -and $image.Height -le 64) {
            $Graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        }
        else {
            $Graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        }
        $scale = [Math]::Min($Bounds.Width / $image.Width, $Bounds.Height / $image.Height)
        $width = [single]($image.Width * $scale)
        $height = [single]($image.Height * $scale)
        $state = $Graphics.Save()
        try {
            $Graphics.TranslateTransform($Bounds.Left + $Bounds.Width / 2, $Bounds.Top + $Bounds.Height / 2)
            if ($Rotation -ne 0) {
                $Graphics.RotateTransform($Rotation)
            }
            $Graphics.DrawImage($image, -$width / 2, -$height / 2, $width, $height)
        }
        finally {
            $Graphics.Restore($state)
        }
    }
    finally {
        $image.Dispose()
    }
}

function New-FramedIcon([Drawing.Color]$Accent) {
    $bitmap = New-TransparentCanvas 256 256
    $graphics = New-Graphics $bitmap
    Draw-CrystalFrame $graphics ([Drawing.RectangleF]::new(22, 18, 212, 220)) $Accent
    return [pscustomobject]@{ Bitmap = $bitmap; Graphics = $graphics; Accent = $Accent }
}

function Write-DirectIcon([string]$Name, [string]$Suffix, [Drawing.Color]$Accent) {
    $icon = New-FramedIcon $Accent
    try {
        Draw-SourceCentered $icon.Graphics (Get-SourcePath $Suffix) ([Drawing.RectangleF]::new(56, 54, 144, 148))
        Save-Png $icon.Bitmap (Join-Path $directRoot "$Name.png")
    }
    finally {
        $icon.Graphics.Dispose()
        $icon.Bitmap.Dispose()
    }
}

$cyan = [Drawing.Color]::FromArgb(255, 69, 241, 208)
$blue = [Drawing.Color]::FromArgb(255, 70, 190, 255)
$violet = [Drawing.Color]::FromArgb(255, 166, 102, 255)
$gold = [Drawing.Color]::FromArgb(255, 244, 203, 84)
$green = [Drawing.Color]::FromArgb(255, 91, 238, 142)
$red = [Drawing.Color]::FromArgb(255, 255, 93, 112)

$direct = @(
    @('lock', 'aspects/vinculum.png', $cyan),
    @('settings', 'items/brass_gear.png', $gold),
    @('region', 'aspects/iter.png', $blue),
    @('book', 'items/thaumonomicon.png', $violet),
    @('scroll', 'items/researchnotes.png', $gold),
    @('spectate', 'items/thaumometer.png', $cyan),
    @('teammate', 'aspects/humanus.png', $blue),
    @('gamemode_end', 'aspects/exanimis.png', $violet),
    @('hp', 'aspects/victus.png', $green),
    @('damage', 'aspects/aversio.png', $red),
    @('arch_top', 'foci/architect.png', $cyan),
    @('nem_top', 'research/r_eldritch.png', $violet)
)
foreach ($item in $direct) {
    Write-DirectIcon $item[0] $item[1] $item[2]
}

function New-Pen([Drawing.Color]$Color, [single]$Width) {
    $pen = [Drawing.Pen]::new($Color, $Width)
    $pen.StartCap = [Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
    return $pen
}

function Write-Composite([string]$Name, [Drawing.Color]$Accent, [scriptblock]$Draw) {
    $icon = New-FramedIcon $Accent
    try {
        & $Draw $icon.Graphics $Accent
        Save-Png $icon.Bitmap (Join-Path $compositeRoot "$Name.png")
    }
    finally {
        $icon.Graphics.Dispose()
        $icon.Bitmap.Dispose()
    }
}

Write-Composite 'back' $cyan {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'misc/architect_arrows.png') ([Drawing.RectangleF]::new(76, 76, 104, 104))
    $pen = New-Pen ([Drawing.Color]::White) 12
    try { $g.DrawLines($pen, [Drawing.PointF[]]@([Drawing.PointF]::new(158, 78), [Drawing.PointF]::new(104, 128), [Drawing.PointF]::new(158, 178))) } finally { $pen.Dispose() }
}
Write-Composite 'next' $cyan {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'misc/architect_arrows.png') ([Drawing.RectangleF]::new(76, 76, 104, 104)) 180
    $pen = New-Pen ([Drawing.Color]::White) 12
    try { $g.DrawLines($pen, [Drawing.PointF[]]@([Drawing.PointF]::new(98, 78), [Drawing.PointF]::new(152, 128), [Drawing.PointF]::new(98, 178))) } finally { $pen.Dispose() }
}
Write-Composite 'plus' $blue {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'foci/enlarge.png') ([Drawing.RectangleF]::new(72, 72, 112, 112))
    $pen = New-Pen ([Drawing.Color]::White) 11
    try { $g.DrawLine($pen, 128, 82, 128, 174); $g.DrawLine($pen, 82, 128, 174, 128) } finally { $pen.Dispose() }
}
Write-Composite 'x' $red {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/perditio.png') ([Drawing.RectangleF]::new(74, 74, 108, 108))
    $pen = New-Pen ([Drawing.Color]::White) 11
    try { $g.DrawLine($pen, 91, 91, 165, 165); $g.DrawLine($pen, 165, 91, 91, 165) } finally { $pen.Dispose() }
}
Write-Composite 'exit' $red {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/perditio.png') ([Drawing.RectangleF]::new(66, 72, 76, 76))
    $pen = New-Pen ([Drawing.Color]::White) 9
    try {
        $g.DrawRectangle($pen, 76, 68, 88, 120)
        $g.DrawLine($pen, 116, 128, 188, 128)
        $g.DrawLines($pen, [Drawing.PointF[]]@([Drawing.PointF]::new(163, 103), [Drawing.PointF]::new(188, 128), [Drawing.PointF]::new(163, 153)))
    } finally { $pen.Dispose() }
}
Write-Composite 'save' $cyan {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/cognitio.png') ([Drawing.RectangleF]::new(94, 94, 68, 68))
    $pen = New-Pen ([Drawing.Color]::White) 8
    try {
        $g.DrawRectangle($pen, 72, 62, 112, 132)
        $g.DrawRectangle($pen, 93, 69, 70, 40)
        $g.DrawRectangle($pen, 94, 137, 68, 49)
    } finally { $pen.Dispose() }
}
Write-Composite 'servers' $blue {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/machina.png') ([Drawing.RectangleF]::new(98, 96, 60, 60))
    $pen = New-Pen ([Drawing.Color]::White) 7
    try {
        foreach ($y in @(70, 112, 154)) { $g.DrawRectangle($pen, 70, $y, 116, 30); $g.DrawEllipse($pen, 80, $y + 9, 8, 8) }
    } finally { $pen.Dispose() }
}
Write-Composite 'task_completed' $green {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/ordo.png') ([Drawing.RectangleF]::new(66, 66, 124, 124))
    $pen = New-Pen ([Drawing.Color]::White) 13
    try { $g.DrawLines($pen, [Drawing.PointF[]]@([Drawing.PointF]::new(82, 132), [Drawing.PointF]::new(116, 166), [Drawing.PointF]::new(181, 91))) } finally { $pen.Dispose() }
}
Write-Composite 'duels' $red {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'items/elemental_sword.png') ([Drawing.RectangleF]::new(70, 53, 116, 150)) -38
    Draw-SourceCentered $g (Get-SourcePath 'items/void_sword.png') ([Drawing.RectangleF]::new(70, 53, 116, 150)) 38
}
Write-Composite 'logo' $cyan {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'items/crystal_essence.png') ([Drawing.RectangleF]::new(56, 48, 144, 164))
    Draw-SourceCentered $g (Get-SourcePath 'aspects/praecantatio.png') ([Drawing.RectangleF]::new(91, 91, 74, 74))
}
Write-Composite 'logo_g' $violet {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/praecantatio.png') ([Drawing.RectangleF]::new(65, 65, 126, 126))
    $pen = New-Pen ([Drawing.Color]::White) 10
    try { $g.DrawArc($pen, 78, 72, 102, 112, 42, 286); $g.DrawLine($pen, 132, 128, 179, 128) } finally { $pen.Dispose() }
}
Write-Composite 'level' $gold {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/potentia.png') ([Drawing.RectangleF]::new(70, 80, 116, 116))
    $pen = New-Pen ([Drawing.Color]::White) 8
    try {
        $g.DrawLines($pen, [Drawing.PointF[]]@([Drawing.PointF]::new(91, 104), [Drawing.PointF]::new(128, 70), [Drawing.PointF]::new(165, 104)))
        $g.DrawLines($pen, [Drawing.PointF[]]@([Drawing.PointF]::new(91, 129), [Drawing.PointF]::new(128, 95), [Drawing.PointF]::new(165, 129)))
    } finally { $pen.Dispose() }
}
Write-Composite 'streak' $gold {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/potentia.png') ([Drawing.RectangleF]::new(56, 56, 144, 144))
    Draw-SourceCentered $g (Get-SourcePath 'aspects/ignis.png') ([Drawing.RectangleF]::new(90, 90, 76, 76))
}
Write-Composite 'headshot' $red {
    param($g, $accent)
    Draw-SourceCentered $g (Get-SourcePath 'aspects/perfodio.png') ([Drawing.RectangleF]::new(76, 76, 104, 104))
    $pen = New-Pen ([Drawing.Color]::White) 6
    try {
        $g.DrawEllipse($pen, 78, 78, 100, 100)
        $g.DrawLine($pen, 128, 60, 128, 92)
        $g.DrawLine($pen, 128, 164, 128, 196)
        $g.DrawLine($pen, 60, 128, 92, 128)
        $g.DrawLine($pen, 164, 128, 196, 128)
    } finally { $pen.Dispose() }
}

$itemRoot = Join-Path $preparedRoot 'item_backgrounds'
$arenaRoot = Join-Path $preparedRoot 'arena_background'
$overlayRoot = Join-Path $preparedRoot 'map_overlay_parts'
[IO.Directory]::CreateDirectory($itemRoot) | Out-Null
[IO.Directory]::CreateDirectory($arenaRoot) | Out-Null
[IO.Directory]::CreateDirectory($overlayRoot) | Out-Null

function Write-ItemBackground(
    [string]$Name,
    [Drawing.Color]$Accent,
    [Drawing.Color]$Core
) {
    $bitmap = New-TransparentCanvas 256 256
    $graphics = New-Graphics $bitmap
    try {
        $points = [Drawing.PointF[]]@(
            [Drawing.PointF]::new(128, 18),
            [Drawing.PointF]::new(225, 74),
            [Drawing.PointF]::new(225, 182),
            [Drawing.PointF]::new(128, 238),
            [Drawing.PointF]::new(31, 182),
            [Drawing.PointF]::new(31, 74)
        )
        $fill = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(214, $Core))
        $outer = New-Pen ([Drawing.Color]::FromArgb(220, $Accent)) 8
        $inner = New-Pen ([Drawing.Color]::FromArgb(145, 245, 255, 255)) 2
        try {
            $graphics.FillPolygon($fill, $points)
            $graphics.DrawPolygon($outer, $points)
            $graphics.DrawPolygon($inner, [Drawing.PointF[]]@(
                [Drawing.PointF]::new(128, 34),
                [Drawing.PointF]::new(211, 82),
                [Drawing.PointF]::new(211, 174),
                [Drawing.PointF]::new(128, 222),
                [Drawing.PointF]::new(45, 174),
                [Drawing.PointF]::new(45, 82)
            ))
        }
        finally {
            $fill.Dispose()
            $outer.Dispose()
            $inner.Dispose()
        }
        Draw-SourceCentered $graphics (Get-SourcePath 'aspects/_back.png') ([Drawing.RectangleF]::new(42, 42, 172, 172))
        Draw-SourceCentered $graphics (Get-SourcePath 'gui/hex1.png') ([Drawing.RectangleF]::new(76, 76, 104, 104))
        Draw-SourceCentered $graphics (Get-SourcePath 'gui/hex2.png') ([Drawing.RectangleF]::new(97, 97, 62, 62))
        Save-Png $bitmap (Join-Path $itemRoot "$Name.png")
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

Write-ItemBackground 'itembg1' ([Drawing.Color]::FromArgb(255, 136, 147, 158)) ([Drawing.Color]::FromArgb(255, 22, 27, 31))
Write-ItemBackground 'itembg2' ([Drawing.Color]::FromArgb(255, 49, 205, 232)) ([Drawing.Color]::FromArgb(255, 10, 34, 43))
Write-ItemBackground 'itembg3' ([Drawing.Color]::FromArgb(255, 241, 200, 75)) ([Drawing.Color]::FromArgb(255, 48, 37, 11))
Write-ItemBackground 'itembg4' ([Drawing.Color]::FromArgb(255, 154, 98, 232)) ([Drawing.Color]::FromArgb(255, 31, 15, 48))
Write-ItemBackground 'itembg5' ([Drawing.Color]::FromArgb(255, 69, 241, 208)) ([Drawing.Color]::FromArgb(255, 7, 24, 28))

$arena = [Drawing.Bitmap]::new(1536, 1024, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$arenaGraphics = New-Graphics $arena
try {
    $arenaGraphics.Clear([Drawing.Color]::FromArgb(255, 4, 10, 14))
    for ($radius = 900; $radius -ge 180; $radius -= 60) {
        $ratio = ($radius - 180) / 720
        $alpha = [int](12 + (1 - $ratio) * 24)
        $brush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb($alpha, 20, 205, 210))
        try {
            $arenaGraphics.FillEllipse($brush, 768 - $radius, 512 - $radius * 0.62, $radius * 2, $radius * 1.24)
        }
        finally {
            $brush.Dispose()
        }
    }
    Draw-SourceCentered $arenaGraphics (Get-SourcePath 'misc/vortex.png') ([Drawing.RectangleF]::new(398, 142, 740, 740))
    Draw-SourceCentered $arenaGraphics (Get-SourcePath 'research/eldritchajor1.png') ([Drawing.RectangleF]::new(70, 230, 430, 560)) -12
    Draw-SourceCentered $arenaGraphics (Get-SourcePath 'research/eldritchajor1.png') ([Drawing.RectangleF]::new(1036, 230, 430, 560)) 12
    $horizon = New-Pen ([Drawing.Color]::FromArgb(120, 69, 241, 208)) 3
    try {
        $arenaGraphics.DrawLine($horizon, 96, 808, 1440, 808)
        $arenaGraphics.DrawLine($horizon, 250, 836, 1286, 836)
    }
    finally {
        $horizon.Dispose()
    }
    Save-Png $arena (Join-Path $arenaRoot 'arena.png')
}
finally {
    $arenaGraphics.Dispose()
    $arena.Dispose()
}

$frame = New-TransparentCanvas 1536 1024
$frameGraphics = New-Graphics $frame
try {
    $framePen = New-Pen ([Drawing.Color]::FromArgb(205, 69, 241, 208)) 8
    $shinePen = New-Pen ([Drawing.Color]::FromArgb(130, 235, 255, 255)) 2
    try {
        $frameGraphics.DrawRectangle($framePen, 30, 30, 1476, 964)
        $frameGraphics.DrawRectangle($shinePen, 46, 46, 1444, 932)
        foreach ($corner in @(
            [Drawing.PointF[]]@([Drawing.PointF]::new(30, 180), [Drawing.PointF]::new(30, 30), [Drawing.PointF]::new(180, 30)),
            [Drawing.PointF[]]@([Drawing.PointF]::new(1356, 30), [Drawing.PointF]::new(1506, 30), [Drawing.PointF]::new(1506, 180)),
            [Drawing.PointF[]]@([Drawing.PointF]::new(30, 844), [Drawing.PointF]::new(30, 994), [Drawing.PointF]::new(180, 994)),
            [Drawing.PointF[]]@([Drawing.PointF]::new(1356, 994), [Drawing.PointF]::new(1506, 994), [Drawing.PointF]::new(1506, 844))
        )) {
            $frameGraphics.DrawLines($framePen, $corner)
        }
    }
    finally {
        $framePen.Dispose()
        $shinePen.Dispose()
    }
    Save-Png $frame (Join-Path $overlayRoot 'map_frame.png')
}
finally {
    $frameGraphics.Dispose()
    $frame.Dispose()
}

$particles = New-TransparentCanvas 1536 1024
$particleGraphics = New-Graphics $particles
try {
    Draw-SourceCentered $particleGraphics (Get-SourcePath 'misc/particlefield.png') ([Drawing.RectangleF]::new(20, 20, 460, 460))
    Draw-SourceCentered $particleGraphics (Get-SourcePath 'misc/particlefield.png') ([Drawing.RectangleF]::new(1056, 544, 460, 460)) 180
    Draw-SourceCentered $particleGraphics (Get-SourcePath 'misc/wispy.png') ([Drawing.RectangleF]::new(420, 22, 696, 180))
    Draw-SourceCentered $particleGraphics (Get-SourcePath 'misc/wispy.png') ([Drawing.RectangleF]::new(420, 822, 696, 180)) 180
    Save-Png $particles (Join-Path $overlayRoot 'map_particles.png')
}
finally {
    $particleGraphics.Dispose()
    $particles.Dispose()
}

Write-Output "PREPARED-BACKGROUNDS item_backgrounds=5 arena=1 overlays=2"
