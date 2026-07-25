param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$rules = @($config.replacement_rules)
$watermarkRules = @($rules | Where-Object { $_.cdn_url -like '*Rivals-Pack-Assets/main/watermark_v1/*' })

if ($watermarkRules.Count -ne 6) {
    throw "Expected 6 watermark rules, found $($watermarkRules.Count)"
}
if ($rules.Count -lt $watermarkRules.Count) {
    throw 'Replacement rules list is shorter than the watermark block'
}

$tail = @($rules | Select-Object -Last $watermarkRules.Count)
$tailWatermarkCount = @($tail | Where-Object { $_.cdn_url -like '*Rivals-Pack-Assets/main/watermark_v1/*' }).Count
if ($tailWatermarkCount -ne $watermarkRules.Count) {
    throw 'Watermark rules must stay at the bottom of Crystal_V1.0.json'
}

$firstRule = $rules[0]
if ($firstRule.cdn_url -like '*Rivals-Pack-Assets/main/watermark_v1/*') {
    throw 'Crystal_V1.0.json starts with watermark rules'
}

Write-Host 'Watermark rule order validation passed: 6 watermark rules are at the bottom.'
