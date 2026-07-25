param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$failures = [System.Collections.Generic.List[string]]::new()

$forbiddenRules = @('magic ui damage', 'crystal lobby music', 'crystal lobby muffled')
foreach ($name in $forbiddenRules) {
    if (@($config.replacement_rules | Where-Object name -eq $name).Count -gt 0) {
        $failures.Add("Rule must be absent: $name")
    }
}

$forbiddenIds = @(13853836511, 17697682466, 120824068504773, 17733314783, 114306049661290)
$configuredIds = @($config.replacement_rules | ForEach-Object replace_ids | ForEach-Object { [long]$_ })
foreach ($id in $forbiddenIds) {
    if ($configuredIds -contains [long]$id) {
        $failures.Add("Replacement ID must be absent: $id")
    }
}

$iconRules = [ordered]@{
    'magic ui arch top' = 'arch_top.png'
    'magic ui nem top' = 'nem_top.png'
}
foreach ($entry in $iconRules.GetEnumerator()) {
    $rule = @($config.replacement_rules | Where-Object name -eq $entry.Key)
    $expectedUrl = "https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/visuals/icons/$($entry.Value)"
    if ($rule.Count -ne 1 -or $rule[0].cdn_url -ne $expectedUrl) {
        $failures.Add("Wrong image rule: $($entry.Key)")
    }

    $path = Join-Path $RepositoryRoot "visuals\icons\$($entry.Value)"
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing icon: $($entry.Value)")
        continue
    }
    Add-Type -AssemblyName System.Drawing
    $bitmap = [Drawing.Bitmap]::FromFile($path)
    try {
        if ($bitmap.Width -ne 256 -or $bitmap.Height -ne 256) {
            $failures.Add("Icon must be 256x256: $($entry.Value)")
        }
        if (-not [Drawing.Image]::IsAlphaPixelFormat($bitmap.PixelFormat)) {
            $failures.Add("Icon must preserve alpha: $($entry.Value)")
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

$medkitRules = @(
    @{ Name='crystal medkit quick stick'; Source='jar1.ogg'; File='medkit_jar1_x2_5.ogg' },
    @{ Name='crystal medkit bandage rip'; Source='page1.ogg'; File='medkit_page1_x2_5.ogg' },
    @{ Name='crystal medkit heal'; Source='learn.ogg'; File='medkit_learn_x2_5.ogg' },
    @{ Name='crystal medkit reload pop'; Source='bubble1.ogg'; File='medkit_bubble1_x2_5.ogg' },
    @{ Name='crystal medkit equip catch'; Source='tool1.ogg'; File='medkit_tool1_x2_5.ogg' },
    @{ Name='crystal medkit apply'; Source='spill.ogg'; File='medkit_spill_x2_5.ogg' }
)

function Get-RmsDb([string]$Path) {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = & ffmpeg -hide_banner -i $Path -af 'astats=metadata=0:reset=0' -f null NUL 2>&1
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $match = $lines | Select-String 'RMS level dB:\s+(-?[0-9.]+)' | Select-Object -Last 1
    if (-not $match) {
        throw "Could not measure RMS level: $Path"
    }
    return [double]$match.Matches[0].Groups[1].Value
}

foreach ($item in $medkitRules) {
    $rule = @($config.replacement_rules | Where-Object name -eq $item.Name)
    $expectedUrl = "https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/sounds/$($item.File)"
    if ($rule.Count -ne 1 -or $rule[0].cdn_url -ne $expectedUrl) {
        $failures.Add("Wrong amplified medkit rule: $($item.Name)")
    }

    $sourcePath = Join-Path $RepositoryRoot "sounds\$($item.Source)"
    $outputPath = Join-Path $RepositoryRoot "sounds\$($item.File)"
    if (-not (Test-Path -LiteralPath $outputPath)) {
        $failures.Add("Missing amplified medkit sound: $($item.File)")
        continue
    }

    $gainDb = (Get-RmsDb $outputPath) - (Get-RmsDb $sourcePath)
    if ([Math]::Abs($gainDb - 7.96) -gt 0.7) {
        $failures.Add("Medkit sound is not amplified by x2.5: $($item.File), measured gain $gainDb dB")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Requested override validation failed with $($failures.Count) problem(s)."
}

Write-Host 'Requested override validation passed: no lobby/damage rules, two UI icons, six x2.5 medkit sounds.'
