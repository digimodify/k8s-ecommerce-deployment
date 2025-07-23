#!/bin/bash

# Security and Quality Gates for CI/CD Pipeline
# This script runs comprehensive security checks and quality gates

echo "🔒 Starting Security and Quality Gate Checks..."

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEMP_DIR="${TEMP_DIR:-/tmp/security-scan}"
mkdir -p "$TEMP_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((CHECKS_WARNING++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((CHECKS_FAILED++))
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        log_warning "Command '$1' not found - some checks will be skipped"
        return 1
    fi
}

# ==============================================================================
# DOCKERFILE SECURITY CHECKS
# ==============================================================================

check_dockerfile_security() {
    log_info "🐳 Checking Dockerfile security..."
    
    local dockerfile="$PROJECT_ROOT/docker/Dockerfile"
    
    if [[ ! -f "$dockerfile" ]]; then
        log_error "Dockerfile not found at $dockerfile"
        return 1
    fi
    
    # Check for root user
    if grep -q "USER root" "$dockerfile"; then
        log_warning "Dockerfile contains explicit root user usage"
    else
        log_success "No explicit root user usage found in Dockerfile"
    fi
    
    # Check for latest tag usage
    if grep -qE "FROM.*:latest|FROM [^:]+$" "$dockerfile"; then
        log_warning "Dockerfile uses 'latest' tag or no tag (defaults to latest)"
    else
        log_success "Dockerfile uses specific version tags"
    fi
    
    # Check for secrets in dockerfile
    if grep -qiE "(password|secret|key|token)" "$dockerfile"; then
        log_error "Potential secrets found in Dockerfile"
    else
        log_success "No obvious secrets found in Dockerfile"
    fi
    
    # Run hadolint if available
    if check_command "hadolint"; then
        log_info "Running hadolint security analysis..."
        if hadolint "$dockerfile" --ignore DL3008 --ignore DL3009 --ignore DL3015; then
            log_success "Hadolint security analysis passed"
        else
            log_warning "Hadolint found issues (see output above)"
        fi
    fi
}

# ==============================================================================
# KUBERNETES MANIFEST SECURITY CHECKS
# ==============================================================================

