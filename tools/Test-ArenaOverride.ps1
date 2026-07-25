param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$arenaPath = Join-Path $RepositoryRoot 'visuals\backgrounds\arena_worldcup.png'
$expectedHash = '8451121DD592919F2E5626D4F4747E1229471FFD3017A135D6720D66EC2E0E13'
$expectedUrl = 'https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/visuals/backgrounds/arena_worldcup.png'

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$rules = @($config.replacement_rules | Where-Object { $_.name -eq 'magic arena background' })
if ($rules.Count -ne 1) {
    throw "Expected one magic arena background rule, found $($rules.Count)"
}
if ((@($rules[0].replace_ids | ForEach-Object { [long]$_ }) -join ',') -ne '7658055825') {
    throw 'Arena replacement ID must remain 7658055825'
}
if ($rules[0].cdn_url -ne $expectedUrl -or $rules[0].mode -ne 'cdn' -or -not $rules[0].enabled) {
    throw 'Arena rule does not point to the World Cup asset'
}

if (-not (Test-Path -LiteralPath $arenaPath)) {
    throw "World Cup arena file is missing: $arenaPath"
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $arenaPath).Hash -ne $expectedHash) {
    throw 'World Cup arena file was modified instead of copied byte-for-byte'
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
}
finally {
    $bitmap.Dispose()
}

Write-Host 'World Cup arena validation passed: exact 64x64 source, ID 7658055825.'
