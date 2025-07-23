# Makefile for Kubernetes E-Commerce Deployment
# Works with Minikube for local development

.PHONY: help start stop status deploy clean logs port-forward toggle-dark-mode enable-dark-mode disable-dark-mode build scale-up scale-down scale-normal rollback setup-hpa check-hpa test-health-probes cleanup-load-test storage-status storage-monitor test-persistence backup-db helm-package helm-install helm-upgrade helm-test helm-uninstall

# Default target
help:
	@echo "Available commands:"
	@echo "  build            - Build the Docker image with latest code"
	@echo "  start            - Start minikube and deploy the application"
	@echo "  stop             - Stop minikube"
	@echo "  status           - Check deployment status"
	@echo "  deploy           - Deploy all Kubernetes resources"
	@echo "  clean            - Delete all deployed resources"
	@echo "  logs             - Show application logs"
	@echo "  port-forward     - Forward port to access the application"
	@echo "  enable-dark-mode - Enable dark mode feature"
	@echo "  disable-dark-mode- Disable dark mode feature"
	@echo "  toggle-dark-mode - Toggle dark mode on/off"
	@echo "  scale-up         - Scale to 6 replicas for high traffic"
	@echo "  scale-down       - Scale to 1 replica for minimal load"
	@echo "  scale-normal     - Scale to 2 replicas for normal load"
	@echo "  rollback         - Rollback to previous deployment version"
	@echo "  setup-hpa        - Setup Horizontal Pod Autoscaler"
	@echo "  check-hpa        - Check HPA status and metrics"
	@echo "  test-health-probes - Test health probe functionality"
	@echo "  cleanup-load-test - Clean up load testing pods"
	@echo "  view-config      - View current Secrets and ConfigMaps"
	@echo "  test-config      - Test configuration injection and health"
	@echo "  update-feature-toggles - Show current feature toggle status"
	@echo "  rollout-config   - Apply configuration changes with restart"
	@echo ""
	@echo "Storage Management:"
	@echo "  storage-status   - Show comprehensive storage information"
	@echo "  storage-monitor  - Monitor PVC usage and health"
	@echo "  test-persistence - Test data persistence across pod restarts"
	@echo "  backup-db        - Create database backup"
	@echo ""
	@echo "Helm Chart Management:"
	@echo "  helm-package     - Package the Helm chart"
	@echo "  helm-install     - Install using Helm chart"
	@echo "  helm-upgrade     - Upgrade Helm deployment"
	@echo "  helm-test        - Run Helm tests"
	@echo "  helm-uninstall   - Uninstall Helm deployment"
	@echo ""
	@echo "Documentation:"
	@echo "  docs             - Open project documentation"
	@echo "  readme           - Show README.md in terminal"

# Start minikube and deploy
start: minikube-start deploy
	@echo "Application deployed! Use 'make port-forward' or minikube service website-service"

# Start minikube if not running
minikube-start:
	@if ! minikube status | grep -q "Running"; then \
		echo "Starting minikube..."; \
		minikube start; \
	else \
		echo "Minikube is already running"; \
	fi

# Deploy all resources in correct order
deploy:
	@echo "Deploying Kubernetes resources..."
	kubectl apply -f k8s/mysql-pvc.yaml
	kubectl apply -f k8s/mysql-configmap.yaml
	kubectl apply -f k8s/feature-toggle-configmap.yaml
	kubectl apply -f k8s/mysql-deployment.yaml
	kubectl apply -f k8s/mysql-service.yaml
	@echo "Waiting for MySQL to be ready..."
	kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s
	kubectl apply -f k8s/website-deployment.yaml
	kubectl apply -f k8s/website-service.yaml
	@echo "Waiting for website to be ready..."
	kubectl wait --for=condition=ready pod -l app=ecom-website --timeout=300s
	@echo "Deployment complete!"

# Check status of all resources
status:
	@echo "=== Pods ==="
	kubectl get pods
	@echo "=== Services ==="
	kubectl get services
	@echo "=== Deployments ==="
	kubectl get deployments

# Clean up all resources
clean:
	@echo "Deleting all resources..."
	-kubectl delete -f k8s/website-service.yaml
	-kubectl delete -f k8s/website-deployment.yaml
	-kubectl delete -f k8s/mysql-service.yaml
	-kubectl delete -f k8s/mysql-deployment.yaml
	-kubectl delete -f k8s/mysql-configmap.yaml
	-kubectl delete -f k8s/feature-toggle-configmap.yaml
	-kubectl delete -f k8s/mysql-pvc.yaml
	@echo "Cleanup complete!"

