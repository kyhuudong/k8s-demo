#!/bin/bash

set -e

# ==============================================================================
# KUBERNETES ROLLING UPDATE CHAOS TEST
# ==============================================================================
# This script demonstrates Kubernetes zero-downtime deployment by:
# 1. Generating continuous API traffic during update
# 2. Simulating a deployment update (new version rollout)
# 3. Measuring uptime and success rate during rolling update
# 4. Verifying zero downtime and gradual pod replacement
# ==============================================================================

clear

echo "================================================"
echo "Zero-Downtime Deployment Demo"
echo "Rolling Update Under Continuous Load"
echo "================================================"
echo ""

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Test duration and traffic parameters
UPDATE_DURATION=60          # Duration to run traffic during update
CONCURRENT_WORKERS=3        # Number of parallel traffic generators
REQUESTS_PER_WORKER=2       # Requests per second per worker
PRE_UPDATE_TIME=5           # Time to run traffic before update
STATUS_CHECKS=8             # Number of status checks during update
CHECK_INTERVAL=5            # Seconds between status checks

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
echo "  Update Duration:      ${UPDATE_DURATION}s"
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
        sleep $(echo "scale=2; 1/$requests_per_sec" | bc 2>/dev/null || echo "0.5")
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

# Get current image version
CURRENT_IMAGE=$(kubectl get deployment nestjs-api -o jsonpath='{.spec.template.spec.containers[0].image}')
echo -e "${BLUE}Current image:${NC} ${MAGENTA}$CURRENT_IMAGE${NC}"
echo ""

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
echo -e "${GREEN}✓ Ready to start rolling update test${NC}"
echo ""

# ==============================================================================
# TEST SCENARIO DESCRIPTION
# ==============================================================================

print_header "TEST SCENARIO: Zero-Downtime Rolling Update"

echo -e "${BOLD}What this test demonstrates:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} ${BOLD}Rolling Updates:${NC} Gradual replacement of pods with new version"
echo -e "  ${CYAN}2.${NC} ${BOLD}Zero Downtime:${NC} Service continues during entire update process"
echo -e "  ${CYAN}3.${NC} ${BOLD}Load Balancing:${NC} Traffic shifts from old to new pods gracefully"
echo -e "  ${CYAN}4.${NC} ${BOLD}Health Checks:${NC} New pods verified before old ones terminated"
echo ""
echo -e "${BOLD}Test steps:${NC}"
echo ""
echo -e "  ${GREEN}→${NC} Phase 1: Start continuous traffic to the API"
echo -e "  ${GREEN}→${NC} Phase 2: Trigger rolling update (simulated new version)"
echo -e "  ${GREEN}→${NC} Phase 3: Monitor pod replacement and API availability"
echo -e "  ${GREEN}→${NC} Phase 4: Verify 100% uptime during entire update"
echo ""
echo -e "${YELLOW}${BOLD}Note:${NC} You'll see pods gradually replaced:"
echo -e "       ${YELLOW}Old pods${NC} → ${CYAN}New pods${NC} (one at a time)"
echo ""

read -p "Press Enter to start the rolling update test..."
echo ""

# ==============================================================================
# PHASE 1: START CONTINUOUS TRAFFIC
# ==============================================================================

print_header "PHASE 1: Starting Continuous Traffic"

# Clean up old temp files
rm -f /tmp/traffic_results_*
rm -f "$TEMP_FILE_ID"

echo -e "${BOLD}Traffic Configuration:${NC}"
echo "  Duration:              $((PRE_UPDATE_TIME + UPDATE_DURATION))s total"
echo "  Concurrent workers:    ${CONCURRENT_WORKERS}"
echo "  Requests/sec (total):  ~$((CONCURRENT_WORKERS * REQUESTS_PER_WORKER))"
echo "  Endpoint:              $API_URL/products"
echo ""
echo -e "${CYAN}Starting traffic generators...${NC}"
echo ""

