# Block Transaction Monitors

Two shell scripts to monitor new blocks and display transaction counts in real-time.

## Prerequisites

- **Foundry** installed (`cast` command available)
- Ethereum RPC endpoint running (default: `http://localhost:8545`)

Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Scripts

### 1. Advanced Monitor (`block_tx_monitor.sh`)
Uses `cast subscribe newHeads` for real-time block subscription.

**Features:**
- Real-time block detection via WebSocket subscription
- JSON parsing for detailed block information
- Color-coded output based on transaction count
- Error handling and connection status

**Usage:**
```bash
# Default (localhost:8545)
./scripts/block_tx_monitor.sh

# Custom RPC URL
RPC_URL="http://your-node:8545" ./scripts/block_tx_monitor.sh
```

### 2. Simple Monitor (`simple_block_monitor.sh`)
Uses block number polling for maximum compatibility.

**Features:**
- Block number polling every second
- More reliable with basic RPC endpoints
- Catches all blocks (no missed blocks)
- Simpler implementation

**Usage:**
```bash
# Default (localhost:8545)
./scripts/simple_block_monitor.sh

# Custom RPC URL  
RPC_URL="http://your-node:8545" ./scripts/simple_block_monitor.sh
```

## Output Format

Both scripts display:
```
[TIMESTAMP] Block #NUMBER: TX_COUNT transactions
```

**Color coding:**
- 🟡 **Yellow**: 0 transactions (empty block)
- 🟢 **Green**: 1-9 transactions (low activity)
- 🔵 **Blue**: 10-49 transactions (medium activity)
- 🔴 **Red**: 50+ transactions (high activity)

## Examples

```bash
[14:30:15] Block #1234567: 0 transactions
[14:30:27] Block #1234568: 15 transactions  
[14:30:39] Block #1234569: 3 transactions
[14:30:51] Block #1234570: 67 transactions
[14:31:03] Block #1234571: 12 transactions
```

## Stopping

Press `Ctrl+C` to stop monitoring.

## Troubleshooting

1. **"cast not found"**: Install Foundry
2. **"Cannot connect to RPC"**: Check if your Ethereum node is running
3. **No new blocks**: Verify network is producing blocks (might be test network)
4. **JSON errors**: Use the simple monitor instead

## Advanced Usage

Monitor specific networks:
```bash
# Mainnet via Alchemy
RPC_URL="https://eth-mainnet.alchemyapi.io/v2/YOUR-KEY" ./scripts/block_tx_monitor.sh

# Local Hardhat
RPC_URL="http://localhost:8545" ./scripts/simple_block_monitor.sh

# Testnet
RPC_URL="https://rpc.ankr.com/eth_goerli" ./scripts/block_tx_monitor.sh
```