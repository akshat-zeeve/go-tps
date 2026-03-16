#!/usr/bin/env python3
"""
Performance Graph Generator and CSV Exporter
Generates performance graphs and exports CSV data with 1-minute intervals.
"""

import sqlite3
import sys
import os
import csv
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
from datetime import datetime


def export_1min_csv(db_path='./transactions.db', output_file=None):
    """
    Quick function to export 1-minute interval CSV data using database queries.
    
    Exports:
    - Gas used in 1-minute intervals
    - Confirmation TPS in that 1 minute
    - Confirmation latency in that 1 minute
    - Submission TPS in 1 minute  
    - Success rate in 1 minute
    - Failure rate in 1 minute
    """
    
    if not os.path.exists(db_path):
        print(f"Database file '{db_path}' not found.")
        return
    
    if not output_file:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_file = f"performance_1min_{timestamp}.csv"
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Query for submission metrics (grouped by submission minute)
        submission_query = """
        SELECT 
            strftime('%Y-%m-%d %H:%M:00', submitted_at) as minute_interval,
            COUNT(*) as submitted_count,
            (SUM(CASE WHEN gas_used > 0 THEN gas_used ELSE gas_limit END) / 60.0) as avg_gas_used_per_second,
            SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as success_count,
            SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failure_count,
            AVG(CASE WHEN execution_time > 0 THEN execution_time ELSE NULL END) as avg_execution_time_ms
        FROM transactions 
        GROUP BY strftime('%Y-%m-%d %H:%M:00', submitted_at)
        ORDER BY minute_interval
        """
        
        cursor.execute(submission_query)
        submission_data = cursor.fetchall()
        
        # Query for confirmation metrics (grouped by confirmation minute)
        confirmation_query = """
        SELECT 
            strftime('%Y-%m-%d %H:%M:00', confirmed_at) as minute_interval,
            COUNT(*) as confirmed_count,
            AVG((JULIANDAY(confirmed_at) - JULIANDAY(submitted_at)) * 86400 * 1000) as avg_latency_ms
        FROM transactions 
        WHERE confirmed_at IS NOT NULL
        GROUP BY strftime('%Y-%m-%d %H:%M:00', confirmed_at)
        ORDER BY minute_interval
        """
        
        cursor.execute(confirmation_query)
        confirmation_data = cursor.fetchall()
        
        conn.close()
        
        if not submission_data:
            print("No transactions found.")
            return
        
        print(f"Processing {len(submission_data)} 1-minute intervals...")
        
        # Convert to dictionaries for easier lookup
        submission_dict = {row['minute_interval']: dict(row) for row in submission_data}
        confirmation_dict = {row['minute_interval']: dict(row) for row in confirmation_data}
        
        # Write CSV
        with open(output_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([
                'timestamp',
                'avg_gas_used_per_second',
                'submission_tps', 
                'confirmation_tps',
                'avg_confirmation_latency_ms',
                'avg_execution_time_ms',
                'success_rate_percent',
                'failure_rate_percent',
                'submitted_count',
                'confirmed_count'
            ])
            
            for minute in sorted(submission_dict.keys()):
                sub_data = submission_dict[minute]
                conf_data = confirmation_dict.get(minute, {})
                
                submission_tps = sub_data['submitted_count'] / 60.0
                confirmation_tps = conf_data.get('confirmed_count', 0) / 60.0
                
                avg_latency = conf_data.get('avg_latency_ms', 0) or 0
                avg_execution_time = sub_data.get('avg_execution_time_ms', 0) or 0
                
                total = sub_data['submitted_count']
                success_rate = (sub_data['success_count'] / total * 100) if total > 0 else 0
                failure_rate = (sub_data['failure_count'] / total * 100) if total > 0 else 0
                
                writer.writerow([
                    minute,
                    sub_data['avg_gas_used_per_second'] or 0,
                    f"{submission_tps:.3f}",
                    f"{confirmation_tps:.3f}", 
                    f"{avg_latency:.2f}",
                    f"{avg_execution_time:.2f}",
                    f"{success_rate:.2f}",
                    f"{failure_rate:.2f}",
                    sub_data['submitted_count'],
                    conf_data.get('confirmed_count', 0)
                ])
        
        print(f"✓ CSV exported to {output_file}")
        print(f"✓ {len(submission_dict)} 1-minute intervals")
        
    except Exception as e:
        print(f"Error: {e}")


if __name__ == '__main__':
    # Default usage
    db_path = sys.argv[1] if len(sys.argv) > 1 else './transactions.db'
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    export_1min_csv(db_path, output_file)