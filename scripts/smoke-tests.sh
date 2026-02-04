#!/bin/bash

# Smoke Tests for Chaotic Backend
# This script performs basic health checks and endpoint validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get load balancer DNS from Kubernetes service
if command -v kubectl &> /dev/null; then
    LB_DNS=$(kubectl get svc chaotic-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
fi

# Allow override via environment variable
LB_DNS=${LB_DNS:-${LOAD_BALANCER_DNS:-""}}

if [ -z "$LB_DNS" ]; then
    echo -e "${RED}Error: Load balancer DNS not found.${NC}"
    echo "Please ensure:"
    echo "  1. kubectl is configured and connected to the cluster"
    echo "  2. The chaotic-backend service is deployed"
    echo "  3. Or set LOAD_BALANCER_DNS environment variable"
    exit 1
fi

echo -e "${YELLOW}Running smoke tests against: http://${LB_DNS}${NC}"
echo ""

# Test counter
PASSED=0
FAILED=0

# Test function
test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "Testing ${name}... "
    
    response=$(curl -s -w "\n%{http_code}" -o /tmp/response_body.txt "${url}" || echo "000")
    status_code=$(echo "$response" | tail -n1)
    body=$(cat /tmp/response_body.txt)
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (Status: ${status_code})"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Expected: ${expected_status}, Got: ${status_code})"
        if [ -n "$body" ]; then
            echo "  Response: ${body:0:100}"
        fi
        ((FAILED++))
        return 1
    fi
}

# Test JSON response
test_json_endpoint() {
    local name=$1
    local url=$2
    
    echo -n "Testing ${name} (JSON)... "
    
    response=$(curl -s "${url}" || echo "")
    
    if echo "$response" | jq . > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC} (Valid JSON)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Invalid JSON)"
        echo "  Response: ${response:0:100}"
        ((FAILED++))
        return 1
    fi
}

# Run tests
echo "=== Health Check Tests ==="
test_endpoint "Root endpoint" "http://${LB_DNS}/" 200
test_json_endpoint "Root endpoint JSON" "http://${LB_DNS}/"

test_endpoint "Liveness probe" "http://${LB_DNS}/health/live" 200
test_endpoint "Readiness probe" "http://${LB_DNS}/health/ready" 200

echo ""
echo "=== Functional Tests ==="
test_endpoint "Data probe" "http://${LB_DNS}/probe/data" 200
test_json_endpoint "Data probe JSON" "http://${LB_DNS}/probe/data"

echo ""
echo "=== Response Time Tests ==="
for i in {1..5}; do
    echo -n "Request ${i}... "
    start_time=$(date +%s%N)
    curl -s -o /dev/null "http://${LB_DNS}/"
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    if [ $duration -lt 5000 ]; then
        echo -e "${GREEN}✓${NC} ${duration}ms"
    else
        echo -e "${YELLOW}⚠${NC} ${duration}ms (slow)"
    fi
done

echo ""
echo "=== Summary ==="
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All smoke tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi

