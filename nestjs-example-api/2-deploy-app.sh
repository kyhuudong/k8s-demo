#!/bin/bash

set -e

echo "========================================="
echo "Building and Deploying NestJS API"
echo "========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo "❌ Error: Docker is not running!"
    echo ""
    echo "Please start Docker Desktop or Docker daemon first."
    echo ""
    exit 1
fi
echo "✓ Docker is running"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed!"
    echo ""
    echo "Please run the complete demo first:"
    echo "  bash run-demo.sh"
    echo ""
    exit 1
fi
echo "✓ kubectl is installed"

# Check if Minikube is running (required)
if ! minikube status &> /dev/null; then
    echo "❌ Error: Minikube is not running!"
    echo ""
    echo "Please start Minikube first:"
    echo "  minikube start --driver=docker --force"
    echo ""
    echo "Or run the complete demo:"
    echo "  bash run-demo.sh"
    echo ""
    exit 1
fi
echo "✓ Minikube is running"
echo ""

# Aggressive cleanup to free disk space
echo "Freeing up disk space..."
echo "This may take a moment..."
docker system prune -a -f --volumes 2>/dev/null || true
docker builder prune -a -f 2>/dev/null || true
echo "✓ Cleanup complete"
echo ""

# Step 1: Build the Docker image locally
echo "Step 1: Building Docker image..."
docker build -t nestjs-api:v1 .
echo "✓ Docker image built successfully"
echo ""
echo ""

# Step 2: Load the image into Minikube
echo "Step 2: Loading image into Minikube..."
minikube image load nestjs-api:v1
echo "✓ Image loaded into Minikube"
echo ""

# Step 3: Deploy MySQL using manifests (infrastructure first)
echo "Step 3: Deploying MySQL database..."
kubectl apply -f k8s/mysql-configmap.yaml
kubectl apply -f k8s/mysql-deployment.yaml
echo "✓ MySQL ConfigMap and Deployment applied"
echo ""

# Step 4: Wait for MySQL to be ready
echo "Step 4: Waiting for MySQL to be ready..."
echo "This may take a minute while MySQL initializes..."
if ! kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s; then
    echo "⚠ MySQL pod failed to become ready. Checking pod status..."
    kubectl get pods -l app=mysql
    echo ""
    echo "Pod logs:"
    kubectl logs -l app=mysql --tail=50 || true
    echo ""
    echo "❌ MySQL deployment failed. Please check the logs above."
    exit 1
fi
echo "✓ MySQL is ready"
echo ""

# Step 5: Create base NestJS deployment (using kubectl create)
echo "Step 5: Creating base NestJS deployment..."
if kubectl get deployment nestjs-api &> /dev/null; then
    echo "⚠ Deployment already exists, deleting first..."
    kubectl delete deployment nestjs-api
    kubectl delete service nestjs-api 2>/dev/null || true
    sleep 5
fi

kubectl create deployment nestjs-api --image=nginx
echo "✓ Base deployment created"
echo ""

# Step 6: Expose the deployment to the network
echo "Step 6: Exposing deployment as NodePort service..."
kubectl expose deployment nestjs-api --type=NodePort --port=3000
echo "✓ Service created"
echo ""

# Step 7: Patch to use our custom image and configuration
echo "Step 7: Patching deployment to use NestJS image with full configuration..."
kubectl patch deployment nestjs-api --patch '{
  "spec": {
    "replicas": 3,
    "template": {
      "spec": {
        "containers": [{
          "name": "nginx",
          "image": "nestjs-api:v1",
          "imagePullPolicy": "Never",
          "ports": [{
            "containerPort": 3000,
            "name": "http"
          }],
          "env": [
            {"name": "HOST", "value": "0.0.0.0"},
            {"name": "PORT", "value": "3000"},
            {"name": "DOMAIN_URL", "value": "http://localhost:3000"},
            {"name": "TYPEORM_HOST", "value": "mysql"},
            {"name": "TYPEORM_PORT", "value": "3306"},
            {"name": "TYPEORM_DATABASE", "value": "testdb"},
            {"name": "TYPEORM_USERNAME", "value": "userdb"},
            {"name": "TYPEORM_PASSWORD", "value": "password"},
            {"name": "TYPEORM_LOGGING", "value": "false"},
            {"name": "TYPEORM_SYNCHRONIZE", "value": "true"}
          ],
          "livenessProbe": {
            "httpGet": {
              "path": "/",
              "port": 3000
            },
            "initialDelaySeconds": 30,
            "periodSeconds": 10,
            "timeoutSeconds": 5,
            "failureThreshold": 3
          },
          "readinessProbe": {
            "httpGet": {
              "path": "/",
              "port": 3000
            },
            "initialDelaySeconds": 10,
            "periodSeconds": 5,
            "timeoutSeconds": 3,
            "failureThreshold": 3
          },
          "resources": {
            "requests": {
              "memory": "256Mi",
              "cpu": "250m"
            },
            "limits": {
              "memory": "512Mi",
              "cpu": "500m"
            }
          }
        }]
      }
    }
  }
}'
echo "✓ Deployment patched with NestJS configuration"
echo ""

# Step 8: Patch the service to use nodePort 30080
echo "Step 8: Updating service to use fixed NodePort..."
kubectl patch service nestjs-api --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}]'
echo "✓ Service updated with NodePort 30080"
echo ""

# Wait for API pods to be ready
echo "Step 9: Waiting for NestJS API pods to be ready..."
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
echo "Products API: http://$MINIKUBE_IP:30080/products"
echo ""

echo "Or use port-forward to access via localhost:"
echo "  kubectl port-forward --address 0.0.0.0 service/nestjs-api 8080:3000"
echo "  Then access: http://localhost:8080"
echo ""

echo "✓ Deployment complete!"
