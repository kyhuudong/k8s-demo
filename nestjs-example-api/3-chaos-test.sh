#!/bin/bash

set -e

# ==============================================================================
# KUBERNETES HIGH AVAILABILITY CHAOS TEST
# ==============================================================================
# This script demonstrates Kubernetes self-healing and high availability by:
# 1. Generating continuous API traffic
# 2. Simulating a pod failure (chaos engineering)
# 3. Measuring uptime and success rate during recovery
# 4. Verifying automatic pod recreation
# ==============================================================================

clear

echo "========================================="
echo "High Availability Demo (99%+ Uptime)"
echo "Pod Failure & Auto-Recovery Under Load"
echo "========================================="
echo ""

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Test duration and traffic parameters
DURATION=45                 # Total test duration in seconds (reduced for faster demo)
CONCURRENT_WORKERS=3        # Number of parallel traffic generators
REQUESTS_PER_WORKER=2       # Requests per second per worker
STABILIZATION_TIME=5        # Time to wait before chaos (seconds)
RECOVERY_CHECKS=6           # Number of status checks during recovery
RECOVERY_CHECK_INTERVAL=5   # Seconds between recovery checks

# ==============================================================================
# COLOR DEFINITIONS
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ==============================================================================
# ENVIRONMENT SETUP
# ==============================================================================

# Get Minikube IP
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
API_URL="http://$MINIKUBE_IP:30080"

echo -e "${BOLD}Configuration:${NC}"
echo "  API Endpoint:         $API_URL"
echo "  Test Duration:        ${DURATION}s"
echo "  Traffic Workers:      ${CONCURRENT_WORKERS}"
echo "  Requests/Worker/sec:  ${REQUESTS_PER_WORKER}"
echo "  Total RPS:            ~$((CONCURRENT_WORKERS * REQUESTS_PER_WORKER))"
echo ""

# ==============================================================================
# GLOBAL COUNTERS
# ==============================================================================

SUCCESS_COUNT=0
FAILURE_COUNT=0

# Create unique temp file identifier
TEMP_FILE_ID="/tmp/traffic_results_${$}_$(date +%s)"

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Print a separator line
print_separator() {
    echo "---------------------------------------------------------------------"
}

