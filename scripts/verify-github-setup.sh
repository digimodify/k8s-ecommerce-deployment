#!/bin/bash

# GitHub Repository Secrets Verification Script
# Helps verify that your GitHub repository is properly configured

set -e

echo "🔍 GitHub Repository Secrets Verification"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}This script helps verify your GitHub repository setup for CI/CD.${NC}"
echo -e "${BLUE}Note: This runs locally and cannot access your GitHub secrets directly.${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Git repository detected${NC}"

# Check remote repository
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "none")
if [[ "$REMOTE_URL" == "none" ]]; then
    echo -e "${YELLOW}⚠️  No remote 'origin' configured${NC}"
    echo "Run: git remote add origin <your-github-repo-url>"
else
    echo -e "${GREEN}✅ Remote repository: $REMOTE_URL${NC}"
fi

# Check if GitHub Actions workflow exists
if [ -f ".github/workflows/deploy.yml" ]; then
    echo -e "${GREEN}✅ Main CI/CD workflow found${NC}"
else
    echo -e "${RED}❌ Main workflow file missing: .github/workflows/deploy.yml${NC}"
fi

# Check if other workflows exist
WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
echo -e "${GREEN}✅ Found $WORKFLOW_COUNT workflow file(s)${NC}"

echo ""
echo -e "${BLUE}📋 Required GitHub Secrets Setup:${NC}"
echo ""

# Required secrets checklist
echo "Navigate to your GitHub repository:"
echo "Settings → Secrets and variables → Actions"
echo ""
echo "🔴 CRITICAL (Required for pipeline to work):"
echo "  1. DOCKER_HUB_USERNAME"
echo "     └─ Your Docker Hub username"
echo "  2. DOCKER_HUB_ACCESS_TOKEN"
echo "     └─ Docker Hub access token (not password!)"
echo ""
echo "🟡 OPTIONAL (Pipeline works without these):"
echo "  3. KUBE_CONFIG_DATA"
echo "     └─ Base64 encoded kubeconfig for real deployment"
echo "  4. SLACK_WEBHOOK_URL"
echo "     └─ Slack webhook for notifications"
echo ""

echo -e "${YELLOW}🧪 Testing Local Docker Setup:${NC}"

# Test Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker is installed${NC}"
    
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker daemon is running${NC}"
        
        # Test if user can run docker commands
        if docker ps >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker permissions are correct${NC}"
        else
            echo -e "${YELLOW}⚠️  Docker requires sudo - consider adding user to docker group${NC}"
        fi
        
        # Check if user is logged into Docker Hub
        if docker info 2>/dev/null | grep -q "Username:"; then
            USERNAME=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
            echo -e "${GREEN}✅ Logged into Docker Hub as: $USERNAME${NC}"
            echo "This username should match your DOCKER_HUB_USERNAME secret"
        else
            echo -e "${YELLOW}⚠️  Not logged into Docker Hub locally${NC}"
            echo "Run: docker login"
        fi
    else
        echo -e "${RED}❌ Docker daemon not running${NC}"
        echo "Start Docker service first"
    fi
else
    echo -e "${RED}❌ Docker not installed${NC}"
fi

echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo ""
echo "1. 📖 Read: .github/docs/SECRETS-SETUP-GUIDE.md"
echo "2. 🐳 Set up Docker Hub secrets (minimum required)"
echo "3. 📤 Push changes to trigger workflow"
echo "4. 👀 Monitor Actions tab for results"
echo "5. 🎉 Celebrate your working CI/CD pipeline!"
echo ""

echo -e "${GREEN}🔗 Quick Links:${NC}"
if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    echo "• Repository: https://github.com/$REPO_OWNER/$REPO_NAME"
    echo "• Actions: https://github.com/$REPO_OWNER/$REPO_NAME/actions"
    echo "• Secrets: https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions"
    echo "• Docker Hub: https://hub.docker.com/repositories"
fi

echo ""
echo -e "${GREEN}✨ Setup verification complete!${NC}"
