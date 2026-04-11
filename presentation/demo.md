# Live Demo Runbook

Prerequisites:

- Docker Desktop (Linux/Windows/Mac)
- At least 4GB free RAM (more recommended for full stack)

Option A — Start full stack (docker-compose)

PowerShell:

```powershell
docker compose -f deploy/docker-compose.yml up -d
docker compose -f deploy/docker-compose.yml ps
docker compose -f deploy/docker-compose.yml logs --tail 50 -f
```

Option B — Start local Jenkins only

```powershell
cd ci/local-jenkins
docker compose up -d
docker compose ps
```

Notes

- If your `docker` client is older, use `docker-compose` instead of `docker compose`.
- To stop the stack:

```powershell
docker compose -f deploy/docker-compose.yml down
```

Troubleshooting

- If containers fail to start, run `docker compose -f <file> logs <service>` to inspect.
- Ensure ports 80/443/9000/9090 are free for the demo components you intend to run.
