# Rebuilds data/photos.json from:
#   data/photo-map.txt   original filename | city | place | new name
#   data/captions.txt    original filename | alt text | caption
#   EXIF on the originals in ../Japan and korea trip
#   the real pixel size of each generated web image
#
# Rows whose source image is missing are skipped with a warning.
# Run:  powershell -ExecutionPolicy Bypass -File tools\build-photos.ps1

Add-Type -AssemblyName System.Drawing

$web  = Split-Path -Parent $PSScriptRoot
$root = Split-Path -Parent $web
$src  = Join-Path $root "Japan and korea trip"

function Read-Pipe($path) {
  $h = @{}
  foreach ($line in (Get-Content $path -Encoding UTF8)) {
    if ($line.Trim() -eq "") { continue }
    $p = $line -split '\|'
    $h[$p[0]] = $p
  }
  return $h
}

$captions = Read-Pipe (Join-Path $web "data\captions.txt")

function Get-Exif($file) {
  $out = @{ dt = ""; lat = $null; lon = $null }
  try {
    $img = [System.Drawing.Image]::FromFile($file)
    $ids = $img.PropertyIdList
    function Rat($b, $o) {
      $n = [BitConverter]::ToUInt32($b, $o); $d = [BitConverter]::ToUInt32($b, $o + 4)
      if ($d -eq 0) { 0 } else { $n / $d }
    }
    if ($ids -contains 2 -and $ids -contains 4) {
      $b = $img.GetPropertyItem(2).Value
      $out.lat = (Rat $b 0) + (Rat $b 8) / 60 + (Rat $b 16) / 3600
      $b = $img.GetPropertyItem(4).Value
      $out.lon = (Rat $b 0) + (Rat $b 8) / 60 + (Rat $b 16) / 3600
      if ($ids -contains 1 -and [Text.Encoding]::ASCII.GetString($img.GetPropertyItem(1).Value).Trim([char]0) -eq 'S') { $out.lat = -$out.lat }
      if ($ids -contains 3 -and [Text.Encoding]::ASCII.GetString($img.GetPropertyItem(3).Value).Trim([char]0) -eq 'W') { $out.lon = -$out.lon }
    }
    if ($ids -contains 36867) { $out.dt = [Text.Encoding]::ASCII.GetString($img.GetPropertyItem(36867).Value).Trim([char]0) }
    elseif ($ids -contains 306) { $out.dt = [Text.Encoding]::ASCII.GetString($img.GetPropertyItem(306).Value).Trim([char]0) }
    $img.Dispose()
  } catch { }
  return $out
}

$rows = @()
$skipped = @()

foreach ($line in (Get-Content (Join-Path $web "data\photo-map.txt") -Encoding UTF8)) {
  if ($line.Trim() -eq "") { continue }
  $p = $line -split '\|'
  $orig = $p[0]; $city = $p[1]; $place = $p[2]; $name = $p[3]

  $origPath = Join-Path $src $orig
  if (-not (Test-Path $origPath)) { $skipped += $orig; continue }

  $rel      = "assets/photos/$city/$place/$name.jpg"
  $relThumb = "assets/photos/$city/$place/$name.thumb.jpg"
  $webPath  = Join-Path $web ($rel -replace '/', '\')
  if (-not (Test-Path $webPath)) { $skipped += "$orig (no web copy - re-run the resize step)"; continue }

  $img = [System.Drawing.Image]::FromFile($webPath)
  $w = $img.Width; $h = $img.Height
  $img.Dispose()

  $ex = Get-Exif $origPath
  $cap = $captions[$orig]

  $rows += [ordered]@{
    id                   = "$city/$place/$name"
    city                 = $city
    place                = $place
    src                  = $rel
    thumb                = $relThumb
    width                = $w
    height               = $h
    alt                  = if ($cap) { $cap[1] } else { "" }
    caption              = if ($cap) { $cap[2] } else { "" }
    original             = $orig
    exifDateTime         = $ex.dt
    cameraClockIsPacific = ($orig -like "100_*" -and $ex.dt -ne "")
    gps                  = if ($ex.lat -ne $null) { @([math]::Round($ex.lat, 5), [math]::Round($ex.lon, 5)) } else { $null }
  }
}

$json = ConvertTo-Json $rows -Depth 5
# ConvertTo-Json escapes these needlessly; unescape so the file stays readable
$json = $json -replace '\\u0026', '&' -replace '\\u003c', '<' -replace '\\u003e', '>' -replace '\\u0027', "'"
[IO.File]::WriteAllText((Join-Path $web "data\photos.json"), $json, (New-Object Text.UTF8Encoding $false))

Write-Output "wrote data/photos.json - $($rows.Count) photographs"
foreach ($s in $skipped) { Write-Warning "skipped (source missing): $s" }
