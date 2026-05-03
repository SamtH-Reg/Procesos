# Aplica supabase_schema.sql al Postgres del proyecto (misma cadena que en Supabase → Settings → Database).
# Requiere psql en PATH (instalable con PostgreSQL o Chocolatey: choco install postgresql).
# Uso:
#   $env:DATABASE_URL = "postgresql://postgres:TU_PASSWORD@db.xxxxx.supabase.co:5432/postgres"
#   .\scripts\apply-supabase-schema.ps1
param(
  [string]$DatabaseUrl = $env:DATABASE_URL
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sql = Join-Path $root "supabase_schema.sql"
if (-not (Test-Path $sql)) {
  Write-Error "No se encuentra supabase_schema.sql en $root"
}
if (-not $DatabaseUrl) {
  Write-Host @"
No hay DATABASE_URL.

Opciones:
  1) Dashboard Supabase → SQL Editor → pega todo supabase_schema.sql → Run
  2) Cursor: configura MCP Supabase (ver .cursor/mcp.json.example) y pide ejecutar el schema al agente
  3) Esta consola: asigna la URI de conexión (modo sesión) y vuelve a ejecutar:
     `$env:DATABASE_URL = 'postgresql://postgres:...@db.<ref>.supabase.co:5432/postgres'`
"@
  exit 1
}
$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
  Write-Error "psql no está en PATH. Instala PostgreSQL client tools o usa el SQL Editor del dashboard."
}
& psql $DatabaseUrl -v ON_ERROR_STOP=1 -f $sql
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Schema aplicado correctamente."
