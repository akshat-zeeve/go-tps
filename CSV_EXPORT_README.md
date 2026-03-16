# 1-Minute Interval CSV Export Tools

This directory contains two Python scripts for exporting transaction metrics in 1-minute intervals to CSV format.

## Scripts

### 1. export_1min_intervals.py (Full-featured)

**Comprehensive CSV export tool with filtering and batch support**

```bash
# Basic usage - exports all transactions
./scripts/export_1min_intervals.py

# With custom database
./scripts/export_1min_intervals.py --db ./custom.db

# Filter by specific batch
./scripts/export_1min_intervals.py --batch batch-20260316-120000

# Custom output filename
./scripts/export_1min_intervals.py --output-file my_metrics.csv

# List available batches first
./scripts/export_1min_intervals.py --list-batches

# Quiet mode (no summary)
./scripts/export_1min_intervals.py --quiet
```

### 2. performance_graph.py (Simple version) 

**Quick and simple CSV export**

```bash
# Basic usage
./scripts/performance_graph.py

# With custom database
./scripts/performance_graph.py ./custom.db

# With custom database and output file
./scripts/performance_graph.py ./custom.db my_output.csv
```

## CSV Output Columns

Both scripts export the same metrics in CSV format:

| Column | Description |
|--------|-------------|
| `timestamp` | 1-minute interval timestamp (YYYY-MM-DD HH:MM:SS) |
| `gas_used_total` | Total gas used in this 1-minute interval |
| `submission_tps` | Submission TPS (transactions per second) in this minute |
| `confirmation_tps` | Confirmation TPS (confirmations per second) in this minute |
| `avg_confirmation_latency_ms` | Average confirmation latency in milliseconds |
| `success_rate_percent` | Success rate as percentage (0-100) |
| `failure_rate_percent` | Failure rate as percentage (0-100) |
| `submitted_count` | Number of transactions submitted in this minute |
| `confirmed_count` | Number of transactions confirmed in this minute |

## Example Output

```csv
timestamp,gas_used_total,submission_tps,confirmation_tps,avg_confirmation_latency_ms,success_rate_percent,failure_rate_percent,submitted_count,confirmed_count
2026-03-16 12:00:00,2100000,16.667,15.000,1250.50,90.00,10.00,1000,900
2026-03-16 12:01:00,1890000,15.000,14.500,1180.75,96.67,3.33,900,870
2026-03-16 12:02:00,2310000,18.500,17.200,1320.25,93.24,6.76,1110,1032
...
```

## Metrics Explanation

- **Gas Used**: Total gas consumption for all transactions in the 1-minute window
- **Submission TPS**: Rate at which transactions were submitted to the network 
- **Confirmation TPS**: Rate at which transactions were confirmed by the network
- **Confirmation Latency**: Average time from submission to confirmation
- **Success/Failure Rates**: Percentage of transactions that succeeded or failed

## Integration with Existing Tools

These scripts work alongside the existing analysis tools:

```bash
# Generate transaction data first
./go-tps

# Export 1-minute intervals
./scripts/export_1min_intervals.py

# View other analytics
./analyze.sh summary
./analyze.sh tps
```

## Requirements

- Python 3.6+
- SQLite3 (built into Python)
- CSV module (built into Python)
- matplotlib (only for performance_graph.py, optional)

## Database Schema

Scripts work with the go-tps SQLite database schema:

```sql
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY,
    batch_number TEXT NOT NULL,
    wallet_address TEXT NOT NULL,
    tx_hash TEXT,
    nonce INTEGER NOT NULL,
    to_address TEXT NOT NULL,
    value TEXT NOT NULL,
    gas_price TEXT NOT NULL,
    gas_limit INTEGER NOT NULL,
    gas_used INTEGER,
    status TEXT NOT NULL,          -- 'success', 'failed', 'pending'
    submitted_at TIMESTAMP NOT NULL,
    confirmed_at TIMESTAMP,
    execution_time REAL,           -- milliseconds
    error TEXT
);
```