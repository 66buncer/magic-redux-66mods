param(
    [string]$SelectionPath = (Join-Path $PSScriptRoot 'asset-selection.json')
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$workingRoot = Join-Path $repoRoot 'working\thaumcraft_visual_extract'
$sourceRoot = Join-Path $workingRoot 'source_selected'
$manifestPath = Join-Path $workingRoot 'manifest.csv'
$selection = Get-Content -Raw -LiteralPath $SelectionPath | ConvertFrom-Json

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing
[IO.Directory]::CreateDirectory($sourceRoot) | Out-Null

$zip = [IO.Compression.ZipFile]::OpenRead($selection.jar)
try {
    $rows = @()
    $seenDestinations = @{}

    foreach ($item in $selection.entries) {
        $entry = $zip.GetEntry($item.source)
        if (-not $entry) {
            throw "Missing JAR entry: $($item.source)"
        }

        $texturePath = $item.source -replace '^assets/thaumcraft/textures/', ''
        $relativePath = "$($item.group)/$texturePath"
        if ($seenDestinations.ContainsKey($relativePath)) {
            throw "Duplicate destination: $relativePath"
        }
        $seenDestinations[$relativePath] = $true

        $destination = Join-Path $sourceRoot ($relativePath -replace '/', '\')
        [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null

        $input = $entry.Open()
        try {
            $output = [IO.File]::Create($destination)
            try {
                $input.CopyTo($output)
            }
            finally {
                $output.Dispose()
            }
        }
        finally {
            $input.Dispose()
        }

        $stream = [IO.File]::OpenRead($destination)
        try {
            $image = [Drawing.Image]::FromStream($stream, $false, $false)
            try {
                $width = $image.Width
                $height = $image.Height
            }
            finally {
                $image.Dispose()
            }
        }
        finally {
            $stream.Dispose()
        }

        $rows += [pscustomobject][ordered]@{
            source = $item.source
            target = $item.target
            mode = $item.mode
            group = $item.group
            relative_path = $relativePath
            width = $width
            height = $height
            bytes = (Get-Item -LiteralPath $destination).Length
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
        }
    }

    $rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
    Write-Output "EXTRACTED count=$($rows.Count) manifest=$manifestPath"
}
finally {
    $zip.Dispose()
}
