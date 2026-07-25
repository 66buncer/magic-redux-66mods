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
$expectedUpUrl = 'https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/visuals/skybox/crystal/up_v4.png'
if ($upRule.Count -ne 1 -or $upRule[0].cdn_url -ne $expectedUpUrl) {
    throw 'Skybox Up rule does not point to up_v4.png'
}

$upV3 = Join-Path $skyboxDirectory 'up_v3.png'
$upV4 = Join-Path $skyboxDirectory 'up_v4.png'
if (-not (Test-Path -LiteralPath $upV4)) {
    throw 'Corrected Skybox Up file is missing'
}

$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempDirectory = Join-Path $tempRoot ("crystal-up-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempDirectory | Out-Null
try {
    $expectedUp = Join-Path $tempDirectory 'expected-up-v4.png'
    & ffmpeg -hide_banner -loglevel error -y -i $upV3 -vf 'transpose=1' -frames:v 1 $expectedUp
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not build expected clockwise Up correction'
    }

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $psnrOutput = (& ffmpeg -hide_banner -i $expectedUp -i $upV4 -lavfi psnr -f null NUL 2>&1) -join "`n"
    $ErrorActionPreference = $previousPreference
    if ($psnrOutput -notmatch 'average:inf') {
        throw 'up_v4.png must be an exact 90-degree clockwise rotation of up_v3.png'
    }
}
finally {
    $resolvedTemp = [IO.Path]::GetFullPath($tempDirectory)
    if ($resolvedTemp.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
    }
}

Write-Host 'Wisp sounds and Skybox Up validation passed: four exact OGG files and one additional clockwise Up correction.'
