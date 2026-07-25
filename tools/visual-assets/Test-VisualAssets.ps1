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
}

Write-Output "PASS phase=$Phase ranks=18 selected=$(@($selection.entries).Count)"