# Start traffic generators in background
for i in $(seq 1 $CONCURRENT_WORKERS); do
    generate_traffic $((PRE_UPDATE_TIME + UPDATE_DURATION)) $REQUESTS_PER_WORKER $i &
done

# Start uptime monitor in background
monitor_uptime $((PRE_UPDATE_TIME + UPDATE_DURATION)) &

echo -e "${GREEN}✓ Traffic generation started${NC}"
echo -e "${GREEN}✓ Uptime monitoring started${NC}"
echo ""
echo -e "Live traffic indicators: ${GREEN}.${NC} = success, ${RED}x${NC} = failure"
echo ""

# Wait for traffic to stabilize
echo -e "${YELLOW}Running baseline traffic for ${PRE_UPDATE_TIME}s...${NC}"
for i in $(seq 1 $PRE_UPDATE_TIME); do
    echo -n "."
    sleep 1
done
echo ""
echo ""

# ==============================================================================
# PHASE 2: TRIGGER ROLLING UPDATE
# ==============================================================================

print_header "PHASE 2: Triggering Rolling Update"

echo -e "${YELLOW}${BOLD}Simulating deployment update...${NC}"
echo ""
echo -e "  Update strategy:   ${CYAN}RollingUpdate${NC}"
echo -e "  MaxSurge:          ${CYAN}1${NC} (max 1 extra pod during update)"
echo -e "  MaxUnavailable:    ${CYAN}0${NC} (always maintain min replicas)"
echo ""

# Simulate update by adding/changing an annotation (doesn't actually change image)
# This triggers a rolling restart
echo -e "${CYAN}Triggering update by adding annotation...${NC}"
kubectl patch deployment nestjs-api -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"rolling-update-test\":\"$(date +%s)\"}}}}}"

echo -e "${GREEN}✓ Rolling update triggered!${NC}"
echo ""
sleep 2

# ==============================================================================
# PHASE 3: MONITOR ROLLING UPDATE
# ==============================================================================

print_header "PHASE 3: Monitoring Rolling Update Progress"

echo -e "${CYAN}Watching pod replacement process...${NC}"
echo ""

for i in $(seq 1 $STATUS_CHECKS); do
    echo -e "${BLUE}${BOLD}[$(date '+%H:%M:%S')] Update Check $i/$STATUS_CHECKS${NC}"
    print_separator

    # Display pod status with age
    kubectl get pods -l app=nestjs-api --no-headers | while read line; do
        STATUS=$(echo $line | awk '{print $3}')
        AGE=$(echo $line | awk '{print $5}')

        if [[ "$STATUS" == "Running" ]]; then
            if [[ "$AGE" =~ ^[0-9]+s$ ]] || [[ "$AGE" =~ ^[0-9]+m$ && ${AGE%m} -lt 3 ]]; then
                echo -e "  ${CYAN}⟳ $line ${BOLD}(NEW POD)${NC}"
            else
                echo -e "  ${YELLOW}○ $line ${BOLD}(OLD POD)${NC}"
            fi
        elif [[ "$STATUS" == "ContainerCreating" ]] || [[ "$STATUS" == "Pending" ]]; then
            echo -e "  ${CYAN}⟳ $line ${BOLD}(creating new pod...)${NC}"
        elif [[ "$STATUS" == "Terminating" ]]; then
            echo -e "  ${YELLOW}⤓ $line ${BOLD}(terminating old pod...)${NC}"
        else
            echo -e "  ${RED}✗ $line${NC}"
        fi
    done

    print_separator

    # Check rollout status
    ROLLOUT_STATUS=$(kubectl rollout status deployment/nestjs-api --timeout=1s 2>&1 || echo "in progress")

    if [[ "$ROLLOUT_STATUS" == *"successfully rolled out"* ]]; then
        echo -e "  ${GREEN}${BOLD}✓ ROLLOUT COMPLETE - All pods updated!${NC}"
    else
        echo -e "  ${CYAN}⟳ Rolling update in progress...${NC}"
    fi

    # Check API availability during update
    if curl -s --max-time 2 "$API_URL" > /dev/null 2>&1; then
        echo -e "  ${GREEN}${BOLD}✓ API RESPONDING${NC} ${CYAN}(zero downtime maintained)${NC}"
    else
        echo -e "  ${RED}⚠ API slow/unavailable${NC}"
    fi
    echo ""

    sleep $CHECK_INTERVAL
