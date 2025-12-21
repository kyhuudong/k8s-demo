#!/bin/bash

set -e

echo "========================================="
echo "Kubernetes Cluster Setup"
echo "========================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "✓ Detected macOS"

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "✗ Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "✓ Homebrew is already installed"
    fi

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        brew install kubectl
    else
        echo "✓ kubectl is already installed ($(kubectl version --client --short 2>/dev/null || kubectl version --client))"
    fi

    # Install minikube
    if ! command -v minikube &> /dev/null; then
        echo "Installing minikube..."
        brew install minikube
    else
        echo "✓ minikube is already installed ($(minikube version --short))"
    fi

else
    # Linux installation
    echo "✓ Detected Linux"

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    else
        echo "✓ kubectl is already installed ($(kubectl version --client --short 2>/dev/null || kubectl version --client))"
    fi

    # Install minikube
    if ! command -v minikube &> /dev/null; then
        echo "Installing minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm minikube-linux-amd64
    else
        echo "✓ minikube is already installed ($(minikube version --short))"
    fi
fi

echo ""
echo "========================================="
echo "Starting Minikube Cluster"
echo "========================================="
echo ""

# Check if minikube is already running
if minikube status &> /dev/null; then
    echo "⚠ Minikube is already running"
    read -p "Do you want to delete and recreate the cluster? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        minikube delete
        echo "Starting fresh Minikube cluster with Docker driver..."
        minikube start --driver=docker --cpus=4 --memory=4096
    else
        echo "Using existing cluster..."
    fi
else
    echo "Starting Minikube cluster with Docker driver..."
    minikube start --driver=docker --cpus=4 --memory=4096
fi

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
