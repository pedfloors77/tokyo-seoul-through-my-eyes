# Regenerates the web copies of every photograph listed in data/photo-map.txt.
# Reads the originals from ../Japan and korea trip, applies EXIF rotation, and
# writes a 1800px version plus a 700px thumbnail into assets/photos/<city>/<place>/.
# Existing files are overwritten. Originals are never touched.
#
# Run:  powershell -ExecutionPolicy Bypass -File tools\resize-photos.ps1

Add-Type -AssemblyName System.Drawing

$web  = Split-Path -Parent $PSScriptRoot
$root = Split-Path -Parent $web
$src  = Join-Path $root "Japan and korea trip"
$dest = Join-Path $web "assets\photos"

$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }

function Save-Resized($img, $maxDim, $path, $quality) {
  $scale = [Math]::Min($maxDim / $img.Width, $maxDim / $img.Height)
  if ($scale -gt 1) { $scale = 1 }
  $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.SmoothingMode = 'HighQuality'
  $g.PixelOffsetMode = 'HighQuality'
  $g.DrawImage($img, 0, 0, $w, $h)
  $g.Dispose()
  $ps = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $ps.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)
  $bmp.Save($path, $enc, $ps)
  $bmp.Dispose()
}

$done = 0; $skipped = @()

foreach ($line in (Get-Content (Join-Path $web "data\photo-map.txt") -Encoding UTF8)) {
  if ($line.Trim() -eq "") { continue }
  $p = $line -split '\|'
  $orig = $p[0]; $city = $p[1]; $place = $p[2]; $name = $p[3]

  $inPath = Join-Path $src $orig
  if (-not (Test-Path $inPath)) { $skipped += $orig; continue }

  $outDir = Join-Path $dest "$city\$place"
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null

  try {
    $img = [System.Drawing.Image]::FromFile($inPath)
    if ($img.PropertyIdList -contains 274) {
      switch ([BitConverter]::ToUInt16($img.GetPropertyItem(274).Value, 0)) {
        3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
      }
    }
    Save-Resized $img 1800 (Join-Path $outDir "$name.jpg") 82
    Save-Resized $img 700  (Join-Path $outDir "$name.thumb.jpg") 76
    $img.Dispose()
    $done++
  } catch {
    $skipped += "$orig ($_)"
  }
}

Write-Output "resized $done photographs into assets/photos"
foreach ($s in $skipped) { Write-Warning "skipped: $s" }
Write-Output "Now run tools\build-photos.ps1 and tools\build-data.ps1."
