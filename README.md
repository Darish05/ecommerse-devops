## Microservices Demo (Sock Shop) - DevOps End-to-End Project

This repository demonstrates a complete DevOps workflow for a microservices e-commerce application, including:

- Application runtime on Docker Compose and Kubernetes
- CI/CD orchestration with Jenkins
- Monitoring with Prometheus + Grafana + Alertmanager
- Infrastructure as Code with Terraform
- Configuration/bootstrap automation with Ansible

---

## 1) Project Architecture (What this project includes)

### Application services

- `front-end`, `edge-router`
- `catalogue`, `catalogue-db`
- `carts`, `carts-db`
- `orders`, `orders-db`
- `payment`, `shipping`, `user`, `user-db`
- `queue-master`, `rabbitmq`

### DevOps tooling

- **Jenkins** pipeline from [Jenkinsfile](Jenkinsfile)
- **Prometheus/Grafana/Alertmanager** via [deploy/docker-compose/docker-compose.monitoring.yml](deploy/docker-compose/docker-compose.monitoring.yml)
- **Kubernetes manifests** in [deploy/kubernetes/](deploy/kubernetes/)
- **Ansible playbooks** in [ansible-iac/](ansible-iac/)
- **Terraform** in [deploy/kubernetes/terraform/](deploy/kubernetes/terraform/)

---

## 2) Prerequisites

Install and verify:

- Docker + Docker daemon running
- Docker Compose (v1 or v2 plugin)
- Git
- (Optional) Minikube + kubectl for Kubernetes runtime
- (Optional) Terraform and Ansible for IaC runs

Quick checks:

```bash
docker --version
docker-compose --version || docker compose version
git --version
kubectl version --client || true
terraform version || true
ansible-playbook --version || true
```

---

## 3) Run from Scratch (Docker Compose + Monitoring)

From repo root:

```bash
cd /home/rhemi/Dar_proj/microservices-demo
```

### 3.1 Clean old state (recommended)

```bash
docker-compose -f deploy/docker-compose/docker-compose.yml -f deploy/docker-compose/docker-compose.monitoring.yml down --remove-orphans
```

If host `8080` is occupied by another app/service, free it first.

### 3.2 Start full stack

```bash
docker-compose -f deploy/docker-compose/docker-compose.yml -f deploy/docker-compose/docker-compose.monitoring.yml up -d
```

### 3.3 Re-import Grafana datasource + dashboards (important)

Sometimes importer starts before Grafana is ready. Re-run importer explicitly:

```bash
docker-compose -f /home/rhemi/Dar_proj/microservices-demo/deploy/docker-compose/docker-compose.yml -f /home/rhemi/Dar_proj/microservices-demo/deploy/docker-compose/docker-compose.monitoring.yml run --rm importer
```

### 3.4 Verify stack status

```bash
docker-compose -f deploy/docker-compose/docker-compose.yml -f deploy/docker-compose/docker-compose.monitoring.yml ps
```

---

## 4) Where to See Outputs (UI + CLI)

### Application output

- App URL: `http://localhost:8080`
- Quick check:

```bash
curl -s http://localhost:8080 | head -n 5
```

### Prometheus output

- URL: `http://localhost:9090`
- Status -> Targets should show service jobs as `UP`
- API readiness:

```bash
curl -s http://localhost:9090/-/ready
```

Useful PromQL examples:

```promql
up
```

```promql
rate(request_duration_seconds_count[5m])
```

```promql
histogram_quantile(0.95, sum(rate(request_duration_seconds_bucket[5m])) by (le, job))
```

### Grafana output

- URL: `http://localhost:3000`
- Login: `admin` / `foobar`
- Dashboards expected:
  - `Sock-Shop Performance`
  - `System Resources`

API checks:

```bash
curl -s -u admin:foobar http://localhost:3000/api/health
curl -s -u admin:foobar http://localhost:3000/api/datasources
curl -s -u admin:foobar http://localhost:3000/api/search?query=
```

### Container logs

```bash
docker logs -f docker-compose_orders_1
docker logs -f docker-compose_carts_1
docker logs -f docker-compose_queue-master_1
docker logs -f docker-compose_shipping_1
```

---

## 5) Jenkins CI/CD (Local)

### 5.1 Start Jenkins

```bash
make local-jenkins-up
```

Jenkins UI: `http://localhost:8081`

### 5.2 Create Pipeline job

Create a Pipeline job (for example `my-app` or `e-commerce`) and configure:

- Pipeline script from SCM
- Repo URL: this repository
- Script path: `Jenkinsfile`

### 5.3 What pipeline does

Pipeline stages in [Jenkinsfile](Jenkinsfile):

