# Kubernetes Demo - NestJS API with Auto-Recovery

This project demonstrates a resilient NestJS API deployed on Kubernetes with automatic pod recovery, high availability, and chaos testing.

## 🚀 Quick Start

### Prerequisites
- Docker installed and running
- macOS or Linux
- Internet connection (for downloading kubectl, minikube, and Docker images)

### One-Command Demo

```bash
chmod +x make-executable.sh && ./make-executable.sh
./run-demo.sh
```

This will:
1. Install kubectl and minikube (if not already installed)
2. Start a Kubernetes cluster
3. Build and deploy the NestJS API with MySQL
4. Run chaos testing to demonstrate auto-recovery

## 📋 Step-by-Step Execution

### Option 1: Run Complete Demo
```bash
./run-demo.sh
```

### Option 2: Run Individual Steps

#### Step 1: Setup Kubernetes Cluster
```bash
./1-setup-cluster.sh
```
- Installs kubectl and minikube
- Starts a local Kubernetes cluster

#### Step 2: Deploy Application
```bash
./2-deploy-app.sh
```
- Builds Docker image for NestJS API
- Deploys MySQL database with persistent storage
- Deploys NestJS API with 3 replicas
- Exposes services

#### Step 3: Chaos Testing
```bash
./3-chaos-test.sh
```
Demonstrates:
- **Single Pod Deletion**: Automatic pod recreation
- **Mass Pod Deletion**: All pods deleted, Kubernetes recreates them
- **DDoS Simulation**: Continuous pod killing while maintaining availability
- **Resource Exhaustion**: Pod restart on failure
- **Scaling**: Horizontal scaling up and down

## 🏗️ Architecture

### Kubernetes Resources

#### NestJS API Deployment
- **Replicas**: 3 pods for high availability
- **Health Checks**: 
  - Liveness probe (restarts unhealthy pods)
  - Readiness probe (controls traffic routing)
- **Resource Limits**: CPU and memory constraints
- **Auto-Recovery**: Pods automatically recreated on failure

#### MySQL Database
- **Persistent Storage**: 1GB PVC for data persistence
- **ConfigMap**: Initialization script with sample data
- **Health Checks**: mysqladmin ping probe
- **Service**: ClusterIP for internal access

### Resilience Features

1. **Self-Healing**: Automatically recreates failed pods
2. **High Availability**: 3 replicas ensure zero downtime
3. **Load Balancing**: Traffic distributed across healthy pods
4. **Health Monitoring**: Probes detect and recover from failures
5. **Resource Management**: Prevents resource exhaustion
6. **Horizontal Scaling**: Easy scaling with `kubectl scale`

## 🔍 Access the Application

### Get Minikube IP
```bash
minikube ip
```

### Access URLs
- **API**: `http://<minikube-ip>:30080`
- **Swagger Docs**: `http://<minikube-ip>:30080/docs`
- **Products**: `http://<minikube-ip>:30080/products`

### Port Forwarding (Alternative)
```bash
kubectl port-forward service/nestjs-api 3000:3000
```
Then access: `http://localhost:3000`

## 🧪 Test API Endpoints

```bash
# Get all products
curl http://$(minikube ip):30080/products

# Get API info
curl http://$(minikube ip):30080

# Access Swagger UI in browser
open http://$(minikube ip):30080/docs
```

## 📊 Monitoring Commands

```bash
# View all pods
kubectl get pods

# View pods with details
kubectl get pods -o wide

# Watch pods in real-time
kubectl get pods -w

# View pod logs
kubectl logs <pod-name>

# View all logs for the app
kubectl logs -l app=nestjs-api

# Describe a pod
kubectl describe pod <pod-name>

# View services
kubectl get services

# View deployments
kubectl get deployments
```

## 🎭 Manual Chaos Testing

### Delete a Single Pod
```bash
kubectl delete pod <pod-name>
# Watch it recreate automatically
kubectl get pods -w
```

