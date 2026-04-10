# End-to-End Automation Blueprint (Jenkins + Terraform + Ansible + Kubernetes)

This repository now includes a baseline CI/CD automation flow with:

- Infrastructure as Code via Terraform
- Host bootstrap via Ansible
- Application deployment via Kubernetes manifests
- Continuous delivery and validation via Jenkins
- Self-healing validation by deleting a pod and ensuring automatic recovery
- Monitoring stack deployment (Prometheus + Grafana)

## 1) Before Proceeding (Mandatory Checks)

1. Jenkins agent has: `terraform`, `ansible-playbook`, `kubectl`.
2. Kubernetes access is configured (`kubectl config current-context` is valid).
3. Terraform AWS credentials are available in Jenkins runtime.
4. SSH key pair used by Terraform matches `deploy/kubernetes/terraform/variables.tf`.
5. Ansible inventory contains reachable target hosts in `ansible-iac/inventory.ini`.

## 2) Pipeline Entry Point

- Jenkins pipeline file: [Jenkinsfile](../Jenkinsfile)

### Parameters

- `INFRA_MODE`: `local` or `aws`
- `TF_ACTION`: `plan`, `apply`, or `destroy`
- `DEPLOY_K8S`: deploy manifests after infra steps
- `DEPLOY_MONITORING`: deploy Prometheus + Grafana on Kubernetes
- `RUN_SELF_HEAL_TEST`: remove one front-end pod and verify re-creation

## 3) What the Pipeline Automates

1. **Preflight checks** for required binaries and input files.
2. **Terraform** init/validate/plan/apply/destroy in `deploy/kubernetes/terraform`.
3. **Ansible** bootstrap (`ansible-iac/k8s-bootstrap.yml`) on target hosts.
4. **Kubernetes deployment** of:
   - `deploy/kubernetes/complete-demo.yaml`
   - autoscaling resources in `deploy/kubernetes/autoscaling`
   - policies in `deploy/kubernetes/manifests-policy`
5. **Monitoring deployment** of:
   - `deploy/kubernetes/manifests-monitoring`
   - `deploy/kubernetes/manifests-alerting`
6. **Self-healing verification** by pod deletion + rollout status checks.

## 4) Local Push-Based Automation

This repository includes local automation so that push events from your machine can trigger Jenkins locally.

- Pre-push hook: [.githooks/pre-push](../.githooks/pre-push)
- Hook setup script: [scripts/setup-local-git-automation.sh](../scripts/setup-local-git-automation.sh)
- Jenkins trigger script: [scripts/trigger-local-jenkins.sh](../scripts/trigger-local-jenkins.sh)

### Quick local setup

1. Start local Jenkins: `make local-jenkins-up`
2. Enable hook automation: `make enable-local-push-automation`
3. Set environment variables in your shell:
   - `JENKINS_URL` (default `http://localhost:8081`)
   - `JENKINS_USER` (default `admin`)
   - `JENKINS_API_TOKEN` (required)
   - `JENKINS_JOB_NAME` (default `microservices-demo`)
4. Push from local repo; pre-push hook triggers Jenkins job automatically.

Jenkinsfile also has SCM polling enabled (`H/1 * * * *`) to auto-run when SCM changes are detected.

## 5) Self-Healing Coverage

Self-healing is provided by Kubernetes controllers and probes:

- `Deployment` desired state reconciliation (pod is recreated after failure)
- `livenessProbe` and `readinessProbe` already present in service manifests
- Horizontal Pod Autoscalers in `deploy/kubernetes/autoscaling`

## 6) Local Runtime Helpers

- Start app locally with Docker Compose: `make local-sockshop-up`
- Start monitoring locally with Docker Compose: `make local-monitoring-up`

Grafana will be available at `http://localhost:3000`, Prometheus at `http://localhost:9090`.

## 7) Notes

- Autoscaling manifests were updated to modern deployment API references (`apps/v1` scale target).
- For production, add remote Terraform state backend and state locking.
- For production, move secrets to a secret manager (not plain environment variables).
