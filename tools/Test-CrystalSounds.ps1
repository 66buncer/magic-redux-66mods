param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$soundDirectory = Join-Path $RepositoryRoot 'sounds'
$failures = [System.Collections.Generic.List[string]]::new()

$expected = @(
    @{ Name='crystal warhorn'; Ids=@(73325703605178,94406584083681); File='warhorn_crystal.ogg' },
    @{ Name='crystal map select'; Ids=@(103035811146294); File='key.ogg' },
    @{ Name='crystal double jump'; Ids=@(16770456156,16492958314); File='swing2.ogg' },
    @{ Name='crystal duel timer 10'; Ids=@(17826470563); File='timer10_crystal.ogg' },
    @{ Name='crystal win theme'; Ids=@(18221725850,18239670056,18221726246); File='win_theme_crystal.ogg' },
    @{ Name='crystal self snitch'; Ids=@(99115398611290); File='learn.ogg' },
    @{ Name='crystal ding'; Ids=@(8483887957); File='jar3.ogg' },
    @{ Name='crystal matchmaking'; Ids=@(18525513345); File='scan.ogg' },
    @{ Name='crystal reward'; Ids=@(17769583566); File='coins.ogg' },
    @{ Name='crystal equipment whoosh'; Ids=@(106551800007995); File='swing1.ogg' },
    @{ Name='crystal duel timer 4'; Ids=@(17826390328); File='timer4_crystal.ogg' },
    @{ Name='crystal intro'; Ids=@(6384899588); File='intro_crystal.ogg' },
    @{ Name='crystal round lose'; Ids=@(16810321565); File='wispdead.ogg' },
    @{ Name='crystal game lose'; Ids=@(18239670367); File='lose_game_crystal.ogg' },
    @{ Name='crystal jumppad bounce'; Ids=@(17835965985); File='poof2.ogg' },
    @{ Name='crystal jumppad place'; Ids=@(85163949920258); File='tool1.ogg' },
    @{ Name='crystal molotov idle'; Ids=@(14812965418); File='fireloop.ogg' },
    @{ Name='crystal portal exit'; Ids=@(81610952487049); File='poof1.ogg' },
    @{ Name='crystal crossbow shoot'; Ids=@(82715240396507); File='wand3.ogg' },
    @{ Name='crystal crossbow pull'; Ids=@(112269321366473,13682532502); File='craftstart.ogg' },
    @{ Name='crystal crossbow latch'; Ids=@(76155503538875); File='hhon.ogg' },
    @{ Name='crystal fists attack'; Ids=@(13160401062); File='crabclaw.ogg' },
    @{ Name='crystal medkit quick stick'; Ids=@(17123622923); File='medkit_jar1_x2_5.ogg' },
    @{ Name='crystal medkit bandage rip'; Ids=@(13505411414); File='medkit_page1_x2_5.ogg' },
    @{ Name='crystal medkit heal'; Ids=@(17138490999); File='medkit_learn_x2_5.ogg' },
    @{ Name='crystal medkit reload pop'; Ids=@(13236026280); File='medkit_bubble1_x2_5.ogg' },
    @{ Name='crystal medkit equip catch'; Ids=@(13160326139); File='medkit_tool1_x2_5.ogg' },
    @{ Name='crystal medkit apply'; Ids=@(13505411336); File='medkit_spill_x2_5.ogg' },
    @{ Name='crystal map ambience'; Ids=@(17813065011,17813065464,12099785239); File='map_ambience_crystal.ogg' },
    @{ Name='magic kill 1'; Ids=@(16530229616); File='chant1_short.ogg' },
    @{ Name='magic kill 2'; Ids=@(16530229541); File='chant2_short.ogg' },
    @{ Name='magic kill 3'; Ids=@(16530229695); File='chant3_short.ogg' },
    @{ Name='crystal portal ambience'; Ids=@(114274252176516); File='evilportal_loop.ogg' },
    @{ Name='crystal katana attack 1'; Ids=@(14000023581); File='wand1_short.ogg' },
    @{ Name='crystal katana attack 2'; Ids=@(14000023392); File='wand2_short.ogg' }
)

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$forbiddenLobbyNames = @('crystal lobby music', 'crystal lobby muffled')
$forbiddenLobbyIds = @(17697682466, 120824068504773, 17733314783, 114306049661290)
$forbiddenLobbyFiles = @('lobby_crystal.ogg', 'lobby_crystal_muffled.ogg')

foreach ($name in $forbiddenLobbyNames) {
    if (@($config.replacement_rules | Where-Object { $_.name -eq $name }).Count -gt 0) {
        $failures.Add("Lobby music rule must be absent: $name")
    }
}

$configuredIds = @($config.replacement_rules | ForEach-Object { $_.replace_ids } | ForEach-Object { [long]$_ })
foreach ($id in $forbiddenLobbyIds) {
    if ($configuredIds -contains [long]$id) {
        $failures.Add("Lobby music replacement ID must be absent: $id")
    }
}

foreach ($fileName in $forbiddenLobbyFiles) {
    if (Test-Path -LiteralPath (Join-Path $soundDirectory $fileName)) {
        $failures.Add("Unused lobby music asset must be absent: $fileName")
    }
}

foreach ($item in $expected) {
    $rules = @($config.replacement_rules | Where-Object { $_.name -eq $item.Name })
    if ($rules.Count -ne 1) {
        $failures.Add("Expected one rule named '$($item.Name)', found $($rules.Count)")
        continue
    }

    $actualIds = @($rules[0].replace_ids | ForEach-Object { [long]$_ } | Sort-Object)
    $expectedIds = @($item.Ids | ForEach-Object { [long]$_ } | Sort-Object)
    if (($actualIds -join ',') -ne ($expectedIds -join ',')) {
        $failures.Add("Wrong IDs for '$($item.Name)'")
    }

    $expectedUrl = "https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/sounds/$($item.File)"
    if ($rules[0].cdn_url -ne $expectedUrl -or $rules[0].mode -ne 'cdn' -or -not $rules[0].enabled) {
        $failures.Add("Wrong CDN settings for '$($item.Name)'")
    }
}

$requiredFiles = @($expected.File | Sort-Object -Unique)
foreach ($fileName in $requiredFiles) {
    $path = Join-Path $soundDirectory $fileName
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing sound file: $fileName")
        continue
    }

    $probe = & ffprobe -v error -select_streams a:0 `
        -show_entries stream=codec_name,sample_rate,channels `
        -show_entries format=duration -of json $path | ConvertFrom-Json
    if ($probe.streams.Count -ne 1 -or $probe.streams[0].codec_name -ne 'vorbis') {
        $failures.Add("$fileName must contain one Vorbis audio stream")
    }
    if ([double]$probe.format.duration -le 0.05) {
        $failures.Add("$fileName is too short or has invalid duration")
    }
}

$soundRules = @($config.replacement_rules | Where-Object { $_.cdn_url -match '/sounds/' })
$duplicateIds = @(
    $soundRules |
        ForEach-Object { $_.replace_ids } |
        ForEach-Object { [long]$_ } |
        Group-Object |
        Where-Object Count -gt 1
)
if ($duplicateIds.Count -gt 0) {
    $failures.Add("Duplicate sound replacement IDs: $($duplicateIds.Name -join ',')")
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Crystal sound validation failed with $($failures.Count) problem(s)."
}

Write-Host "Crystal sound validation passed: $($expected.Count) mapped rule groups and $($requiredFiles.Count) required OGG files."
