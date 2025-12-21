#!/bin/bash

echo "Making all scripts executable..."

chmod +x 1-setup-cluster.sh
chmod +x 2-deploy-app.sh
chmod +x 3-chaos-test.sh
chmod +x run-demo.sh
chmod +x check-status.sh

echo "✓ All scripts are now executable!"
echo ""
echo "You can now run:"
echo "  ./run-demo.sh          - Run the complete demo"
echo "  ./1-setup-cluster.sh   - Only setup Kubernetes"
echo "  ./2-deploy-app.sh      - Only deploy the application"
echo "  ./3-chaos-test.sh      - Only run chaos testing"
echo "  ./check-status.sh      - Check Docker containers status"