### Delete All API Pods
```bash
kubectl delete pods -l app=nestjs-api
# All pods will be recreated
```

### Scale the Deployment
```bash
# Scale up to 5 replicas
kubectl scale deployment nestjs-api --replicas=5

# Scale down to 1 replica
kubectl scale deployment nestjs-api --replicas=1
```

### Simulate High Load
```bash
# Continuously delete random pods
while true; do 
  kubectl delete pod $(kubectl get pods -l app=nestjs-api -o jsonpath='{.items[0].metadata.name}')
  sleep 3
done
```

## 📁 Project Structure

```
nestjs-example-api/
├── k8s/                          # Kubernetes manifests
│   ├── mysql-configmap.yaml      # MySQL init script
│   ├── mysql-deployment.yaml     # MySQL deployment + PVC
│   └── nestjs-deployment.yaml    # NestJS API deployment + service
├── 1-setup-cluster.sh            # Cluster setup script
├── 2-deploy-app.sh               # Application deployment script
├── 3-chaos-test.sh               # Chaos testing script
├── run-demo.sh                   # Master automation script
├── Dockerfile                    # Multi-stage Docker build
├── docker-compose.yml            # Docker Compose (alternative)
└── init-db.sql                   # Database initialization
```

## 🔧 Configuration

### Environment Variables (in nestjs-deployment.yaml)
- `TYPEORM_HOST`: mysql
- `TYPEORM_PORT`: 3306
- `TYPEORM_DATABASE`: testdb
- `TYPEORM_USERNAME`: userdb
- `TYPEORM_PASSWORD`: password

### Replica Count
Edit `k8s/nestjs-deployment.yaml`:
```yaml
spec:
  replicas: 3  # Change this number
```

### Resource Limits
Edit `k8s/nestjs-deployment.yaml`:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 🧹 Cleanup

### Delete All Resources
```bash
kubectl delete -f k8s/
```

### Stop Minikube
```bash
minikube stop
```

### Delete Minikube Cluster
```bash
minikube delete
```

### Remove Docker Images
```bash
docker rmi nestjs-api:v1
```

## 🐛 Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### API Not Accessible
```bash
# Check if pods are ready
kubectl get pods

# Check service
kubectl get svc nestjs-api

# Test from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://nestjs-api:3000
```

### MySQL Connection Issues
```bash
# Check MySQL pod
kubectl get pods -l app=mysql

# Check MySQL logs
kubectl logs -l app=mysql

# Test MySQL connection
kubectl exec -it <mysql-pod-name> -- mysql -u userdb -ppassword testdb
```

## 📚 What You'll Learn

1. **Kubernetes Basics**: Deployments, Services, ConfigMaps, PVCs
2. **High Availability**: Multiple replicas and load balancing
3. **Self-Healing**: Automatic pod recovery
4. **Health Checks**: Liveness and readiness probes
5. **Horizontal Scaling**: Scaling applications
6. **Chaos Engineering**: Testing system resilience
7. **Container Orchestration**: Managing containerized applications

## 🎯 Chaos Testing Scenarios

The `3-chaos-test.sh` script demonstrates:

1. **Single Pod Failure**: Deletes one pod, watches recreation
2. **Mass Deletion**: Deletes all pods simultaneously
3. **DDoS Simulation**: Continuously kills pods for 30 seconds
4. **Resource Exhaustion**: Simulates pod failure due to resource limits
5. **Scale Testing**: Tests scaling from 1 to 5 replicas

All scenarios prove that Kubernetes maintains application availability!

## 📝 Notes

- Minikube runs a single-node cluster (good for development/demo)
- Production would use multi-node clusters (EKS, GKE, AKS, etc.)
- The demo uses `imagePullPolicy: Never` to use local images
- MySQL data persists in a PersistentVolume
- NodePort (30080) is used for easy external access

## 🤝 Contributing

Feel free to modify the scripts and configurations to suit your needs!

## 📄 License

This demo is for educational purposes.
