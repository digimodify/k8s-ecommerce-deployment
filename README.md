# Kubernetes E-Commerce Deployment Challenge

A comprehensive Kubernetes deployment project demonstrating enterprise-grade container orchestration, configuration management, scaling, and monitoring practices.

## 🎯 Project Overview

This project implements a complete e-commerce application deployment on Kubernetes, showcasing:

- **Containerized PHP/Apache web application** with MySQL database
- **Advanced Kubernetes features**: ConfigMaps, Secrets, Health Probes, HPA
- **Production-ready practices**: Rolling updates, rollbacks, scaling strategies
- **Security best practices**: Externalized configuration, secure credential management

## 🏗️ Architecture & Repository Strategy

This project demonstrates **enterprise-grade separation of concerns** between application code and infrastructure code:

### 📂 **Repository Structure**
```
┌─ External App Repository (KodeKloud) ─────────────┐
│  kodekloudhub/learning-app-ecommerce              │
│  ├── index.php                                    │
│  ├── health.php                                   │
│  ├── css/                                         │
│  └── config/                                      │
└────────────────────────────────────────────────────┘
                           ↓ Dynamic Fetch
┌─ This Repository (Infrastructure) ─────────────────┐
│  digimodify/k8s-ecommerce-deployment              │
│  ├── k8s/                 # Kubernetes manifests  │
│  ├── docker/              # Container definitions │
│  ├── .github/workflows/   # CI/CD automation     │
│  └── ecommerce-app/       # Helm charts          │
└────────────────────────────────────────────────────┘
```

### 🔄 **Why This Architecture Matters**

**Professional Benefits:**
- **Clean Separation**: Infrastructure team ≠ Application team responsibilities
- **Latest Code**: CI/CD always builds with current application version
- **Focused Repository**: Each repo has single, clear responsibility
- **Real-world Pattern**: Mirrors how enterprise platform teams operate
- **Minimal Footprint**: No duplicate application code stored

**Dynamic Integration Process:**
1. GitHub Actions triggers on infrastructure changes
2. Automatically fetches latest application code during build
3. Builds container with current app version
4. Deploys with proper versioning and rollback capabilities

This approach demonstrates **production-ready DevOps practices** used by platform engineering teams.

📖 **[Detailed Architecture Documentation →](docs/ARCHITECTURE.md)**

## 🚀 CI/CD Pipeline

This project includes a comprehensive CI/CD pipeline built with GitHub Actions that automates the entire build, test, and deployment process.

### 🔄 **Automated Workflows**

#### **Main CI/CD Pipeline** (`.github/workflows/deploy.yml`)
Triggered on pushes to `main`/`master` branch:
- 🔨 **Build & Test**: Docker image building, security scanning, application testing
- 🔍 **Validation**: Kubernetes manifests and Helm chart validation
- 🚀 **Deployment**: Automated deployment to Kubernetes cluster
- 🧪 **Health Checks**: Post-deployment verification and smoke tests

#### **Pull Request Validation** (`.github/workflows/pr-validation.yml`)
Triggered on pull requests:
- 🔍 **Lint & Validate**: Code quality and syntax checking
- 🔒 **Security Scan**: Secret detection and vulnerability scanning
- 🏗️ **Build Test**: Docker build verification
- 🎯 **K8s Dry Run**: Kubernetes manifest validation

#### **Release Pipeline** (`.github/workflows/release.yml`)
Triggered on version tags (`v*.*.*`):
- 📦 **Release Build**: Multi-architecture Docker images
- 🎯 **Helm Packaging**: Chart versioning and packaging
- 📝 **GitHub Release**: Automated release notes and artifacts
- 🌐 **Production Deployment**: Automated production rollout

### 🔧 **Setup Requirements**

#### **GitHub Repository Secrets**
Configure these secrets in your repository settings:

| Secret | Description | Required For |
|--------|-------------|--------------|
| `DOCKER_USERNAME` | Docker Hub username | Image publishing |
| `DOCKER_PASSWORD` | Docker Hub access token | Image publishing |
| `KUBE_CONFIG` | Base64 encoded kubeconfig (dev/staging) | Development deployments |
| `PROD_KUBE_CONFIG` | Base64 encoded kubeconfig (production) | Production deployments |

📖 **Detailed setup guide**: [`.github/docs/SECRETS.md`](.github/docs/SECRETS.md)

