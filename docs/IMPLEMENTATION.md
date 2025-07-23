# Kubernetes E-Commerce Deployment Challenge

A comprehensive Kubernetes deployment project demonstrating enterprise-grade container orchestration, configuration management, scaling, and monitoring practices.

## 🎯 Project Overview

This project implements a complete e-commerce application deployment on Kubernetes, showcasing:

- **Containerized PHP/Apache web application** with MySQL database
- **Advanced Kubernetes features**: ConfigMaps, Secrets, Health Probes, HPA
- **Production-ready practices**: Rolling updates, rollbacks, scaling strategies
- **Security best practices**: Externalized configuration, secure credential management

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│  Web Tier                    │  Database Tier               │
│  ┌─────────────────────┐    │  ┌─────────────────────┐     │
│  │ Website Deployment  │    │  │ MySQL Deployment    │     │
│  │ - ecom-web:v6       │    │  │ - mysql:5.7         │     │
│  │ - Health Probes     │◄───┼──┤ - PersistentVolume   │     │
│  │ - HPA Enabled       │    │  │ - ConfigMap Init     │     │
│  │ - ConfigMaps/Secrets│    │  │ - Secret Credentials │     │
│  └─────────────────────┘    │  └─────────────────────┘     │
│           │                  │                              │
│  ┌─────────────────────┐    │  ┌─────────────────────┐     │
│  │ Website Service     │    │  │ MySQL Service       │     │
│  │ - LoadBalancer      │    │  │ - ClusterIP         │     │
│  │ - Port 80           │    │  │ - Port 3306         │     │
│  └─────────────────────┘    │  └─────────────────────┘     │
├─────────────────────────────────────────────────────────────┤
│  Configuration Management                                   │
│  ┌─────────────────┐ ┌──────────────────┐ ┌─────────────┐ │
│  │ mysql-credentials│ │ app-config       │ │feature-toggle│ │
│  │ Secret          │ │ ConfigMap        │ │ ConfigMap   │ │
│  │ - DB_HOST       │ │ - APP_ENV        │ │ - DARK_MODE │ │
│  │ - DB_USER       │ │ - FEATURE_FLAGS  │ │             │ │
│  │ - DB_PASSWORD   │ │ - LOG_LEVEL      │ │             │ │
│  └─────────────────┘ └──────────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) or Kubernetes cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured
- [Docker](https://docs.docker.com/get-docker/) for image building

### One-Command Deployment
```bash
git clone https://github.com/your-username/k8s-ecommerce-deployment.git
cd k8s-ecommerce-deployment
make start
```

### Manual Step-by-Step
```bash
# 1. Start Minikube
minikube start

# 2. Build application image
make build

# 3. Deploy all resources
make deploy

# 4. Access application
make port-forward
# Open browser to http://localhost:8080
```

## 📋 Implementation Steps Completed

### ✅ Step 6: Configuration Management (Dark Mode Feature Toggle)
**Objective**: Implement feature toggles using ConfigMaps for runtime configuration management

**Implementation Overview**:
The dark mode feature demonstrates advanced Kubernetes configuration management using ConfigMaps to control application behavior without code changes.

**Architecture**:
- **ConfigMap**: `feature-toggle-config` stores feature toggle states
- **Environment Variable Injection**: Values are injected into pods at runtime
- **Application Logic**: PHP application reads environment variables to enable/disable features
- **CSS Styling**: Conditional dark theme loading based on feature state

**Detailed Implementation**:

1. **ConfigMap Configuration** (`feature-toggle-configmap.yaml`):
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: feature-toggle-config
   data:
     FEATURE_DARK_MODE: "true"
   ```

2. **Application Integration** (`index.php`):
   - Reads `FEATURE_DARK_MODE` environment variable
   - Conditionally applies `dark-mode` CSS class to body element
   - Loads `dark-mode.css` when feature is enabled
   - Shows visual indicator when dark mode is active

3. **Dark Theme Styles** (`css/dark-mode.css`):
   - Complete dark theme implementation covering:
     - Header and navigation elements
     - Background and text colors
     - Form elements and buttons
     - Cards and panels
     - Interactive elements

4. **Deployment Integration** (`website-deployment.yaml`):
   ```yaml
   env:
   - name: FEATURE_DARK_MODE
     valueFrom:
       configMapKeyRef:
         name: feature-toggle-config
         key: FEATURE_DARK_MODE
   ```

**Usage & Management**:

**Enable Dark Mode**:
```bash
kubectl patch configmap feature-toggle-config -p '{"data":{"FEATURE_DARK_MODE":"true"}}'
kubectl rollout restart deployment website-deployment
```

**Disable Dark Mode**:
```bash
kubectl patch configmap feature-toggle-config -p '{"data":{"FEATURE_DARK_MODE":"false"}}'
kubectl rollout restart deployment website-deployment
```

**Automated Commands**:
```bash
make enable-dark-mode   # Enable dark theme
make disable-dark-mode  # Disable dark theme
make toggle-dark-mode   # Toggle current state
```

**Configuration Management Benefits**:
- **Centralized Control**: Feature toggles managed in one location
- **Environment-Specific**: Different environments can have different feature states
- **Runtime Changes**: Features toggled without code deployments
- **Rollback Safety**: Easy to disable features if issues arise
- **Zero Downtime**: Rolling restarts maintain service availability

**Verification Steps**:
1. Access the website after enabling dark mode
2. Look for "Dark Mode Active" indicator in the top-right corner
3. Verify dark background colors throughout the site
4. Confirm light text on dark backgrounds

**Files Modified**:
- `k8s/feature-toggle-configmap.yaml` - Feature toggle configuration
- `learning-app-ecommerce/index.php` - Dark mode logic and conditional loading
- `learning-app-ecommerce/css/dark-mode.css` - Comprehensive dark theme styles
- `k8s/website-deployment.yaml` - Environment variable injection
- `Makefile` - Automation commands for dark mode management

### ✅ Step 7: Application Scaling
**Objective**: Demonstrate manual and automatic scaling capabilities

**Implementation**:
- Manual scaling commands for different traffic levels
- Resource requests/limits for proper scheduling
- Scaling monitoring and status verification

**Key Commands**:
```bash
make scale-up      # Scale to 6 replicas (high traffic)
make scale-normal  # Scale to 2 replicas (normal load)
make scale-down    # Scale to 1 replica (minimal load)
```

### ✅ Step 8: Rolling Updates (Promotional Banner)
**Objective**: Zero-downtime deployments with new features

**Implementation**:
- Built new Docker image (ecom-web:v3) with promotional banner
- Implemented rolling update strategy
- Monitored deployment progress and verified functionality

**Process**:
```bash
# 1. Code changes for promotional banner
# 2. Build new image: docker build -t ecom-web:v3
# 3. Update deployment image reference
# 4. Apply changes: kubectl apply -f website-deployment.yaml
# 5. Monitor: kubectl rollout status deployment/website-deployment
```

### ✅ Step 9: Deployment Rollbacks
**Objective**: Quick recovery from deployment issues

**Implementation**:
- Demonstrated rollback to previous working version
- Verified application functionality after rollback
- Documented rollback procedures

**Key Commands**:
```bash
make rollback  # Rollback to previous deployment version
kubectl rollout history deployment/website-deployment  # View rollout history
```

### ✅ Step 10: Horizontal Pod Autoscaling (HPA)
**Objective**: Automatic scaling based on resource utilization

**Implementation**:
- Enabled metrics-server addon in Minikube
- Configured HPA with 50% CPU threshold (min=2, max=10 pods)
- Load tested to demonstrate scale-up and scale-down behavior

**Configuration**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: website-deployment
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: website-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

**Key Commands**:
```bash
make setup-hpa    # Configure HPA
make check-hpa    # Monitor HPA status
```

### ✅ Step 11: Liveness and Readiness Probes
**Objective**: Application health monitoring and automatic recovery

**Implementation**:
- Created dedicated health check endpoint (`/health.php`)
- Configured comprehensive probes (startup, liveness, readiness)
- Enhanced Docker image with PDO MySQL extensions
- Demonstrated probe failure scenarios and recovery

**Health Check Features**:
- Database connectivity verification
- Feature configuration validation
- Probe-aware response logic (startup vs liveness vs readiness)
- Detailed health status reporting

**Probe Configuration**:
```yaml
startupProbe:
  httpGet:
    path: /health.php
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 6

livenessProbe:
  httpGet:
    path: /health.php
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health.php
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

### ✅ Step 12: ConfigMaps and Secrets
**Objective**: Secure configuration management following best practices

**Implementation**:
- Externalized all database credentials to Kubernetes Secret
- Created comprehensive ConfigMap for application settings
- Updated deployments to use environment variable injection
- Maintained backward compatibility with existing configurations

**Security Benefits**:
- No hardcoded credentials in code or Docker images
- Centralized configuration management
- Easy credential rotation without code changes
- Separation of sensitive vs non-sensitive configuration

**Configuration Structure**:
```yaml
# Secret (sensitive data)
apiVersion: v1
kind: Secret
metadata:
  name: mysql-credentials
stringData:
  DB_HOST: mysql-service
  DB_NAME: ecomdb
  DB_USER: ecomuser
  DB_PASSWORD: ecompassword

# ConfigMap (application settings)
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  FEATURE_DARK_MODE: "true"
  APP_ENV: "production"
  LOG_LEVEL: "info"
```

## 🛠️ Management Commands

The project includes a comprehensive Makefile with commands for all operations:

### Core Operations
```bash
make help              # Show all available commands
make start             # Start Minikube and deploy application
make deploy            # Deploy all Kubernetes resources
make status            # Check deployment status
make clean             # Delete all resources
make logs              # Show application logs
```

### Development & Building
```bash
make build             # Build Docker image with latest code
make port-forward      # Access application locally (http://localhost:8080)
make open              # Open application in browser via Minikube service
```

### Configuration Management
```bash
make view-config       # View current Secrets and ConfigMaps
make test-config       # Test configuration injection and health
make update-feature-toggles # Show feature toggle status
make rollout-config    # Apply configuration changes
```

### Scaling & Performance
```bash
make scale-up          # Scale to 6 replicas (high traffic)
make scale-normal      # Scale to 2 replicas (normal load)
make scale-down        # Scale to 1 replica (minimal load)
make setup-hpa         # Configure Horizontal Pod Autoscaler
make check-hpa         # Monitor HPA status and metrics
```

### Health & Monitoring
```bash
make test-health-probes # Test health probe functionality
make cleanup-load-test  # Clean up load testing resources
```

### Feature Management
```bash
make enable-dark-mode   # Enable dark mode theme
make disable-dark-mode  # Disable dark mode theme
make toggle-dark-mode   # Toggle dark mode state
```

### Deployment Management
```bash
make rollback          # Rollback to previous deployment version
```

## 🏆 Key Achievements

### Enterprise-Grade Features Implemented
- ✅ **Containerization**: Multi-stage Docker builds with optimized images
- ✅ **Service Discovery**: Kubernetes-native service communication
- ✅ **Data Persistence**: PersistentVolumes for database storage
- ✅ **Configuration Management**: Secrets and ConfigMaps for secure config
- ✅ **Health Monitoring**: Comprehensive probe configuration
- ✅ **Auto-scaling**: HPA based on CPU utilization
- ✅ **Zero-downtime Deployments**: Rolling updates with readiness probes
- ✅ **Disaster Recovery**: Quick rollback capabilities
- ✅ **Security**: No hardcoded credentials, environment-based configuration

### Production Readiness Checklist
- ✅ Resource limits and requests configured
- ✅ Health checks implemented (startup, liveness, readiness)
- ✅ Horizontal scaling configured and tested
- ✅ Configuration externalized and secured
- ✅ Logging and monitoring endpoints available
- ✅ Deployment automation with Makefile
- ✅ Documentation and runbooks created

## 🔧 Technical Decisions & Challenges

### Challenge 1: Database Connection in Health Checks
**Problem**: Initial health checks failed due to missing PDO MySQL extensions.

**Solution**: Enhanced Dockerfile to include `pdo pdo_mysql` extensions:
```dockerfile
RUN docker-php-ext-install mysqli pdo pdo_mysql
```

**Learning**: Always ensure application dependencies are properly included in container images.

### Challenge 2: Environment Variable Injection
**Problem**: Multiple ConfigMaps and Secrets needed to be properly injected.

**Solution**: Used combination of `envFrom` and individual `valueFrom` references:
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mysql-credentials
      key: DB_PASSWORD
envFrom:
- configMapRef:
    name: app-config
```

**Learning**: Kubernetes provides flexible options for environment variable injection to handle different scenarios.

### Challenge 3: HPA Load Testing
**Problem**: Generating sufficient CPU load to trigger HPA scaling.

**Solution**: Created multiple load generator pods with CPU-intensive operations:
```bash
kubectl run load-gen-$i --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://website-service; done"
```

**Learning**: HPA requires realistic load patterns and proper resource requests to function effectively.

### Challenge 4: Backward Compatibility
**Problem**: Maintaining existing feature toggle functionality while adding new configuration management.

**Solution**: Implemented layered configuration approach:
- Legacy `feature-toggle-config` ConfigMap maintained
- New `app-config` ConfigMap for additional settings
- Application code supports both methods

**Learning**: Migration strategies should maintain backward compatibility during transition periods.

## 📊 Performance Metrics

### Scaling Behavior Observed
- **Manual Scaling**: 2 → 6 replicas in ~30 seconds
- **HPA Scale-up**: 2 → 7 replicas when CPU > 50%
- **HPA Scale-down**: 7 → 2 replicas when load decreased
- **Health Check Response**: <100ms average response time

### Resource Utilization
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Deployment Timings
- **Rolling Update**: ~2-3 minutes for complete rollout
- **Rollback**: ~1-2 minutes to restore previous version
- **Cold Start**: ~30 seconds for new pod to become ready

## 🔐 Security Considerations

### Implemented Security Measures
1. **No Hardcoded Credentials**: All sensitive data in Kubernetes Secrets
2. **Least Privilege**: Pods run with minimal required permissions
3. **Network Segmentation**: Database only accessible via ClusterIP service
4. **Configuration Validation**: Health checks verify configuration integrity

### Security Best Practices Followed
- Secrets stored as base64 encoded data in etcd
- Environment variable injection at runtime
- Separate concerns (secrets vs configuration)
- No sensitive data in container images or code

## 🚧 Future Enhancements

### Potential Improvements
1. **Monitoring**: Add Prometheus/Grafana for metrics collection
2. **Logging**: Centralized logging with ELK stack
3. **Security**: Implement Pod Security Policies/Standards
4. **Networking**: Add Ingress controller for advanced routing
5. **Storage**: Implement backup strategies for persistent data
6. **CI/CD**: Add GitHub Actions for automated testing and deployment

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **KodeKloud** for the original learning-app-ecommerce application
- **Kubernetes Community** for excellent documentation and examples
- **Docker** for containerization platform
- **Minikube** for local Kubernetes development environment

---

**Built with ❤️ for learning Kubernetes enterprise deployment practices**
