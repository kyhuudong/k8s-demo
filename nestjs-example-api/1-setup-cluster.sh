#!/bin/bash

set -e

echo "========================================="
echo "Kubernetes Cluster Setup"
echo "Following steps.txt"
echo "========================================="
echo ""

# 1. Install Alpine dependencies
echo "Step 1: Installing dependencies..."
apk add --no-cache gcompat conntrack-tools || echo "⚠ apk not found, skipping Alpine dependencies"

echo ""

# 2. Install kubectl (The Remote Control)
echo "Step 2: Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    echo "✓ kubectl installed"
else
    echo "✓ kubectl already installed"
fi

echo ""

# 3. Install Minikube (The Cluster)
echo "Step 3: Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64
    echo "✓ Minikube installed"
else
    echo "✓ Minikube already installed"
fi

echo ""
echo "========================================="
echo "Starting Minikube Cluster"
echo "========================================="
echo ""

# Start minikube with Docker driver (using --force as per steps.txt)
minikube start --driver=docker --force

echo ""
echo "========================================="
echo "Cluster Information"
echo "========================================="
echo ""

echo "Cluster Status:"
minikube status

echo ""
echo "Cluster Info:"
kubectl cluster-info

echo ""
echo "Nodes:"
kubectl get nodes

echo ""
echo "✓ Kubernetes cluster is ready!"
echo ""
