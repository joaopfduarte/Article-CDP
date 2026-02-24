#!/bin/bash
#
# Manual NiFi and Hive Service Initialization Script
# This script bypasses the NiFi encrypt-config.sh interactive password issue
# by configuring NiFi directly and using Ambari REST API to start services
#

set -e

# Configuration
AMBARI_USER="admin"
AMBARI_PASS="admin"
AMBARI_HOST="localhost"
AMBARI_PORT="8080"
CLUSTER_NAME="odp-cluster"
AMBARI_URL="http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1"
NIFI_NODE="node1.cdp"
NIFI_SENSITIVE_KEY="Ambari1234567"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to call Ambari REST API
ambari_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -u "${AMBARI_USER}:${AMBARI_PASS}" \
             -H "X-Requested-By: ambari" \
             -X "${method}" \
             -d "${data}" \
             "${AMBARI_URL}${endpoint}"
    else
        curl -s -u "${AMBARI_USER}:${AMBARI_PASS}" \
             -H "X-Requested-By: ambari" \
             -X "${method}" \
             "${AMBARI_URL}${endpoint}"
    fi
}

# Function to get service state
get_service_state() {
    local service=$1
    ambari_api GET "/clusters/${CLUSTER_NAME}/services/${service}" | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['ServiceInfo']['state'])" 2>/dev/null || echo "UNKNOWN"
}

# Function to wait for service state
wait_for_service_state() {
    local service=$1
    local expected_state=$2
    local max_attempts=${3:-60}
    local attempt=0
    
    log_info "Waiting for ${service} to reach ${expected_state} state..."
    
    while [ $attempt -lt $max_attempts ]; do
        local current_state=$(get_service_state "$service")
        log_info "${service} current state: ${current_state}"
        
        if [ "$current_state" == "$expected_state" ]; then
            log_info "${service} reached ${expected_state} state"
            return 0
        fi
        
        sleep 10
        attempt=$((attempt + 1))
    done
    
    log_error "Timeout waiting for ${service} to reach ${expected_state}"
    return 1
}

# Main execution
log_info "=========================================="
log_info "Manual NiFi and Hive Initialization"
log_info "=========================================="

# Step 1: Configure NiFi on node1.cdp using the WORKING approach
log_info "Step 1: Configuring NiFi on ${NIFI_NODE}..."

# Generate a consistent 256-bit hex key (64 hex chars = 32 bytes) using SHA-256
NIFI_HEX_KEY=$(echo -n "Ambari1234567" | sha256sum | awk '{print $1}')
NIFI_ALGORITHM="NIFI_PBKDF2_AES_GCM_256"

log_info "Using SHA-256 derived hex key for NiFi encryption..."
log_info "Key length: ${#NIFI_HEX_KEY} characters"
log_info "Algorithm: ${NIFI_ALGORITHM}"

ssh -o StrictHostKeyChecking=no "opc@${NIFI_NODE}" sudo bash <<EOF
set -e

# Variables
NIFI_HEX_KEY="${NIFI_HEX_KEY}"
NIFI_ALGORITHM="${NIFI_ALGORITHM}"
NIFI_CONFIG_DIR="/usr/odp/current/nifi/conf"
BOOTSTRAP_CONF="\${NIFI_CONFIG_DIR}/bootstrap.conf"
NIFI_PROPS="\${NIFI_CONFIG_DIR}/nifi.properties"

echo "Step 1.1: Backing up NiFi configuration files..."
if [ -f "\${BOOTSTRAP_CONF}" ]; then
    cp "\${BOOTSTRAP_CONF}" "\${BOOTSTRAP_CONF}.backup.\$(date +%Y%m%d_%H%M%S)"
fi
if [ -f "\${NIFI_PROPS}" ]; then
    cp "\${NIFI_PROPS}" "\${NIFI_PROPS}.backup.\$(date +%Y%m%d_%H%M%S)"
fi

echo "Step 1.2: Stopping NiFi (if running)..."
systemctl stop nifi 2>/dev/null || /usr/odp/current/nifi/bin/nifi.sh stop 2>/dev/null || true
sleep 3

