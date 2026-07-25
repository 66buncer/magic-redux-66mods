param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$arenaPath = Join-Path $RepositoryRoot 'visuals\backgrounds\arena_worldcup_transparent.png'
$expectedUrl = 'https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/visuals/backgrounds/arena_worldcup_transparent.png'

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$rules = @($config.replacement_rules | Where-Object { $_.name -eq 'magic arena background' })
if ($rules.Count -ne 1) {
    throw "Expected one magic arena background rule, found $($rules.Count)"
}
if ((@($rules[0].replace_ids | ForEach-Object { [long]$_ }) -join ',') -ne '7658055825') {
    throw 'Arena replacement ID must remain 7658055825'
}
if ($rules[0].cdn_url -ne $expectedUrl -or $rules[0].mode -ne 'cdn' -or -not $rules[0].enabled) {
    throw 'Arena rule does not point to the transparent World Cup asset'
}

if (-not (Test-Path -LiteralPath $arenaPath)) {
    throw "Transparent World Cup arena file is missing: $arenaPath"
}

Add-Type -AssemblyName System.Drawing
$bitmap = [Drawing.Bitmap]::FromFile($arenaPath)
try {
    if ($bitmap.Width -ne 64 -or $bitmap.Height -ne 64) {
        throw 'World Cup arena dimensions changed'
    }
    if (-not [Drawing.Image]::IsAlphaPixelFormat($bitmap.PixelFormat)) {
        throw 'World Cup arena alpha channel is missing'
    }

    $opaqueWhite = 0
    $transparent = 0
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -eq 0) { $transparent++ }
            if ($pixel.A -gt 0 -and $pixel.R -ge 245 -and $pixel.G -ge 245 -and $pixel.B -ge 245) {
                $opaqueWhite++
            }
        }
    }
    if ($transparent -le 68) { throw 'World Cup arena did not gain transparent pixels' }
    if ($opaqueWhite -ne 0) { throw "World Cup arena still has $opaqueWhite opaque white pixel(s)" }
}
finally {
    $bitmap.Dispose()
}

Write-Host 'World Cup arena validation passed: white pixels are transparent, ID 7658055825.'