param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$soundDirectory = Join-Path $RepositoryRoot 'sounds'
$skyboxDirectory = Join-Path $RepositoryRoot 'visuals\skybox\crystal'

$expectedSounds = @(
    @{ Name='crystal warhorn'; File='warhorn_egidle1.ogg'; Hash='EA3B34CA667A719000E98467A8FC968F23EE15DBC8F0A6EAA3E1EF9AE2686C16' },
    @{ Name='magic kill 1'; File='kill1_wisplive1.ogg'; Hash='6B82A28746E26FF02797B7B493ECEABED57FD2D3605AD5279EBD7C415E3F8AD2' },
    @{ Name='magic kill 2'; File='kill2_wisplive2.ogg'; Hash='35AC9D0D0C9D4FA9FC0FDCFE1A235AE03681EEB186D073F0F6212ADAAB506F06' },
    @{ Name='magic kill 3'; File='kill3_wisplive3.ogg'; Hash='33DF220EB34CBA2566D773B6E9B6514DD4D37E1D32E8CE5F74FC5B43DAAC1C35' }
)

foreach ($item in $expectedSounds) {
    $rule = @($config.replacement_rules | Where-Object { $_.name -eq $item.Name })
    $expectedUrl = "https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/sounds/$($item.File)"
    if ($rule.Count -ne 1 -or $rule[0].cdn_url -ne $expectedUrl) {
        throw "Wrong sound rule for $($item.Name)"
    }

    $path = Join-Path $soundDirectory $item.File
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing replacement sound: $($item.File)"
    }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -ne $item.Hash) {
        throw "Replacement sound was modified: $($item.File)"
    }
}

$upRule = @($config.replacement_rules | Where-Object { $_.name -eq 'crystal skybox up' })
$expectedUpUrl = 'https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/visuals/skybox/crystal/sky31_up.png'
if ($upRule.Count -ne 1 -or $upRule[0].cdn_url -ne $expectedUpUrl) {
    throw 'Skybox Up rule does not point to sky31_up.png'
}

$upPath = Join-Path $skyboxDirectory 'sky31_up.png'
if (-not (Test-Path -LiteralPath $upPath)) {
    throw 'Sky 31 Up file is missing'
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $upPath).Hash -ne 'DD9AF8BD494E8E77C62C01A5B931D78E7A97B1315D9F7C9E4DAB7BCFA14E0CDF') {
    throw 'sky31_up.png hash does not match the catalog asset'
}

Write-Host 'Wisp sounds and Skybox Up validation passed: four exact OGG files and Sky 31 Up replacement.'