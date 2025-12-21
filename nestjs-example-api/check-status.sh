#!/bin/bash

echo "========================================="
echo "Docker Containers Health Check"
echo "========================================="
echo ""

echo "1. Container Status:"
echo "-------------------"
docker-compose ps
echo ""

echo "2. Port Bindings:"
echo "----------------"
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep -E "nestjs-app|nestjs-mysql|NAMES"
echo ""

echo "3. Testing API Endpoint:"
echo "-----------------------"
if curl -s http://localhost:3000 > /dev/null; then
    echo "✓ API is responding on http://localhost:3000"
else
    echo "✗ API is NOT responding on http://localhost:3000"
fi
echo ""

echo "4. Testing Swagger Documentation:"
echo "--------------------------------"
if curl -s http://localhost:3000/docs > /dev/null; then
    echo "✓ Swagger is accessible at http://localhost:3000/docs"
else
    echo "✗ Swagger is NOT accessible"
fi
echo ""

echo "5. MySQL Container Health:"
echo "-------------------------"
MYSQL_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' nestjs-mysql 2>/dev/null)
if [ "$MYSQL_HEALTH" = "healthy" ]; then
    echo "✓ MySQL is healthy"
else
    echo "⚠ MySQL status: $MYSQL_HEALTH"
fi
echo ""

echo "6. Recent App Logs (last 10 lines):"
echo "----------------------------------"
docker-compose logs --tail=10 app
echo ""

echo "========================================="
echo "Health Check Complete!"
echo "========================================="
