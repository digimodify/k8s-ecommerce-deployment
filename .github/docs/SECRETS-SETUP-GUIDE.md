# GitHub Secrets Setup Guide

## 🎯 **Required Secrets for Full CI/CD Pipeline**

This guide walks you through setting up all GitHub repository secrets needed for the complete CI/CD pipeline.

## 📋 **Secrets Checklist**

| Priority | Secret Name | Required | Purpose | Setup Status |
|----------|-------------|----------|---------|--------------|
| 🔴 HIGH | `DOCKER_HUB_USERNAME` | Yes | Docker registry auth | ⏳ Pending |
| 🔴 HIGH | `DOCKER_HUB_ACCESS_TOKEN` | Yes | Docker registry auth | ⏳ Pending |
| 🟡 MEDIUM | `KUBE_CONFIG_DATA` | Optional* | K8s cluster access | ⏳ Pending |
| 🟢 LOW | `SLACK_WEBHOOK_URL` | Optional | Notifications | ⏳ Pending |

*Optional for demo purposes - workflow will simulate deployment without it

---

## 🐳 **1. Docker Hub Setup (Required)**

### Step 1: Create Docker Hub Account
```bash
# Visit: https://hub.docker.com
# Sign up or log in to existing account
```

### Step 2: Generate Access Token
1. Go to **Account Settings** → **Security**
2. Click **New Access Token**
3. Name: `k8s-ecommerce-deployment-ci`
4. Permissions: **Read, Write, Delete**
5. **Copy the token** (you won't see it again!)

### Step 3: Add Secrets to GitHub
Navigate to your repository: `Settings` → `Secrets and variables` → `Actions`

Add these secrets:
```
Name: DOCKER_HUB_USERNAME
Value: your-dockerhub-username

Name: DOCKER_HUB_ACCESS_TOKEN  
Value: dckr_pat_xxxxxxxxxxxxxxxxxxxxx
```

---

## ☸️ **2. Kubernetes Cluster Setup (Optional)**

### Option A: Skip for Demo (Recommended)
The workflow is designed to work without real cluster access:
- Validation runs against YAML files
- Deployment is simulated with mock kubeconfig
- All testing happens locally

### Option B: Connect Real Cluster
If you have a Kubernetes cluster (Minikube, cloud provider, etc.):

```bash
# Encode your kubeconfig
cat ~/.kube/config | base64 -w 0

# Add to GitHub secrets:
# Name: KUBE_CONFIG_DATA
# Value: <base64-encoded-kubeconfig>
```

---

## 💬 **3. Slack Notifications (Optional)**

### Setup Slack Webhook
1. Go to your Slack workspace
2. Create a new app: https://api.slack.com/apps
3. Add Incoming Webhooks feature
4. Generate webhook URL
5. Add to GitHub secrets:
   ```
   Name: SLACK_WEBHOOK_URL
   Value: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
   ```

---

## 🧪 **Testing Your Setup**

### After Adding Docker Secrets:
1. Make any commit to trigger workflow
2. Check Actions tab - should see successful Docker build
3. Check Docker Hub - should see new image

### Validation Commands:
```bash
# Test locally with your credentials
docker login
docker build -t test-image .
docker push your-username/test-image
```

---

## 🔧 **Troubleshooting Common Issues**

### Docker Authentication Fails
```
Error: unauthorized: authentication required
```
**Solution**: 
- Verify username is exact (case-sensitive)
- Regenerate access token
- Check token has write permissions

### Kubernetes Connection Issues
```
Error: couldn't get current server API group list
```
**Solution**:
- Verify kubeconfig is valid: `kubectl cluster-info`
- Ensure base64 encoding is correct (no line breaks)
- Check cluster is accessible from GitHub runners

### Workflow Still Failing
**Check these**:
- Secret names match exactly (case-sensitive)
- No extra spaces in secret values
- Repository has Actions enabled
- Branch protection rules allow workflow runs

---

## 🎯 **Minimal Setup for Demo**

**To get the pipeline working immediately:**

1. **Just add Docker Hub secrets** (2 secrets)
2. **Skip Kubernetes and Slack** (workflow handles missing secrets gracefully)
3. **Make a commit** to trigger workflow
4. **Verify Docker image gets built and pushed**

This gives you:
- ✅ Full CI/CD pipeline execution
- ✅ Docker image builds and pushes
- ✅ Kubernetes validation (dry-run)
- ✅ All quality gates and security checks
- ⚠️ Simulated deployment (not real cluster)

---

## 📚 **Next Steps After Setup**

1. **Monitor first successful run** in Actions tab
2. **Verify Docker image** appears in Docker Hub
3. **Test pull request workflow** with a small change
4. **Set up branch protection** rules for main branch
5. **Configure deployment environments** (staging/prod)

## 🆘 **Need Help?**

- Check `.github/docs/CI-CD-SUMMARY.md` for workflow details
- Review `SECRETS.md` for additional configuration options
- Look at workflow logs in Actions tab for specific error messages