echo "Step 1.3: Configuring bootstrap.conf with hex key..."
# Configure bootstrap.conf with the CORRECT property name
if ! grep -q "nifi.bootstrap.sensitive.key=" "\${BOOTSTRAP_CONF}"; then
    echo "nifi.bootstrap.sensitive.key=\${NIFI_HEX_KEY}" >> "\${BOOTSTRAP_CONF}"
    echo "✓ Added nifi.bootstrap.sensitive.key"
else
    sed -i "s|^nifi.bootstrap.sensitive.key=.*|nifi.bootstrap.sensitive.key=\${NIFI_HEX_KEY}|" "\${BOOTSTRAP_CONF}"
    echo "✓ Updated nifi.bootstrap.sensitive.key"
fi

# Set the protection algorithm
if ! grep -q "nifi.bootstrap.protection.algorithm=" "\${BOOTSTRAP_CONF}"; then
    echo "nifi.bootstrap.protection.algorithm=\${NIFI_ALGORITHM}" >> "\${BOOTSTRAP_CONF}"
    echo "✓ Added protection algorithm"
else
    sed -i "s|^nifi.bootstrap.protection.algorithm=.*|nifi.bootstrap.protection.algorithm=\${NIFI_ALGORITHM}|" "\${BOOTSTRAP_CONF}"
    echo "✓ Updated protection algorithm"
fi

echo "Step 1.4: Configuring nifi.properties..."
# Configure nifi.properties with the correct algorithm
if ! grep -q "nifi.sensitive.props.algorithm=" "\${NIFI_PROPS}"; then
    echo "nifi.sensitive.props.algorithm=\${NIFI_ALGORITHM}" >> "\${NIFI_PROPS}"
    echo "✓ Added props algorithm"
else
    sed -i "s|^nifi.sensitive.props.algorithm=.*|nifi.sensitive.props.algorithm=\${NIFI_ALGORITHM}|" "\${NIFI_PROPS}"
    echo "✓ Updated props algorithm"
fi

# Set provider to BC (BouncyCastle)
if ! grep -q "nifi.sensitive.props.provider=" "\${NIFI_PROPS}"; then
    echo "nifi.sensitive.props.provider=BC" >> "\${NIFI_PROPS}"
    echo "✓ Added BC provider"
else
    sed -i "s|^nifi.sensitive.props.provider=.*|nifi.sensitive.props.provider=BC|" "\${NIFI_PROPS}"
    echo "✓ Updated BC provider"
fi

echo "Step 1.5: Setting correct ownership and permissions..."
chown -R nifi:nifi "\${NIFI_CONFIG_DIR}/"
chmod 600 "\${BOOTSTRAP_CONF}"
chmod 600 "\${NIFI_PROPS}"

echo "Step 1.6: Starting NiFi via systemctl..."
systemctl start nifi 2>/dev/null || /usr/odp/current/nifi/bin/nifi.sh start 2>/dev/null || true

echo "Step 1.7: Waiting for NiFi to initialize (30 seconds)..."
sleep 30

# Check if NiFi process is running
if pgrep -f "org.apache.nifi.NiFi" >/dev/null 2>&1; then
    echo "✓ NiFi process is running"
else
    echo "⚠ WARNING: NiFi process not detected yet"
fi

echo "✓ NiFi configuration completed successfully"
EOF

if [ $? -eq 0 ]; then
    log_info "✓ NiFi configuration on ${NIFI_NODE} completed successfully"
else
    log_error "✗ Failed to configure NiFi on ${NIFI_NODE}"
    exit 1
fi

# Give NiFi more time to fully start
log_info "Waiting additional 30 seconds for NiFi to fully start..."
sleep 30

# Step 2: Check and fix NiFi service state in Ambari
log_info "Step 2: Checking NiFi service state..."

NIFI_STATE=$(get_service_state "NIFI")
log_info "Current NiFi state: ${NIFI_STATE}"

