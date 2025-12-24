#!/bin/bash

set -e

echo "========================================="
echo "Thank You Frontend - Docker Launcher"
echo "========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found!"
    echo "Please run this script from the frontend directory:"
    echo "  cd frontend"
    echo "  bash start-frontend.sh"
    exit 1
fi

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo "❌ Error: Docker is not running!"
    echo "Please start Docker first."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "========================================="
echo "Starting Frontend in Docker"
echo "========================================="
echo ""

# Build and start the container
echo "Building Docker image..."
docker-compose build

echo ""
echo "Starting container..."
docker-compose up -d

echo ""
echo -e "${GREEN}✓ Frontend is now running in Docker!${NC}"
echo ""

# Get container IP
CONTAINER_ID=$(docker ps -qf "name=k8s-demo-frontend")

echo "========================================="
echo "Access Information"
echo "========================================="
echo ""

echo -e "${CYAN}Local Access:${NC}"
echo "  http://localhost:3000"
echo ""

echo -e "${CYAN}Port Forwarding (for remote access):${NC}"
echo ""
echo "If you're in a remote Docker environment (like Play with Docker):"
echo "  1. The container is exposed on port 3000"
echo "  2. Use your Docker host's IP:3000"
echo "  3. Or use the platform's port forwarding feature"
echo ""

echo -e "${CYAN}Useful Commands:${NC}"
echo "  docker-compose logs -f          # View logs"
echo "  docker-compose stop             # Stop the container"
echo "  docker-compose down             # Stop and remove container"
echo "  docker-compose restart          # Restart the container"
echo ""

echo -e "${YELLOW}Container is running in the background.${NC}"
echo "Press Ctrl+C to return to terminal (container will keep running)"
echo ""

# Show logs
docker-compose logs -f

