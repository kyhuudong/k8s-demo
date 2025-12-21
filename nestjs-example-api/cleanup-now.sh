#!/bin/bash

echo "========================================="
echo "Emergency Docker Cleanup"
echo "Freeing up disk space NOW"
echo "========================================="
echo ""

echo "Current disk usage:"
df -h / | grep -E "Filesystem|/" || df -h | head -2
echo ""

echo "Removing ALL Docker images, containers, volumes, and build cache..."
echo "This will free up maximum space but remove everything."
echo ""

# Stop all containers
docker stop $(docker ps -aq) 2>/dev/null || true

# Remove all containers
docker rm $(docker ps -aq) 2>/dev/null || true

# Remove all images
docker rmi $(docker images -q) -f 2>/dev/null || true

# Prune everything
docker system prune -a -f --volumes 2>/dev/null || true

# Prune build cache
docker builder prune -a -f 2>/dev/null || true

echo ""
echo "✓ Cleanup complete!"
echo ""

echo "New disk usage:"
df -h / | grep -E "Filesystem|/" || df -h | head -2
echo ""

echo "Docker status:"
docker system df
echo ""

echo "You can now run:"
echo "  bash run-demo.sh"
echo "  or"
echo "  bash 2-deploy-app.sh"
