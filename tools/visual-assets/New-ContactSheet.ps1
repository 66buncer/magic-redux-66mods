param(
    [string]$WorkingRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $WorkingRoot) {
    $WorkingRoot = Join-Path $repoRoot 'working\thaumcraft_visual_extract'
}
$preparedRoot = Join-Path $WorkingRoot 'prepared'
$sheetRoot = Join-Path $WorkingRoot 'contact-sheets'
[IO.Directory]::CreateDirectory($sheetRoot) | Out-Null

function New-Sheet([int]$Width, [int]$Height) {
    return [Drawing.Bitmap]::new($Width, $Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function New-SheetGraphics([Drawing.Bitmap]$Bitmap) {
    $graphics = [Drawing.Graphics]::FromImage($Bitmap)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return $graphics
}

function Draw-Checker(
    [Drawing.Graphics]$Graphics,
    [Drawing.Rectangle]$Bounds,
    [int]$Cell = 16
) {
    $light = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 72, 76, 84))
    $dark = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 42, 46, 53))
    try {
        for ($y = $Bounds.Top; $y -lt $Bounds.Bottom; $y += $Cell) {
            for ($x = $Bounds.Left; $x -lt $Bounds.Right; $x += $Cell) {
                $brush = if (((($x - $Bounds.Left) / $Cell) + (($y - $Bounds.Top) / $Cell)) % 2 -eq 0) { $light } else { $dark }
                $Graphics.FillRectangle($brush, $x, $y, [Math]::Min($Cell, $Bounds.Right - $x), [Math]::Min($Cell, $Bounds.Bottom - $y))
            }
        }
    }
    finally {
        $light.Dispose()
        $dark.Dispose()
    }
}

function Draw-ImageFit(
    [Drawing.Graphics]$Graphics,
    [Drawing.Image]$Image,
    [Drawing.RectangleF]$Bounds
) {
    $scale = [Math]::Min($Bounds.Width / $Image.Width, $Bounds.Height / $Image.Height)
    $width = [single]($Image.Width * $scale)
    $height = [single]($Image.Height * $scale)
    $x = [single]($Bounds.Left + ($Bounds.Width - $width) / 2)
    $y = [single]($Bounds.Top + ($Bounds.Height - $height) / 2)
    $Graphics.DrawImage($Image, $x, $y, $width, $height)
}

$iconFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $preparedRoot 'icons_direct') -File -Filter '*.png'
    Get-ChildItem -LiteralPath (Join-Path $preparedRoot 'icons_composite') -File -Filter '*.png'
) | Sort-Object Name, DirectoryName

$iconColumns = 5
$iconTileWidth = 220
$iconTileHeight = 240
$iconRows = [int][Math]::Ceiling($iconFiles.Count / [double]$iconColumns)
$iconSheet = New-Sheet ($iconColumns * $iconTileWidth) ($iconRows * $iconTileHeight)
$iconGraphics = New-SheetGraphics $iconSheet
$font = [Drawing.Font]::new('Arial', 11, [Drawing.FontStyle]::Bold)
$smallFont = [Drawing.Font]::new('Arial', 9, [Drawing.FontStyle]::Regular)
$white = [Drawing.Brushes]::White
$muted = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 174, 184, 194))
try {
    $iconGraphics.Clear([Drawing.Color]::FromArgb(255, 14, 17, 22))
    for ($index = 0; $index -lt $iconFiles.Count; $index++) {
        $column = $index % $iconColumns
        $row = [int][Math]::Floor($index / [double]$iconColumns)
        $x = $column * $iconTileWidth
        $y = $row * $iconTileHeight
        $preview = [Drawing.Rectangle]::new($x + 20, $y + 14, 180, 180)
        Draw-Checker $iconGraphics $preview 15
        $darkHalf = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 5, 9, 13))
        try {
            $iconGraphics.FillRectangle($darkHalf, $preview.Left, $preview.Top, 90, 180)
        }
        finally {
            $darkHalf.Dispose()
        }
        $image = [Drawing.Bitmap]::FromFile($iconFiles[$index].FullName)
        try {
            Draw-ImageFit $iconGraphics $image ([Drawing.RectangleF]::new($preview.Left + 4, $preview.Top + 4, 172, 172))
        }
        finally {
            $image.Dispose()
        }
        $iconGraphics.DrawString($iconFiles[$index].BaseName, $font, $white, [single]($x + 12), [single]($y + 199))
        $group = Split-Path -Leaf $iconFiles[$index].DirectoryName
        $iconGraphics.DrawString($group, $smallFont, $muted, [single]($x + 12), [single]($y + 218))
    }
    $iconSheet.Save((Join-Path $sheetRoot 'icons.png'), [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $iconGraphics.Dispose()
    $iconSheet.Dispose()
    $font.Dispose()
    $smallFont.Dispose()
    $muted.Dispose()
}

$backgroundFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $preparedRoot 'item_backgrounds') -File -Filter '*.png'
    Get-ChildItem -LiteralPath (Join-Path $preparedRoot 'arena_background') -File -Filter '*.png'
    Get-ChildItem -LiteralPath (Join-Path $preparedRoot 'map_overlay_parts') -File -Filter '*.png'
) | Sort-Object DirectoryName, Name

