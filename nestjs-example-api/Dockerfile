# Build stage
FROM node:16-alpine AS builder

WORKDIR /app

# Install build dependencies for native modules
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./

# Clean npm cache and install dependencies
RUN npm cache clean --force && \
    npm install --legacy-peer-deps --no-optional || \
    npm install --force --no-optional

# Copy source code and configuration files
COPY . .

# Build the application
RUN npm run build

# Verify build output
RUN ls -la dist/ && \
    test -f dist/src/main.js || \
    (echo "Build failed: main.js not found" && exit 1)

# Production stage
FROM node:16-alpine

WORKDIR /app

# Set NODE_ENV to production
ENV NODE_ENV=production

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm cache clean --force && \
    npm install --production --legacy-peer-deps --no-optional || \
    npm install --production --force --no-optional

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/environments ./environments

# Expose the application port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD node -e "require('http').get('http://localhost:3000', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Start the application
CMD ["node", "dist/src/main.js"]

