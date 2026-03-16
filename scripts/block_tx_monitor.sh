#!/bin/bash

# Block Transaction Monitor
# Listens for new blocks and prints transaction count for each block

set -euo pipefail

# Default RPC URL (can be overridden with environment variable)
RPC_URL="${RPC_URL:-http://localhost:8545}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if cast is available
if ! command -v cast &> /dev/null; then
    print_error "cast command not found. Please install Foundry first:"
    print_error "curl -L https://foundry.paradigm.xyz | bash"
    print_error "foundryup"
    exit 1
fi

# Function to get transaction count from block
get_tx_count_from_block() {
    local block_hash="$1"
    
    # Get block details using cast
    local block_info=$(cast block "$block_hash" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
    
    if [ -z "$block_info" ]; then
        print_warning "Failed to fetch block $block_hash"
        return 1
    fi
    
    # Extract transaction count from block info
    # Looking for the line that contains transaction hashes or count
    local tx_count=$(echo "$block_info" | grep -E "transactions|txs" | wc -l)
    
    # Alternative method: count transaction hashes directly
    if [ "$tx_count" -eq 0 ]; then
        tx_count=$(echo "$block_info" | grep -E "^0x[a-fA-F0-9]{64}$" | wc -l)
    fi
    
    echo "$tx_count"
}

# Function to get block number and transaction count
get_block_info() {
    local block_hash="$1"
    
    # Get block details
    local block_info=$(cast block "$block_hash" --rpc-url "$RPC_URL" --json 2>/dev/null || echo "")
    
    if [ -z "$block_info" ]; then
        print_warning "Failed to fetch block $block_hash"
        return 1
    fi
    
    # Parse JSON to get block number and transaction count
    local block_number=$(echo "$block_info" | jq -r '.number // empty' 2>/dev/null || echo "")
    local tx_count=$(echo "$block_info" | jq -r '.transactions | length' 2>/dev/null || echo "0")
    
    # Convert hex block number to decimal if needed
    if [[ "$block_number" =~ ^0x ]]; then
        block_number=$(printf "%d" "$block_number")
    fi
    
    echo "$block_number:$tx_count"
}

# Cleanup function
cleanup() {
    print_info "Shutting down block monitor..."
    kill $CAST_PID 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

print_success "🔍 Starting block transaction monitor..."
print_info "RPC URL: $RPC_URL"
print_info "Press Ctrl+C to stop"
print_info ""
print_info "Format: [TIMESTAMP] Block #NUMBER: TX_COUNT transactions (Hash: HASH)"
print_info "$(printf '%.60s' "$(printf '%0.1s' "=" {1..60})")"

# Check RPC connection
if ! cast block-number --rpc-url "$RPC_URL" &> /dev/null; then
    print_error "Cannot connect to RPC at $RPC_URL"
    print_error "Make sure your Ethereum node is running and accessible"
    exit 1
fi

# Start listening to new blocks
cast subscribe newHeads --rpc-url "$RPC_URL" 2>/dev/null | while read -r line; do
    # Extract block hash from the output
    # cast subscribe newHeads outputs JSON, we need to extract the hash
    block_hash=$(echo "$line" | jq -r '.hash // empty' 2>/dev/null || echo "")
    
    if [ -n "$block_hash" ] && [[ "$block_hash" =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Get block info
        block_info=$(get_block_info "$block_hash" 2>/dev/null || echo "unknown:0")
        IFS=':' read -r block_number tx_count <<< "$block_info"
        
        if [ "$block_number" = "unknown" ]; then
            print_warning "[$timestamp] New block detected but failed to get details: $block_hash"
        else
            # Color code based on transaction count
            if [ "$tx_count" -eq 0 ]; then
                color="$YELLOW"
            elif [ "$tx_count" -lt 10 ]; then
                color="$GREEN"
            elif [ "$tx_count" -lt 50 ]; then
                color="$BLUE"
            else
                color="$RED"
            fi
            
            echo -e "[$timestamp] ${color}Block #$block_number: $tx_count transactions${NC} (Hash: $block_hash)"
        fi
    fi
done &

CAST_PID=$!

# Wait for the cast process
wait $CAST_PID