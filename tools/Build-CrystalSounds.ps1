param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ExtractRoot = 'C:\Users\b\Desktop\chat\thaumcraft_sound_extract\selected'
)

$ErrorActionPreference = 'Stop'
$outputDirectory = Join-Path $RepositoryRoot 'sounds'
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

function Get-SourcePath {
    param([string]$RelativePath)
    $path = Join-Path $ExtractRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing source sound: $path"
    }
    return $path
}

function Invoke-AudioBuild {
    param(
        [string[]]$Arguments,
        [string]$OutputName
    )
    $outputPath = Join-Path $outputDirectory $OutputName
    & ffmpeg -hide_banner -loglevel error -y @Arguments -ar 44100 -c:a libvorbis -q:a 5 $outputPath
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while building $OutputName"
    }
}

$directFiles = [ordered]@{
    'key.ogg'        = '02_ui_feedback\key.ogg'
    'scan.ogg'       = '01_crystal_core\scan.ogg'
    'coins.ogg'      = '02_ui_feedback\coins.ogg'
    'learn.ogg'      = '01_crystal_core\learn.ogg'
    'jar1.ogg'       = '01_crystal_core\jar1.ogg'
    'jar3.ogg'       = '01_crystal_core\jar3.ogg'
    'poof1.ogg'      = '02_ui_feedback\poof1.ogg'
    'poof2.ogg'      = '02_ui_feedback\poof2.ogg'
    'tool1.ogg'      = '05_mechanical_ui\tool1.ogg'
    'fireloop.ogg'   = '07_dark_magic_ambience\fireloop.ogg'
    'wispdead.ogg'   = '07_dark_magic_ambience\wispdead.ogg'
    'wand3.ogg'      = '03_combat_magic\wand3.ogg'
    'craftstart.ogg' = '02_ui_feedback\craftstart.ogg'
    'hhon.ogg'       = '05_mechanical_ui\hhon.ogg'
    'crabclaw.ogg'   = '06_impacts_breaks\crabclaw.ogg'
    'page1.ogg'      = '05_mechanical_ui\page1.ogg'
    'bubble1.ogg'    = '08_liquids_machines\bubble1.ogg'
    'spill.ogg'      = '06_impacts_breaks\spill.ogg'
}

