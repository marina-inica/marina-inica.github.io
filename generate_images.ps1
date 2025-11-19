param (
    [Parameter(Mandatory = $true)]
    [string]$OutputDir,

    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Inputs
)

# Check for ImageMagick
if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
    Write-Host "Error: ImageMagick 'magick' command not found. Install from https://imagemagick.org/script/download.php"
    exit 1
}

# Create output directory if missing
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$widths = @(200, 600, 900)
$formats = @("jpeg", "webp")

# Gather all input image files
$files = @()
foreach ($input in $Inputs) {
    if (Test-Path $input) {
        if ((Get-Item $input).PSIsContainer) {
            $files += Get-ChildItem -Path $input -Include *.jpg, *.jpeg, *.png -Recurse
        } else {
            $files += Get-Item $input
        }
    } else {
        Write-Host "Warning: $input not found"
    }
}

if ($files.Count -eq 0) {
    Write-Host "No image files found."
    exit 0
}

foreach ($file in $files) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $baseOutDir = Join-Path $OutputDir $name

    foreach ($format in $formats) {
        foreach ($w in $widths) {
            $targetDir = Join-Path $baseOutDir $format
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            # width is filename
            $targetFile = Join-Path $targetDir "$w.$format"
            Write-Host "Generating $targetFile"
            magick "$($file.FullName)" -auto-orient -resize $w "$targetFile"
        }
    }
}

Write-Host "Done. All resized images are in '$OutputDir'."
