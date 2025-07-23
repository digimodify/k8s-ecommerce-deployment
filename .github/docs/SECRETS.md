# CI/CD Secrets Configuration

This document describes the GitHub repository secrets required for the CI/CD pipeline to function properly.

## 🔑 Required Secrets

### Docker Registry Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `DOCKER_USERNAME` | Docker Hub username | `your-dockerhub-username` |
| `DOCKER_PASSWORD` | Docker Hub password or access token | `dckr_pat_xxxxxxxxxxxxx` |

### Kubernetes Cluster Secrets

| Secret Name | Description | Format |
|-------------|-------------|--------|
| `KUBE_CONFIG` | Base64 encoded kubeconfig file for staging/dev cluster | `base64 encoded ~/.kube/config` |
| `PROD_KUBE_CONFIG` | Base64 encoded kubeconfig file for production cluster | `base64 encoded ~/.kube/config` |

## 🛠️ Setting Up Secrets

### 1. Docker Hub Setup

1. **Create Docker Hub Account**: Visit [hub.docker.com](https://hub.docker.com)
2. **Generate Access Token**:
   - Go to Account Settings → Security
   - Click "New Access Token"
   - Name: `github-actions-ecommerce`
   - Permissions: Read, Write, Delete
3. **Add to GitHub**:
   - Go to your repository → Settings → Secrets and variables → Actions
   - Add `DOCKER_USERNAME` (your Docker Hub username)
   - Add `DOCKER_PASSWORD` (the generated access token)

### 2. Kubernetes Cluster Setup

#### For Development/Staging (KUBE_CONFIG)

```bash
# Option 1: Using Minikube
minikube start
kubectl config view --raw --minify > /tmp/kubeconfig-dev
base64 -w 0 /tmp/kubeconfig-dev

# Option 2: Using cloud provider (example with GKE)
gcloud container clusters get-credentials dev-cluster --zone us-central1-a
kubectl config view --raw --minify > /tmp/kubeconfig-dev
base64 -w 0 /tmp/kubeconfig-dev
```

#### For Production (PROD_KUBE_CONFIG)

```bash
# Configure access to production cluster
kubectl config use-context production-cluster
kubectl config view --raw --minify > /tmp/kubeconfig-prod
base64 -w 0 /tmp/kubeconfig-prod
```

**Add to GitHub Secrets**:
- Copy the base64 output
- Add as `KUBE_CONFIG` (development/staging) or `PROD_KUBE_CONFIG` (production)

## 🔒 Security Best Practices

### Secret Management

1. **Use Access Tokens**: Never use plain passwords for Docker Hub
2. **Least Privilege**: Create kubeconfig with minimal required permissions
3. **Rotation**: Rotate secrets regularly (every 90 days recommended)
4. **Separate Environments**: Use different secrets for dev/staging/prod

### Kubernetes RBAC

Create service accounts with minimal permissions:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-actions-deployer
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: deployer-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: github-actions-deployer
  namespace: default
roleRef:
  kind: Role
  name: deployer-role
  apiGroup: rbac.authorization.k8s.io
```

### Generate Kubeconfig for Service Account

```bash
# Get service account token
SERVICE_ACCOUNT_NAME="github-actions-deployer"
NAMESPACE="default"
SECRET_NAME=$(kubectl get serviceaccount $SERVICE_ACCOUNT_NAME -n $NAMESPACE -o jsonpath='{.secrets[0].name}')
TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 -d)

# Get cluster info
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

# Create kubeconfig
cat > /tmp/kubeconfig-sa << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CLUSTER_CA
    server: $CLUSTER_SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    namespace: $NAMESPACE
    user: $SERVICE_ACCOUNT_NAME
  name: $SERVICE_ACCOUNT_NAME@$CLUSTER_NAME
current-context: $SERVICE_ACCOUNT_NAME@$CLUSTER_NAME
users:
- name: $SERVICE_ACCOUNT_NAME
  user:
    token: $TOKEN
EOF

# Encode for GitHub secret
base64 -w 0 /tmp/kubeconfig-sa
```

## 🧪 Testing Secrets

### Local Testing

```bash
# Test Docker Hub access
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# Test Kubernetes access
echo $KUBE_CONFIG | base64 -d > /tmp/test-kubeconfig
export KUBECONFIG=/tmp/test-kubeconfig
kubectl cluster-info
kubectl get nodes
```

### CI/CD Pipeline Testing

1. **Create a test branch**: `git checkout -b test-ci-cd`
2. **Make a small change**: Update a comment in any file
3. **Push and monitor**: Watch the GitHub Actions workflow
4. **Check logs**: Verify secrets are properly masked in logs

## 🔄 Secret Rotation Process

### Monthly Rotation (Recommended)

1. **Docker Hub Token**:
   ```bash
   # Generate new token in Docker Hub UI
   # Update DOCKER_PASSWORD secret in GitHub
   ```

2. **Kubernetes Access**:
   ```bash
   # Regenerate kubeconfig
   kubectl config view --raw --minify > /tmp/new-kubeconfig
   base64 -w 0 /tmp/new-kubeconfig
   # Update KUBE_CONFIG secret in GitHub
   ```

### Emergency Rotation

If secrets are compromised:

1. **Immediately revoke** the compromised credentials
2. **Generate new credentials** following the setup process
3. **Update GitHub secrets** with new values
4. **Test the pipeline** to ensure functionality

## 📊 Monitoring and Auditing

### GitHub Actions Logs

- Secrets are automatically masked in logs
- Monitor for failed authentication attempts
- Review workflow run history regularly

### Kubernetes Audit Logs

```bash
# Check who deployed what
kubectl get events --sort-by='.lastTimestamp'

# Review deployment history
kubectl rollout history deployment/website-deployment
```

## 🚨 Troubleshooting

### Common Issues

1. **"unauthorized" errors**: Check token permissions and expiration
2. **"cluster unreachable"**: Verify kubeconfig format and cluster endpoint
3. **"namespace not found"**: Ensure service account has access to target namespace

### Debug Commands

```bash
# Test Docker authentication
docker run --rm -it alpine sh -c "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin"

# Test Kubernetes connectivity
kubectl auth can-i get pods --namespace=default
kubectl auth whoami
```

## 📋 Checklist

Before going live with CI/CD:

- [ ] Docker Hub access token created and tested
- [ ] Kubernetes service account created with minimal permissions
- [ ] Kubeconfig generated and base64 encoded
- [ ] All secrets added to GitHub repository
- [ ] Test workflow executed successfully
- [ ] Secrets rotation schedule established
- [ ] Team members trained on secret management

---

**⚠️ Security Note**: Never commit actual secret values to the repository. This documentation should only contain instructions and examples with placeholder values.
