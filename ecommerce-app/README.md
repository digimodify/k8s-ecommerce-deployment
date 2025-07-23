# Helm Chart Documentation

## Overview
This directory contains a comprehensive Helm chart for deploying the e-commerce application on Kubernetes. The chart includes all necessary components for a production-ready deployment.

## Chart Structure
```
ecommerce-app/
├── Chart.yaml                 # Chart metadata and version info
├── values.yaml                # Default configuration values
├── values-dev.yaml            # Development environment overrides
├── values-prod.yaml           # Production environment overrides
└── templates/
    ├── deployment.yaml         # Web application deployment
    ├── mysql-deployment.yaml   # MySQL database deployment
    ├── service.yaml           # Web application service
    ├── mysql-service.yaml     # MySQL service
    ├── mysql-pvc.yaml         # Persistent volume claim for MySQL
    ├── mysql-secret.yaml      # Database credentials secret
    ├── configmap.yaml         # Application and database configuration
    ├── serviceaccount.yaml    # Service account
    ├── hpa.yaml               # Horizontal Pod Autoscaler
    ├── NOTES.txt              # Post-installation instructions
    ├── _helpers.tpl           # Template helper functions
    └── tests/
        └── test-connection.yaml # Connection test pod
```

## Installation

### Prerequisites
- Kubernetes cluster (1.19+)
- Helm 3.0+
- kubectl configured to access your cluster

### Quick Start
```bash
# Package the chart
helm package ecommerce-app

# Install with default values
helm install my-ecommerce ecommerce-app-1.0.0.tgz

# Install for development
helm install my-dev-ecommerce ecommerce-app-1.0.0.tgz -f ecommerce-app/values-dev.yaml

# Install for production
helm install my-prod-ecommerce ecommerce-app-1.0.0.tgz -f ecommerce-app/values-prod.yaml
```

### Using the Management Script
```bash
# Package chart
./scripts/helm-manager.sh package

# Install development environment
./scripts/helm-manager.sh install dev my-dev-app

# Install production environment
./scripts/helm-manager.sh install prod my-prod-app

# Upgrade deployment
./scripts/helm-manager.sh upgrade dev my-dev-app

# Run tests
./scripts/helm-manager.sh test my-dev-app

# Check status
./scripts/helm-manager.sh status my-dev-app
```

## Configuration

### Default Values
The chart comes with sensible defaults suitable for development:
- 2 web application replicas
- 1Gi MySQL storage
- Health probes enabled
- Auto-scaling (2-10 replicas)
- Security contexts configured

### Environment-Specific Values

#### Development (values-dev.yaml)
- 1 replica (no auto-scaling)
- 500Mi MySQL storage
- Debug mode enabled
- Resource limits optimized for development

#### Production (values-prod.yaml)
- 3 replicas minimum
- 10Gi MySQL storage
- Auto-scaling (3-20 replicas)
- Enhanced security settings
- Pod disruption budget

### Key Configuration Parameters

#### Web Application
```yaml
webapp:
  replicaCount: 2
  image:
    repository: ecom-web
    tag: v6
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
  healthProbes:
    enabled: true
```

#### MySQL Database
```yaml
mysql:
  enabled: true
  persistence:
    enabled: true
    size: 1Gi
  auth:
    database: ecomdb
    username: ecomuser
```

#### Auto-scaling
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 50
```

## Features

### Persistent Storage
- MySQL data persists across pod restarts
- Configurable storage size per environment
- Uses standard storage class by default

### Configuration Management
- Database credentials stored in Kubernetes secrets
- Application configuration via ConfigMaps
- Feature toggles for dark mode and other features
- Environment-specific settings

### Health Monitoring
- Startup, liveness, and readiness probes
- Custom health endpoint (/health.php)
- MySQL connectivity checks

### Security
- Non-root containers
- Security contexts configured
- Capability dropping
- Service accounts with minimal permissions

### Auto-scaling
- Horizontal Pod Autoscaler based on CPU usage
- Configurable min/max replicas
- Production-ready scaling policies

## Testing

### Helm Tests
```bash
# Run built-in connectivity test
helm test my-ecommerce

# Manual testing
kubectl port-forward service/my-ecommerce 8080:80
curl http://localhost:8080/health.php
```

### Application Testing
```bash
# Check application health
curl http://localhost:8080/health.php

# Test database connectivity
curl http://localhost:8080/

# Check feature toggles
curl http://localhost:8080/ | grep -i "dark"
```

## Upgrading

### Chart Version Updates
```bash
# Update Chart.yaml version
# Package new version
helm package ecommerce-app

# Upgrade deployment
helm upgrade my-ecommerce ecommerce-app-1.1.0.tgz
```

### Application Updates
```bash
# Update image tag in values.yaml
# Upgrade deployment
helm upgrade my-ecommerce ecommerce-app-1.0.0.tgz --set webapp.image.tag=v7
```

## Rollback

### Automatic Rollback
```bash
# Rollback to previous version
helm rollback my-ecommerce

# Rollback to specific revision
helm rollback my-ecommerce 2
```

### Manual Rollback
```bash
# Check rollout history
kubectl rollout history deployment/my-ecommerce

# Rollback deployment
kubectl rollout undo deployment/my-ecommerce
```

## Troubleshooting

### Common Issues

#### Pod Won't Start
```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/instance=my-ecommerce

# Check pod logs
kubectl logs -l app.kubernetes.io/name=ecommerce-app

# Check events
kubectl describe pod <pod-name>
```

#### Database Connection Issues
```bash
# Check MySQL pod
kubectl get pods -l app.kubernetes.io/component=database

# Check MySQL logs
kubectl logs -l app.kubernetes.io/component=database

# Test database connectivity
kubectl exec -it <mysql-pod> -- mysql -u<username> -p<password> <database>
```

#### Storage Issues
```bash
# Check PVC status
kubectl get pvc

# Check storage class
kubectl get storageclass

# Check persistent volumes
kubectl get pv
```

### Health Checks
```bash
# Check application health
kubectl exec <web-pod> -- curl localhost/health.php

# Check all components
helm status my-ecommerce
kubectl get all -l app.kubernetes.io/instance=my-ecommerce
```

## Monitoring

### Built-in Monitoring
- Application health endpoint
- Kubernetes resource monitoring
- HPA metrics

### External Monitoring
The chart is ready for integration with:
- Prometheus (ServiceMonitor can be enabled)
- Grafana dashboards
- Alertmanager rules

## Security Considerations

### Production Deployment
- Use secrets for all sensitive data
- Enable network policies if supported
- Use pod security policies/standards
- Regular security updates
- Image scanning

### Access Control
- Use RBAC for fine-grained permissions
- Separate service accounts per component
- Limit container capabilities

## Best Practices

### Development
- Use development values file
- Enable debug mode for troubleshooting
- Use smaller resource limits

### Production
- Use production values file
- Enable all security features
- Set appropriate resource limits
- Configure monitoring and alerting
- Regular backups

### CI/CD Integration
- Automate chart linting
- Test deployments in staging
- Use GitOps for deployments
- Version control all configurations

## Support

For issues and questions:
- Check the troubleshooting section
- Review Kubernetes events and logs
- Consult the main project documentation
- Use the helm-manager.sh script for common operations
