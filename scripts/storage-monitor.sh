#!/bin/bash

# Storage monitoring and management script for the e-commerce application
# Provides insights into storage usage, PVC status, and volume health

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Storage Monitoring Dashboard${NC}"
echo "================================="

# Function to display PVC information
show_pvc_info() {
    echo -e "\n${CYAN}💾 Persistent Volume Claims${NC}"
    echo "----------------------------"
    kubectl get pvc --show-labels
    
    echo -e "\n${PURPLE}📋 PVC Details:${NC}"
    kubectl describe pvc mysql-pvc
}

# Function to show volume usage
show_volume_usage() {
    echo -e "\n${CYAN}📈 Volume Usage${NC}"
    echo "----------------"
    
    # Get MySQL pod name
    MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$MYSQL_POD" ]; then
        echo "MySQL Pod: $MYSQL_POD"
        echo -e "\n${YELLOW}Database Volume Usage:${NC}"
        kubectl exec $MYSQL_POD -- df -h /var/lib/mysql 2>/dev/null || echo "Unable to get volume usage"
        
        echo -e "\n${YELLOW}Database Directory Size:${NC}"
        kubectl exec $MYSQL_POD -- du -sh /var/lib/mysql 2>/dev/null || echo "Unable to get directory size"
        
        echo -e "\n${YELLOW}Database Files:${NC}"
        kubectl exec $MYSQL_POD -- ls -la /var/lib/mysql/ 2>/dev/null | head -10 || echo "Unable to list database files"
    else
        echo -e "${RED}❌ MySQL pod not found${NC}"
    fi
}

# Function to show storage class information
show_storage_classes() {
    echo -e "\n${CYAN}🏗️ Storage Classes${NC}"
    echo "-------------------"
    kubectl get storageclass
    
    echo -e "\n${PURPLE}Default Storage Class Details:${NC}"
    kubectl get storageclass standard -o yaml 2>/dev/null || kubectl get storageclass -o yaml | head -20
}

# Function to show persistent volumes
show_persistent_volumes() {
    echo -e "\n${CYAN}🗄️ Persistent Volumes${NC}"
    echo "----------------------"
    kubectl get pv
    
    # Get the specific PV for our PVC
    PV_NAME=$(kubectl get pvc mysql-pvc -o jsonpath='{.spec.volumeName}' 2>/dev/null || echo "")
    if [ -n "$PV_NAME" ]; then
        echo -e "\n${PURPLE}MySQL PV Details:${NC}"
        kubectl describe pv $PV_NAME
    fi
}

# Function to show pod volume mounts
show_pod_mounts() {
    echo -e "\n${CYAN}🔗 Pod Volume Mounts${NC}"
    echo "---------------------"
    
    MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$MYSQL_POD" ]; then
        echo -e "${YELLOW}MySQL Pod Volume Mounts:${NC}"
        kubectl describe pod $MYSQL_POD | grep -A 10 -B 5 "Mounts:" || echo "No mount information available"
        
        echo -e "\n${YELLOW}Volume Specifications:${NC}"
        kubectl get pod $MYSQL_POD -o yaml | grep -A 20 "volumes:" || echo "No volume specifications available"
    fi
}

# Function to check backup capabilities
show_backup_info() {
    echo -e "\n${CYAN}💾 Backup Considerations${NC}"
    echo "-------------------------"
    echo "Current setup supports the following backup strategies:"
    echo "• Volume snapshots (if supported by storage class)"
    echo "• Database logical backups (mysqldump)"
    echo "• File-level backups of persistent volume"
    echo ""
    echo "Recommended backup frequency:"
    echo "• Daily logical backups for data consistency"
    echo "• Weekly volume snapshots for fast recovery"
    echo "• Monthly full backups for disaster recovery"
}

# Function to provide storage recommendations
show_recommendations() {
    echo -e "\n${CYAN}💡 Storage Optimization Recommendations${NC}"
    echo "----------------------------------------"
    
    # Check current usage
    MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$MYSQL_POD" ]; then
        USAGE=$(kubectl exec $MYSQL_POD -- df /var/lib/mysql | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
        
        if [ "$USAGE" -gt 80 ]; then
            echo -e "${RED}⚠️  HIGH USAGE: Volume is ${USAGE}% full${NC}"
            echo "   Consider expanding the PVC or implementing data archival"
        elif [ "$USAGE" -gt 60 ]; then
            echo -e "${YELLOW}📊 MODERATE USAGE: Volume is ${USAGE}% full${NC}"
            echo "   Monitor growth and plan for expansion"
        else
            echo -e "${GREEN}✅ GOOD: Volume usage is ${USAGE}%${NC}"
        fi
    fi
    
    echo ""
    echo "General recommendations:"
    echo "• Monitor disk usage regularly"
    echo "• Implement automated backups"
    echo "• Consider read replicas for scaling"
    echo "• Use appropriate storage class for performance needs"
    echo "• Plan for data growth and capacity expansion"
}

# Main execution
case "${1:-all}" in
    "pvc")
        show_pvc_info
        ;;
    "usage")
        show_volume_usage
        ;;
    "storage-classes")
        show_storage_classes
        ;;
    "volumes")
        show_persistent_volumes
        ;;
    "mounts")
        show_pod_mounts
        ;;
    "backup")
        show_backup_info
        ;;
    "recommendations")
        show_recommendations
        ;;
    "all"|*)
        show_pvc_info
        show_volume_usage
        show_storage_classes
        show_persistent_volumes
        show_pod_mounts
        show_backup_info
        show_recommendations
        ;;
esac

echo -e "\n${GREEN}📊 Storage monitoring complete!${NC}"
echo ""
echo "Usage: $0 [pvc|usage|storage-classes|volumes|mounts|backup|recommendations|all]"
