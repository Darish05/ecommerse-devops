pipeline {
  agent any

  triggers {
    pollSCM('H/1 * * * *')
  }

  options {
    timestamps()
    ansiColor('xterm')
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'LOCAL_RUNTIME', choices: ['docker-compose', 'kubernetes'], description: 'Run locally on Docker Compose or Kubernetes (kubectl)')
    booleanParam(name: 'ENABLE_IAC', defaultValue: true, description: 'Run Terraform + Ansible stages for IaC/orchestration objective')
    choice(name: 'IAC_MODE', choices: ['validate-only', 'provision-aws'], description: 'Validate IaC only (local-safe) or provision on AWS')
    choice(name: 'TF_ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action (used when IAC_MODE=provision-aws)')
    booleanParam(name: 'RUN_ANSIBLE_BOOTSTRAP', defaultValue: true, description: 'Run Ansible bootstrap (check mode for validate-only)')
    booleanParam(name: 'DEPLOY_APP', defaultValue: true, description: 'Deploy application services')
    booleanParam(name: 'DEPLOY_MONITORING', defaultValue: true, description: 'Deploy Prometheus + Grafana monitoring stack')
    booleanParam(name: 'RUN_SELF_HEAL_TEST', defaultValue: false, description: 'Delete one pod and verify automatic recovery (Kubernetes only)')
  }

  environment {
    TF_DIR = 'deploy/kubernetes/terraform'
    ANSIBLE_INVENTORY = 'ansible-iac/inventory.ini'
    ANSIBLE_PLAYBOOK = 'ansible-iac/k8s-bootstrap.yml'
    K8S_NS = 'sock-shop'
    K8S_BASE_MANIFEST = 'deploy/kubernetes/complete-demo.yaml'
    K8S_AUTOSCALING_DIR = 'deploy/kubernetes/autoscaling'
    K8S_POLICY_DIR = 'deploy/kubernetes/manifests-policy'
    K8S_MONITORING_DIR = 'deploy/kubernetes/manifests-monitoring'
    K8S_ALERTING_DIR = 'deploy/kubernetes/manifests-alerting'
    MONITORING_NS = 'monitoring'
    COMPOSE_BASE_FILE = 'deploy/docker-compose/docker-compose.yml'
    COMPOSE_MONITORING_FILE = 'deploy/docker-compose/docker-compose.monitoring.yml'
  }

  stages {
    stage('Preflight') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail

          if [ "${ENABLE_IAC}" = "true" ]; then
            command -v terraform >/dev/null 2>&1 || { echo "Missing required command: terraform"; exit 1; }
            command -v ansible-playbook >/dev/null 2>&1 || { echo "Missing required command: ansible-playbook"; exit 1; }
            test -f "$ANSIBLE_INVENTORY"
            test -f "$ANSIBLE_PLAYBOOK"
            test -d "$TF_DIR"
          fi

          if [ "${LOCAL_RUNTIME}" = "kubernetes" ]; then
            command -v kubectl >/dev/null 2>&1 || { echo "Missing required command: kubectl"; exit 1; }
            test -f "$K8S_BASE_MANIFEST"
          else
            command -v docker >/dev/null 2>&1 || { echo "Missing required command: docker"; exit 1; }
            if docker compose version >/dev/null 2>&1; then
              true
            elif command -v docker-compose >/dev/null 2>&1; then
              true
            else
              echo "Missing required command: docker compose or docker-compose"
              exit 1
            fi
            test -f "$COMPOSE_BASE_FILE"
          fi
        '''
      }

      }

      stage('IaC: Terraform Init + Validate') {
      when {
        expression { params.ENABLE_IAC }
      }
      steps {
        dir(env.TF_DIR) {
          sh '''#!/usr/bin/env bash
            set -euo pipefail
            terraform init -input=false
            terraform validate
          '''
        }
      }
    }

    stage('IaC: Terraform Plan/Apply/Destroy') {
      when {
        allOf {
          expression { params.ENABLE_IAC }
          expression { params.IAC_MODE == 'provision-aws' }
        }
      }
      steps {
        dir(env.TF_DIR) {
          sh '''#!/usr/bin/env bash
            set -euo pipefail

            case "${TF_ACTION}" in
              plan)
                terraform plan -input=false -out=tfplan
                ;;
              apply)
                terraform plan -input=false -out=tfplan
                terraform apply -input=false -auto-approve tfplan
                ;;
              destroy)
                terraform destroy -input=false -auto-approve
                ;;
              *)
                echo "Unsupported TF_ACTION=${TF_ACTION}" >&2
                exit 1
                ;;
            esac
          '''
        }
      }
    }

    stage('IaC: Ansible Bootstrap') {
      when {
        anyOf {
          expression { params.RUN_ANSIBLE_ONLY }
          allOf {
            expression { params.ENABLE_IAC }
            expression { params.RUN_ANSIBLE_BOOTSTRAP }
            anyOf {
              expression { params.IAC_MODE == 'validate-only' }
              expression { params.TF_ACTION == 'apply' }
            }
          }
        }
      }
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail

          if [ "${RUN_ANSIBLE_ONLY}" = "true" ]; then
            ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_PLAYBOOK" -e bootstrap_become=true
            exit 0
          fi

          if [ "${IAC_MODE}" = "validate-only" ]; then
            ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_PLAYBOOK" --check -e bootstrap_become=false
          else
            ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_PLAYBOOK"
          fi
        '''
      }
    }

    stage('CI: Manifest/Compose Validation') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          if [ "${LOCAL_RUNTIME}" = "kubernetes" ]; then
            test -s "$K8S_BASE_MANIFEST"
            grep -q '^apiVersion:' "$K8S_BASE_MANIFEST"
            grep -q '^kind:' "$K8S_BASE_MANIFEST"
          else
            if docker compose version >/dev/null 2>&1; then
              COMPOSE="docker compose"
            else
              COMPOSE="docker-compose"
            fi
            $COMPOSE -f "$COMPOSE_BASE_FILE" config -q
          fi
        '''
      }
    }

    stage('Deploy Application') {
      when {
        expression { params.DEPLOY_APP }
      }
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          if [ "${LOCAL_RUNTIME}" = "kubernetes" ]; then
            if [ -n "${KUBECONFIG:-}" ] && [ -f "${KUBECONFIG}" ]; then
              mkdir -p .ci-kube
              cp "${KUBECONFIG}" .ci-kube/config
              sed -i 's#https://127.0.0.1:#https://host.docker.internal:#g' .ci-kube/config || true
              sed -i 's#https://localhost:#https://host.docker.internal:#g' .ci-kube/config || true
              export KUBECONFIG="$PWD/.ci-kube/config"
            fi

            if ! kubectl version --request-timeout=5s >/dev/null 2>&1; then
              echo "Kubernetes API not reachable from Jenkins. Skipping Deploy Application stage."
              exit 0
            fi

            kubectl apply -f "$K8S_BASE_MANIFEST"
            if [ -d "$K8S_AUTOSCALING_DIR" ]; then
              kubectl apply -f "$K8S_AUTOSCALING_DIR"
            fi
            if [ -d "$K8S_POLICY_DIR" ]; then
              kubectl apply -f "$K8S_POLICY_DIR"
            fi

            kubectl rollout status deployment/front-end -n "$K8S_NS" --timeout=300s
            kubectl rollout status deployment/catalogue -n "$K8S_NS" --timeout=300s
            kubectl rollout status deployment/carts -n "$K8S_NS" --timeout=300s
          else
            if docker compose version >/dev/null 2>&1; then
              COMPOSE="docker compose"
            else
              COMPOSE="docker-compose"
            fi
            $COMPOSE -f "$COMPOSE_BASE_FILE" up -d
            $COMPOSE -f "$COMPOSE_BASE_FILE" ps
          fi
        '''
      }
    }

    stage('Deploy Prometheus + Grafana') {
      when {
        expression { params.DEPLOY_MONITORING }
      }
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          if [ "${LOCAL_RUNTIME}" = "kubernetes" ]; then
            if [ -n "${KUBECONFIG:-}" ] && [ -f "${KUBECONFIG}" ]; then
              mkdir -p .ci-kube
              cp "${KUBECONFIG}" .ci-kube/config
              sed -i 's#https://127.0.0.1:#https://host.docker.internal:#g' .ci-kube/config || true
              sed -i 's#https://localhost:#https://host.docker.internal:#g' .ci-kube/config || true
              export KUBECONFIG="$PWD/.ci-kube/config"
            fi

            if ! kubectl version --request-timeout=5s >/dev/null 2>&1; then
              echo "Kubernetes API not reachable from Jenkins. Skipping Deploy Prometheus + Grafana stage."
              exit 0
            fi

            if [ -d "$K8S_MONITORING_DIR" ]; then
              kubectl apply -f "$K8S_MONITORING_DIR"
            fi
            if [ -d "$K8S_ALERTING_DIR" ]; then
              kubectl apply -f "$K8S_ALERTING_DIR"
            fi

            kubectl rollout status deployment/prometheus-deployment -n "$MONITORING_NS" --timeout=300s || true
            kubectl rollout status deployment/grafana-core -n "$MONITORING_NS" --timeout=300s || true
            kubectl get svc -n "$MONITORING_NS" | grep -E 'grafana|prometheus' || true
          else
            if docker compose version >/dev/null 2>&1; then
              COMPOSE="docker compose"
            else
              COMPOSE="docker-compose"
            fi

            # Start core monitoring services only (skip node-exporter by default).
            # On some hosts (Windows / Docker Desktop) mounting host root for node-exporter
            # fails with "not a shared or slave mount". To keep the pipeline portable,
            # start Prometheus, Alertmanager, Grafana and the importer only.
            echo "Starting monitoring (prometheus, alertmanager, grafana, importer) — node-exporter skipped"
            $COMPOSE -f "$COMPOSE_BASE_FILE" -f "$COMPOSE_MONITORING_FILE" up -d prometheus alertmanager grafana importer || true

            $COMPOSE -f "$COMPOSE_BASE_FILE" -f "$COMPOSE_MONITORING_FILE" ps
          fi
        '''
      }
    }

    stage('Self-Healing Validation') {
      when {
        allOf {
          expression { params.RUN_SELF_HEAL_TEST }
          expression { params.DEPLOY_APP }
          expression { params.LOCAL_RUNTIME == 'kubernetes' }
        }
      }
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail

          if [ -n "${KUBECONFIG:-}" ] && [ -f "${KUBECONFIG}" ]; then
            mkdir -p .ci-kube
            cp "${KUBECONFIG}" .ci-kube/config
            sed -i 's#https://127.0.0.1:#https://host.docker.internal:#g' .ci-kube/config || true
            sed -i 's#https://localhost:#https://host.docker.internal:#g' .ci-kube/config || true
            export KUBECONFIG="$PWD/.ci-kube/config"
          fi

          if ! kubectl version --request-timeout=5s >/dev/null 2>&1; then
            echo "Kubernetes API not reachable from Jenkins. Skipping Self-Healing Validation stage."
            exit 0
          fi

          POD_NAME="$(kubectl get pods -n "$K8S_NS" -l name=front-end -o jsonpath='{.items[0].metadata.name}')"
          test -n "$POD_NAME"

          echo "Deleting pod $POD_NAME to verify self-healing"
          kubectl delete pod "$POD_NAME" -n "$K8S_NS"

          kubectl rollout status deployment/front-end -n "$K8S_NS" --timeout=300s
          kubectl get pods -n "$K8S_NS" -l name=front-end
        '''
      }
    }
  }

  post {
    always {
      sh '''#!/usr/bin/env bash
        set +e
        if [ "${LOCAL_RUNTIME}" = "kubernetes" ]; then
          kubectl get pods -n "$K8S_NS" 2>/dev/null || true
        else
          if docker compose version >/dev/null 2>&1; then
            COMPOSE="docker compose"
          else
            COMPOSE="docker-compose"
          fi
          $COMPOSE -f "$COMPOSE_BASE_FILE" ps 2>/dev/null || true
        fi
      '''
      archiveArtifacts artifacts: 'deploy/kubernetes/terraform/tfplan', allowEmptyArchive: true
    }
  }
}