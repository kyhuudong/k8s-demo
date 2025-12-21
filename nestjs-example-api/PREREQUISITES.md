# Prerequisites & System Requirements

This document lists all prerequisites needed to run the Kubernetes demo.

## 🔧 Required Software

### 1. Docker (REQUIRED)

**What it does:** Builds container images and runs Minikube

**Check if installed:**
```bash
docker --version
docker ps
```

**Installation:**
- **macOS:** [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- **Windows:** [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- **Linux:** [Docker Engine](https://docs.docker.com/engine/install/)

**Verify it's running:**
```bash
docker ps
# Should show running containers or empty list (not an error)
```

---

### 2. curl (REQUIRED)

**What it does:** Downloads kubectl and minikube installers

**Check if installed:**
```bash
curl --version
```

**Installation:**
- **macOS:** `brew install curl` (usually pre-installed)
- **Alpine Linux:** `apk add curl`
- **Ubuntu/Debian:** `apt-get install curl`
- **RHEL/CentOS:** `yum install curl`

---

### 3. kubectl (AUTO-INSTALLED)

**What it does:** Kubernetes command-line tool

**Installation:** 
- ✅ Automatically installed by `run-demo.sh`
- ✅ Automatically installed by `2-deploy-app.sh` if missing

**Manual installation (if needed):**
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
```

---

### 4. Minikube (AUTO-INSTALLED)

**What it does:** Local Kubernetes cluster

**Installation:** 
- ✅ Automatically installed by `run-demo.sh`

**Manual installation (if needed):**
```bash
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
```

---

## 💾 System Requirements

### Minimum Requirements
- **CPU:** 2 cores
- **RAM:** 4 GB
- **Disk Space:** 20 GB free
- **OS:** macOS, Linux, or Windows with WSL2

### Recommended Requirements
- **CPU:** 4 cores or more
- **RAM:** 8 GB or more
- **Disk Space:** 40 GB free
- **Docker:** Latest stable version

---

## 🚫 What You DON'T Need

### ❌ Node.js (NOT REQUIRED on host)
- Node.js is **inside the Docker container**
- The Dockerfile handles all Node.js dependencies
- You don't need to install Node.js on your machine
- You don't need to run `npm install` manually

### ❌ MySQL (NOT REQUIRED on host)
- MySQL runs **inside Kubernetes**
- Deployed automatically by the scripts
- No need to install MySQL locally

### ❌ NestJS CLI (NOT REQUIRED)
- All NestJS commands run **inside Docker**
- No need to install `@nestjs/cli` globally

---

## ✅ Pre-flight Checklist

Before running `run-demo.sh`, verify:

```bash
# 1. Docker is installed and running
docker --version
docker ps

# 2. curl is installed
curl --version

# 3. Sufficient disk space
df -h

# 4. (Optional) Check current containers
docker ps -a

# 5. (Optional) Clean up if needed
docker system df
```

---

## 🔍 What Gets Installed Automatically

When you run `bash run-demo.sh`:

1. ✅ **kubectl** - If not already installed
2. ✅ **minikube** - If not already installed
3. ✅ **Kubernetes cluster** - Started via Minikube
4. ✅ **Node.js dependencies** - Inside Docker container during build
5. ✅ **MySQL database** - Inside Kubernetes cluster
6. ✅ **NestJS application** - Inside Kubernetes pods

---

## 🐛 Troubleshooting

### "Docker is not running"
```bash
# macOS: Start Docker Desktop app
open -a Docker

# Linux: Start Docker daemon
sudo systemctl start docker
```

### "Disk quota exceeded"
```bash
# Clean up Docker
docker system prune -a -f --volumes

# Or use our cleanup option in run-demo.sh
bash run-demo.sh
# Select 'y' when asked about cleanup
```

### "Minikube won't start"
```bash
# Delete and recreate
minikube delete
minikube start --driver=docker --force

# Check Docker has enough resources
# Docker Desktop → Settings → Resources
# Increase CPU to 4 and Memory to 8GB
```

### "Command not found: kubectl"
```bash
# Install manually
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

---

## 📋 Platform-Specific Notes

### macOS (Apple Silicon M1/M2/M3)
- ✅ Fully supported
- Uses `platform: linux/amd64` for MySQL compatibility
- Docker Desktop required (not Docker Engine)

### macOS (Intel)
- ✅ Fully supported
- Docker Desktop required

### Linux
- ✅ Fully supported
- Can use Docker Desktop or Docker Engine
- May need to add user to docker group: `sudo usermod -aG docker $USER`

### Windows
- ⚠️ Use WSL2 (Windows Subsystem for Linux)
- Install Docker Desktop for Windows
- Run scripts inside WSL2 terminal

### Alpine Linux
- ✅ Supported with additional packages
- Script auto-installs: `gcompat` and `conntrack-tools`

---

## 🎯 Quick Start (If All Prerequisites Met)

If you already have Docker running:

```bash
cd nestjs-example-api
bash run-demo.sh
```

That's it! Everything else is automated.
