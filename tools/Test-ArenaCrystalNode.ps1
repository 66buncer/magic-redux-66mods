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

    $opaqueBlack = 0
    $opaqueWhite = 0
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -eq 0) { continue }
            if ($pixel.R -lt 30 -and $pixel.G -lt 30 -and $pixel.B -lt 30) { $opaqueBlack++ }
            if ($pixel.R -gt 245 -and $pixel.G -gt 245 -and $pixel.B -gt 245) { $opaqueWhite++ }
        }
    }
    if ($opaqueBlack -ne 0) {
        throw "Arena tile must be gray, not black; found $opaqueBlack opaque black pixel(s)"
    }
    if ($opaqueWhite -ne 0) {
        throw "Arena tile must use transparency instead of white; found $opaqueWhite opaque white pixel(s)"
    }

    $centerX = 32
    $centerY = 32
    $outsideDiamond = 0
    $rowCounts = @{}
    for ($y = 22; $y -le 42; $y++) {
        $rowCounts[$y] = 0
        for ($x = 22; $x -le 42; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -eq 0) { continue }
            $rowCounts[$y]++
            if (([Math]::Abs($x - $centerX) + [Math]::Abs($y - $centerY)) -gt 11) {
                $outsideDiamond++
            }
        }
    }

    if ($rowCounts[24] -ge $rowCounts[32] -or $rowCounts[40] -ge $rowCounts[32]) {
        throw 'Arena center node must read as a crystal/diamond: narrow top and bottom, wider middle'
    }
    if ($rowCounts[32] -lt 9) {
        throw 'Arena crystal center is too small to replace the old plus node'
    }
    if ($outsideDiamond -gt 8) {
        throw "Arena center still reads like a plus/block instead of a crystal; $outsideDiamond pixel(s) sit outside the diamond silhouette"
    }
}
finally {
    $bitmap.Dispose()
}

Write-Host 'Arena crystal node validation passed.'