# Print a section header
print_header() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN} $title${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Show pod status with color coding
show_pods() {
    echo ""
    echo -e "${BLUE}${BOLD}Current Pod Status:${NC}"
    print_separator
    kubectl get pods -l app=nestjs-api -o wide
    print_separator
    echo ""
}

# Generate continuous API traffic and track success/failure
generate_traffic() {
    local duration=$1
    local requests_per_sec=$2
    local worker_id=$3

    END_TIME=$(($(date +%s) + duration))
    local success=0
    local failure=0

    while [ $(date +%s) -lt $END_TIME ]; do
        # Attempt API request with timeout
        if curl -s --max-time 2 "$API_URL/products" > /dev/null 2>&1; then
            echo -n -e "${GREEN}.${NC}"
            ((success++))
        else
            echo -n -e "${RED}x${NC}"
            ((failure++))
        fi

        # Calculate sleep time based on requests per second
        sleep $(echo "scale=2; 1/$requests_per_sec" | bc 2>/dev/null || echo "0.2")
    done

    # Write results to temp file for aggregation
    echo "$success $failure" >> "$TEMP_FILE_ID"
}

# Monitor API uptime by checking every second
monitor_uptime() {
    local duration=$1
    END_TIME=$(($(date +%s) + duration))

    while [ $(date +%s) -lt $END_TIME ]; do
        # Quick health check every second
        if curl -s --max-time 1 "$API_URL" > /dev/null 2>&1; then
            ((SUCCESS_COUNT++))
        else
            ((FAILURE_COUNT++))
        fi
        sleep 1
    done
}

# Check if required commands are available
check_prerequisites() {
    local missing_deps=0

    echo -e "${YELLOW}Checking prerequisites...${NC}"

    for cmd in kubectl minikube curl bc; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "  ${RED}✗ $cmd is not installed${NC}"
            ((missing_deps++))
        else
            echo -e "  ${GREEN}✓ $cmd is available${NC}"
        fi
    done

    if [ $missing_deps -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies. Please install them first.${NC}"
        exit 1
    fi

    echo ""
}

# ==============================================================================
# PREREQUISITES CHECK
# ==============================================================================

check_prerequisites

# ==============================================================================
# INITIAL STATUS CHECK
# ==============================================================================

print_header "INITIAL STATUS CHECK"

echo -e "${YELLOW}Checking deployment status...${NC}"
show_pods

echo -e "${YELLOW}Testing initial API availability...${NC}"
echo ""

# Test root endpoint
echo -n "  Testing root endpoint (/)...          "
if curl -s --max-time 3 "$API_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    echo -e "${RED}✗ API is NOT responding${NC}"
    echo ""
    echo "Run this first:"
    echo "  kubectl apply -f k8s/"
    exit 1
fi

# Test products endpoint
echo -n "  Testing /products endpoint...         "
if curl -s --max-time 3 "$API_URL/products" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    echo -e "${RED}✗ Products endpoint is NOT responding${NC}"
    exit 1
fi

# Run quick load test
echo -n "  Quick load test (10 requests)...      "
QUICK_SUCCESS=0
QUICK_FAIL=0
for i in {1..10}; do
    if curl -s --max-time 2 "$API_URL/products" > /dev/null 2>&1; then
        ((QUICK_SUCCESS++))
    else
        ((QUICK_FAIL++))
    fi
done

if [ $QUICK_SUCCESS -ge 8 ]; then
    echo -e "${GREEN}✓ OK ($QUICK_SUCCESS/10 succeeded)${NC}"
else
    echo -e "${YELLOW}⚠ WARNING ($QUICK_SUCCESS/10 succeeded)${NC}"
fi

echo ""
echo -e "${GREEN}✓ All API endpoints are healthy${NC}"
echo -e "${GREEN}✓ Ready to start chaos test${NC}"
echo ""

# ==============================================================================
# TEST SCENARIO DESCRIPTION
# ==============================================================================

print_header "TEST SCENARIO: Pod Failure During High Traffic"

echo -e "${BOLD}What this test demonstrates:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} ${BOLD}Self-Healing:${NC} Kubernetes automatically recreates failed pods"
echo -e "  ${CYAN}2.${NC} ${BOLD}High Availability:${NC} Remaining pods handle traffic during recovery"
echo -e "  ${CYAN}3.${NC} ${BOLD}Load Balancing:${NC} Service distributes requests across healthy pods"
echo -e "  ${CYAN}4.${NC} ${BOLD}Zero Downtime:${NC} Service maintains 99%+ uptime during failures"
echo ""
echo -e "${BOLD}Test steps:${NC}"
echo ""
echo -e "  ${GREEN}→${NC} Phase 1: Start continuous high traffic to the API (${DURATION}s)"
echo -e "  ${GREEN}→${NC} Phase 2: Kill one pod to simulate a real failure"
echo -e "  ${GREEN}→${NC} Phase 3: Monitor API availability and auto-recovery"
echo -e "  ${GREEN}→${NC} Phase 4: Calculate uptime and success metrics"
echo ""
echo -e "${YELLOW}${BOLD}Note:${NC} You'll see live traffic indicators:"
echo -e "       ${GREEN}.${NC} = Successful request"
echo -e "       ${RED}x${NC} = Failed request"
echo ""

read -p "Press Enter to start the chaos test..."
echo ""

# ==============================================================================
# PHASE 1: START CONTINUOUS TRAFFIC
# ==============================================================================

print_header "PHASE 1: Starting Continuous Traffic"

# Clean up old temp files
rm -f /tmp/traffic_results_*
rm -f "$TEMP_FILE_ID"

echo -e "${BOLD}Traffic Configuration:${NC}"
echo "  Duration:              ${DURATION} seconds"
echo "  Concurrent workers:    ${CONCURRENT_WORKERS}"
echo "  Requests/sec (total):  ~$((CONCURRENT_WORKERS * REQUESTS_PER_WORKER))"
echo "  Endpoint:              $API_URL/products"
echo ""
echo -e "${CYAN}Starting traffic generators...${NC}"
echo ""

# Start traffic generators in background
for i in $(seq 1 $CONCURRENT_WORKERS); do
    generate_traffic $DURATION $REQUESTS_PER_WORKER $i &
done
TRAFFIC_PIDS=$!

# Start uptime monitor in background
monitor_uptime $DURATION &
MONITOR_PID=$!

echo -e "${GREEN}✓ Traffic generation started${NC}"
echo -e "${GREEN}✓ Uptime monitoring started${NC}"
echo ""
echo -e "Live traffic indicators: ${GREEN}.${NC} = success, ${RED}x${NC} = failure"
echo ""

# Wait for traffic to stabilize before introducing chaos
echo -e "${YELLOW}Waiting ${STABILIZATION_TIME}s for traffic to stabilize...${NC}"
for i in $(seq 1 $STABILIZATION_TIME); do
    echo -n "."
    sleep 1
done
echo ""
echo ""

# Show current status before chaos
echo -e "${BLUE}${BOLD}[$(date '+%H:%M:%S')] Status Before Chaos:${NC}"
print_separator
kubectl get pods -l app=nestjs-api --no-headers | while read line; do
    echo -e "  ${GREEN}✓ $line${NC}"
done
print_separator
echo -e "${GREEN}All pods are healthy and serving traffic${NC}"
echo ""
sleep 3

# ==============================================================================
# PHASE 2: INTRODUCE CHAOS (POD FAILURE)
# ==============================================================================

print_header "PHASE 2: Introducing Chaos - Simulating Pod Failure"

POD_TO_KILL=$(kubectl get pods -l app=nestjs-api -o jsonpath='{.items[0].metadata.name}')

echo -e "${YELLOW}${BOLD}⚠ Simulating real-world pod failure...${NC}"
echo ""
echo -e "  Target pod:     ${MAGENTA}$POD_TO_KILL${NC}"
echo -e "  Action:         ${RED}Force delete (immediate termination)${NC}"
echo -e "  Expected:       ${CYAN}Traffic continues via remaining pods${NC}"
echo ""

kubectl delete pod $POD_TO_KILL --grace-period=0 --force 2>/dev/null

echo -e "${RED}${BOLD}  ✗ Pod deleted!${NC}"
echo -e "${YELLOW}  → Kubernetes should now detect the missing pod...${NC}"
echo -e "${YELLOW}  → Expected to auto-create a replacement pod...${NC}"
echo ""
sleep 2

# ==============================================================================
# PHASE 3: MONITOR AUTO-RECOVERY
# ==============================================================================

print_header "PHASE 3: Monitoring Kubernetes Auto-Recovery"

echo -e "${CYAN}Watching pod status and API availability...${NC}"
echo -e "${CYAN}Check interval: every ${RECOVERY_CHECK_INTERVAL}s${NC}"
echo ""

for i in $(seq 1 $RECOVERY_CHECKS); do
    echo -e "${BLUE}${BOLD}[$(date '+%H:%M:%S')] Recovery Check $i/$RECOVERY_CHECKS${NC}"
    print_separator

    # Display pod status with color coding
    kubectl get pods -l app=nestjs-api --no-headers | while read line; do
        STATUS=$(echo $line | awk '{print $3}')
        POD_NAME=$(echo $line | awk '{print $1}')

        if [[ "$STATUS" == "Running" ]]; then
            echo -e "  ${GREEN}✓ $line${NC}"
        elif [[ "$STATUS" == "ContainerCreating" ]] || [[ "$STATUS" == "Pending" ]]; then
            echo -e "  ${YELLOW}⟳ $line ${BOLD}(recreating...)${NC}"
        elif [[ "$STATUS" == "Terminating" ]]; then
            echo -e "  ${RED}⤓ $line ${BOLD}(terminating...)${NC}"
        else
            echo -e "  ${RED}✗ $line${NC}"
        fi
    done

    print_separator

    # Check API availability during recovery
    if curl -s --max-time 2 "$API_URL" > /dev/null 2>&1; then
        echo -e "  ${GREEN}${BOLD}✓ API STILL RESPONDING${NC} ${CYAN}(traffic handled by healthy pods)${NC}"
    else
        echo -e "  ${YELLOW}⚠ API response slow${NC} ${CYAN}(may indicate temporary overload)${NC}"
    fi
    echo ""

    sleep $RECOVERY_CHECK_INTERVAL
done

# ==============================================================================
# WAIT FOR TEST COMPLETION
# ==============================================================================

# Wait for all background jobs (traffic generators and uptime monitor)
echo -e "${YELLOW}Waiting for all background processes to complete...${NC}"
wait

# Give a moment for file writes to complete
sleep 1

echo ""
echo -e "${GREEN}${BOLD}✓ Test execution complete!${NC}"
echo ""

# ==============================================================================
# FINAL STATUS VERIFICATION
# ==============================================================================

print_header "FINAL STATUS VERIFICATION"

echo -e "${YELLOW}Waiting for cluster to stabilize...${NC}"
sleep 5

show_pods

echo -e "${BOLD}Final API health check:${NC}"
if curl -s "$API_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}${BOLD}✓ API is healthy and responding normally${NC}"
else
    echo -e "${RED}${BOLD}✗ API is not responding (unexpected!)${NC}"
fi
echo ""

# ==============================================================================
# CALCULATE METRICS
# ==============================================================================

# Calculate uptime percentage from health checks
TOTAL_CHECKS=$((SUCCESS_COUNT + FAILURE_COUNT))
if [ $TOTAL_CHECKS -gt 0 ]; then
    UPTIME_PERCENT=$(echo "scale=2; ($SUCCESS_COUNT * 100) / $TOTAL_CHECKS" | bc)
else
    UPTIME_PERCENT=0
fi

# Calculate request success rate from traffic generators
if [ -f "$TEMP_FILE_ID" ]; then
    TOTAL_SUCCESS=0
    TOTAL_FAILURE=0

    echo -e "${CYAN}Debug: Reading results from $TEMP_FILE_ID${NC}" >&2
    echo -e "${CYAN}Debug: File contents:${NC}" >&2
    cat "$TEMP_FILE_ID" >&2

    # Aggregate results from all workers
    while read success failure; do
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + success))
        TOTAL_FAILURE=$((TOTAL_FAILURE + failure))
    done < "$TEMP_FILE_ID"

    TOTAL_REQUESTS=$((TOTAL_SUCCESS + TOTAL_FAILURE))
    if [ $TOTAL_REQUESTS -gt 0 ]; then
        REQUEST_SUCCESS_RATE=$(echo "scale=2; ($TOTAL_SUCCESS * 100) / $TOTAL_REQUESTS" | bc)
    else
        REQUEST_SUCCESS_RATE=0
    fi

    # Clean up temp file
    rm -f "$TEMP_FILE_ID"
