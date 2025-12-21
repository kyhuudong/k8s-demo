#!/bin/bash

set -e

echo "========================================="
echo "Building and Deploying NestJS API"
echo "========================================="
echo ""

# Build Docker image
echo "1. Building Docker image..."
docker build -t nestjs-api:v1 .
echo "✓ Docker image built successfully"
echo ""

# Load image into Minikube
echo "2. Loading image into Minikube..."
minikube image load nestjs-api:v1
echo "✓ Image loaded into Minikube"
echo ""

# Deploy MySQL ConfigMap
echo "3. Deploying MySQL ConfigMap..."
kubectl apply -f k8s/mysql-configmap.yaml
echo "✓ MySQL ConfigMap deployed"
echo ""

# Deploy MySQL
echo "4. Deploying MySQL..."
kubectl apply -f k8s/mysql-deployment.yaml
echo "✓ MySQL deployment and service created"
echo ""

# Wait for MySQL to be ready
echo "5. Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s
echo "✓ MySQL is ready"
echo ""

# Deploy NestJS API
echo "6. Deploying NestJS API..."
kubectl apply -f k8s/nestjs-deployment.yaml
echo "✓ NestJS API deployment and service created"
echo ""

# Wait for API pods to be ready
echo "7. Waiting for NestJS API pods to be ready..."
kubectl wait --for=condition=ready pod -l app=nestjs-api --timeout=120s
echo "✓ NestJS API pods are ready"
echo ""

echo "========================================="
echo "Deployment Status"
echo "========================================="
echo ""

echo "Pods:"
kubectl get pods
echo ""

echo "Services:"
kubectl get services
echo ""

echo "Deployments:"
kubectl get deployments
echo ""

echo "========================================="
echo "Access Information"
echo "========================================="
echo ""

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"
echo "NestJS API URL: http://$MINIKUBE_IP:30080"
echo "Swagger Docs: http://$MINIKUBE_IP:30080/docs"
echo ""

echo "Or use port-forward to access via localhost:"
echo "  kubectl port-forward service/nestjs-api 3000:3000"
echo "  Then access: http://localhost:3000"
echo ""

echo "✓ Deployment complete!"
