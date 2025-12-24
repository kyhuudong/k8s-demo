# K8s Demo - Thank You Page

A simple React frontend to thank your audience after the Kubernetes demo.

## Features

- Beautiful gradient background
- Animated Kubernetes logo
- Summary of demo highlights
- Responsive design
- Smooth animations

## How to Run (Docker - Recommended)

1. Make sure Docker is running

2. Run the startup script:
   ```bash
   cd frontend
   bash start-frontend.sh
   ```

3. Access at http://localhost:3000

4. To stop:
   ```bash
   docker-compose down
   ```

## How to Run (Local Development)

1. Install dependencies:
   ```bash
   cd frontend
   npm install
   ```

2. Start the development server:
   ```bash
   npm start
   ```

3. Open http://localhost:3000 in your browser

## Port Forwarding

If you're running in a remote Docker environment (like Play with Docker):

1. The container exposes port 3000
2. Use your Docker host's port forwarding feature
3. Or access via the platform's built-in port mapping

Example for Play with Docker:
- Click on the "3000" button that appears at the top
- Or use the generated URL

## Build for Production

```bash
npm run build
```

The optimized production build will be in the `build/` folder.

## What's Displayed

- "Thank You for Listening" message
- Kubernetes logo (spinning animation)
- Summary of demo features:
  - Self-Healing Pods
  - Automatic Load Balancing
  - Zero-Downtime Deployments
  - Auto-Recovery from Failures