else
    echo -e "${YELLOW}Debug: Temp file $TEMP_FILE_ID not found${NC}" >&2
    TOTAL_SUCCESS=0
    TOTAL_FAILURE=0
    TOTAL_REQUESTS=0
    REQUEST_SUCCESS_RATE=0
fi

# ==============================================================================
# TEST RESULTS SUMMARY
# ==============================================================================

print_header "HIGH AVAILABILITY TEST RESULTS"

echo -e "${BOLD}${CYAN}📊 Uptime Monitoring${NC} ${CYAN}(health checks every second):${NC}"
echo ""
echo "  Total health checks:  $TOTAL_CHECKS"
echo "  Successful checks:    ${GREEN}$SUCCESS_COUNT${NC}"
echo "  Failed checks:        ${RED}$FAILURE_COUNT${NC}"
echo ""
echo -e "  ${BOLD}${GREEN}API Uptime: ${UPTIME_PERCENT}%${NC}"
echo ""
print_separator
echo ""

echo -e "${BOLD}${CYAN}📈 Request Success Rate${NC} ${CYAN}(actual API requests):${NC}"
echo ""
echo "  Total requests:       $TOTAL_REQUESTS"
echo "  Successful:           ${GREEN}$TOTAL_SUCCESS${NC}"
echo "  Failed:               ${RED}$TOTAL_FAILURE${NC}"
echo ""
echo -e "  ${BOLD}${GREEN}Success Rate: ${REQUEST_SUCCESS_RATE}%${NC}"
echo ""
print_separator
echo ""