- Preflight validation
- Terraform validate / plan/apply/destroy (parameterized)
- Ansible bootstrap (check mode or real apply)
- Compose/K8s validation
- Application deploy
- Monitoring deploy
- Optional self-healing test (K8s)

### 5.4 Trigger from local push (optional)

```bash
make enable-local-push-automation
```

Set env vars before push trigger automation:

- `JENKINS_URL` (default `http://localhost:8081`)
- `JENKINS_USER` (default `admin`)
- `JENKINS_API_TOKEN` (required)
- `JENKINS_JOB_NAME` (default `e-commerce`)

---

## 6) Kubernetes Runtime

### 6.1 Start cluster

```bash
minikube start
kubectl get nodes
```

### 6.2 Deploy app

```bash
kubectl apply -f deploy/kubernetes/complete-demo.yaml
kubectl get pods -n sock-shop
kubectl get svc -n sock-shop
```

### 6.3 Optional self-healing demo

```bash
kubectl get pods -n sock-shop -l name=front-end
kubectl delete pod -n sock-shop <front-end-pod-name>
kubectl get pods -n sock-shop -l name=front-end -w
```

### 6.4 Stop Kubernetes

```bash
minikube stop
```

or delete cluster:

```bash
minikube delete
```

---

## 7) Ansible

### 7.1 Syntax check

```bash
ansible-playbook -i ansible-iac/inventory.ini ansible-iac/k8s-bootstrap.yml --syntax-check
```

### 7.2 Dry run

```bash
ansible-playbook -i ansible-iac/inventory.ini ansible-iac/k8s-bootstrap.yml --check -e bootstrap_become=false
```

---

## 8) Terraform

Terraform directory:

- [deploy/kubernetes/terraform/](deploy/kubernetes/terraform/)

Run:

```bash
cd deploy/kubernetes/terraform
terraform init -input=false
terraform validate
terraform plan -input=false
```

If using Jenkins parameters:

- `IAC_MODE=validate-only` for safe local verification
- `IAC_MODE=provision-aws` + `TF_ACTION=plan|apply|destroy` for cloud workflows

---

## 9) DevOps Process Used in This Project

1. **Code & Config as source of truth**
	- App/runtime config in Compose and Kubernetes manifests
	- IaC in Terraform
	- Ops automation in Ansible
2. **CI/CD orchestration with Jenkins**
	- Preflight checks
	- IaC validation/provisioning gates
	- Runtime deployment stage selection (Compose/K8s)
3. **Observability-first operations**
	- Prometheus for scraping metrics
	- Grafana for visualization
	- Alertmanager for alert routing
4. **Recovery and reliability**
	- Compose/K8s restart mechanics
	- K8s self-healing demonstration path

---

## 10) Common Troubleshooting

### Port 8080 conflict

If edge-router fails to start, check port usage:

```bash
ss -ltnp '( sport = :8080 )'
docker service ls
```

Stop conflicting service/process, then:

```bash
docker-compose -f deploy/docker-compose/docker-compose.yml -f deploy/docker-compose/docker-compose.monitoring.yml down --remove-orphans
docker-compose -f deploy/docker-compose/docker-compose.yml -f deploy/docker-compose/docker-compose.monitoring.yml up -d
```

### Grafana has no dashboards

Re-run importer:

```bash
docker-compose -f /home/rhemi/Dar_proj/microservices-demo/deploy/docker-compose/docker-compose.yml -f /home/rhemi/Dar_proj/microservices-demo/deploy/docker-compose/docker-compose.monitoring.yml run --rm importer
```

### Prometheus UI empty

Verify targets:

```bash
curl -s http://localhost:9090/api/v1/targets
```

---

## 11) Stop Everything

```bash
docker-compose -f deploy/docker-compose/docker-compose.yml -f deploy/docker-compose/docker-compose.monitoring.yml down --remove-orphans
```

---

## 12) Useful Project Paths

- Root pipeline: [Jenkinsfile](Jenkinsfile)
- Compose app: [deploy/docker-compose/docker-compose.yml](deploy/docker-compose/docker-compose.yml)
- Compose monitoring: [deploy/docker-compose/docker-compose.monitoring.yml](deploy/docker-compose/docker-compose.monitoring.yml)
- Grafana import assets: [deploy/docker-compose/grafana/](deploy/docker-compose/grafana/)
- Kubernetes manifests: [deploy/kubernetes/manifests/](deploy/kubernetes/manifests/)
- Kubernetes full manifest: [deploy/kubernetes/complete-demo.yaml](deploy/kubernetes/complete-demo.yaml)
- Terraform: [deploy/kubernetes/terraform/](deploy/kubernetes/terraform/)
- Ansible: [ansible-iac/](ansible-iac/)