foreach ($entry in $directFiles.GetEnumerator()) {
    Copy-Item -LiteralPath (Get-SourcePath $entry.Value) `
        -Destination (Join-Path $outputDirectory $entry.Key) -Force
}

$infuserStart = Get-SourcePath '04_ambience_portals\infuserstart.ogg'
$shieldEffect = Get-SourcePath '01_crystal_core\runicShieldEffect.ogg'
Invoke-AudioBuild -OutputName 'warhorn_crystal.ogg' -Arguments @(
    '-i', $infuserStart,
    '-i', $shieldEffect,
    '-filter_complex',
    '[0:a]volume=0.72[a0];[1:a]adelay=850|850,volume=0.88[a1];[a0][a1]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.95,volume=0.8[out]',
    '-map', '[out]'
)

$ice1 = Get-SourcePath '01_crystal_core\ice1.ogg'
$ice2 = Get-SourcePath '01_crystal_core\ice2.ogg'
$ice3 = Get-SourcePath '01_crystal_core\ice3.ogg'
Invoke-AudioBuild -OutputName 'timer10_crystal.ogg' -Arguments @(
    '-i', $ice1, '-i', $ice2, '-i', $ice3,
    '-filter_complex',
    '[0:a]volume=0.68[a0];[1:a]adelay=900|900,volume=0.82[a1];[2:a]adelay=1800|1800,volume=1.0[a2];[a0][a1][a2]amix=inputs=3:duration=longest:normalize=0,alimiter=limit=0.95,volume=0.8[out]',
    '-map', '[out]'
)
Invoke-AudioBuild -OutputName 'timer4_crystal.ogg' -Arguments @(
    '-i', $ice1, '-i', $ice2, '-i', $ice3,
    '-filter_complex',
    '[0:a]volume=0.62[a0];[1:a]adelay=420|420,volume=0.78[a1];[2:a]adelay=840|840,volume=1.0[a2];[a0][a1][a2]amix=inputs=3:duration=longest:normalize=0,alimiter=limit=0.95,volume=0.8[out]',
    '-map', '[out]'
)

$monolith = Get-SourcePath '04_ambience_portals\monolith.ogg'
Invoke-AudioBuild -OutputName 'lobby_crystal.ogg' -Arguments @(
    '-i', $monolith,
    '-filter_complex',
    '[0:a]asplit=3[a][b][c];[a]atrim=start=3:end=20.028,asetpts=PTS-STARTPTS[mid];[b]atrim=start=20.028:end=23.028,asetpts=PTS-STARTPTS[tail];[c]atrim=start=0:end=3,asetpts=PTS-STARTPTS[head];[tail][head]acrossfade=d=3:c1=tri:c2=tri[seam];[mid][seam]concat=n=2:v=0:a=1,highpass=f=55,lowpass=f=11000,volume=0.72,alimiter=limit=0.92[out]',
    '-map', '[out]'
)
Invoke-AudioBuild -OutputName 'lobby_crystal_muffled.ogg' -Arguments @(
    '-i', (Join-Path $outputDirectory 'lobby_crystal.ogg'),
    '-af', 'lowpass=f=950,highpass=f=70,volume=0.48'
)
Invoke-AudioBuild -OutputName 'map_ambience_crystal.ogg' -Arguments @(
    '-i', (Join-Path $outputDirectory 'lobby_crystal.ogg'),
    '-af', 'lowpass=f=6500,highpass=f=65,volume=0.34'
)

Invoke-AudioBuild -OutputName 'win_theme_crystal.ogg' -Arguments @(
    '-i', $monolith,
    '-i', $shieldEffect,
    '-filter_complex',
    '[0:a]atrim=0:6,asetpts=PTS-STARTPTS,volume=0.55,afade=t=out:st=5:d=1[a0];[1:a]adelay=2200|2200,volume=0.9[a1];[a0][a1]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.95,volume=0.8[out]',
    '-map', '[out]'
)
Invoke-AudioBuild -OutputName 'intro_crystal.ogg' -Arguments @(
    '-i', $monolith,
    '-i', $shieldEffect,
    '-filter_complex',
    '[0:a]atrim=0:5.2,asetpts=PTS-STARTPTS,volume=0.5,afade=t=out:st=4.4:d=0.8[a0];[1:a]adelay=1450|1450,volume=0.82[a1];[a0][a1]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.94[out]',
    '-map', '[out]'
)

$rumble = Get-SourcePath '06_impacts_breaks\rumble.ogg'
$wispDead = Get-SourcePath '07_dark_magic_ambience\wispdead.ogg'
Invoke-AudioBuild -OutputName 'lose_game_crystal.ogg' -Arguments @(
    '-i', $wispDead,
    '-i', $rumble,
    '-filter_complex',
    '[0:a]volume=0.78[a0];[1:a]adelay=700|700,volume=0.72[a1];[a0][a1]amix=inputs=2:duration=longest:normalize=0,afade=t=out:st=2.45:d=0.45,alimiter=limit=0.94,volume=0.8[out]',
    '-map', '[out]'
)

foreach ($index in 1..3) {
    $chant = Get-SourcePath "07_dark_magic_ambience\chant$index.ogg"
    Invoke-AudioBuild -OutputName "chant${index}_short.ogg" -Arguments @(
        '-i', $chant,
        '-af', 'atrim=0:1.35,asetpts=PTS-STARTPTS,afade=t=out:st=1.0:d=0.35,alimiter=limit=0.94,volume=0.82'
    )
}

foreach ($index in 1..2) {
    $wand = Get-SourcePath "03_combat_magic\wand$index.ogg"
    Invoke-AudioBuild -OutputName "wand${index}_short.ogg" -Arguments @(
        '-i', $wand,
        '-af', 'atrim=0:0.9,asetpts=PTS-STARTPTS,afade=t=out:st=0.62:d=0.28,alimiter=limit=0.94'
    )
}

$evilPortal = Get-SourcePath '04_ambience_portals\evilportal.ogg'
Invoke-AudioBuild -OutputName 'evilportal_loop.ogg' -Arguments @(
    '-i', $evilPortal,
    '-filter_complex',
    '[0:a]asplit=3[a][b][c];[a]atrim=start=2:end=12.524,asetpts=PTS-STARTPTS[mid];[b]atrim=start=12.524:end=14.524,asetpts=PTS-STARTPTS[tail];[c]atrim=start=0:end=2,asetpts=PTS-STARTPTS[head];[tail][head]acrossfade=d=2:c1=tri:c2=tri[seam];[mid][seam]concat=n=2:v=0:a=1,alimiter=limit=0.92,volume=0.8[out]',
    '-map', '[out]'
)

Write-Host "Built Crystal sound set in $outputDirectory"
