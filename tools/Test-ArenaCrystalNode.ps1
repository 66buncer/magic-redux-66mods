param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Add-Type -AssemblyName System.Drawing

$arenaPath = Join-Path $RepositoryRoot 'visuals\backgrounds\arena_worldcup_transparent.png'
if (-not (Test-Path -LiteralPath $arenaPath)) {
    throw "Arena tile is missing: $arenaPath"
}

$bitmap = [Drawing.Bitmap]::FromFile($arenaPath)
try {
    if ($bitmap.Width -ne 64 -or $bitmap.Height -ne 64) {
        throw "Arena tile must stay 64x64, got $($bitmap.Width)x$($bitmap.Height)"
    }

    foreach ($point in @(@(0, 0), @(63, 0), @(0, 63), @(63, 63))) {
        $pixel = $bitmap.GetPixel($point[0], $point[1])
        if ($pixel.A -ne 0) {
            throw "Arena tile corner $($point[0]),$($point[1]) must stay transparent"
        }
    }

    $opaquePixels = 0
    $opaqueBlack = 0
    $opaqueWhite = 0
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -eq 0) { continue }
            $opaquePixels++
            if ($pixel.R -lt 30 -and $pixel.G -lt 30 -and $pixel.B -lt 30) { $opaqueBlack++ }
            if ($pixel.R -gt 245 -and $pixel.G -gt 245 -and $pixel.B -gt 245) { $opaqueWhite++ }
        }
    }
    if ($opaquePixels -lt 3200) {
        throw "Arena tile must stay mostly filled like a square plate; found only $opaquePixels opaque pixel(s)"
    }
    if ($opaqueBlack -ne 0) {
        throw "Arena tile must be gray, not black; found $opaqueBlack opaque black pixel(s)"
    }
    if ($opaqueWhite -ne 0) {
        throw "Arena tile must use transparency instead of white; found $opaqueWhite opaque white pixel(s)"
    }

    for ($y = 24; $y -le 40; $y++) {
        for ($x = 24; $x -le 40; $x++) {
            if ($bitmap.GetPixel($x, $y).A -lt 220) {
                throw 'Arena tile center must stay filled; crystal shape must come from repeated edge/corner cutouts'
            }
        }
    }

    $canvas = [Drawing.Bitmap]::new(128, 128, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($canvas)
    try {
        $graphics.Clear([Drawing.Color]::FromArgb(0, 255, 255, 255))
        $graphics.DrawImageUnscaled($bitmap, 0, 0)
        $graphics.DrawImageUnscaled($bitmap, 64, 0)
        $graphics.DrawImageUnscaled($bitmap, 0, 64)
        $graphics.DrawImageUnscaled($bitmap, 64, 64)

        $joinX = 64
        $joinY = 64
        $transparentRows = @{}
        $transparentOutsideDiamond = 0
        for ($dy = -14; $dy -le 14; $dy++) {
            $transparentRows[$dy] = 0
            for ($dx = -14; $dx -le 14; $dx++) {
                $pixel = $canvas.GetPixel($joinX + $dx, $joinY + $dy)
                if ($pixel.A -ne 0) { continue }
                $transparentRows[$dy]++
                if (([Math]::Abs($dx) + [Math]::Abs($dy)) -gt 16) {
                    $transparentOutsideDiamond++
                }
            }
        }

        if ($transparentRows[0] -lt 24) {
            throw 'Repeated arena corners must create a visible crystal node at the tile junction'
        }
        if ($transparentRows[-12] -ge $transparentRows[0] -or $transparentRows[12] -ge $transparentRows[0]) {
            throw 'Repeated arena corner cutouts still read like a plus; they need a diamond/crystal profile'
        }
        if ($transparentOutsideDiamond -gt 28) {
            throw "Repeated arena corner cutouts spill outside the crystal silhouette: $transparentOutsideDiamond pixel(s)"
        }
    }
    finally {
        $graphics.Dispose()
        $canvas.Dispose()
    }
}
finally {
    $bitmap.Dispose()
}

Write-Host 'Arena edge crystal validation passed.'
