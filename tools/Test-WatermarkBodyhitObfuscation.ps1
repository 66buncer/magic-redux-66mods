param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$WatermarkConfigPath = 'C:\Users\b\Downloads\watermark_v1 (1).json'
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$watermarkConfig = Get-Content -Raw -LiteralPath $WatermarkConfigPath | ConvertFrom-Json
$failures = [System.Collections.Generic.List[string]]::new()
$bannedNamePattern = '(?i)(watermark|body|boby|hit|crystal|head|rank|sound)'

foreach ($incoming in @($watermarkConfig.replacement_rules)) {
    $ids = @($incoming.replace_ids | ForEach-Object { [long]$_ })
    $matches = @($config.replacement_rules | Where-Object {
        $_.cdn_url -eq $incoming.cdn_url -and ((@($_.replace_ids | ForEach-Object { [long]$_ }) -join ',') -eq ($ids -join ','))
    })
    if ($matches.Count -ne 1) {
        $failures.Add("Expected exactly one watermark rule for $($incoming.cdn_url), found $($matches.Count)")
        continue
    }
    if ($matches[0].name -match $bannedNamePattern) {
        $failures.Add("Watermark rule has readable name: $($matches[0].name)")
    }
    if ($matches[0].name.Length -lt 12) {
        $failures.Add("Watermark rule name is too short to look randomized: $($matches[0].name)")
    }
}

$bodyhitUrl = 'https://raw.githubusercontent.com/66buncer/magic-redux-66mods/main/sounds/critical_hit7_8_layered.ogg'
$bodyhitRules = @($config.replacement_rules | Where-Object { $_.cdn_url -eq $bodyhitUrl -and @($_.replace_ids | ForEach-Object { [long]$_ }) -contains 13110130082 })
if ($bodyhitRules.Count -ne 1) {
    $failures.Add("Expected exactly one layered bodyhit rule, found $($bodyhitRules.Count)")
} else {
    if ($bodyhitRules[0].name -match $bannedNamePattern) {
        $failures.Add("Bodyhit rule has readable name: $($bodyhitRules[0].name)")
    }
    if ($bodyhitRules[0].name.Length -lt 12) {
        $failures.Add("Bodyhit rule name is too short to look randomized: $($bodyhitRules[0].name)")
    }
    if ($bodyhitRules[0].mode -ne 'cdn') {
        $failures.Add('Bodyhit rule must stay cdn mode')
    }
}

$allNames = @($config.replacement_rules | ForEach-Object { $_.name })
$duplicateNames = @($allNames | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
foreach ($name in $duplicateNames) {
    $failures.Add("Duplicate rule name: $name")
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Watermark/bodyhit obfuscation validation failed with $($failures.Count) problem(s)."
}

Write-Host 'Watermark/bodyhit obfuscation validation passed.'