if [ "$NIFI_STATE" == "INSTALL_FAILED" ] || [ "$NIFI_STATE" == "UNKNOWN" ]; then
    log_warn "NiFi is in ${NIFI_STATE} state, forcing to INSTALLED state..."
    
    # Force service to INSTALLED state
    ambari_api PUT "/clusters/${CLUSTER_NAME}/services/NIFI" \
        '{"RequestInfo":{"context":"Manual NiFi Recovery - Force INSTALLED"},"Body":{"ServiceInfo":{"state":"INSTALLED"}}}'
    
    sleep 5
    wait_for_service_state "NIFI" "INSTALLED" 30
fi

# Step 3: Start NiFi service
log_info "Step 3: Starting NiFi service..."

if [ "$NIFI_STATE" != "STARTED" ]; then
    log_info "Sending START request to NiFi..."
    
    RESPONSE=$(ambari_api PUT "/clusters/${CLUSTER_NAME}/services/NIFI" \
        '{"RequestInfo":{"context":"Manual NiFi Start"},"Body":{"ServiceInfo":{"state":"STARTED"}}}')
    
    REQUEST_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['Requests']['id'])" 2>/dev/null || echo "")
    
    if [ -n "$REQUEST_ID" ]; then
        log_info "NiFi start request submitted (Request ID: ${REQUEST_ID})"
        
        # Wait for NiFi to start
        wait_for_service_state "NIFI" "STARTED" 120
        
        if [ $? -eq 0 ]; then
            log_info "✓ NiFi started successfully!"
        else
            log_error "✗ NiFi failed to start within timeout"
            log_warn "Check NiFi logs on ${NIFI_NODE}: /var/log/nifi/nifi-app.log"
            exit 1
        fi
    else
        log_error "Failed to submit NiFi start request"
        exit 1
    fi
else
    log_info "✓ NiFi is already in STARTED state"
fi

# Step 4: Start Hive service
log_info "Step 4: Starting Hive service..."

HIVE_STATE=$(get_service_state "HIVE")
log_info "Current Hive state: ${HIVE_STATE}"

if [ "$HIVE_STATE" != "STARTED" ]; then
    log_info "Sending START request to Hive..."
    
    RESPONSE=$(ambari_api PUT "/clusters/${CLUSTER_NAME}/services/HIVE" \
        '{"RequestInfo":{"context":"Manual Hive Start"},"Body":{"ServiceInfo":{"state":"STARTED"}}}')
    
    REQUEST_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['Requests']['id'])" 2>/dev/null || echo "")
    
    if [ -n "$REQUEST_ID" ]; then
        log_info "Hive start request submitted (Request ID: ${REQUEST_ID})"
        
        # Wait for Hive to start
        wait_for_service_state "HIVE" "STARTED" 120
        
        if [ $? -eq 0 ]; then
            log_info "✓ Hive started successfully!"
        else
            log_error "✗ Hive failed to start within timeout"
            log_warn "Check Hive logs on node1.cdp: /var/log/hive/"
            exit 1
        fi
    else
        log_error "Failed to submit Hive start request"
        exit 1
    fi
else
    log_info "✓ Hive is already in STARTED state"
fi

# Step 5: Final verification
log_info "Step 5: Final verification..."

log_info "Service Status Summary:"
log_info "  NiFi:  $(get_service_state 'NIFI')"
log_info "  Hive:  $(get_service_state 'HIVE')"

log_info "=========================================="
log_info "✓ Manual initialization completed!"
log_info "=========================================="
log_info ""
log_info "Access Points:"
log_info "  - NiFi UI: http://${NIFI_NODE}:9090/nifi"
log_info "  - Ambari UI: http://${AMBARI_HOST}:${AMBARI_PORT}"
log_info ""
log_info "To verify NiFi is running:"
log_info "  ssh ${NIFI_NODE} 'systemctl status nifi'"
log_info ""
log_info "To verify Hive is running:"
log_info "  beeline -u 'jdbc:hive2://${NIFI_NODE}:10000/' -n hive -e 'SHOW DATABASES;'"

exit 0