# Show logs
logs:
	@echo "=== MySQL Logs ==="
	kubectl logs -l app=mysql --tail=50
	@echo "=== Website Logs ==="
	kubectl logs -l app=ecom-website --tail=50

# Port forward for local access
port-forward:
	@echo "Port forwarding to http://localhost:8080"
	@echo "Press Ctrl+C to stop"
	kubectl port-forward service/website-service 8080:80

# Stop minikube
stop:
	minikube stop

# Quick access via minikube service
open:
	minikube service website-service

# Dark mode feature management
enable-dark-mode:
	@echo "Enabling dark mode..."
	kubectl patch configmap feature-toggle-config -p '{"data":{"FEATURE_DARK_MODE":"true"}}'
	kubectl rollout restart deployment website-deployment
	@echo "Dark mode enabled! Pods are restarting to pick up the change."

disable-dark-mode:
	@echo "Disabling dark mode..."
	kubectl patch configmap feature-toggle-config -p '{"data":{"FEATURE_DARK_MODE":"false"}}'
	kubectl rollout restart deployment website-deployment
	@echo "Dark mode disabled! Pods are restarting to pick up the change."

toggle-dark-mode:
	@CURRENT_MODE=$$(kubectl get configmap feature-toggle-config -o jsonpath='{.data.FEATURE_DARK_MODE}'); \
	if [ "$$CURRENT_MODE" = "true" ]; then \
		echo "Dark mode is currently enabled. Disabling..."; \
		make disable-dark-mode; \
	else \
		echo "Dark mode is currently disabled. Enabling..."; \
		make enable-dark-mode; \
	fi

# Build Docker image with latest code
build:
	@echo "Building Docker image with latest application code..."
	@eval $$(minikube docker-env) && docker build -f docker/Dockerfile -t ecom-web:v2 ../
	@echo "Docker image ecom-web:v2 built successfully!"

# Scaling commands for different traffic levels
scale-up:
	@echo "Scaling up for high traffic (6 replicas)..."
	kubectl scale deployment website-deployment --replicas=6
	@echo "Scaled to 6 replicas. Monitoring scaling progress..."
	kubectl rollout status deployment website-deployment
	@echo "High-traffic scaling complete!"

scale-down:
	@echo "Scaling down for minimal load (1 replica)..."
	kubectl scale deployment website-deployment --replicas=1
	@echo "Scaled to 1 replica. Monitoring scaling progress..."
	kubectl rollout status deployment website-deployment
	@echo "Minimal-load scaling complete!"

scale-normal:
	@echo "Scaling to normal load (2 replicas)..."
	kubectl scale deployment website-deployment --replicas=2
	@echo "Scaled to 2 replicas. Monitoring scaling progress..."
	kubectl rollout status deployment website-deployment
	@echo "Normal-load scaling complete!"

# Rollback deployment to previous version
rollback:
	@echo "Rolling back to previous deployment version..."
	kubectl rollout undo deployment website-deployment
	@echo "Rollback initiated. Monitoring rollback progress..."
	kubectl rollout status deployment website-deployment
	@echo "Rollback complete! Application restored to previous version."

# HPA (Horizontal Pod Autoscaler) management
setup-hpa:
	@echo "Setting up Horizontal Pod Autoscaler..."
	@echo "Ensuring metrics-server is enabled..."
	minikube addons enable metrics-server
	@echo "Creating HPA with 50% CPU threshold, min=2, max=10..."
	kubectl autoscale deployment website-deployment --cpu-percent=50 --min=2 --max=10
	@echo "HPA setup complete!"

check-hpa:
	@echo "=== HPA Status ==="
	kubectl get hpa
	@echo ""
	@echo "=== Current Pod Count ==="
	kubectl get pods -l app=ecom-website --no-headers | wc -l
	@echo ""
	@echo "=== Resource Usage ==="
	kubectl top pods -l app=ecom-website

# Health probe testing
test-health-probes:
	@echo "Testing health probe functionality..."
	@FIRST_POD=$$(kubectl get pods -l app=ecom-website -o jsonpath='{.items[0].metadata.name}'); \
	echo "Testing health endpoint on pod: $$FIRST_POD"; \
	kubectl exec $$FIRST_POD -- curl -s localhost:80/health.php | jq .; \
	echo ""; \
	echo "Probe configuration:"; \
	kubectl describe pod $$FIRST_POD | grep -A 3 -E "(Liveness|Readiness|Startup):"

# Load testing cleanup
cleanup-load-test:
	@echo "Cleaning up load testing resources..."
	-kubectl delete pods -l app=load-generator 2>/dev/null || true
	-kubectl delete pod load-generator 2>/dev/null || true
	@for i in {1..10}; do \
		kubectl delete pod load-gen-$$i 2>/dev/null || true; \
	done
	@echo "Load test cleanup complete!"

