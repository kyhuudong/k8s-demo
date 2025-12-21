# Kubernetes Demo Scripts

This directory contains scripts for running the NestJS API Kubernetes demo.

## 🚀 Quick Start

```bash
bash run-demo.sh
```

This single script does everything in order.

## 📁 Final Script Structure

### ⭐ Main Script: `run-demo.sh`

**Complete end-to-end automation:**
1. Makes all scripts executable
2. **Step 0** (Optional): Docker cleanup - `docker system prune -f --volumes`
3. **Step 1**: Kubernetes cluster setup
   - Installs Alpine dependencies (if needed)
   - Installs kubectl (if needed)
   - Installs minikube (if needed)
   - Starts Minikube cluster
4. **Step 2**: Calls `./2-deploy-app.sh` (build and deploy)
5. **Step 3**: Calls `./3-chaos-test.sh` (resilience demo)

---

### � Individual Scripts (can run standalone)

#### `2-deploy-app.sh` - Deploy Application

**Prerequisites:** Minikube must be running (will exit with error if not)

**Steps:**
1. Check Minikube status (fail if not running)
2. **Step 1**: Build Docker image (`nestjs-api:v1`)
3. **Step 2**: Load image into Minikube
4. **Step 3**: Deploy MySQL (ConfigMap + Deployment)
5. **Step 4**: Wait for MySQL to be ready (5 min timeout)
6. **Step 5**: Create base NestJS deployment
7. **Step 6**: Expose as NodePort service
8. **Step 7**: Patch deployment with full config (3 replicas)
9. **Step 8**: Set NodePort to 30080
10. **Step 9**: Wait for API pods to be ready

**Usage:**
```bash
# Only if Minikube is already running
bash 2-deploy-app.sh
```

---

#### `3-chaos-test.sh` - Chaos Testing

**Prerequisites:** Application must be deployed

**Demos:**
1. Shows current pod status
2. Tests API availability
3. Scenario 1: Single pod deletion
4. Scenario 2: Multiple pod deletions
5. Scenario 3: Scaling test (scale up/down)
6. Scenario 4 (Optional): High load simulation
7. Final status check

**Usage:**
```bash
# Only if app is already deployed
bash 3-chaos-test.sh
```

---

#### `check-status.sh` - Docker Health Check

**Purpose:** Check Docker Compose container status (not Kubernetes)

**Checks:**
- Container status
- Port bindings
- API endpoint
- Swagger docs
- MySQL health
- Recent logs

**Usage:**
```bash
bash check-status.sh
```

**Note:** This is for Docker Compose setup, not Kubernetes!

---

## 🔄 Workflow Comparison

### Option 1: Complete Demo (Recommended)
```bash
bash run-demo.sh
```
- Does everything from scratch
- Interactive prompts
- Best for first-time setup

### Option 2: Individual Steps
```bash
# Step 1: Setup cluster (manual)
minikube start --driver=docker --force

# Step 2: Deploy app
bash 2-deploy-app.sh

# Step 3: Test resilience
bash 3-chaos-test.sh
```
- More control over each step
- Good for development/debugging

---

## 📊 Consistency Matrix

| Script | Checks Minikube | Starts Minikube | Does Cleanup | Builds Image | Deploys App | Tests App |
|--------|----------------|-----------------|--------------|--------------|-------------|-----------|
| `run-demo.sh` | ✅ | ✅ | ✅ (optional) | ➡️ calls 2 | ➡️ calls 2 | ➡️ calls 3 |
| `2-deploy-app.sh` | ✅ | ❌ (exits if not running) | ❌ | ✅ | ✅ | ❌ |
| `3-chaos-test.sh` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `check-status.sh` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ (Docker) |

---

## 🧹 Cleanup Commands

### Clean Kubernetes Resources
```bash
kubectl delete -f k8s/
kubectl delete deployment nestjs-api
kubectl delete service nestjs-api
```

### Clean Minikube
```bash
minikube delete
```

### Clean Docker
```bash
docker system prune -a -f --volumes
```

### Complete Cleanup
```bash
kubectl delete all --all
minikube delete --all --purge
docker system prune -a -f --volumes
```

---

## ✅ Final File List

**Scripts to KEEP:**
- ✅ `run-demo.sh` - Main automation script
- ✅ `2-deploy-app.sh` - Deploy application
- ✅ `3-chaos-test.sh` - Chaos testing
- ✅ `check-status.sh` - Docker health check

**Scripts REMOVED (integrated into run-demo.sh):**
- ❌ `0-cleanup.sh` - Cleanup functionality now in `run-demo.sh`
- ❌ `1-setup-cluster.sh` - Setup functionality now in `run-demo.sh`
- ❌ `1-setup-cluster-new.sh` - Was duplicate
- ❌ `make-executable.sh` - Chmod functionality now in `run-demo.sh`

---

## 🎯 Consistency Rules

1. **`run-demo.sh`** is the only script that:
   - Installs dependencies
   - Starts Minikube
   - Does Docker cleanup

2. **`2-deploy-app.sh`**:
   - Only builds and deploys
   - Requires Minikube to be running
   - Exits with helpful error if Minikube is not running

3. **`3-chaos-test.sh`**:
   - Only tests resilience
   - Assumes app is deployed
   - No prerequisites checking

4. **`check-status.sh`**:
   - Only for Docker Compose (not K8s)
   - Independent utility

This ensures no duplicate logic and clear separation of concerns!
