param(
    [string]$ComposeFile = "deploy/docker-compose.yml"
)

# Try docker compose (v2) then fallback to docker-compose
Write-Host "Starting stack using compose file: $ComposeFile"
if (Get-Command "docker" -ErrorAction SilentlyContinue) {
    docker compose -f $ComposeFile up -d
    docker compose -f $ComposeFile ps
    docker compose -f $ComposeFile logs --tail 50 -f
} else {
    Write-Error "Docker not found in PATH. Install Docker Desktop and retry."
}
