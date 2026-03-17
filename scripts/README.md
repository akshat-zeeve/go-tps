# Scripts Directory

Analysis, visualization, and monitoring tools for go-tps.

## Overview

This directory contains all auxiliary tools for analyzing transaction data, generating performance graphs, monitoring blockchain activity, and exporting data.

## Files

### `analyze.sh`
Shell script for querying the SQLite database. Also available as `./analyze.sh` in the project root (wrapper).

```bash
./scripts/analyze.sh [command]
```

| Command | Output |
|---------|--------|
| `summary` | Total, success, failure, avg latency |
| `tps` | Submission and confirmation TPS |
| `performance` | Execution time breakdown |
| `wallets` | Per-wallet transaction counts and latency |
| `batches` | List all batch executions |
| `batch <id>` | Stats for a specific batch |
| `recent` | Last 10 transactions |
| `errors` | Error message breakdown |
| `timeline` | Time-series transaction counts |
| `export` | Dump transactions to CSV |
| `query` | Interactive `sqlite3` shell |

### `graph_metrics.py`
Unified Python graphing tool. Also available as `./graph.py` in the project root (wrapper). Saves all images to `images/`.

**Requirements:**
```bash
pip3 install -r requirements.txt
```

**Usage:**
```bash
./scripts/graph_metrics.py
```

Interactive prompts let you select a batch and graph type:

| Graph | File | Description |
|-------|------|-------------|
| TPS | `images/tps_graph_<batch>.png` | Submission TPS (blue) + confirmation TPS (green) |
| Latency | `images/latency_graph_<batch>.png` | RPC submission latency (orange) + confirmation latency (purple) |
| Gas Price | `images/gas_price_graph_<batch>.png` | Signed gas price vs effective gas price from receipt |

All graphs group data into 1-second intervals and display avg/min/max statistics. Output is high-quality PNG (300 DPI).

### `get-gas.py`
Helper script for analysing gas price data from the database. Useful for examining gas price trends across batches.

### `export-address-transactions.js`
Node.js script to export all transactions from an Ethereum address to CSV format using the Etherscan API.

