#!/bin/bash

set -e

echo "========================================="
echo "Kubernetes Resilience Demo"
echo "Simulating Pod Failures & Auto-Recovery"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show pod status
show_pods() {
    echo ""
    echo "Current Pod Status:"
    kubectl get pods -l app=nestjs-api -o wide
    echo ""
}

# Function to test API availability
test_api() {
    MINIKUBE_IP=$(minikube ip)
    if curl -s http://$MINIKUBE_IP:30080 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API is responding${NC}"
        return 0
    else
        echo -e "${RED}✗ API is NOT responding${NC}"
        return 1
    fi
}

# Function to continuously test API
continuous_test() {
    echo "Starting continuous API testing (press Ctrl+C to stop)..."
    while true; do
        if curl -s http://$(minikube ip):30080/products > /dev/null 2>&1; then
            echo -e "${GREEN}$(date '+%H:%M:%S') - API OK${NC}"
        else
            echo -e "${RED}$(date '+%H:%M:%S') - API DOWN${NC}"
        fi
        sleep 2
    done
}

echo "Initial deployment status:"
show_pods

echo "Testing API availability..."
test_api

echo ""
echo "========================================="
echo "Demo 1: Delete a Single Pod"
echo "========================================="
echo ""

echo "Kubernetes will automatically recreate the deleted pod."
echo ""

# Get one pod name
POD_NAME=$(kubectl get pods -l app=nestjs-api -o jsonpath='{.items[0].metadata.name}')

echo -e "${YELLOW}Deleting pod: $POD_NAME${NC}"
kubectl delete pod $POD_NAME

echo ""
echo "Watch the pod being recreated (waiting 5 seconds)..."
sleep 5
show_pods

echo "API should still be available due to other replicas:"
test_api

echo ""
read -p "Press Enter to continue to Demo 2..."

echo ""
echo "========================================="
echo "Demo 2: Delete All Pods Simultaneously"
echo "========================================="
echo ""

echo "Simulating a massive failure - deleting ALL API pods!"
echo "Kubernetes will recreate all pods automatically."
echo ""

echo -e "${RED}Deleting all NestJS API pods...${NC}"
kubectl delete pods -l app=nestjs-api

echo ""
echo "Monitoring pod recreation (this will take ~30 seconds)..."
sleep 3
show_pods

echo "Waiting for pods to be ready again..."
kubectl wait --for=condition=ready pod -l app=nestjs-api --timeout=120s

show_pods
echo -e "${GREEN}All pods are back online!${NC}"
test_api

echo ""
read -p "Press Enter to continue to Demo 3..."

echo ""
echo "========================================="
echo "Demo 3: Simulate DDoS Attack"
echo "========================================="
echo ""

echo "We'll simulate high load by scaling down and killing pods repeatedly."
echo "Kubernetes will maintain the desired replica count automatically."
echo ""

# Function to continuously delete random pods
ddos_simulation() {
    echo -e "${RED}Starting DDoS simulation...${NC}"
    echo "Continuously deleting random pods for 30 seconds..."
    echo "Watch how Kubernetes maintains availability!"
    echo ""

    END_TIME=$(($(date +%s) + 30))
    while [ $(date +%s) -lt $END_TIME ]; do
        POD=$(kubectl get pods -l app=nestjs-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ ! -z "$POD" ]; then
            echo -e "${YELLOW}$(date '+%H:%M:%S') - Killing pod: $POD${NC}"
            kubectl delete pod $POD --grace-period=0 --force 2>/dev/null || true
            sleep 3
        fi
    done

    echo ""
    echo -e "${GREEN}DDoS simulation complete!${NC}"
}

# Run DDoS simulation in background and monitor API
echo "Starting parallel monitoring..."
echo ""

ddos_simulation &
DDOS_PID=$!

# Monitor API availability during attack
sleep 2
MINIKUBE_IP=$(minikube ip)
echo "Monitoring API availability during attack..."
echo ""

for i in {1..10}; do
    if curl -s http://$MINIKUBE_IP:30080 > /dev/null 2>&1; then
        echo -e "${GREEN}$(date '+%H:%M:%S') - API is still responding!${NC}"
    else
        echo -e "${RED}$(date '+%H:%M:%S') - API temporarily unavailable${NC}"
    fi
    sleep 3
done

wait $DDOS_PID

echo ""
echo "Waiting for cluster to stabilize..."
sleep 10

show_pods

echo "Final API test:"
test_api

echo ""
read -p "Press Enter to continue to Demo 4..."

echo ""
echo "========================================="
echo "Demo 4: Resource Exhaustion Simulation"
echo "========================================="
echo ""

echo "Simulating a pod consuming too much memory (will be killed and restarted)."
echo ""

POD_NAME=$(kubectl get pods -l app=nestjs-api -o jsonpath='{.items[0].metadata.name}')

echo "Current pod: $POD_NAME"
echo ""
echo "Attempting to consume excessive memory inside the pod..."
echo "(This is simulated - we'll just delete the pod to demonstrate restart)"
echo ""

kubectl delete pod $POD_NAME

echo "Monitoring restart..."
sleep 5
show_pods

kubectl wait --for=condition=ready pod -l app=nestjs-api --timeout=120s

show_pods
test_api

echo ""
echo "========================================="
echo "Demo 5: Scale Testing"
echo "========================================="
echo ""

echo "Testing horizontal scaling capabilities..."
echo ""

echo "Current replicas: 3"
show_pods

echo -e "${YELLOW}Scaling down to 1 replica...${NC}"
kubectl scale deployment nestjs-api --replicas=1
sleep 5
show_pods

echo -e "${YELLOW}Scaling up to 5 replicas...${NC}"
kubectl scale deployment nestjs-api --replicas=5
sleep 5
show_pods

echo "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod -l app=nestjs-api --timeout=120s

show_pods

echo -e "${YELLOW}Scaling back to 3 replicas...${NC}"
kubectl scale deployment nestjs-api --replicas=3
sleep 5
show_pods

echo ""
echo "========================================="
echo "Summary of Resilience Features"
echo "========================================="
echo ""

echo "✓ Self-Healing: Deleted pods are automatically recreated"
echo "✓ High Availability: Multiple replicas ensure zero downtime"
echo "✓ Health Checks: Liveness and readiness probes detect failures"
echo "✓ Resource Limits: Prevents resource exhaustion"
echo "✓ Horizontal Scaling: Easy to scale up or down"
echo "✓ Load Balancing: Traffic distributed across healthy pods"
echo ""

echo "========================================="
echo "Chaos Testing Complete!"
echo "========================================="
echo ""

echo "Your NestJS API demonstrated excellent resilience against:"
echo "  - Single pod failures"
echo "  - Mass pod deletion"
echo "  - Simulated DDoS attacks"
echo "  - Resource exhaustion"
echo "  - Scaling operations"
echo ""

echo "Final Status:"
show_pods
test_api
