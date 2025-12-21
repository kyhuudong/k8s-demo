# Setup Summary - Following steps.txt Pattern

This document explains how the deployment scripts follow the pattern from `steps.txt`.

## Pattern from steps.txt

The original `steps.txt` demonstrates a simple deployment pattern:

```bash
# 1. Build image locally
docker build -t my-custom-v1 .

# 2. Load image into Minikube
minikube image load my-custom-v1

# 3. Create base deployment
kubectl create deployment my-web --image=nginx

# 4. Expose the deployment
kubectl expose deployment my-web --type=NodePort --port=80

# 5. Patch to use custom image with imagePullPolicy: Never
kubectl patch deployment my-web --patch '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "nginx",
          "image": "my-custom-v1",
          "imagePullPolicy": "Never"
        }]
      }
    }
  }
}'

# 6. Access via port-forward
kubectl port-forward --address 0.0.0.0 service/my-web 8080:80
```

## How Our Scripts Follow This Pattern

### 1-setup-cluster.sh

Follows the cluster setup steps from `steps.txt`:

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start --driver=docker --force
```

**Enhancements:**
- Auto-detects macOS vs Linux
- Uses Homebrew on macOS for easier installation
- Configures cluster with 4 CPUs and 4GB RAM

### 2-deploy-app.sh

Follows the **exact same pattern** as steps.txt:

| Step | steps.txt Command | Our Script |
|------|------------------|------------|
| 1 | `docker build -t my-custom-v1 .` | `docker build -t nestjs-api:v1 .` |
| 2 | `minikube image load my-custom-v1` | `minikube image load nestjs-api:v1` |
| 3 | Deploy infrastructure | `kubectl apply -f k8s/mysql-*.yaml` |
| 4 | `kubectl create deployment my-web --image=nginx` | `kubectl create deployment nestjs-api --image=nginx` |
| 5 | `kubectl expose deployment my-web --type=NodePort --port=80` | `kubectl expose deployment nestjs-api --type=NodePort --port=3000` |
| 6 | `kubectl patch deployment my-web ...` | `kubectl patch deployment nestjs-api ...` |
| 7 | `kubectl port-forward ...` | Instructions provided |

**Enhancements in the patch:**
- Sets `replicas: 3` for high availability
- Adds environment variables for database connection
- Includes liveness and readiness probes
- Sets resource limits and requests
- Configures NodePort 30080 for easy access

### 3-chaos-test.sh

**New addition** - Demonstrates Kubernetes resilience features:

1. **Single Pod Deletion** - Shows self-healing
2. **Mass Pod Deletion** - Tests recovery from catastrophic failure
3. **DDoS Simulation** - Continuous pod deletion while monitoring uptime
4. **Resource Exhaustion** - Simulates OOM scenarios
5. **Scale Testing** - Demonstrates horizontal scaling

## Key Differences from steps.txt

While following the same pattern, we've added:

### 1. Database Infrastructure
- MySQL deployment with PersistentVolumeClaim
- ConfigMap for initialization scripts
- Sample product data

### 2. High Availability
- 3 replicas instead of 1
- Health checks (liveness/readiness probes)
- Resource limits

### 3. Production-Ready Configuration
- Environment variable injection
- Proper service discovery (app → mysql)
- Rolling update strategy

### 4. Chaos Engineering
- Automated resilience testing
- Monitoring during failures
- Recovery verification

## Complete Workflow

```bash
# Step 1: Setup cluster (following steps.txt install pattern)
./1-setup-cluster.sh
# → Installs kubectl, minikube
# → Starts cluster with Docker driver

# Step 2: Deploy app (following steps.txt deployment pattern)
./2-deploy-app.sh
# → Build image locally
# → Load into Minikube
# → Deploy MySQL
# → Create base deployment
# → Expose service
# → Patch with custom image and config

# Step 3: Test resilience (new addition)
./3-chaos-test.sh
# → Demonstrates Kubernetes auto-recovery
# → Tests high availability
# → Validates self-healing

# Or run everything at once
./run-demo.sh
```

## Why This Pattern?

The `kubectl create` → `kubectl expose` → `kubectl patch` pattern from steps.txt:

✅ **Educational** - Shows how Kubernetes resources are built incrementally  
✅ **Flexible** - Easy to modify specific parts via patching  
✅ **Transparent** - Each step is visible and understandable  
✅ **Reproducible** - Can be run multiple times safely  

Alternative approach using `kubectl apply -f` is also valid but less educational for learning purposes.

## Access the Application

After deployment:

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Access API
curl http://$MINIKUBE_IP:30080

# Access Swagger docs
open http://$MINIKUBE_IP:30080/docs

# Or use port-forward (like steps.txt)
kubectl port-forward --address 0.0.0.0 service/nestjs-api 8080:3000
curl http://localhost:8080
```

## Verification Commands

```bash
# Check cluster is running
kubectl cluster-info

# Check all resources
kubectl get all

# Check pods
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments

# View pod logs
kubectl logs -l app=nestjs-api

# Test API
curl http://$(minikube ip):30080/products
```

## Cleanup

```bash
# Delete all resources
kubectl delete deployment nestjs-api mysql
kubectl delete service nestjs-api mysql
kubectl delete pvc mysql-pvc
kubectl delete configmap mysql-initdb-config

# Or delete entire cluster
minikube delete
```

---

This setup faithfully follows the **steps.txt pattern** while adding production-ready features and demonstrating Kubernetes resilience capabilities! 🚀