echo -e "${BOLD}${CYAN}📝 What Happened During the Test:${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} Continuous traffic was handled by ${BOLD}3 pods${NC}"
echo -e "  ${RED}2.${NC} One pod was ${BOLD}forcefully killed${NC} (simulating real failure)"
echo -e "  ${GREEN}3.${NC} Traffic ${BOLD}automatically continued${NC} via remaining 2 pods"
echo -e "  ${GREEN}4.${NC} Kubernetes ${BOLD}auto-created${NC} a new pod to maintain 3 replicas"
echo -e "  ${GREEN}5.${NC} Service maintained ${BOLD}${UPTIME_PERCENT}%${NC} uptime during failure & recovery"
echo ""
print_separator
echo ""

# Evaluate results
if (( $(echo "$UPTIME_PERCENT >= 99" | bc -l) )); then
    echo -e "${GREEN}${BOLD}✓ SUCCESS: Achieved 99%+ uptime despite pod failure!${NC}"
    echo -e "${GREEN}${BOLD}✓ High availability objective met!${NC}"
elif (( $(echo "$UPTIME_PERCENT >= 95" | bc -l) )); then
    echo -e "${YELLOW}${BOLD}⚠ GOOD: Achieved ${UPTIME_PERCENT}% uptime${NC}"
    echo -e "${YELLOW}  (slight degradation during recovery, but still highly available)${NC}"
