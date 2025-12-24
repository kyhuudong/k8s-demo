#!/bin/bash

echo "========================================="
echo "Clean Up Stuck Deployment"
echo "========================================="
echo ""

echo "Current pods:"
kubectl get pods
echo ""

echo "Forcefully deleting all NestJS resources..."
kubectl delete deployment nestjs-api --grace-period=0 --force 2>/dev/null || true
kubectl delete service nestjs-api --grace-period=0 --force 2>/dev/null || true
kubectl delete pods -l app=nestjs-api --grace-period=0 --force 2>/dev/null || true
kubectl delete replicaset -l app=nestjs-api --grace-period=0 --force 2>/dev/null || true

echo ""
echo "Waiting for cleanup..."
sleep 5

echo ""
echo "Remaining pods:"
kubectl get pods
echo ""

echo "✓ Cleanup complete!"
echo ""
echo "Now you can re-run:"
echo "  bash 2-deploy-app.sh"
