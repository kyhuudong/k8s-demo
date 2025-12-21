# Build stage
FROM node:16-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with relaxed settings
RUN npm install --legacy-peer-deps --no-optional || npm install --force --no-optional

# Copy source code and configuration files
COPY . .

# Build the application
RUN npm run build

# Verify build output
RUN ls -la dist/ && test -f dist/src/main.js || (echo "Build failed" && exit 1)

# Production stage
FROM node:16-alpine

WORKDIR /app

ENV NODE_ENV=production

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm install --production --legacy-peer-deps --no-optional || npm install --production --force --no-optional

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