$backgroundColumns = 3
$backgroundTileWidth = 500
$backgroundTileHeight = 390
$backgroundRows = [int][Math]::Ceiling($backgroundFiles.Count / [double]$backgroundColumns)
$backgroundSheet = New-Sheet ($backgroundColumns * $backgroundTileWidth) ($backgroundRows * $backgroundTileHeight)
$backgroundGraphics = New-SheetGraphics $backgroundSheet
$backgroundFont = [Drawing.Font]::new('Arial', 13, [Drawing.FontStyle]::Bold)
$backgroundMuted = [Drawing.Font]::new('Arial', 10, [Drawing.FontStyle]::Regular)
try {
    $backgroundGraphics.Clear([Drawing.Color]::FromArgb(255, 13, 16, 21))
    for ($index = 0; $index -lt $backgroundFiles.Count; $index++) {
        $column = $index % $backgroundColumns
        $row = [int][Math]::Floor($index / [double]$backgroundColumns)
        $x = $column * $backgroundTileWidth
        $y = $row * $backgroundTileHeight
        $preview = [Drawing.Rectangle]::new($x + 20, $y + 18, 460, 310)
        Draw-Checker $backgroundGraphics $preview 20
        $image = [Drawing.Bitmap]::FromFile($backgroundFiles[$index].FullName)
        try {
            Draw-ImageFit $backgroundGraphics $image ([Drawing.RectangleF]::new($preview.Left + 8, $preview.Top + 8, 444, 294))
            $sizeText = "$($image.Width)x$($image.Height)"
        }
        finally {
            $image.Dispose()
        }
        $backgroundGraphics.DrawString($backgroundFiles[$index].BaseName, $backgroundFont, [Drawing.Brushes]::White, [single]($x + 20), [single]($y + 338))
        $backgroundGraphics.DrawString($sizeText, $backgroundMuted, [Drawing.Brushes]::LightGray, [single]($x + 20), [single]($y + 363))
    }
    $backgroundSheet.Save((Join-Path $sheetRoot 'backgrounds.png'), [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $backgroundGraphics.Dispose()
    $backgroundSheet.Dispose()
    $backgroundFont.Dispose()
    $backgroundMuted.Dispose()
}

$preparedFiles = @(Get-ChildItem -LiteralPath $preparedRoot -Recurse -File -Filter '*.png' | Sort-Object FullName)
$readme = @(
    '# Magic Redux Thaumcraft visual working set',
    '',
    '- Selected byte-identical source PNGs: 36',
    "- Prepared PNGs: $($preparedFiles.Count)",
    '- Frozen rank PNGs changed: 0',
    '- `configs/Crystal_V1.0.json` changed: no',
    '- Full Thaumcraft visual library published: no',
    '',
    '## Prepared outputs',
    '',
    '| File | Dimensions | SHA-256 |',
    '| --- | --- | --- |'
)
foreach ($file in $preparedFiles) {
    $image = [Drawing.Bitmap]::FromFile($file.FullName)
    try {
        $dimensions = "$($image.Width)x$($image.Height)"
    }
    finally {
        $image.Dispose()
    }
    $relative = $file.FullName.Substring($WorkingRoot.Length + 1).Replace('\', '/')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    $readme += "| `$relative` | $dimensions | `$hash` |"
}
$readme += @(
    '',
    'Thaumcraft sound and visual assets — used with permission.',
    '',
    'These files are local review outputs. Nothing in this working directory is published automatically.'
)
[IO.File]::WriteAllLines((Join-Path $WorkingRoot 'README.md'), $readme, [Text.UTF8Encoding]::new($false))

Write-Output "CONTACT-SHEETS icons=$($iconFiles.Count) backgrounds=$($backgroundFiles.Count) prepared=$($preparedFiles.Count)"