#### **CI/CD Make Commands**
```bash
# CI/CD specific operations
make ci-validate       # Run validation tests locally
make ci-build          # Build Docker image for CI/CD
make ci-pipeline       # Simulate complete CI/CD pipeline
make ci-deploy-env     # Deploy to specific environment
make ci-smoke-test     # Run post-deployment smoke tests
make ci-cleanup        # Clean up CI/CD resources
```

### 📊 **Pipeline Features**

#### **🔒 Security & Quality Gates**
- **Docker Security**: Hadolint static analysis and vulnerability scanning
- **Secret Detection**: TruffleHog integration for sensitive data scanning
- **Code Quality**: PHP syntax validation and YAML linting
- **Kubernetes Security**: Manifest validation and security policy checks

#### **📦 Multi-Environment Support**
- **Development**: Automated deployment for feature branches
- **Staging**: Integration testing and validation environment
- **Production**: Controlled release deployment with approval gates

#### **🔄 Deployment Strategies**
- **Rolling Updates**: Zero-downtime deployments with health checks
- **Rollback Capability**: Automatic rollback on deployment failures
- **Blue-Green Ready**: Infrastructure prepared for blue-green deployments
- **Canary Ready**: Gradual traffic shifting capabilities

### 🎯 **Getting Started with CI/CD**

#### **1. Fork and Configure**
```bash
# Fork the repository
git clone https://github.com/YOUR-USERNAME/k8s-ecommerce-deployment.git
cd k8s-ecommerce-deployment

# Configure secrets (see .github/docs/SECRETS.md)
# Update image references with your Docker Hub username
```

#### **2. First Deployment**
```bash
# Make a change and push to main
echo "# CI/CD Test" >> README.md
git add .
git commit -m "test: trigger CI/CD pipeline"
git push origin main

# Watch the pipeline in GitHub Actions
```

#### **3. Create a Release**
```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# This triggers the release pipeline
```

### 📈 **Pipeline Monitoring**

#### **GitHub Actions Dashboard**
- **Workflow Runs**: Monitor build and deployment status
- **Job Details**: View logs for each pipeline stage
- **Deployment History**: Track successful deployments and rollbacks

#### **Deployment Verification**
```bash
# Check deployment status
kubectl get deployments
kubectl rollout status deployment/website-deployment

# Verify application health
make ci-smoke-test
```

### 🛠️ **Customization**

#### **Environment Variables**
Configure in `.github/config/environments.env`:
- Resource allocations for different environments
- Scaling parameters and HPA settings
- Health check configurations

#### **Pipeline Modifications**
- **Add stages**: Extend workflows for additional testing
- **Custom validators**: Add application-specific checks
- **Notification integrations**: Slack, Teams, or email notifications

---

## 🚀 Quick Start

