# Chaos Test Scripts - Summary

## Overview
Two chaos engineering test scripts for demonstrating Kubernetes high availability and resilience:

1. **3-chaos-test.sh** - Pod Failure & Self-Healing Test
2. **4-chaos-test.sh** - Zero-Downtime Rolling Update Test

## Recent Improvements

### ✅ Fixed Issues
- **Total Request Count Bug**: Fixed the temp file handling that caused "total requests = 0"
  - Changed from `$$` to unique temp file identifier `TEMP_FILE_ID`
  - Added proper file synchronization with `sleep 1` after background processes
  - Added debug output to verify file creation and content

- **Faster Execution**: Reduced test duration for quicker demos
  - Test 3: 45 seconds (down from 90s)
  - Test 4: 60 seconds for rolling update
  - Fewer recovery checks (6 instead of 10)
  - Shorter intervals (5s instead of 8s)

- **Better API Validation**: Integrated comprehensive endpoint testing
  - Tests root endpoint `/`
  - Tests `/products` endpoint specifically
  - Runs quick load test (10 requests)
  - Shows success rate before starting chaos test

## Script Features

### 3-chaos-test.sh - Pod Failure Test
**Duration**: ~45 seconds

**What it does**:
1. Starts continuous API traffic (3 workers, ~6 RPS)
2. Kills one pod forcefully
3. Monitors auto-recovery
4. Measures uptime and success rate

**Key Metrics**:
- API Uptime percentage (health checks every second)
- Request success rate (actual API calls)
- Expected: 99%+ uptime

### 4-chaos-test.sh - Rolling Update Test
**Duration**: ~60 seconds

**What it does**:
1. Starts continuous API traffic
2. Triggers rolling update (via annotation)
3. Monitors pod replacement
4. Verifies zero downtime

**Key Metrics**:
- API Uptime percentage during update
- Request success rate
- Expected: 99.5%+ uptime (true zero downtime)

## Configuration

Both scripts have configurable parameters at the top:

```bash
DURATION=45                 # Total test duration
CONCURRENT_WORKERS=3        # Parallel traffic generators
REQUESTS_PER_WORKER=2       # Requests per second per worker
STABILIZATION_TIME=5        # Wait before introducing chaos
RECOVERY_CHECKS=6           # Number of status checks
RECOVERY_CHECK_INTERVAL=5   # Seconds between checks
```

## Usage

```bash
# Make scripts executable
chmod +x 3-chaos-test.sh 4-chaos-test.sh

# Run pod failure test
./3-chaos-test.sh

# Run rolling update test
./4-chaos-test.sh
```

## Prerequisites

Both scripts check for required tools:
- kubectl
- minikube
- curl
- bc

## Output

Each script provides:
- Color-coded output (green=success, red=failure, yellow=warning)
- Live traffic indicators (. = success, x = failure)
- Real-time pod status updates
- Comprehensive results summary
- Next steps for exploration

## Debug Information

If requests still show 0, check:
1. Temp file is being created: Look for debug output showing file path
2. File contents: Debug output shows what's written to the file
3. Background processes: Verify workers are actually running

## Kubernetes Concepts Demonstrated

### Test 3 - Pod Failure
- ✅ Self-healing
- ✅ High availability
- ✅ Load balancing
- ✅ Automatic recovery
- ✅ Zero downtime

### Test 4 - Rolling Update
- ✅ Rolling update strategy
- ✅ Zero downtime deployment
- ✅ MaxSurge/MaxUnavailable
- ✅ Health checks
- ✅ Gradual traffic shifting
