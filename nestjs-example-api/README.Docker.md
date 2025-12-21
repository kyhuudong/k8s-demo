# Docker Setup Guide

This guide explains how to run the NestJS application with MySQL using Docker.

## Prerequisites

- Docker installed on your machine
- Docker Compose installed on your machine

## Quick Start

### Option 1: Using Docker Compose (Recommended)

Run both the application and MySQL database together:

```bash
# Build and start all services
docker-compose up --build

# Run in detached mode (background)
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove volumes (this will delete database data)
docker-compose down -v
```

The application will be available at:
- API: http://localhost:3000
- Swagger Documentation: http://localhost:3000/docs

### Option 2: Using Dockerfile Only

If you want to run the application container separately:

```bash
# Build the image
docker build -t nestjs-example-api .

# Run the container (you'll need a separate MySQL instance)
docker run -p 3000:3000 \
  -e TYPEORM_HOST=your-mysql-host \
  -e TYPEORM_PORT=3306 \
  -e TYPEORM_DATABASE=testdb \
  -e TYPEORM_USERNAME=userdb \
  -e TYPEORM_PASSWORD=password \
  nestjs-example-api
```

## Configuration

### Environment Variables

The application supports the following environment variables:

#### Server Configuration
- `HOST`: Server host (default: 0.0.0.0)
- `PORT`: Server port (default: 3000)
- `DOMAIN_URL`: Domain URL (default: http://localhost:3000)

#### Database Configuration
- `TYPEORM_HOST`: MySQL host (default: 127.0.0.1)
- `TYPEORM_PORT`: MySQL port (default: 3306)
- `TYPEORM_DATABASE`: Database name (default: testdb)
- `TYPEORM_USERNAME`: Database username (default: userdb)
- `TYPEORM_PASSWORD`: Database password (default: password)
- `TYPEORM_LOGGING`: Enable SQL logging (default: false)

### Modifying docker-compose.yml

You can modify the `docker-compose.yml` file to change:
- Database credentials
- Port mappings
- Volume configurations
- Network settings

## Docker Commands Cheat Sheet

```bash
# Build images
docker-compose build

# Start services
docker-compose up

# Start services in background
docker-compose up -d

# Stop services
docker-compose stop

# Remove containers
docker-compose down

# View running containers
docker-compose ps

# View logs
docker-compose logs

# Follow logs
docker-compose logs -f

# Execute command in running container
docker-compose exec app sh

# Access MySQL CLI
docker-compose exec mysql mysql -u userdb -p testdb
```

## Troubleshooting

### Application can't connect to database

Make sure the MySQL container is healthy before the app starts. The docker-compose configuration includes a health check for this.

### Port already in use

If port 3000 or 3306 is already in use, modify the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "3001:3000"  # Maps host port 3001 to container port 3000
```

### Database data persistence

The MySQL data is stored in a Docker volume named `mysql_data`. To reset the database:

```bash
docker-compose down -v
```

## Production Considerations

For production deployment:

1. Use environment-specific configurations
2. Enable SSL/TLS for database connections
3. Use secrets management for sensitive data
4. Set `synchronize: false` in production (already configured)
5. Implement proper logging and monitoring
6. Use a process manager or orchestration tool (Kubernetes, etc.)
