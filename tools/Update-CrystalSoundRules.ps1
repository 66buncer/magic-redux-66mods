param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$baseUrl = 'https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/sounds'

$newRules = @(
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
    @{ Name='crystal map ambience'; Ids=@(17813065011,17813065464,12099785239); File='map_ambience_crystal.ogg' }
)

$replacementFiles = [ordered]@{
    'magic kill 1' = 'chant1_short.ogg'
    'magic kill 2' = 'chant2_short.ogg'
    'magic kill 3' = 'chant3_short.ogg'
    'crystal portal ambience' = 'evilportal_loop.ogg'
    'crystal katana attack 1' = 'wand1_short.ogg'
    'crystal katana attack 2' = 'wand2_short.ogg'
}

foreach ($entry in $replacementFiles.GetEnumerator()) {
    $matches = @($config.replacement_rules | Where-Object { $_.name -eq $entry.Key })
    if ($matches.Count -ne 1) {
        throw "Expected one existing rule named '$($entry.Key)'"
    }
    $matches[0].cdn_url = "$baseUrl/$($entry.Value)"
}

$removedNames = @('crystal lobby music', 'crystal lobby muffled', 'magic ui damage')
$newNames = @($newRules.Name) + $removedNames
$keptRules = @($config.replacement_rules | Where-Object { $newNames -notcontains $_.name })
$generatedRules = foreach ($item in $newRules) {
    [pscustomobject][ordered]@{
        name = $item.Name
        replace_ids = @($item.Ids | ForEach-Object { [long]$_ })
        enabled = $true
        mode = 'cdn'
        cdn_url = "$baseUrl/$($item.File)"
    }
}

$config.replacement_rules = @($keptRules) + @($generatedRules)
$json = $config | ConvertTo-Json -Depth 10
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($configPath, $json, $utf8NoBom)

Write-Host "Updated Crystal sound rules: added $($newRules.Count), refreshed $($replacementFiles.Count)."