### Prerequisites
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) or Kubernetes cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured
- [Docker](https://docs.docker.com/get-docker/) for image building
- [GitHub account](https://github.com) for CI/CD pipeline (optional)

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

### CI/CD Deployment (Automated)
```bash
# 1. Fork repository and configure secrets (see CI/CD section above)
# 2. Push changes to main branch - automatic deployment
# 3. Create release tags for production deployment
git tag v1.0.0 && git push origin v1.0.0
```

## 📋 Repository Structure

```
k8s-ecommerce-deployment/
├── README.md                    # This file - Quick start guide and overview
├── Makefile                     # Automation commands (40+ operations)
├── .github/                     # 📁 CI/CD Pipeline configuration
│   ├── workflows/               # GitHub Actions workflows
│   │   ├── deploy.yml           # Main CI/CD pipeline
│   │   ├── pr-validation.yml    # Pull request validation
│   │   └── release.yml          # Release and production deployment
│   ├── scripts/                 # CI/CD automation scripts
│   │   └── security-gates.sh    # Security and quality gate checks
│   ├── config/                  # Environment configurations
│   │   └── environments.env     # Environment-specific settings
│   └── docs/                    # CI/CD documentation
│       └── SECRETS.md           # Repository secrets setup guide
├── docs/                        # 📁 Comprehensive documentation
│   ├── IMPLEMENTATION.md        # Complete technical deployment guide
│   ├── PROJECT-METRICS.md       # Project evolution and performance metrics
│   ├── LEARNING-JOURNEY.md      # Personal transformation story and insights
│   ├── README.md                # Documentation navigation guide
│   └── STORAGE.md               # Persistent storage deep dive
├── docker/
│   └── Dockerfile               # Multi-stage container build
├── ecommerce-app/               # 📁 Helm chart for alternative deployment
│   ├── Chart.yaml               # Helm chart metadata
│   ├── README.md                # Helm-specific documentation
│   ├── values*.yaml             # Environment-specific configurations
│   └── templates/               # Kubernetes resource templates
├── k8s/                         # 📁 Kubernetes manifests
│   ├── mysql-credentials-secret.yaml
│   ├── app-config-configmap.yaml
│   ├── feature-toggle-configmap.yaml
│   ├── mysql-deployment.yaml
│   ├── mysql-service.yaml
│   ├── mysql-pvc.yaml
│   ├── mysql-configmap.yaml
│   ├── website-deployment.yaml
│   ├── website-service.yaml
│   └── load-generator.yaml
├── scripts/
│   ├── db-load-script.sql       # Database initialization
│   ├── helm-manager.sh          # Helm deployment automation
│   ├── storage-monitor.sh       # Storage monitoring tools
│   └── test-persistence.sh      # Persistence verification
├── backups/                     # 📁 Database backups
│   └── backup_20250722_104911.sql
├── releases/                    # 📁 Helm chart releases
│   └── ecommerce-app-1.0.0.tgz
└── learning-app-ecommerce/      # 📁 Source application (submodule)
    ├── index.php                # Enhanced with config management
    ├── health.php               # Kubernetes health endpoint
    ├── css/
    │   ├── dark-mode.css        # Feature toggle styling
    │   └── ...
    └── ...
```

## 🛠️ Key Features Implemented

### ✅ Configuration Management (Step 6)
- Kubernetes ConfigMaps for feature toggles
- Dynamic dark mode theme switching
- Runtime configuration changes

### ✅ Application Scaling (Step 7)
- Manual scaling commands (1-6 replicas)
- Resource optimization with requests/limits
- Traffic-based scaling strategies

### ✅ Rolling Updates (Step 8)
- Zero-downtime feature deployments
- Promotional banner implementation
- Gradual pod replacement strategy

### ✅ Rollback Strategy (Step 9)
- One-command rollback to previous versions
- Quick recovery from deployment issues
- Deployment history management

### ✅ Horizontal Pod Autoscaling (Step 10)
- CPU-based automatic scaling (50% threshold)
- 2-10 replica range with intelligent scaling
- Load testing and scale-up demonstration

### ✅ Health Probes (Step 11)
- Comprehensive health monitoring endpoint
- Startup, liveness, and readiness probes
- Automatic failure detection and recovery

### ✅ Secrets and ConfigMaps (Step 12)
- Secure credential management with Secrets
- Application configuration with ConfigMaps
- Environment variable injection patterns

## 🎮 Management Commands

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

### Documentation
```bash
make docs              # Show documentation overview
make readme            # Quick README display
```

## 📚 Documentation

This repository includes comprehensive documentation organized in the `docs/` directory:

### 📖 **[docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md)**
- **Purpose**: Complete technical deployment guide and architecture reference
- **Content**: Step-by-step implementation details, YAML configurations, troubleshooting
- **Audience**: Developers and DevOps engineers implementing similar solutions
- **Highlights**: Architecture diagrams, best practices, production considerations

### 📊 **[docs/PROJECT-METRICS.md](docs/PROJECT-METRICS.md)**
- **Purpose**: Project evolution timeline, performance metrics, and insights
- **Content**: Implementation phases, resource utilization data, lessons learned
- **Audience**: Stakeholders, project managers, and future maintainers
- **Highlights**: Success metrics, technical challenges overcome, future roadmap

### ✍️ **[docs/LEARNING-JOURNEY.md](docs/LEARNING-JOURNEY.md)**
- **Purpose**: Personal narrative of transformation from LAMP to cloud-native
- **Content**: Learning insights, challenges faced, "aha!" moments, practical advice
- **Audience**: Developers transitioning to cloud-native, blog readers
- **Highlights**: Real-world lessons, mindset shifts, career development insights

### 🗄️ **[docs/STORAGE.md](docs/STORAGE.md)**
- **Purpose**: Deep dive into persistent storage implementation and monitoring
- **Content**: Storage architecture, backup strategies, monitoring scripts
- **Audience**: Operations teams and storage specialists
- **Highlights**: Persistence testing, volume management, disaster recovery

### 📋 **[ecommerce-app/README.md](ecommerce-app/README.md)**
- **Purpose**: Helm chart documentation and alternative deployment method
- **Content**: Chart installation, configuration options, troubleshooting
- **Audience**: Teams preferring Helm over kubectl for deployments
- **Highlights**: Environment-specific configurations, automated management

## 🏗️ Architecture Overview

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
├─────────────────────────────────────────────────────────────┤
│  Configuration Management                                   │
│  ┌─────────────────┐ ┌──────────────────┐ ┌─────────────┐ │
│  │ mysql-credentials│ │ app-config       │ │feature-toggle│ │
│  │ Secret          │ │ ConfigMap        │ │ ConfigMap   │ │
│  └─────────────────┘ └──────────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Success Metrics

### Functional Excellence ✅
- Zero-downtime deployments with rolling updates
- Automatic scaling based on resource utilization
- Self-healing with health probes and automatic restarts
- Secure configuration with Secrets and ConfigMaps
- Operational automation with comprehensive Makefile

### Technical Metrics
- **Deployment Time**: ~2-3 minutes for rolling updates
- **Recovery Time**: ~1-2 minutes for rollbacks
- **Scale-up Time**: ~30 seconds for manual, automatic for HPA
- **Health Check Response**: <100ms average

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🎯 Project Status

**Current Status:** ✅ **Production-Ready CI/CD Pipeline Complete**

### ✅ **Accomplished**
- **Enterprise CI/CD Pipeline**: GitHub Actions with automated testing, building, and deployment
- **Kubernetes Orchestration**: Complete manifests with ConfigMaps, Secrets, HPA, health probes
- **Infrastructure as Code**: Helm charts for multi-environment deployment
- **Security Integration**: Vulnerability scanning, secret detection, quality gates
- **Professional Documentation**: Comprehensive architecture and implementation guides
- **Repository Architecture**: Enterprise-grade separation of concerns between app and infrastructure

### 🚀 **Next Phase: AWS EKS Migration**
**Timeline:** Q4 2025
- Migrate from local/simulated deployment to production AWS EKS cluster
- Implement cloud-native features (ALB, EBS storage, IAM roles)
- Add monitoring and observability stack (Prometheus, Grafana)
- Set up disaster recovery and backup strategies

### 🏆 **Skills Demonstrated**
- **Platform Engineering**: Infrastructure automation and developer productivity
- **DevOps Practices**: CI/CD pipeline design and implementation
- **Kubernetes Expertise**: Container orchestration and configuration management
- **Cloud Readiness**: Architecture designed for cloud migration
- **Professional Development**: Modern tooling and best practices

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **KodeKloud** for the original learning-app-ecommerce application
- **Kubernetes Community** for excellent documentation and examples
- **Docker** for containerization platform
- **Minikube** for local Kubernetes development environment

---

**Built with ❤️ for learning Kubernetes enterprise deployment practices**

**📖 For detailed technical implementation:** [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md)  
**📊 For project metrics and evolution:** [docs/PROJECT-METRICS.md](docs/PROJECT-METRICS.md)  
**✍️ For the complete learning journey:** [docs/LEARNING-JOURNEY.md](docs/LEARNING-JOURNEY.md)

## Setup Instructions

1. **Clone the Repository**
   Clone this repository to your local machine.

   ```bash
   git clone https://github.com/kodekloudhub/learning-app-ecommerce.git
   cd learning-app-ecommerce
   ```

2. **Build and Push Docker Image**
   Navigate to the `docker` directory and build the Docker image for the web application.

   ```bash
   cd docker
   docker build -t yourdockerhubusername/ecom-web:v1 .
   docker push yourdockerhubusername/ecom-web:v1
   ```

3. **Deploy to Kubernetes**
   Apply the Kubernetes configurations to deploy the application and database.

   ```bash
   kubectl apply -f k8s/mysql-configmap.yaml
   kubectl apply -f k8s/mysql-pvc.yaml
   kubectl apply -f k8s/mysql-deployment.yaml
   kubectl apply -f k8s/mysql-service.yaml
   kubectl apply -f k8s/web-deployment.yaml
   kubectl apply -f k8s/web-service.yaml
   ```

## Usage

Once the deployments are up and running, you can access the e-commerce web application through the service exposed by Kubernetes. Use the following command to get the service details:

```bash
kubectl get services
```

## Notes

- Ensure that your Kubernetes cluster is up and running before deploying the application.
- Modify the `db-load-script.sql` as needed to initialize your database with the required data.
- Update the database connection strings in the web application to point to the `mysql-service`.

For further details, refer to the individual YAML files and scripts in the project.# CI/CD Pipeline Status: Ready for GitHub Secrets Setup! 🚀
