Param(
  [string]$SourceDir = "c:\WoW\_retail_\WTF\UI\AddonDev\fr0z3nUI_QuestTracker",
  [string]$OutDir = "c:\WoW\_retail_\WTF\UI\AddonDev\fr0z3nUI_QuestTracker\dist\fr0z3nUI_QuestTracker",
  [switch]$Clean
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

$TocPath = Join-Path $SourceDir 'fr0z3nUI_QuestTracker.toc'
if (-not (Test-Path -LiteralPath $TocPath)) {
  throw "TOC not found: $TocPath"
}

Ensure-Dir $OutDir

if ($Clean) {
  Get-ChildItem -LiteralPath $OutDir -Force | Remove-Item -Recurse -Force
  Ensure-Dir $OutDir
}

# Copy TOC
Copy-Item -LiteralPath $TocPath -Destination (Join-Path $OutDir 'fr0z3nUI_QuestTracker.toc') -Force

# Parse TOC: include only file lines, ignore comments/metadata/blank
$lines = Get-Content -LiteralPath $TocPath
$files = foreach ($line in $lines) {
  $t = $line.Trim()
  if ($t.Length -eq 0) { continue }
  if ($t.StartsWith('#')) { continue }
  if ($t.StartsWith('##')) { continue }
  if ($t.StartsWith(';')) { continue }
  $t
}

foreach ($rel in $files) {
  # TOC paths always use backslashes or forward slashes; normalize.
  $relNorm = $rel -replace '/', '\\'
  $src = Join-Path $SourceDir $relNorm

  if (-not (Test-Path -LiteralPath $src)) {
    throw "Missing file referenced by TOC: $rel (resolved to $src)"
  }

  $dest = Join-Path $OutDir $relNorm
  $destDir = Split-Path -Parent $dest
  Ensure-Dir $destDir

  Copy-Item -LiteralPath $src -Destination $dest -Force
}

Write-Host "Packaged QuestTracker release to: $OutDir" -ForegroundColor Green
