#!/bin/bash

echo "========================================="
echo "Docker & Minikube Cleanup"
echo "========================================="
echo ""

echo "This will remove:"
echo "  - Unused Docker containers"
echo "  - Unused Docker images"
echo "  - Unused Docker volumes"
echo "  - Unused Docker build cache"
echo "  - Minikube cache (optional)"
echo ""

read -p "Do you want to continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Step 1: Cleaning Docker system..."
docker system prune -a -f --volumes
echo "✓ Docker cleanup complete"
echo ""

echo "Step 2: Checking disk usage..."
echo ""
echo "Docker disk usage:"
docker system df
echo ""

read -p "Do you want to clean Minikube cache as well? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Step 3: Cleaning Minikube cache..."
    minikube delete --all --purge 2>/dev/null || true
    echo "✓ Minikube cleanup complete"
    echo ""
    echo "⚠ You'll need to run 1-setup-cluster.sh again to recreate the cluster"
fi

echo ""
echo "========================================="
echo "Cleanup Complete!"
echo "========================================="
echo ""
echo "Available disk space:"
df -h | grep -E "Filesystem|/System/Volumes/Data" || df -h | head -2
echo ""