**Requirements:**
- Node.js 14+ 
- Etherscan API key (get free key at [etherscan.io/apis](https://etherscan.io/apis))

**Features:**
- Exports all normal transactions for any Ethereum address
- Optional internal transactions support
- Comprehensive transaction details: hash, block, timestamp, gas data, fees, status
- Automatic pagination (handles addresses with 10,000+ transactions)
- Rate limiting (respects Etherscan API limits)
- CSV format with proper escaping

**Usage:**
```bash
# Basic export (normal transactions only)
ETHERSCAN_API_KEY=your_key node export-address-transactions.js 0x742d35cc6460c0dbc25b35b5c65d5ebaeacadc21

# Include internal transactions
ETHERSCAN_API_KEY=your_key node export-address-transactions.js --include-internal 0x742d35cc6460c0dbc25b35b5c65d5ebaeacadc21

# Custom output directory
ETHERSCAN_API_KEY=your_key OUTPUT_DIR=./exports node export-address-transactions.js 0x742d35cc6460c0dbc25b35b5c65d5ebaeacadc21

# Help
node export-address-transactions.js --help
```

**Output:**
- CSV file: `<address>_<type>_transactions_<timestamp>.csv`
- Headers: hash, blockNumber, timeStamp, from, to, value, gas, gasPrice, gasUsed, txnFee, status, isError, input, contractAddress, cumulativeGasUsed, confirmations
- Transaction summary with totals and date range

### `export-example.sh`
Interactive example script that demonstrates how to use the address transaction exporter with well-known Ethereum addresses or custom addresses.

**Requirements:**
- Etherscan API key set as `ETHERSCAN_API_KEY` environment variable

**Usage:**
```bash
export ETHERSCAN_API_KEY=your_key_here
./scripts/export-example.sh
```

Features interactive selection of example addresses and export options.

### `analyze_multi_db.py`
Python script for analyzing and comparing data across multiple transaction databases. Useful for comparing performance across different test runs or configurations.

**Usage:**
```bash
# Analyze all .db files in current directory
python3 scripts/analyze_multi_db.py

# Analyze specific databases
python3 scripts/analyze_multi_db.py transactions1.db transactions2.db
```

### `fund_wallets.sh`
Automated script for funding multiple wallet addresses from a source account. Supports batch funding operations.

**Usage:**
```bash
# Interactive mode
./scripts/fund_wallets.sh

# With parameters
SOURCE_PRIVATE_KEY=0x123... ./scripts/fund_wallets.sh addresses.txt
```

### `withdraw-all-funds.sh`
Withdraw all funds from wallets derived from a BIP39 mnemonic phrase to a specified destination address. Automatically calculates gas costs and withdraws the maximum possible amount.

**Requirements:**
- `cast` (from Foundry toolkit)
- `bc` (basic calculator)

**Usage:**
```bash
# Basic usage
./scripts/withdraw-all-funds.sh "abandon abandon abandon..." 0x742d35Cc6639C0532fEb66FF7CB9132dcBacbD1A

# Custom parameters
./scripts/withdraw-all-funds.sh "your mnemonic phrase" 0xDestination 50 http://localhost:8545
```

**Parameters:**
- `MNEMONIC` - BIP39 mnemonic phrase (12-24 words)
- `DESTINATION_ADDRESS` - Address to send all funds to
- `COUNT` - Number of wallets to check (default: 20)
- `RPC_URL` - Ethereum RPC endpoint (default: http://localhost:8545)

**Features:**
- Automatically derives wallet addresses using BIP44 derivation path
- Gets current gas prices from the network
- Calculates gas costs and withdraws maximum amount (balance - gas)
- Skips empty wallets and wallets with insufficient balance for gas
- Provides detailed summary of successful/failed withdrawals
- Handles errors gracefully and continues processing remaining wallets

### `withdraw-from-mnemonic-file.sh`
Simplified wrapper that reads the mnemonic from a file (like `mnemonic.txt` generated by go-tps) and withdraws all funds to a destination address.

**Usage:**
```bash
# Use default mnemonic.txt file
./scripts/withdraw-from-mnemonic-file.sh 0x742d35Cc6639C0532fEb66FF7CB9132dcBacbD1A

# Use custom mnemonic file
./scripts/withdraw-from-mnemonic-file.sh 0xDestination custom.mnemonic 50 http://localhost:8545
```

**Parameters:**
- `DESTINATION_ADDRESS` - Address to send all funds to
- `MNEMONIC_FILE` - File containing BIP39 mnemonic (default: mnemonic.txt)  
- `COUNT` - Number of wallets to check (default: 20)
- `RPC_URL` - Ethereum RPC endpoint (default: http://localhost:8545)

**Features:**
- Integrates seamlessly with go-tps workflow (uses same mnemonic.txt)
- Validates mnemonic file exists and contains valid data
- Calls the main withdrawal script with file contents
- Perfect for cleaning up after go-tps testing sessions

### `stress-test.js`
Node.js script for advanced network stress testing with configurable parameters.

**Usage:**
```bash
# Default stress test
node scripts/stress-test.js

# Custom configuration
RPC_URL=http://localhost:8545 CONCURRENT_REQUESTS=50 node scripts/stress-test.js
```

## Additional Tools

### Block Monitoring
Real-time blockchain activity monitoring:
- `block_tx_monitor.sh` - Advanced WebSocket-based monitor with color-coded output
- `simple_block_monitor.sh` - Polling-based monitor for maximum compatibility
- `BLOCK_MONITOR_README.md` - Detailed monitoring documentation

### Data Export & Analysis
- `export-address-transactions.js` - Export Etherscan address transactions to CSV
- `export-example.sh` - Interactive examples for address transaction export
- `analyze_multi_db.py` - Multi-database analysis and comparison
- `export_1min_intervals.py` - Time-based data export with customizable intervals

### Wallet Management
- `fund_wallets.sh` - Automated wallet funding helper
- `generate-and-fund.sh` - Combined wallet generation and funding workflow
- `withdraw-all-funds.sh` - Withdraw all funds from mnemonic-derived wallets to a destination address
- `withdraw-from-mnemonic-file.sh` - Withdraw funds using mnemonic from file (integrates with go-tps workflow)

### Performance & Testing
- `performance_graph.py` - Advanced performance visualization
- `stress-test.js` - Network stress testing script
- `tps.sh` - TPS calculation and monitoring helper

### Utilities
- `get-gas.py` - Gas price analysis and trending

## Root Wrappers

For convenience, the root directory contains thin wrappers:
```bash
./analyze.sh [command]   # → scripts/analyze.sh
./graph.py               # → scripts/graph_metrics.py
```
