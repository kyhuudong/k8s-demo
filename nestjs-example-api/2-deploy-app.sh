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

# Fix CoreDNS for Play with Docker environments
echo "Step 4.5: Fixing CoreDNS for restricted environments..."
if kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep -q "CrashLoopBackOff\|Error"; then
    echo "⚠ CoreDNS is failing, applying privileged mode patch..."
    kubectl patch deployment coredns -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/securityContext", "value": {"privileged": true}}]' 2>/dev/null || true
    sleep 5

    # If still failing, use hostAliases workaround
    if kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep -q "CrashLoopBackOff\|Error"; then
        echo "⚠ CoreDNS still failing, will use hostAliases workaround"

        # Get MySQL service ClusterIP
        MYSQL_IP=$(kubectl get svc mysql -o jsonpath='{.spec.clusterIP}')
        echo "  MySQL Service IP: $MYSQL_IP"

        # Update nestjs-deployment.yaml with hostAliases
        if ! grep -q "hostAliases:" k8s/nestjs-deployment.yaml; then
            echo "  Adding hostAliases to NestJS deployment..."
            # Create temporary file with hostAliases injection
            awk -v mysql_ip="$MYSQL_IP" '
                /app: nestjs-api/ { labels_found=1 }
                labels_found && /^    spec:$/ && !done {
                    print $0
                    print "      # Add static host entry to bypass broken CoreDNS in Play with Docker"
                    print "      hostAliases:"
                    print "      - ip: \"" mysql_ip "\""
                    print "        hostnames:"
                    print "        - \"mysql\""
                    done=1
                    next
                }
                { print }
            ' k8s/nestjs-deployment.yaml > k8s/nestjs-deployment.yaml.tmp
            mv k8s/nestjs-deployment.yaml.tmp k8s/nestjs-deployment.yaml
            echo "  ✓ hostAliases added"
        else
            # Update existing hostAliases IP
            awk -v mysql_ip="$MYSQL_IP" '
                /ip: "[0-9.]+"/ && /hostAliases/,/containers:/ {
                    gsub(/ip: "[0-9.]+"/, "ip: \"" mysql_ip "\"")
                }
                { print }
            ' k8s/nestjs-deployment.yaml > k8s/nestjs-deployment.yaml.tmp
            mv k8s/nestjs-deployment.yaml.tmp k8s/nestjs-deployment.yaml
            echo "  ✓ hostAliases IP updated to $MYSQL_IP"
        fi
    else
        echo "✓ CoreDNS is now running"
    fi
else
    echo "✓ CoreDNS is running properly"
fi
echo ""

# Step 5: Deploy NestJS application using kubectl apply
echo "Step 5: Deploying NestJS application..."

# First, clean up any existing deployment completely
if kubectl get deployment nestjs-api &> /dev/null; then
    echo "⚠ Deployment already exists, cleaning up completely..."
    kubectl delete deployment nestjs-api --grace-period=0 --force 2>/dev/null || true
    kubectl delete service nestjs-api --grace-period=0 --force 2>/dev/null || true
    kubectl delete pods -l app=nestjs-api --grace-period=0 --force 2>/dev/null || true
    kubectl delete replicaset -l app=nestjs-api --grace-period=0 --force 2>/dev/null || true
    echo "Waiting for cleanup to complete..."
    sleep 10
    echo "✓ Cleanup complete"
fi

# Apply the NestJS deployment directly (no two-step process)
kubectl apply -f k8s/nestjs-deployment.yaml
echo "✓ NestJS deployment created"
echo ""

# Step 6: Expose the deployment to the network
echo "Step 6: Creating NodePort service..."
if ! kubectl get service nestjs-api &> /dev/null; then
    kubectl expose deployment nestjs-api --type=NodePort --port=3000
    echo "✓ Service created"
else
    echo "✓ Service already exists"
fi
echo ""

# Step 7: Update service to use fixed NodePort 30080
echo "Step 7: Updating service to use fixed NodePort..."
kubectl patch service nestjs-api --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}]'
echo "✓ Service updated with NodePort 30080"
echo ""

# Clean up any old replica sets before waiting
echo "Cleaning up old replica sets..."
kubectl delete replicaset -l app=nestjs-api --field-selector=status.replicas=0 2>/dev/null || true

# Wait for API pods to be ready
echo "Step 8: Waiting for NestJS API pods to be ready..."
echo "Waiting for deployment to stabilize..."
kubectl rollout status deployment/nestjs-api --timeout=180s

echo ""
echo "Verifying all pods are ready..."
kubectl wait --for=condition=ready pod -l app=nestjs-api --timeout=60s --all

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
