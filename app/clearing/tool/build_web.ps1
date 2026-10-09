param([string]$EnvFile = ".env")

if (-not (Test-Path $EnvFile)) { throw "Falta $EnvFile. Copia .env.example a .env." }
$values = @{}
Get-Content $EnvFile | ForEach-Object {
  if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') {
    $values[$matches[1]] = $matches[2].Trim('"''')
  }
}
if (-not $values['MAPBOX_ACCESS_TOKEN']) { throw "Falta MAPBOX_ACCESS_TOKEN en $EnvFile." }
if (-not $values['API_BASE_URL']) { throw "Falta API_BASE_URL en $EnvFile." }

flutter build web `
  --dart-define="MAPBOX_ACCESS_TOKEN=$($values['MAPBOX_ACCESS_TOKEN'])" `
  --dart-define="API_BASE_URL=$($values['API_BASE_URL'])"
