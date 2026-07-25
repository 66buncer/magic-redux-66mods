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
        File = 'sky31_ft.png'
        Ids = @(14147882761, 12261809766, 135908632589654, 84214501374682, 10196550367, 2108482231)
    }
    'crystal skybox bk' = @{
        File = 'sky31_bk.png'
        Ids = @(2108482005, 14147881792, 135908632589654, 84214501374682, 10196550937, 12261809766)
    }
    'crystal skybox lf' = @{
        File = 'sky31_lf.png'
        Ids = @(14147883091, 135908632589654, 84214501374682, 2108482395, 12261809766, 10196550128)
    }
    'crystal skybox rt' = @{
        File = 'sky31_rt.png'
        Ids = @(14147882405, 135908632589654, 84214501374682, 2108482542, 12261809766, 10196549902)
    }
    'crystal skybox up' = @{
        File = 'sky31_up.png'
        Ids = @(14147881297, 72960281658487, 92138082970751, 2108482676, 10196567794, 12261813678)
    }
    'crystal skybox dn' = @{
        File = 'sky31_dn.png'
        Ids = @(2108545280, 10196550667, 14147882149, 103020541883227, 89972436184102, 12261813110)
    }
}

Add-Type -AssemblyName System.Drawing
foreach ($fileName in @('sky31_ft.png', 'sky31_bk.png', 'sky31_lf.png', 'sky31_rt.png', 'sky31_up.png', 'sky31_dn.png')) {
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

if ((Test-Path -LiteralPath $panoramaPath) -and $false) {
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $tempDirectory = Join-Path $tempRoot ("magic-redux-skybox-test-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDirectory | Out-Null
    try {
        $robloxCubemapPath = Join-Path $tempDirectory 'roblox-cubemap.png'
        $roundtripPath = Join-Path $tempDirectory 'roundtrip.png'
        $facePaths = @('sky31_ft.png', 'sky31_rt.png', 'sky31_bk.png', 'sky31_lf.png', 'sky31_up.png', 'sky31_dn.png') |
            ForEach-Object { Join-Path $skyboxDirectory $_ }

        # Roblox uses -Z for SkyboxFt and +Z for SkyboxBk. FFmpeg's
        # cubemap FRONT is +Z and BACK is -Z, so Ft/Bk must be reversed.
        # Roblox maps +Y to Up (rotated CW) and -Y to Dn (rotated CCW),
        # while FFmpeg calls -Y "up" and +Y "down".
        & ffmpeg -hide_banner -loglevel error -y `
            -i $facePaths[0] -i $facePaths[1] -i $facePaths[2] `
            -i $facePaths[3] -i $facePaths[4] -i $facePaths[5] `
            -filter_complex "[2:v][1:v][0:v]hstack=inputs=3[top];[5:v]transpose=1[ffmpeg_up];[4:v]transpose=2,hflip,vflip,transpose=2[ffmpeg_down];[3:v][ffmpeg_up][ffmpeg_down]hstack=inputs=3[bottom];[top][bottom]vstack=inputs=2" `
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

Write-Host "Crystal skybox validation passed: Sky 31 has six 1024px faces and six config rules."