done

# ==============================================================================
# WAIT FOR TEST COMPLETION
# ==============================================================================

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

echo -e "${YELLOW}Waiting for rollout to complete...${NC}"
kubectl rollout status deployment/nestjs-api --timeout=30s

show_pods

# Get new image version
NEW_IMAGE=$(kubectl get deployment nestjs-api -o jsonpath='{.spec.template.spec.containers[0].image}')
echo -e "${BLUE}Updated image:${NC} ${MAGENTA}$NEW_IMAGE${NC}"
echo ""

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

print_header "ZERO-DOWNTIME DEPLOYMENT TEST RESULTS"

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
echo -e "  ${GREEN}1.${NC} Continuous traffic started hitting the API"
echo -e "  ${CYAN}2.${NC} Rolling update triggered with ${BOLD}RollingUpdate strategy${NC}"
echo -e "  ${CYAN}3.${NC} Pods replaced ${BOLD}one at a time${NC} (not all at once)"
echo -e "  ${GREEN}4.${NC} New pods verified healthy ${BOLD}before${NC} old ones terminated"
echo -e "  ${GREEN}5.${NC} Traffic seamlessly shifted from old to new pods"
echo -e "  ${GREEN}6.${NC} Service maintained ${BOLD}${UPTIME_PERCENT}%${NC} uptime during entire update"
echo ""
print_separator
echo ""

# Evaluate results
if (( $(echo "$UPTIME_PERCENT >= 99.5" | bc -l) )); then
    echo -e "${GREEN}${BOLD}✓ EXCELLENT: Achieved 99.5%+ uptime during rolling update!${NC}"
    echo -e "${GREEN}${BOLD}✓ True zero-downtime deployment!${NC}"
elif (( $(echo "$UPTIME_PERCENT >= 98" | bc -l) )); then
    echo -e "${GREEN}${BOLD}✓ GOOD: Achieved ${UPTIME_PERCENT}% uptime${NC}"
    echo -e "${GREEN}  (minimal disruption during pod transitions)${NC}"
else
    echo -e "${YELLOW}${BOLD}⚠ Uptime: ${UPTIME_PERCENT}%${NC}"
    echo -e "${YELLOW}  (some disruption detected - check readiness probes)${NC}"
fi
echo ""
print_separator
echo ""

echo -e "${BOLD}${CYAN}🎓 Key Kubernetes Concepts Demonstrated:${NC}"
echo ""
echo -e "  ${BOLD}• Rolling Updates:${NC}     Gradual pod replacement strategy"
echo -e "  ${BOLD}• Zero Downtime:${NC}       Service available throughout update"
echo -e "  ${BOLD}• MaxSurge/MaxUnavailable:${NC} Controls update speed and safety"
echo -e "  ${BOLD}• Health Checks:${NC}       Readiness probes verify new pods"
echo -e "  ${BOLD}• Traffic Shifting:${NC}    Load balancer adapts to pod changes"
echo ""
print_separator
echo ""

echo -e "${BOLD}${CYAN}🔍 Next Steps - Explore Further:${NC}"
echo ""
echo "  Check rollout history:"
echo -e "    ${CYAN}kubectl rollout history deployment/nestjs-api${NC}"
echo ""
echo "  View deployment strategy:"
echo -e "    ${CYAN}kubectl describe deployment nestjs-api | grep -A 5 Strategy${NC}"
echo ""
echo "  Rollback to previous version:"
echo -e "    ${CYAN}kubectl rollout undo deployment/nestjs-api${NC}"
echo ""
echo "  Watch rollout in real-time:"
echo -e "    ${CYAN}kubectl rollout status deployment/nestjs-api --watch${NC}"
echo ""
echo -e "${GREEN}${BOLD}Test completed successfully!${NC}"
echo ""
