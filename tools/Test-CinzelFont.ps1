param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$fontPath = Join-Path $RepositoryRoot 'fonts\cinzel.ttf'
$fontUrl = 'https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/fonts/cinzel.ttf'
$expectedIds = @(
    12187342816,
    12187288714,
    12187271237,
    12187320363,
    12187303601,
    12187262242,
    12187280273,
    12187354260,
    12187341500,
    12187320081,
    12187323909
)

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$fontRules = @($config.replacement_rules | Where-Object { $_.name -like 'magic font cinzel*' })
if ($fontRules.Count -ne $expectedIds.Count) {
    throw "Expected $($expectedIds.Count) Cinzel font rules, found $($fontRules.Count)"
}

$actualIds = @($fontRules | ForEach-Object { $_.replace_ids } | ForEach-Object { [long]$_ } | Sort-Object)
$expectedSorted = @($expectedIds | Sort-Object)
if (($actualIds -join ',') -ne ($expectedSorted -join ',')) {
    throw "Cinzel font IDs do not match the source font pack"
}

foreach ($rule in $fontRules) {
    if ($rule.mode -ne 'cdn' -or -not $rule.enabled -or $rule.cdn_url -ne $fontUrl) {
        throw "Wrong Cinzel font rule settings: $($rule.name)"
    }
    if (@($rule.replace_ids).Count -ne 1) {
        throw "Cinzel font rule must replace exactly one ID: $($rule.name)"
    }
}

if (-not (Test-Path -LiteralPath $fontPath)) {
    throw "Cinzel font file is missing: $fontPath"
}

$bytes = [IO.File]::ReadAllBytes($fontPath)
$signature = [Text.Encoding]::ASCII.GetString($bytes, 0, 4)
$isTrueType = $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x01 -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00
if ($signature -ne 'OTTO' -and -not $isTrueType -and $signature -ne 'true' -and $signature -ne 'ttcf') {
    throw "Cinzel font file does not look like a valid font"
}

Write-Host 'Cinzel font validation passed: 11 Rubik IDs point to fonts/cinzel.ttf.'
