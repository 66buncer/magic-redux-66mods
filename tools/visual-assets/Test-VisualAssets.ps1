param(
    [ValidateSet('Selection', 'Prepared')]
    [string]$Phase = 'Selection'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$selectionPath = Join-Path $PSScriptRoot 'asset-selection.json'
$baselinePath = Join-Path $PSScriptRoot 'rank-baseline.csv'
$selection = Get-Content -Raw -LiteralPath $selectionPath | ConvertFrom-Json
$baseline = @(Import-Csv -LiteralPath $baselinePath)

if ($baseline.Count -ne 18) {
    throw "Expected 18 frozen ranks, found $($baseline.Count)"
}

foreach ($rank in $baseline) {
    $rankPath = Join-Path $repoRoot "ranks\$($rank.file)"
    if (-not (Test-Path -LiteralPath $rankPath)) {
        throw "Frozen rank is missing: $($rank.file)"
    }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $rankPath).Hash
    if ($actual -ne $rank.sha256) {
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
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
        if ($actual -ne $row.sha256) {
            throw "Extracted source hash mismatch: $($row.relative_path)"
        }
    }
}

Write-Output "PASS phase=$Phase ranks=18 selected=$(@($selection.entries).Count)"
