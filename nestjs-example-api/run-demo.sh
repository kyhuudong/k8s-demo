#!/bin/bash

set -e

echo "========================================="
echo "NestJS API - Kubernetes Demo"
echo "Complete Automation Script"
echo "========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed!"
    echo ""
    echo "Please install Docker first:"
    echo "  macOS: https://docs.docker.com/desktop/install/mac-install/"
    echo "  Linux: https://docs.docker.com/engine/install/"
    echo ""
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo "❌ Error: Docker is not running!"
    echo ""
    echo "Please start Docker Desktop or Docker daemon first."
    echo ""
    exit 1
fi
echo "✓ Docker is installed and running"

# Check if curl is installed (needed for downloading kubectl/minikube)
if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl is not installed!"
    echo ""
    echo "Please install curl first:"
    echo "  macOS: brew install curl"
    echo "  Alpine: apk add curl"
    echo "  Ubuntu/Debian: apt-get install curl"
    echo ""
    exit 1
fi
echo "✓ curl is installed"
echo ""

# Make all scripts executable
echo "Making scripts executable..."
chmod +x run-demo.sh 2>/dev/null || true
chmod +x 2-deploy-app.sh 2>/dev/null || true
chmod +x 3-chaos-test.sh 2>/dev/null || true
chmod +x check-status.sh 2>/dev/null || true
echo "✓ Scripts are executable"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "This script will:"
echo "  0. Clean up Docker/Minikube (optional)"
echo "  1. Setup Kubernetes cluster (kubectl + minikube)"
echo "  2. Build and deploy NestJS API with MySQL"
echo "  3. Run chaos testing to demonstrate resilience"
echo ""

read -p "Do you want to clean up Docker first to free disk space? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "========================================="
    echo "Step 0: Cleaning up Docker & Minikube"
    echo "========================================="
    echo ""
    echo "Removing ALL unused Docker resources..."
    echo "This may take a moment..."
    docker system prune -a -f --volumes 2>/dev/null || true
    docker builder prune -a -f 2>/dev/null || true
    echo "✓ Docker cleanup complete"
    echo ""
    echo "Disk space freed. Checking available space..."
    df -h / | grep -E "Filesystem|/" || df -h | head -2
    echo ""
fi

echo ""
echo "========================================="
echo "Step 1: Setting up Kubernetes Cluster"
echo "========================================="
echo ""

# Check if Minikube is running
if ! minikube status &> /dev/null; then
    echo "Installing dependencies and starting Minikube..."
    echo ""

    # Install Alpine dependencies (skip if not Alpine)
    apk add --no-cache gcompat conntrack-tools 2>/dev/null || echo "⚠ Skipping Alpine dependencies"

    # Install kubectl if needed
    if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
    fi

    # Install minikube if needed
    if ! command -v minikube &> /dev/null; then
        echo "Installing minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        install minikube-linux-amd64 /usr/local/bin/minikube
        rm -f minikube-linux-amd64
    fi

    # Start minikube
    echo "Starting Minikube cluster..."
    minikube start --driver=docker --force
else
    echo "✓ Minikube is already running"
fi

echo ""
kubectl cluster-info
echo ""
kubectl get nodes
echo ""

echo -e "${GREEN}✓ Cluster setup complete!${NC}"
echo ""
read -p "Press Enter to continue to deployment..."

echo ""
echo "========================================="
echo "Step 2: Building and Deploying Application"
echo "========================================="
echo ""

./2-deploy-app.sh

echo ""
echo -e "${GREEN}✓ Application deployed successfully!${NC}"
echo ""

# Show access information
MINIKUBE_IP=$(minikube ip)
echo "========================================="
echo "Application is now running!"
echo "========================================="
echo ""
echo "Access your NestJS API at:"
echo "  - API: http://$MINIKUBE_IP:30080"
echo "  - Swagger Docs: http://$MINIKUBE_IP:30080/docs"
echo "  - Products endpoint: http://$MINIKUBE_IP:30080/products"
echo ""

echo "You can also use port-forward:"
echo "  kubectl port-forward service/nestjs-api 3000:3000"
echo "  Then access: http://localhost:3000"
echo ""

read -p "Do you want to test the API now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Testing API..."
    echo ""
    echo "GET /"
    curl -s http://$MINIKUBE_IP:30080 | head -n 5
    echo ""
    echo ""
    echo "GET /products"
    curl -s http://$MINIKUBE_IP:30080/products | head -n 20
    echo ""
fi

echo ""
read -p "Press Enter to continue to chaos testing demo..."

echo ""
echo "========================================="
echo "Step 3: Chaos Testing & Resilience Demo"
echo "========================================="
echo ""

./3-chaos-test.sh

echo ""
echo "========================================="
echo "All Steps Complete!"
echo "========================================="
echo ""

echo -e "${GREEN}Your NestJS API is running on Kubernetes!${NC}"
echo ""

echo "Useful commands:"
echo "  kubectl get pods              # List all pods"
echo "  kubectl get services          # List all services"
echo "  kubectl logs <pod-name>       # View pod logs"
echo "  kubectl describe pod <name>   # Pod details"
echo "  kubectl delete pod <name>     # Delete a pod (will auto-recreate)"
echo "  kubectl scale deployment nestjs-api --replicas=5  # Scale to 5 pods"
echo ""

echo "To access the application:"
echo "  minikube service nestjs-api --url"
echo "  or"
echo "  kubectl port-forward service/nestjs-api 3000:3000"
echo ""

echo "To clean up everything:"
echo "  kubectl delete -f k8s/"
echo "  minikube delete"
echo ""

echo -e "${GREEN}Demo complete! 🎉${NC}"
