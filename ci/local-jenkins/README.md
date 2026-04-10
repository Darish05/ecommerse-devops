# Local Jenkins for fully local automation

This setup runs Jenkins on your machine and executes the repository `Jenkinsfile`.

## Pipeline scope

- GitHub is used for versioning/source control.
- Jenkins is used for CI/CD orchestration.
- Runtime is local by default: Kubernetes or Docker Compose.
- Terraform + Ansible stages are included for IaC/orchestration objectives.
- AWS provisioning is optional and controlled by pipeline parameters.

## Start

```bash
make local-jenkins-up
```

Jenkins UI: `http://localhost:8081`

## Create pipeline job

1. Create a Pipeline job named `e-commerce`.
2. Set **Pipeline script from SCM**.
3. SCM: Git.
4. Repository URL: local path to this repo or your local Git remote.
5. Script path: `Jenkinsfile`.

Recommended build parameters:

- `LOCAL_RUNTIME=kubernetes` (or `docker-compose`)
- `ENABLE_IAC=true`
- `IAC_MODE=validate-only` (safe local mode) or `provision-aws`
- `TF_ACTION=plan` (or `apply`, `destroy` when using `provision-aws`)
- `RUN_ANSIBLE_BOOTSTRAP=true`
- `DEPLOY_APP=true`
- `DEPLOY_MONITORING=true`
- `RUN_SELF_HEAL_TEST=true` (Kubernetes only)

## Objective-friendly run profiles

1. Local-only full demo (recommended):
	- `IAC_MODE=validate-only`
	- validates Terraform, runs Ansible in check mode, deploys app locally

2. IaC provisioning demo:
	- `IAC_MODE=provision-aws`
	- `TF_ACTION=plan` or `apply`
	- runs Terraform + Ansible provisioning workflow

## Trigger on local push

Enable local push hook automation:

```bash
make enable-local-push-automation
```

Set Jenkins auth env vars in your shell:

- `JENKINS_URL` (optional, default `http://localhost:8081`)
- `JENKINS_USER` (optional, default `admin`)
- `JENKINS_API_TOKEN` (required)
- `JENKINS_JOB_NAME` (optional, default `e-commerce`)

After this, each `git push` triggers the Jenkins job.