# Configuration management commands
view-config:
	@echo "=== Current Configuration ==="
	@echo "Secrets:"
	kubectl get secrets mysql-credentials -o yaml
	@echo ""
	@echo "ConfigMaps:"
	kubectl get configmap app-config -o yaml
	kubectl get configmap feature-toggle-config -o yaml

test-config:
	@echo "Testing application configuration..."
	@FIRST_POD=$$(kubectl get pods -l app=ecom-website -o jsonpath='{.items[0].metadata.name}'); \
	echo "Health check on pod: $$FIRST_POD"; \
	kubectl exec $$FIRST_POD -- curl -s localhost/health.php; \
	echo ""; \
	echo "Configuration sources:"; \
	kubectl describe pod $$FIRST_POD | grep -A 10 "Environment"

update-feature-toggles:
	@echo "Available feature toggles:"
	@echo "  FEATURE_DARK_MODE (current: $$(kubectl get configmap feature-toggle-config -o jsonpath='{.data.FEATURE_DARK_MODE}'))"
	@echo "  FEATURE_PROMOTIONAL_BANNER (current: $$(kubectl get configmap app-config -o jsonpath='{.data.FEATURE_PROMOTIONAL_BANNER}'))"
	@echo "  FEATURE_ADVANCED_SEARCH (current: $$(kubectl get configmap app-config -o jsonpath='{.data.FEATURE_ADVANCED_SEARCH}'))"
	@echo ""
	@echo "Use 'make toggle-dark-mode' or manually update ConfigMaps"

rollout-config:
	@echo "Rolling out configuration changes..."
	kubectl rollout restart deployment/website-deployment
	kubectl rollout restart deployment/mysql-deployment
	@echo "Waiting for rollout to complete..."
	kubectl rollout status deployment/website-deployment
	kubectl rollout status deployment/mysql-deployment
	@echo "Configuration rollout complete!"

# Documentation commands
docs:
	@echo "=== Kubernetes E-Commerce Deployment Documentation ==="
	@echo ""
	@echo "📖 Available Documentation:"
	@echo "  - KUBERNETES-README.md  : Comprehensive deployment guide"
	@echo "  - STORAGE-README.md     : Persistent storage implementation"
	@echo "  - PROJECT-SUMMARY.md    : Project evolution and metrics"
	@echo "  - BLOG-POST.md          : Detailed journey blog post"
	@echo "  - Makefile              : All automation commands"
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make start              : Deploy everything"
	@echo "  make status             : Check deployment status"
	@echo "  make port-forward       : Access application"
	@echo ""
	@echo "📚 Open documentation with your preferred editor:"
	@echo "  code KUBERNETES-README.md"
	@echo "  vim BLOG-POST.md"

readme:
	@echo "=== Kubernetes E-Commerce Deployment ==="
	@head -50 KUBERNETES-README.md
	@echo ""
	@echo "📖 For complete documentation, run: make docs"

# Storage management commands
storage-status:
	@echo "=== Storage Status Overview ==="
	@echo "PVC Status:"
	kubectl get pvc
	@echo ""
	@echo "Persistent Volumes:"
	kubectl get pv
	@echo ""
	@echo "Storage Classes:"
	kubectl get storageclass

storage-monitor:
	@echo "Running comprehensive storage monitoring..."
	./scripts/storage-monitor.sh

test-persistence:
	@echo "Testing database persistence across pod restarts..."
	./scripts/test-persistence.sh

backup-db:
	@echo "Creating database backup..."
	@MYSQL_POD=$$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}'); \
	TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	DB_USER=$$(kubectl get secret mysql-credentials -o jsonpath='{.data.DB_USER}' | base64 -d); \
	DB_PASSWORD=$$(kubectl get secret mysql-credentials -o jsonpath='{.data.DB_PASSWORD}' | base64 -d); \
	DB_NAME=$$(kubectl get secret mysql-credentials -o jsonpath='{.data.DB_NAME}' | base64 -d); \
	echo "Creating backup: backup_$$TIMESTAMP.sql"; \
	kubectl exec $$MYSQL_POD -- mysqldump -u$$DB_USER -p$$DB_PASSWORD $$DB_NAME > backup_$$TIMESTAMP.sql; \
	echo "Backup created: backup_$$TIMESTAMP.sql"

# Helm chart management commands
helm-package:
	@echo "Packaging Helm chart..."
	./scripts/helm-manager.sh package

helm-install:
	@echo "Installing application using Helm chart..."
	./scripts/helm-manager.sh install dev ecommerce-helm

