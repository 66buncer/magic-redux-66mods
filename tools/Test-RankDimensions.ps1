param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$rankDirectory = Join-Path $RepositoryRoot 'ranks'
$configPath = Join-Path $RepositoryRoot 'configs\Crystal_V1.0.json'
$maxSize = 128

Add-Type -AssemblyName System.Drawing
$failures = [System.Collections.Generic.List[string]]::new()
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$rankRules = @($config.replacement_rules | Where-Object { $_.name -like 'crystal rank:*' })

if ($rankRules.Count -ne 18) {
    throw "Expected 18 rank rules, found $($rankRules.Count)"
}

foreach ($rule in $rankRules) {
    if ($rule.cdn_url -notmatch '/ranks/([^/]+_128\.png)$') {
        $failures.Add("Rank rule does not use a 128px URL: $($rule.name)")
        continue
    }

    $fileName = $Matches[1]
    $rankPath = Join-Path $rankDirectory $fileName
    if (-not (Test-Path -LiteralPath $rankPath)) {
        $failures.Add("Missing 128px rank file: $fileName")
        continue
    }

    $image = [Drawing.Image]::FromFile($rankPath)
    try {
        if ($image.Width -gt $maxSize -or $image.Height -gt $maxSize) {
            $failures.Add("$fileName is too large: $($image.Width)x$($image.Height)")
        }
        if (-not [Drawing.Image]::IsAlphaPixelFormat($image.PixelFormat)) {
            $failures.Add("$fileName does not preserve alpha")
        }
    }
    finally {
        $image.Dispose()
    }
}

foreach ($protectedIcon in @('visuals\icons\arch_top.png', 'visuals\icons\nem_top.png')) {
    $protectedPath = Join-Path $RepositoryRoot $protectedIcon
    if (-not (Test-Path -LiteralPath $protectedPath)) {
        $failures.Add("Protected icon is missing: $protectedIcon")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Rank dimension validation failed with $($failures.Count) problem(s)."
}

Write-Host "Rank dimension validation passed: 18 rank rules use 128px alpha PNGs."