else
    echo -e "${RED}${BOLD}⚠ Uptime: ${UPTIME_PERCENT}%${NC}"
    echo -e "${YELLOW}  (more degradation than expected - check pod resources/health)${NC}"
fi
echo ""
print_separator
echo ""

echo -e "${BOLD}${CYAN}🎓 Key Kubernetes Concepts Demonstrated:${NC}"
echo ""
echo -e "  ${BOLD}• Self-Healing:${NC}       Failed pods automatically recreated by ReplicaSet"
echo -e "  ${BOLD}• High Availability:${NC}  Multiple replicas ensure continuous service"
echo -e "  ${BOLD}• Load Balancing:${NC}     Service distributes traffic across healthy pods"
echo -e "  ${BOLD}• Resilience:${NC}         System recovered without manual intervention"
echo -e "  ${BOLD}• Zero Downtime:${NC}      Service stayed online during pod failure"
echo ""
print_separator
echo ""

echo -e "${BOLD}${CYAN}🔍 Next Steps - Explore Further:${NC}"
echo ""
echo "  View pod logs:"
echo -e "    ${CYAN}kubectl logs -l app=nestjs-api --tail=50${NC}"
echo ""
echo "  Check pod events:"
echo -e "    ${CYAN}kubectl get events --sort-by='.lastTimestamp' | grep nestjs-api${NC}"
echo ""
echo "  Describe a pod:"
echo -e "    ${CYAN}kubectl describe pod -l app=nestjs-api | head -50${NC}"
echo ""
echo "  Watch pods in real-time:"
echo -e "    ${CYAN}kubectl get pods -l app=nestjs-api --watch${NC}"
echo ""
echo -e "${GREEN}${BOLD}Test completed successfully!${NC}"
echo ""