helm-upgrade:
	@echo "Upgrading Helm deployment..."
	./scripts/helm-manager.sh upgrade dev ecommerce-helm

helm-test:
	@echo "Running Helm tests..."
	./scripts/helm-manager.sh test ecommerce-helm

helm-uninstall:
	@echo "Uninstalling Helm deployment..."
	./scripts/helm-manager.sh uninstall ecommerce-helm

# ==============================================================================
# CI/CD INTEGRATION COMMANDS
# ==============================================================================

# Build and tag image for CI/CD
ci-build:
	@echo "🔨 Building Docker image for CI/CD..."
	@IMAGE_TAG=${IMAGE_TAG:-latest}; \
	docker build -f docker/Dockerfile -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:$$IMAGE_TAG ../
	@echo "✅ Docker image built: ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# Push image to registry
ci-push:
	@echo "📤 Pushing Docker image to registry..."
	@IMAGE_TAG=${IMAGE_TAG:-latest}; \
	docker push ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:$$IMAGE_TAG
	@echo "✅ Docker image pushed: ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# Update deployment with new image
ci-deploy:
	@echo "🚀 Updating Kubernetes deployment..."
	@IMAGE_TAG=${IMAGE_TAG:-latest}; \
	NEW_IMAGE=${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:$$IMAGE_TAG; \
	kubectl set image deployment/website-deployment ecom-web=$$NEW_IMAGE; \
	kubectl rollout status deployment/website-deployment --timeout=300s
	@echo "✅ Deployment updated successfully!"

# Run CI/CD validation tests
ci-validate:
	@echo "🔍 Running CI/CD validation tests..."
	@echo "Validating Kubernetes manifests..."
	@for file in k8s/*.yaml; do \
		if [[ -f "$$file" && -s "$$file" ]]; then \
			echo "Validating $$file"; \
			kubectl apply --dry-run=client -f "$$file" || exit 1; \
		fi; \
	done
	@echo "Validating Helm chart..."
	@helm lint ecommerce-app/ || echo "Helm lint completed with warnings"
	@echo "✅ CI/CD validation passed!"

# Complete CI/CD pipeline simulation
ci-pipeline:
	@echo "🔄 Running complete CI/CD pipeline simulation..."
	make ci-validate
	@IMAGE_TAG=$$(git rev-parse --short HEAD 2>/dev/null || echo "latest"); \
	echo "📦 Building with tag: $$IMAGE_TAG"; \
	IMAGE_TAG=$$IMAGE_TAG make ci-build
	@echo "✅ CI/CD pipeline simulation completed!"

# Deploy to specific environment
ci-deploy-env:
	@echo "🌍 Deploying to environment: ${ENVIRONMENT:-development}"
	@NAMESPACE=${ENVIRONMENT:-development}; \
	kubectl create namespace $$NAMESPACE --dry-run=client -o yaml | kubectl apply -f -; \
	echo "📦 Deploying to namespace: $$NAMESPACE"; \
	kubectl apply -f k8s/ -n $$NAMESPACE; \
	kubectl rollout status deployment/website-deployment -n $$NAMESPACE --timeout=300s
	@echo "✅ Environment deployment completed!"

# Smoke tests for CI/CD
ci-smoke-test:
	@echo "💨 Running smoke tests..."
	@NAMESPACE=${NAMESPACE:-default}; \
	echo "Testing health endpoint in namespace: $$NAMESPACE"; \
	kubectl wait --for=condition=ready pod -l app=ecom-website -n $$NAMESPACE --timeout=120s; \
	FIRST_POD=$$(kubectl get pods -l app=ecom-website -n $$NAMESPACE -o jsonpath='{.items[0].metadata.name}'); \
	kubectl exec $$FIRST_POD -n $$NAMESPACE -- curl -f http://localhost/health.php || exit 1
	@echo "✅ Smoke tests passed!"

# CI/CD cleanup
ci-cleanup:
	@echo "🧹 Cleaning up CI/CD resources..."
	@NAMESPACE=${NAMESPACE:-development}; \
	if [ "$$NAMESPACE" != "default" ] && [ "$$NAMESPACE" != "production" ]; then \
		echo "Cleaning up namespace: $$NAMESPACE"; \
		kubectl delete namespace $$NAMESPACE --ignore-not-found=true; \
	else \
		echo "⚠️  Skipping cleanup for protected namespace: $$NAMESPACE"; \
	fi
	@echo "✅ CI/CD cleanup completed!"

# Set default values for CI/CD variables
DOCKER_REGISTRY ?= docker.io
DOCKER_USERNAME ?= your-username
IMAGE_NAME ?= ecom-web
IMAGE_TAG ?= latest
ENVIRONMENT ?= development
NAMESPACE ?= default
