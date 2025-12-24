#!/bin/bash

echo "========================================="
echo "Minikube Complete Cleanup & Restart"
echo "========================================="
echo ""

echo "⚠️  WARNING: This will delete your Minikube cluster completely!"
echo "All deployments, pods, and data will be lost."
echo ""
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Step 1: Stopping Minikube..."
minikube stop 2>/dev/null || true

echo ""
echo "Step 2: Deleting Minikube cluster (this frees up space)..."
minikube delete --all --purge

echo ""
echo "Step 3: Cleaning up Docker on host..."
docker system prune -a -f --volumes 2>/dev/null || true
docker builder prune -a -f 2>/dev/null || true

echo ""
echo "Step 4: Starting fresh Minikube with more disk space..."
echo "Allocating 40GB disk space, 4 CPUs, 8GB RAM..."
minikube start --driver=docker --force \
    --disk-size=40g \
    --cpus=4 \
    --memory=8192 \
    --delete-on-failure

echo ""
echo "Step 5: Verifying Minikube status..."
minikube status

echo ""
echo "✓ Minikube cleanup and restart complete!"
echo ""
echo "Disk space in Minikube:"
minikube ssh "df -h /"

echo ""
echo "You can now run:"
echo "  bash 2-deploy-app.sh"
echo ""
