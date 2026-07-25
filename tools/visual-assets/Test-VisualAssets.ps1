param(
    [ValidateSet('Selection', 'Prepared')]
    [string]$Phase = 'Selection'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$selection = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'asset-selection.json') | ConvertFrom-Json
$baseline = @(Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'rank-baseline.csv'))

if ($baseline.Count -ne 18) {
    throw "Expected 18 frozen ranks, found $($baseline.Count)"
}
foreach ($rank in $baseline) {
    $rankPath = Join-Path $repoRoot "ranks\$($rank.file)"
    if (-not (Test-Path -LiteralPath $rankPath)) {
        throw "Frozen rank is missing: $($rank.file)"
    }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $rankPath).Hash -ne $rank.sha256) {
        throw "Rank changed: $($rank.file)"
    }
}

if (-not (Test-Path -LiteralPath $selection.jar)) {
    throw "Thaumcraft JAR is missing: $($selection.jar)"
}
$duplicates = @($selection.entries | Group-Object source | Where-Object Count -gt 1)
if ($duplicates.Count -ne 0) {
    throw "Duplicate source entries: $($duplicates.Name -join ', ')"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($selection.jar)
try {
    $names = @($zip.Entries.FullName)
    foreach ($entry in $selection.entries) {
        if ($names -notcontains $entry.source) {
            throw "Missing JAR entry: $($entry.source)"
        }
    }
}
finally {
    $zip.Dispose()
}

if ($Phase -eq 'Prepared') {
    $workingRoot = Join-Path $repoRoot 'working\thaumcraft_visual_extract'
    $sourceRoot = Join-Path $workingRoot 'source_selected'
    $manifestPath = Join-Path $workingRoot 'manifest.csv'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Prepared manifest is missing: $manifestPath"
    }
    $manifest = @(Import-Csv -LiteralPath $manifestPath)
    if ($manifest.Count -ne @($selection.entries).Count) {
        throw "Manifest row count mismatch"
    }
    foreach ($row in $manifest) {
        $sourcePath = Join-Path $sourceRoot ($row.relative_path -replace '/', '\')
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Extracted source is missing: $($row.relative_path)"
        }
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $row.sha256) {
            throw "Extracted source hash mismatch: $($row.relative_path)"
        }
    }

    $preparedRoot = Join-Path $workingRoot 'prepared'
    $requiredIcons = [ordered]@{
        icons_direct = @(
            'lock', 'settings', 'region', 'book', 'scroll', 'spectate',
            'teammate', 'gamemode_end', 'hp', 'damage', 'arch_top', 'nem_top'
        )
        icons_composite = @(
            'back', 'next', 'plus', 'x', 'exit', 'save', 'servers',
            'task_completed', 'duels', 'logo', 'logo_g', 'level',
            'streak', 'headshot'
        )
    }

    Add-Type -AssemblyName System.Drawing
    foreach ($folder in $requiredIcons.Keys) {
        foreach ($name in $requiredIcons[$folder]) {
            $iconPath = Join-Path $preparedRoot "$folder\$name.png"
            if (-not (Test-Path -LiteralPath $iconPath)) {
                throw "Prepared icon is missing: $folder/$name.png"
            }
            $bitmap = [Drawing.Bitmap]::FromFile($iconPath)
            try {
                if ($bitmap.Width -ne 256 -or $bitmap.Height -ne 256) {
                    throw "Prepared icon has wrong dimensions: $folder/$name.png"
                }
                if (-not [Drawing.Image]::IsAlphaPixelFormat($bitmap.PixelFormat)) {
                    throw "Prepared icon has no alpha channel: $folder/$name.png"
                }
                $hasVisiblePixel = $false
                $borderTouched = $false
                for ($y = 0; $y -lt 256; $y++) {
                    for ($x = 0; $x -lt 256; $x++) {
                        $alpha = $bitmap.GetPixel($x, $y).A
                        if ($alpha -gt 0) {
                            $hasVisiblePixel = $true
                            if ($x -lt 8 -or $x -ge 248 -or $y -lt 8 -or $y -ge 248) {
                                $borderTouched = $true
                            }
                        }
                    }
                }
                if (-not $hasVisiblePixel) {
                    throw "Prepared icon is fully transparent: $folder/$name.png"
                }
                if ($borderTouched) {
                    throw "Prepared icon touches the 8 px safe border: $folder/$name.png"
                }
            }
            finally {
                $bitmap.Dispose()
            }
        }
    }
    $itemRoot = Join-Path $preparedRoot 'item_backgrounds'
    $itemHashes = @()
    for ($index = 1; $index -le 5; $index++) {
        $itemPath = Join-Path $itemRoot "itembg$index.png"
        if (-not (Test-Path -LiteralPath $itemPath)) {
            throw "Item background is missing: itembg$index.png"
        }
        $item = [Drawing.Bitmap]::FromFile($itemPath)
        try {
            if ($item.Width -ne 256 -or $item.Height -ne 256) {
                throw "Item background has wrong dimensions: itembg$index.png"
            }
        }
        finally {
            $item.Dispose()
        }
        $itemHashes += (Get-FileHash -Algorithm SHA256 -LiteralPath $itemPath).Hash
    }
    if (@($itemHashes | Sort-Object -Unique).Count -ne 5) {
        throw "Item backgrounds are not visually distinct"
    }

    $arenaPath = Join-Path $preparedRoot 'arena_background\arena.png'
    if (-not (Test-Path -LiteralPath $arenaPath)) {
        throw "Arena background is missing"
    }
    $arena = [Drawing.Bitmap]::FromFile($arenaPath)
    try {
        if ($arena.Width -ne 1536 -or $arena.Height -ne 1024) {
            throw "Arena background has wrong dimensions"
        }
        for ($y = 0; $y -lt $arena.Height; $y += 8) {
            for ($x = 0; $x -lt $arena.Width; $x += 8) {
                if ($arena.GetPixel($x, $y).A -ne 255) {
                    throw "Arena background contains alpha holes"
                }
            }
        }
    }
    finally {
        $arena.Dispose()
    }

    foreach ($overlayName in @('map_frame', 'map_particles')) {
        $overlayPath = Join-Path $preparedRoot "map_overlay_parts\$overlayName.png"
        if (-not (Test-Path -LiteralPath $overlayPath)) {
            throw "Map overlay is missing: $overlayName.png"
        }
        $overlay = [Drawing.Bitmap]::FromFile($overlayPath)
        try {
            if ($overlay.Width -ne 1536 -or $overlay.Height -ne 1024) {
                throw "Map overlay has wrong dimensions: $overlayName.png"
            }
            $visible = $false
            $transparent = $false
            for ($y = 0; $y -lt $overlay.Height; $y += 8) {
                for ($x = 0; $x -lt $overlay.Width; $x += 8) {
                    $alpha = $overlay.GetPixel($x, $y).A
                    if ($alpha -gt 0) { $visible = $true }
                    if ($alpha -eq 0) { $transparent = $true }
                }
            }
            if (-not $visible -or -not $transparent) {
                throw "Map overlay must contain visible and transparent pixels: $overlayName.png"
            }
        }
        finally {
            $overlay.Dispose()
        }
    }

}

Write-Output "PASS phase=$Phase ranks=18 selected=$(@($selection.entries).Count)"
