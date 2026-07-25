param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
$skyboxDirectory = Join-Path $RepositoryRoot 'visuals\skybox\crystal'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$panoramaPath = Join-Path $skyboxDirectory 'crystal_panorama.png'

$expectedRules = [ordered]@{
    'crystal skybox ft' = @{
        File = 'ft_v2.png'
        Ids = @(14147882761, 2108482231, 10196550367)
    }
    'crystal skybox bk' = @{
        File = 'bk_v2.png'
        Ids = @(14147881792, 2108482005, 10196550937)
    }
    'crystal skybox lf' = @{
        File = 'lf_v2.png'
        Ids = @(14147883091, 2108482395, 10196550128)
    }
    'crystal skybox rt' = @{
        File = 'rt_v2.png'
        Ids = @(14147882405, 2108482542, 10196549902)
    }
    'crystal skybox up' = @{
        File = 'up_v3.png'
        Ids = @(14147881297, 2108482676, 10196567794)
    }
    'crystal skybox dn' = @{
        File = 'dn_v2.png'
        Ids = @(14147882149, 2108545280, 10196550667)
    }
}

Add-Type -AssemblyName System.Drawing
foreach ($fileName in @('ft_v2.png', 'bk_v2.png', 'lf_v2.png', 'rt_v2.png', 'up_v3.png', 'dn_v2.png')) {
    $facePath = Join-Path $skyboxDirectory $fileName
    if (-not (Test-Path -LiteralPath $facePath)) {
        $failures.Add("Missing face: $fileName")
        continue
    }

    $image = [System.Drawing.Image]::FromFile($facePath)
    try {
        if ($image.Width -ne 1024 -or $image.Height -ne 1024) {
            $failures.Add("$fileName must be 1024x1024, got $($image.Width)x$($image.Height)")
        }
    }
    finally {
        $image.Dispose()
    }
}

if ((Test-Path -LiteralPath $panoramaPath) -and $failures.Count -eq 0) {
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $tempDirectory = Join-Path $tempRoot ("magic-redux-skybox-test-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDirectory | Out-Null
    try {
        $robloxCubemapPath = Join-Path $tempDirectory 'roblox-cubemap.png'
        $roundtripPath = Join-Path $tempDirectory 'roundtrip.png'
        $facePaths = @('ft_v2.png', 'rt_v2.png', 'bk_v2.png', 'lf_v2.png', 'up_v3.png', 'dn_v2.png') |
            ForEach-Object { Join-Path $skyboxDirectory $_ }

        # Roblox uses -Z for SkyboxFt and +Z for SkyboxBk. FFmpeg's
        # cubemap FRONT is +Z and BACK is -Z, so Ft/Bk must be reversed.
        # Roblox maps +Y to Up (rotated CW) and -Y to Dn (rotated CCW),
        # while FFmpeg calls -Y "up" and +Y "down".
        # up_v3 also contains the manually verified 180-degree in-game correction.
        & ffmpeg -hide_banner -loglevel error -y `
            -i $facePaths[0] -i $facePaths[1] -i $facePaths[2] `
            -i $facePaths[3] -i $facePaths[4] -i $facePaths[5] `
            -filter_complex "[2:v][1:v][0:v]hstack=inputs=3[top];[5:v]transpose=1[ffmpeg_up];[4:v]hflip,vflip,transpose=2[ffmpeg_down];[3:v][ffmpeg_up][ffmpeg_down]hstack=inputs=3[bottom];[top][bottom]vstack=inputs=2" `
            -frames:v 1 $robloxCubemapPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while assembling the Roblox cubemap"
        }

        & ffmpeg -hide_banner -loglevel error -y -i $robloxCubemapPath `
            -vf "v360=input=c3x2:in_forder=frblud:in_frot=000000:output=equirect:interp=lanczos:w=1774:h=887" `
            -frames:v 1 $roundtripPath
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed while reconstructing the panorama"
        }

        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $psnrOutput = (& ffmpeg -hide_banner -i $panoramaPath -i $roundtripPath -lavfi psnr -f null NUL 2>&1) -join "`n"
        $ErrorActionPreference = $previousPreference
        if ($psnrOutput -notmatch 'average:([0-9.]+)') {
            $failures.Add('Could not read the cubemap roundtrip PSNR')
        }
        elseif ([double]$Matches[1] -lt 30.0) {
            $failures.Add("Roblox face orientation is incorrect; roundtrip PSNR is $($Matches[1]) dB")
        }
    }
    finally {
        $resolvedTemp = [System.IO.Path]::GetFullPath($tempDirectory)
        if ($resolvedTemp.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
        }
    }
}

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
foreach ($entry in $expectedRules.GetEnumerator()) {
    $rule = @($config.replacement_rules | Where-Object { $_.name -eq $entry.Key })
    if ($rule.Count -ne 1) {
        $failures.Add("Expected exactly one config rule named '$($entry.Key)'")
        continue
    }

    $expectedIds = @($entry.Value.Ids | Sort-Object)
    $actualIds = @($rule[0].replace_ids | ForEach-Object { [long]$_ } | Sort-Object)
    if (($expectedIds -join ',') -ne ($actualIds -join ',')) {
        $failures.Add("Wrong IDs for '$($entry.Key)': $($actualIds -join ',')")
    }

    $expectedUrl = "https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/visuals/skybox/crystal/$($entry.Value.File)"
    if ($rule[0].cdn_url -ne $expectedUrl -or $rule[0].mode -ne 'cdn' -or -not $rule[0].enabled) {
        $failures.Add("Wrong CDN settings for '$($entry.Key)'")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Crystal skybox validation failed with $($failures.Count) problem(s)."
}

Write-Host "Crystal skybox validation passed: six 1024px Roblox-oriented faces and six config rules."
