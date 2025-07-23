#!/bin/bash

# Helm Chart Management Script for E-Commerce Application
# Provides easy commands for managing Helm deployments across environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CHART_NAME="ecommerce-app"
CHART_VERSION="1.0.0"

# Function to display usage
show_help() {
    echo -e "${BLUE}Helm Chart Management for E-Commerce Application${NC}"
    echo "=================================================="
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  package                   - Package the Helm chart"
    echo "  install [env] [release]   - Install chart (env: dev/prod, release: name)"
    echo "  upgrade [env] [release]   - Upgrade existing release"
    echo "  uninstall [release]       - Uninstall release"
    echo "  status [release]          - Show release status"
    echo "  test [release]            - Run Helm tests"
    echo "  list                      - List all releases"
    echo "  lint                      - Lint the chart"
    echo "  template [env]            - Generate templates for environment"
    echo "  rollback [release] [rev]  - Rollback to previous revision"
    echo ""
    echo "Examples:"
    echo "  $0 install dev my-dev-app"
    echo "  $0 upgrade prod my-prod-app"
    echo "  $0 test my-dev-app"
    echo "  $0 rollback my-prod-app 1"
}

# Function to package chart
package_chart() {
    echo -e "${YELLOW}📦 Packaging Helm chart...${NC}"
    helm package $CHART_NAME
    echo -e "${GREEN}✅ Chart packaged successfully!${NC}"
    ls -la ${CHART_NAME}-${CHART_VERSION}.tgz
}

# Function to install chart
install_chart() {
    local env=${1:-dev}
    local release=${2:-ecommerce-${env}}
    local values_file="values-${env}.yaml"
    
    echo -e "${YELLOW}🚀 Installing chart for ${env} environment...${NC}"
    
    if [[ -f "${CHART_NAME}/${values_file}" ]]; then
        helm install $release ./${CHART_NAME} -f ${CHART_NAME}/${values_file}
    else
        helm install $release ./${CHART_NAME}
    fi
    
    echo -e "${GREEN}✅ Chart installed successfully as '${release}'!${NC}"
    echo ""
    echo "To access the application:"
    echo "kubectl port-forward service/${release} 8080:80"
}

# Function to upgrade chart
upgrade_chart() {
    local env=${1:-dev}
    local release=${2:-ecommerce-${env}}
    local values_file="values-${env}.yaml"
    
    echo -e "${YELLOW}⬆️ Upgrading chart for ${env} environment...${NC}"
    
    if [[ -f "${CHART_NAME}/${values_file}" ]]; then
        helm upgrade $release ./${CHART_NAME} -f ${CHART_NAME}/${values_file}
    else
        helm upgrade $release ./${CHART_NAME}
    fi
    
    echo -e "${GREEN}✅ Chart upgraded successfully!${NC}"
}

# Function to uninstall chart
uninstall_chart() {
    local release=${1}
    
    if [[ -z "$release" ]]; then
        echo -e "${RED}❌ Error: Release name required${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}🗑️ Uninstalling release '${release}'...${NC}"
    helm uninstall $release
    echo -e "${GREEN}✅ Release uninstalled successfully!${NC}"
}

# Function to show status
show_status() {
    local release=${1}
    
    if [[ -z "$release" ]]; then
        echo -e "${RED}❌ Error: Release name required${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}📊 Status for release '${release}':${NC}"
    helm status $release
    
    echo -e "\n${BLUE}📋 Kubernetes Resources:${NC}"
    kubectl get all -l app.kubernetes.io/instance=$release
}

# Function to run tests
run_tests() {
    local release=${1}
    
    if [[ -z "$release" ]]; then
        echo -e "${RED}❌ Error: Release name required${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}🧪 Running tests for release '${release}'...${NC}"
    helm test $release
    echo -e "${GREEN}✅ Tests completed!${NC}"
}

# Function to list releases
list_releases() {
    echo -e "${BLUE}📋 All Helm releases:${NC}"
    helm list
}

# Function to lint chart
lint_chart() {
    echo -e "${YELLOW}🔍 Linting Helm chart...${NC}"
    helm lint $CHART_NAME --strict
    echo -e "${GREEN}✅ Chart linting completed!${NC}"
}

# Function to generate templates
template_chart() {
    local env=${1:-dev}
    local values_file="values-${env}.yaml"
    
    echo -e "${YELLOW}📄 Generating templates for ${env} environment...${NC}"
    
    if [[ -f "${CHART_NAME}/${values_file}" ]]; then
        helm template ${env}-release ./${CHART_NAME} -f ${CHART_NAME}/${values_file}
    else
        helm template ${env}-release ./${CHART_NAME}
    fi
}

# Function to rollback
rollback_chart() {
    local release=${1}
    local revision=${2:-0}
    
    if [[ -z "$release" ]]; then
        echo -e "${RED}❌ Error: Release name required${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}⏪ Rolling back release '${release}' to revision ${revision}...${NC}"
    helm rollback $release $revision
    echo -e "${GREEN}✅ Rollback completed!${NC}"
}

# Main script logic
case "${1}" in
    "package")
        package_chart
        ;;
    "install")
        install_chart "${2}" "${3}"
        ;;
    "upgrade")
        upgrade_chart "${2}" "${3}"
        ;;
    "uninstall")
        uninstall_chart "${2}"
        ;;
    "status")
        show_status "${2}"
        ;;
    "test")
        run_tests "${2}"
        ;;
    "list")
        list_releases
        ;;
    "lint")
        lint_chart
        ;;
    "template")
        template_chart "${2}"
        ;;
    "rollback")
        rollback_chart "${2}" "${3}"
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: ${1}${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