check_k8s_security() {
    log_info "🎯 Checking Kubernetes manifest security..."
    
    local k8s_dir="$PROJECT_ROOT/k8s"
    
    if [[ ! -d "$k8s_dir" ]]; then
        log_error "Kubernetes manifests directory not found at $k8s_dir"
        return 1
    fi
    
    # Check for hardcoded secrets
    if find "$k8s_dir" -name "*.yaml" -exec grep -l "password.*:" {} \; | head -1 | grep -q .; then
        log_error "Potential hardcoded passwords found in Kubernetes manifests"
    else
        log_success "No hardcoded passwords found in Kubernetes manifests"
    fi
    
    # Check for privileged containers
    if find "$k8s_dir" -name "*.yaml" -exec grep -l "privileged.*true" {} \; | head -1 | grep -q .; then
        log_error "Privileged containers found in Kubernetes manifests"
    else
        log_success "No privileged containers found"
    fi
    
    # Check for resource limits
    local deployments_without_limits=0
    for file in "$k8s_dir"/*.yaml; do
        if grep -q "kind: Deployment" "$file"; then
            if ! grep -q "resources:" "$file"; then
                log_warning "Deployment in $(basename "$file") has no resource limits"
                ((deployments_without_limits++))
            fi
        fi
    done
    
    if [[ $deployments_without_limits -eq 0 ]]; then
        log_success "All deployments have resource limits defined"
    fi
    
    # Check for security contexts
    local pods_without_security_context=0
    for file in "$k8s_dir"/*.yaml; do
        if grep -q "kind: Deployment" "$file"; then
            if ! grep -q "securityContext:" "$file"; then
                log_warning "Deployment in $(basename "$file") has no security context"
                ((pods_without_security_context++))
            fi
        fi
    done
    
    if [[ $pods_without_security_context -eq 0 ]]; then
        log_success "All deployments have security contexts defined"
    fi
}

# ==============================================================================
# SECRET DETECTION
# ==============================================================================

check_secrets() {
    log_info "🔍 Scanning for secrets and sensitive data..."
    
    # Patterns to check for
    local secret_patterns=(
        "password.*=.*[^{]"
        "secret.*=.*[^{]"
        "api[_-]?key.*=.*[^{]"
        "token.*=.*[^{]"
        "auth.*=.*[^{]"
        "[A-Za-z0-9/+]{40,}"  # Base64-like strings
    )
    
    local files_with_secrets=0
    
    for pattern in "${secret_patterns[@]}"; do
        log_info "Checking pattern: $pattern"
        
        if find "$PROJECT_ROOT" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.php" -o -name "*.sh" \) \
           -not -path "*/.*" -not -path "*/node_modules/*" \
           -exec grep -l -iE "$pattern" {} \; | head -1 | grep -q .; then
            log_warning "Potential secrets found matching pattern: $pattern"
            ((files_with_secrets++))
        fi
    done
    
    if [[ $files_with_secrets -eq 0 ]]; then
        log_success "No obvious secrets found in source files"
    fi
    
    # Run trufflehog if available
    if check_command "trufflehog"; then
        log_info "Running TruffleHog secret detection..."
        if trufflehog filesystem "$PROJECT_ROOT" --only-verified 2>/dev/null; then
            log_success "TruffleHog scan completed"
        else
            log_warning "TruffleHog found potential issues"
        fi
    fi
}

# ==============================================================================
# CODE QUALITY CHECKS
# ==============================================================================

check_code_quality() {
    log_info "🧹 Checking code quality..."
    
    # PHP syntax check
    if check_command "php"; then
        log_info "Checking PHP syntax..."
        local php_errors=0
        
        while IFS= read -r -d '' file; do
            if ! php -l "$file" > /dev/null 2>&1; then
                log_error "PHP syntax error in $file"
                ((php_errors++))
            fi
        done < <(find "$PROJECT_ROOT/learning-app-ecommerce" -name "*.php" -print0 2>/dev/null)
        
        if [[ $php_errors -eq 0 ]]; then
            log_success "All PHP files have valid syntax"
        fi
    fi
    
    # YAML validation
    if check_command "python3"; then
        log_info "Validating YAML syntax..."
        local yaml_errors=0
        
        while IFS= read -r -d '' file; do
            if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                log_error "YAML syntax error in $file"
                ((yaml_errors++))
            fi
        done < <(find "$PROJECT_ROOT" -name "*.yaml" -o -name "*.yml" -print0 2>/dev/null)
        
        if [[ $yaml_errors -eq 0 ]]; then
            log_success "All YAML files have valid syntax"
        fi
    fi
}

# ==============================================================================
# DEPENDENCY CHECKS
# ==============================================================================

check_dependencies() {
    log_info "📦 Checking dependencies and vulnerabilities..."
    
    # Check for known vulnerable packages in Dockerfile
    local dockerfile="$PROJECT_ROOT/docker/Dockerfile"
    
    if [[ -f "$dockerfile" ]]; then
        # Check for specific vulnerable packages (example patterns)
        if grep -qE "php:.*-(alpine|slim)" "$dockerfile"; then
            log_success "Using minimal/secure base image"
        else
            log_warning "Consider using alpine or slim base images for security"
        fi
    fi
    
    # Check if we're using specific versions
    if grep -qE "mysql:[0-9]+\.[0-9]+" "$PROJECT_ROOT/k8s/"*.yaml 2>/dev/null; then
        log_success "Using specific MySQL version"
    else
        log_warning "Consider pinning MySQL to specific version"
    fi
}

# ==============================================================================
# CONFIGURATION SECURITY
# ==============================================================================

check_configuration_security() {
    log_info "⚙️ Checking configuration security..."
    
    # Check if secrets are properly configured as Kubernetes secrets
    local secrets_dir="$PROJECT_ROOT/k8s"
    
    if find "$secrets_dir" -name "*secret*.yaml" | grep -q .; then
        log_success "Kubernetes secrets are properly separated"
    else
        log_warning "No Kubernetes secret files found - ensure secrets are externalized"
    fi
    
    # Check for proper secret usage in deployments
    if grep -q "secretKeyRef" "$secrets_dir"/*.yaml 2>/dev/null; then
        log_success "Deployments properly reference Kubernetes secrets"
    else
        log_warning "Deployments should reference secrets via secretKeyRef"
    fi
    
    # Check for ConfigMap usage
    if grep -q "configMapKeyRef\|configMapRef" "$secrets_dir"/*.yaml 2>/dev/null; then
        log_success "Deployments properly use ConfigMaps for configuration"
    else
        log_warning "Consider using ConfigMaps for non-sensitive configuration"
    fi
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    echo "🔒 Security and Quality Gate Analysis"
    echo "====================================="
    echo "Project: Kubernetes E-Commerce Deployment"
    echo "Date: $(date)"
    echo ""
    
    # Run all checks
    check_dockerfile_security
    echo ""
    
    check_k8s_security
    echo ""
    
    check_secrets
    echo ""
    
    check_code_quality
    echo ""
    
    check_dependencies
    echo ""
    
    check_configuration_security
    echo ""
    
    # Summary
    echo "=================================="
    echo "🏁 Security Gate Summary"
    echo "=================================="
    echo -e "${GREEN}Checks Passed: $CHECKS_PASSED${NC}"
    echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
    echo -e "${RED}Checks Failed: $CHECKS_FAILED${NC}"
    echo ""
    
    if [[ $CHECKS_FAILED -gt 0 ]]; then
        echo -e "${RED}❌ Security gate FAILED - $CHECKS_FAILED critical issues found${NC}"
        exit 1
    elif [[ $CHECKS_WARNING -gt 0 ]]; then
        echo -e "${YELLOW}⚠️ Security gate PASSED with warnings - $CHECKS_WARNING warnings found${NC}"
        echo "Consider addressing warnings before production deployment"
        exit 0
    else
        echo -e "${GREEN}✅ Security gate PASSED - All checks successful!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
