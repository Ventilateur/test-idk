#!/bin/bash

# Chaos Testing Script for Chaotic Backend
# This script performs various chaos experiments to test resilience

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found. Please install kubectl.${NC}"
    exit 1
fi

# Check if connected to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Not connected to Kubernetes cluster.${NC}"
    echo "Run: aws eks update-kubeconfig --region <region> --name <cluster-name>"
    exit 1
fi

echo -e "${BLUE}=== Chaos Testing for Chaotic Backend ===${NC}"
echo ""

# Test counter
PASSED=0
FAILED=0

# Wait for pods to be ready
wait_for_ready() {
    local timeout=${1:-60}
    local count=0
    
    echo -n "Waiting for pods to be ready... "
    while [ $count -lt $timeout ]; do
        ready=$(kubectl get pods -l app.kubernetes.io/name=chaotic-backend \
            -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' \
            2>/dev/null | grep -o "True" | wc -l || echo "0")
        total=$(kubectl get pods -l app.kubernetes.io/name=chaotic-backend \
            -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | wc -w || echo "0")
        
        if [ "$ready" = "$total" ] && [ "$total" -gt 0 ]; then
            echo -e "${GREEN}✓${NC}"
            return 0
        fi
        sleep 2
        ((count+=2))
    done
    echo -e "${RED}✗ Timeout${NC}"
    return 1
}

# Get initial pod count
get_pod_count() {
    kubectl get pods -l app.kubernetes.io/name=chaotic-backend \
        -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | wc -w || echo "0"
}

# Test 1: Pod Deletion
test_pod_deletion() {
    echo -e "${YELLOW}Test 1: Pod Deletion${NC}"
    
    initial_count=$(get_pod_count)
    echo "  Initial pod count: ${initial_count}"
    
    if [ "$initial_count" -eq 0 ]; then
        echo -e "  ${RED}✗ No pods found${NC}"
        ((FAILED++))
        return 1
    fi
    
    # Get first pod
    pod=$(kubectl get pods -l app.kubernetes.io/name=chaotic-backend \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod" ]; then
        echo -e "  ${RED}✗ Could not find pod${NC}"
        ((FAILED++))
        return 1
    fi
    
    echo "  Deleting pod: ${pod}"
    kubectl delete pod "$pod" --grace-period=0 --force 2>/dev/null || true
    
    sleep 5
    
    # Wait for recovery
    if wait_for_ready 120; then
        new_count=$(get_pod_count)
        echo "  New pod count: ${new_count}"
        
        if [ "$new_count" -ge "$initial_count" ]; then
            echo -e "  ${GREEN}✓ Pod replaced successfully${NC}"
            ((PASSED++))
            return 0
        else
            echo -e "  ${RED}✗ Pod count decreased${NC}"
            ((FAILED++))
            return 1
        fi
    else
        echo -e "  ${RED}✗ Pods did not recover${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test 2: Multiple Pod Deletions
test_multiple_pod_deletions() {
    echo -e "${YELLOW}Test 2: Multiple Pod Deletions${NC}"
    
    initial_count=$(get_pod_count)
    echo "  Initial pod count: ${initial_count}"
    
    if [ "$initial_count" -lt 2 ]; then
        echo -e "  ${YELLOW}⚠ Skipping (need at least 2 pods)${NC}"
        return 0
    fi
    
    # Delete 2 pods
    pods=($(kubectl get pods -l app.kubernetes.io/name=chaotic-backend \
        -o jsonpath='{.items[*].metadata.name}' 2>/dev/null))
    
    echo "  Deleting pods: ${pods[0]}, ${pods[1]}"
    kubectl delete pod "${pods[0]}" "${pods[1]}" --grace-period=0 --force 2>/dev/null || true
    
    sleep 5
    
    # Wait for recovery
    if wait_for_ready 180; then
        new_count=$(get_pod_count)
        echo "  New pod count: ${new_count}"
        
        if [ "$new_count" -ge "$initial_count" ]; then
            echo -e "  ${GREEN}✓ Pods replaced successfully${NC}"
            ((PASSED++))
            return 0
        else
            echo -e "  ${RED}✗ Pod count decreased${NC}"
            ((FAILED++))
            return 1
        fi
    else
        echo -e "  ${RED}✗ Pods did not recover${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test 3: Scale Down and Up
test_scaling() {
    echo -e "${YELLOW}Test 3: Scaling${NC}"
    
    initial_count=$(get_pod_count)
    echo "  Initial pod count: ${initial_count}"
    
    # Scale down
    echo "  Scaling down to 1 replica..."
    kubectl scale deployment chaotic-backend --replicas=1
    
    sleep 10
    
    count=$(get_pod_count)
    echo "  Pod count after scale down: ${count}"
    
    if [ "$count" -eq 1 ]; then
        echo -e "  ${GREEN}✓ Scaled down successfully${NC}"
    else
        echo -e "  ${RED}✗ Scale down failed${NC}"
        ((FAILED++))
        return 1
    fi
    
    # Scale up
    echo "  Scaling up to ${initial_count} replicas..."
    kubectl scale deployment chaotic-backend --replicas=$initial_count
    
    sleep 10
    
    if wait_for_ready 120; then
        new_count=$(get_pod_count)
        echo "  Pod count after scale up: ${new_count}"
        
        if [ "$new_count" -eq "$initial_count" ]; then
            echo -e "  ${GREEN}✓ Scaled up successfully${NC}"
            ((PASSED++))
            return 0
        else
            echo -e "  ${RED}✗ Scale up failed${NC}"
            ((FAILED++))
            return 1
        fi
    else
        echo -e "  ${RED}✗ Pods did not become ready${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test 4: Check HPA
test_hpa() {
    echo -e "${YELLOW}Test 4: Horizontal Pod Autoscaler${NC}"
    
    hpa=$(kubectl get hpa chaotic-backend -o json 2>/dev/null || echo "")
    
    if [ -z "$hpa" ]; then
        echo -e "  ${YELLOW}⚠ HPA not found (may not be enabled)${NC}"
        return 0
    fi
    
    min_replicas=$(echo "$hpa" | jq -r '.spec.minReplicas // .spec.minReplicas')
    max_replicas=$(echo "$hpa" | jq -r '.spec.maxReplicas')
    current_replicas=$(echo "$hpa" | jq -r '.status.currentReplicas // 0')
    
    echo "  Min replicas: ${min_replicas}"
    echo "  Max replicas: ${max_replicas}"
    echo "  Current replicas: ${current_replicas}"
    
    if [ "$current_replicas" -ge "$min_replicas" ] && [ "$current_replicas" -le "$max_replicas" ]; then
        echo -e "  ${GREEN}✓ HPA configured correctly${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ HPA configuration issue${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test 5: Check PDB
test_pdb() {
    echo -e "${YELLOW}Test 5: Pod Disruption Budget${NC}"
    
    pdb=$(kubectl get pdb chaotic-backend -o json 2>/dev/null || echo "")
    
    if [ -z "$pdb" ]; then
        echo -e "  ${YELLOW}⚠ PDB not found (may not be enabled)${NC}"
        return 0
    fi
    
    min_available=$(echo "$pdb" | jq -r '.spec.minAvailable // "N/A"')
    
    echo "  Min available: ${min_available}"
    
    if [ "$min_available" != "N/A" ]; then
        echo -e "  ${GREEN}✓ PDB configured${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ PDB not properly configured${NC}"
        ((FAILED++))
        return 1
    fi
}

# Run all tests
echo "Starting chaos tests..."
echo ""

test_pod_deletion
echo ""

test_multiple_pod_deletions
echo ""

test_scaling
echo ""

test_hpa
echo ""

test_pdb
echo ""

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All chaos tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi

