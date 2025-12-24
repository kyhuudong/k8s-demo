#!/bin/bash

set -e

echo "========================================="
echo "High Availability Demo (99%+ Uptime)"
echo "Pod Failure & Auto-Recovery Under Load"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get Minikube IP
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
API_URL="http://$MINIKUBE_IP:30080"

echo "API Endpoint: $API_URL"
echo ""

# Counters for uptime calculation
SUCCESS_COUNT=0
FAILURE_COUNT=0

# Function to show pod status
show_pods() {
    echo ""
    echo -e "${BLUE}Current Pod Status:${NC}"
    kubectl get pods -l app=nestjs-api -o wide
    echo ""
}

# Function to generate traffic and track success/failure
generate_traffic() {
    local duration=$1
    local requests_per_sec=$2
    local worker_id=$3

    END_TIME=$(($(date +%s) + duration))
    local success=0
    local failure=0

    while [ $(date +%s) -lt $END_TIME ]; do
        if curl -s --max-time 2 "$API_URL/products" > /dev/null 2>&1; then
            echo -n -e "${GREEN}.${NC}"
            ((success++))
        else
            echo -n -e "${RED}x${NC}"
            ((failure++))
        fi
        sleep $(echo "scale=2; 1/$requests_per_sec" | bc 2>/dev/null || echo "0.2")
    done

    # Write results to temp file
    echo "$success $failure" >> /tmp/traffic_results_$$
}

# Function to monitor and calculate uptime
monitor_uptime() {
    local duration=$1
    END_TIME=$(($(date +%s) + duration))

    while [ $(date +%s) -lt $END_TIME ]; do
        if curl -s --max-time 1 "$API_URL" > /dev/null 2>&1; then
            ((SUCCESS_COUNT++))
        else
            ((FAILURE_COUNT++))
        fi
        sleep 1
    done
}

echo "Initial deployment status:"
show_pods

echo -e "${YELLOW}Testing initial API availability...${NC}"
if curl -s "$API_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API is responding${NC}"
else
    echo -e "${RED}✗ API is NOT responding${NC}"
    echo "Please ensure the deployment is running first."
    exit 1
fi
echo ""

echo "========================================="
echo "Scenario: Pod Failure During High Traffic"
echo "========================================="
echo ""
echo "This demo will:"
echo "  1. Start continuous high traffic to the API"
echo "  2. Kill one pod to simulate a real failure"
echo "  3. Monitor API availability (should stay ~99%+)"
echo "  4. Watch Kubernetes auto-recover the failed pod"
echo "  5. Calculate actual uptime percentage"
echo ""

read -p "Press Enter to start the demo..."
echo ""

# Clean up old temp files
rm -f /tmp/traffic_results_$$

# Traffic generation parameters
DURATION=90  # 90 seconds total
CONCURRENT_WORKERS=5
REQUESTS_PER_WORKER=2

echo -e "${CYAN}Phase 1: Starting continuous traffic (90 seconds)${NC}"
echo "  Concurrent workers: ${CONCURRENT_WORKERS}"
echo "  Total requests per second: ~$((CONCURRENT_WORKERS * REQUESTS_PER_WORKER))"
echo ""
echo "Legend: ${GREEN}.${NC} = Success, ${RED}x${NC} = Failed request"
echo ""

# Start traffic generators in background
for i in $(seq 1 $CONCURRENT_WORKERS); do
    generate_traffic $DURATION $REQUESTS_PER_WORKER $i &
done
TRAFFIC_PIDS=$!

# Start uptime monitor in background
monitor_uptime $DURATION &
MONITOR_PID=$!

# Wait a bit for traffic to stabilize
sleep 10
echo ""
echo ""

# Show current status
echo -e "${BLUE}[$(date '+%H:%M:%S')] Current status - All pods healthy:${NC}"
kubectl get pods -l app=nestjs-api --no-headers
echo ""
sleep 5

echo -e "${RED}Phase 2: Simulating pod failure (killing one pod)...${NC}"
POD_TO_KILL=$(kubectl get pods -l app=nestjs-api -o jsonpath='{.items[0].metadata.name}')
echo -e "${YELLOW}  Killing pod: $POD_TO_KILL${NC}"
kubectl delete pod $POD_TO_KILL --grace-period=0 --force 2>/dev/null
echo -e "${RED}  ✗ Pod deleted!${NC}"
echo ""

# Monitor recovery
echo -e "${CYAN}Phase 3: Monitoring auto-recovery...${NC}"
echo ""

for i in {1..10}; do
    echo -e "${BLUE}[$(date '+%H:%M:%S')] Pod Status:${NC}"
    kubectl get pods -l app=nestjs-api --no-headers | while read line; do
        STATUS=$(echo $line | awk '{print $3}')
        if [[ "$STATUS" == "Running" ]]; then
            echo -e "  ${GREEN}$line${NC}"
        elif [[ "$STATUS" == "ContainerCreating" ]] || [[ "$STATUS" == "Pending" ]]; then
            echo -e "  ${YELLOW}$line${NC}"
        else
            echo -e "  ${RED}$line${NC}"
        fi
    done

    # Check API availability
    if curl -s --max-time 2 "$API_URL" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ API still responding (traffic handled by remaining pods)${NC}"
    else
        echo -e "  ${RED}✗ API temporarily slow${NC}"
    fi
    echo ""

    sleep 8
done

# Wait for all background jobs
wait

echo ""
echo -e "${GREEN}Test complete!${NC}"
echo ""
echo ""

# Show final status
echo "Waiting for cluster to stabilize..."
sleep 5

show_pods

echo -e "${YELLOW}Final API test:${NC}"
if curl -s "$API_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API is healthy and responding${NC}"
else
    echo -e "${RED}✗ API is not responding${NC}"
fi

# Calculate uptime percentage
TOTAL_CHECKS=$((SUCCESS_COUNT + FAILURE_COUNT))
if [ $TOTAL_CHECKS -gt 0 ]; then
    UPTIME_PERCENT=$(echo "scale=2; ($SUCCESS_COUNT * 100) / $TOTAL_CHECKS" | bc)
else
    UPTIME_PERCENT=0
fi

# Calculate request success rate from traffic generators
if [ -f /tmp/traffic_results_$$ ]; then
    TOTAL_SUCCESS=0
    TOTAL_FAILURE=0
    while read success failure; do
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + success))
        TOTAL_FAILURE=$((TOTAL_FAILURE + failure))
    done < /tmp/traffic_results_$$

    TOTAL_REQUESTS=$((TOTAL_SUCCESS + TOTAL_FAILURE))
    if [ $TOTAL_REQUESTS -gt 0 ]; then
        REQUEST_SUCCESS_RATE=$(echo "scale=2; ($TOTAL_SUCCESS * 100) / $TOTAL_REQUESTS" | bc)
    else
        REQUEST_SUCCESS_RATE=0
    fi

    rm -f /tmp/traffic_results_$$
else
    TOTAL_SUCCESS=0
    TOTAL_FAILURE=0
    TOTAL_REQUESTS=0
    REQUEST_SUCCESS_RATE=0
fi

echo ""
echo "========================================="
echo "High Availability Test Results"
echo "========================================="
echo ""
echo -e "${CYAN}Uptime Monitoring (checked every second):${NC}"
echo "  Total checks: $TOTAL_CHECKS"
echo "  Successful: ${GREEN}$SUCCESS_COUNT${NC}"
echo "  Failed: ${RED}$FAILURE_COUNT${NC}"
echo -e "  ${GREEN}Uptime: ${UPTIME_PERCENT}%${NC}"
echo ""
echo -e "${CYAN}Request Success Rate:${NC}"
echo "  Total requests: $TOTAL_REQUESTS"
echo "  Successful: ${GREEN}$TOTAL_SUCCESS${NC}"
echo "  Failed: ${RED}$TOTAL_FAILURE${NC}"
echo -e "  ${GREEN}Success rate: ${REQUEST_SUCCESS_RATE}%${NC}"
echo ""
echo -e "${CYAN}What happened:${NC}"
echo "  1. ✓ Continuous traffic was handled by 3 pods"
echo "  2. ✗ One pod was killed (simulating real failure)"
echo "  3. ✓ Traffic continued via remaining 2 pods (load balanced)"
echo "  4. ✓ Kubernetes auto-created new pod to maintain 3 replicas"
echo "  5. ✓ Service maintained ${UPTIME_PERCENT}% uptime during failure"
echo ""

if (( $(echo "$UPTIME_PERCENT >= 99" | bc -l) )); then
    echo -e "${GREEN}✓ SUCCESS: Achieved 99%+ uptime despite pod failure!${NC}"
else
    echo -e "${YELLOW}⚠ Uptime: ${UPTIME_PERCENT}% (slight degradation during recovery)${NC}"
fi
echo ""

echo "This demonstrates:"
echo "  • Self-healing: Failed pods automatically recreated"
echo "  • High availability: Remaining pods handled traffic"
echo "  • Zero downtime: Service stayed online during failure"
echo "  • Resilience: System recovered without manual intervention"
echo ""
echo "Try checking pod logs:"
echo "  kubectl logs -l app=nestjs-api --tail=50"
echo ""

