#!/bin/bash

# Withdraw all funds using mnemonic from file
# Usage: ./withdraw-from-mnemonic-file.sh <DESTINATION_ADDRESS> [MNEMONIC_FILE] [COUNT] [RPC_URL]

RPC_URL="${4:-http://localhost:8545}"
COUNT="${3:-20}"
MNEMONIC_FILE="${2:-mnemonic.txt}"
DESTINATION="$1"

if [ -z "$DESTINATION" ]; then
  echo "Usage: $0 <DESTINATION_ADDRESS> [MNEMONIC_FILE] [COUNT] [RPC_URL]"
  echo ""
  echo "Examples:"
  echo "  $0 0x742d35Cc6639C0532fEb66FF7CB9132dcBacbD1A"
  echo "  $0 0x742d35Cc6639C0532fEb66FF7CB9132dcBacbD1A mnemonic.txt 50"
  echo "  $0 0x742d35Cc6639C0532fEb66FF7CB9132dcBacbD1A custom.mnemonic 10 http://localhost:8545"
  echo ""
  echo "Parameters:"
  echo "  DESTINATION       - Address to send all funds to"
  echo "  MNEMONIC_FILE     - File containing BIP39 mnemonic (default: mnemonic.txt)"
  echo "  COUNT             - Number of wallets to check (default: 20)"
  echo "  RPC_URL           - Ethereum RPC endpoint (default: http://localhost:8545)"
  exit 1
fi

# Check if mnemonic file exists
if [ ! -f "$MNEMONIC_FILE" ]; then
  echo "❌ Mnemonic file not found: $MNEMONIC_FILE"
  echo ""
  echo "Available mnemonic files in current directory:"
  ls -la *.txt *.mnemonic 2>/dev/null || echo "  No .txt or .mnemonic files found"
  exit 1
fi

# Read mnemonic from file
MNEMONIC=$(cat "$MNEMONIC_FILE" | tr -d '\n\r' | xargs)
if [ -z "$MNEMONIC" ]; then
  echo "❌ Empty or invalid mnemonic file: $MNEMONIC_FILE"
  exit 1
fi

echo "=== WITHDRAWING FROM MNEMONIC FILE ==="
echo "Mnemonic file: $MNEMONIC_FILE"
echo "Destination: $DESTINATION"
echo "Wallet count: $COUNT"
echo "RPC URL: $RPC_URL"
echo ""

# Call the main withdrawal script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/withdraw-all-funds.sh" "$MNEMONIC" "$DESTINATION" "$COUNT" "$RPC_URL"