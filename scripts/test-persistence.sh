#!/bin/bash

# Test script for verifying database persistence across pod restarts
# This script validates that data survives pod deletions and recreations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Database Persistence${NC}"
echo "=================================="

# Get MySQL credentials from secret
DB_USER=$(kubectl get secret mysql-credentials -o jsonpath='{.data.DB_USER}' | base64 -d)
DB_PASSWORD=$(kubectl get secret mysql-credentials -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)
DB_NAME=$(kubectl get secret mysql-credentials -o jsonpath='{.data.DB_NAME}' | base64 -d)

# Get current MySQL pod name
MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')

echo -e "${YELLOW}Step 1: Creating test data${NC}"
# Create a test table and insert test data
kubectl exec $MYSQL_POD -- mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "
CREATE TABLE IF NOT EXISTS persistence_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    test_data VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO persistence_test (test_data) VALUES 
('Test data before pod restart'),
('Persistence verification entry'),
('Data integrity test');
"

# Verify table creation
kubectl exec $MYSQL_POD -- mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "SELECT COUNT(*) as 'Test records inserted' FROM persistence_test WHERE test_data LIKE '%Test%';"

echo -e "${GREEN}✅ Test data created${NC}"

echo -e "${YELLOW}Step 2: Recording current data state${NC}"
# Get current record count
BEFORE_COUNT=$(kubectl exec $MYSQL_POD -- mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME -se "SELECT COUNT(*) FROM persistence_test WHERE test_data LIKE '%Test%';")
echo "Records before restart: $BEFORE_COUNT"

echo -e "${YELLOW}Step 3: Deleting MySQL pod to test persistence${NC}"
kubectl delete pod $MYSQL_POD

echo "Waiting for new pod to be ready..."
kubectl wait --for=condition=Ready pod -l app=mysql --timeout=120s

# Get new pod name
NEW_MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')
echo "New MySQL pod: $NEW_MYSQL_POD"

echo -e "${YELLOW}Step 4: Verifying data persistence${NC}"
# Wait a bit for MySQL to fully start
sleep 10

# Check if our test data survived
AFTER_COUNT=$(kubectl exec $NEW_MYSQL_POD -- mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME -se "SELECT COUNT(*) FROM persistence_test WHERE test_data LIKE '%Test%';" 2>/dev/null || echo "0")

echo "Records after restart: $AFTER_COUNT"

if [ "$BEFORE_COUNT" -eq "$AFTER_COUNT" ] && [ "$AFTER_COUNT" -gt "0" ]; then
    echo -e "${GREEN}🎉 SUCCESS: Data persistence verified!${NC}"
    echo -e "${GREEN}   - $AFTER_COUNT test records survived pod restart${NC}"
    
    # Show the actual data
    echo -e "${BLUE}Persistent data:${NC}"
    kubectl exec $NEW_MYSQL_POD -- mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "SELECT * FROM persistence_test WHERE test_data LIKE '%Test%';"
    
    # Clean up test data
    echo -e "${YELLOW}Cleaning up test data...${NC}"
    kubectl exec $NEW_MYSQL_POD -- mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "DELETE FROM persistence_test WHERE test_data LIKE '%Test%';"
    
else
    echo -e "${RED}❌ FAILURE: Data persistence test failed!${NC}"
    echo -e "${RED}   Expected: $BEFORE_COUNT, Got: $AFTER_COUNT${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Persistence test completed successfully!${NC}"
