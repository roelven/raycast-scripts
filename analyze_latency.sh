#!/bin/bash

# Simple script to analyze latency stats from the translation script

STATS_FILE="/tmp/translate_latency_stats.csv"

if [ ! -f "$STATS_FILE" ]; then
    echo "No latency data found. Run translations first."
    exit 1
fi

echo "Translation Latency Analysis"
echo "==========================="
echo

# Count total translations
TOTAL=$(wc -l < "$STATS_FILE")
echo "Total translations: $TOTAL"

# Get min, max, avg latency
if command -v datamash &> /dev/null; then
    # If datamash is available (more accurate)
    echo "Latency stats (seconds):"
    tail -n 100 "$STATS_FILE" | cut -d ',' -f2 | datamash min 1 max 1 mean 1 median 1
else
    # Fallback to basic bash calculations
    MIN=$(cut -d ',' -f2 "$STATS_FILE" | sort -n | head -n1)
    MAX=$(cut -d ',' -f2 "$STATS_FILE" | sort -n | tail -n1)
    AVG=$(awk -F ',' '{sum+=$2} END {print sum/NR}' "$STATS_FILE")
    
    echo "Latency stats (seconds):"
    echo "  Min: $MIN"
    echo "  Max: $MAX"
    echo "  Avg: $AVG"
fi

# Show recent translations
echo
echo "Recent translations:"
tail -n 5 "$STATS_FILE"

# Show trend (if we have enough data)
if [ $TOTAL -gt 10 ]; then
    echo
    echo "Recent trend (last 10 translations):"
    echo "Time,Latency" > /tmp/recent.csv
    tail -n 10 "$STATS_FILE" >> /tmp/recent.csv
    
    if command -v gnuplot &> /dev/null; then
        # Generate simple ASCII chart if gnuplot is available
        gnuplot -e "set terminal dumb; set datafile separator ','; plot '/tmp/recent.csv' using 2 with lines title 'Latency'"
        rm /tmp/recent.csv
    else
        echo "(Install gnuplot for trend visualization)"
    fi
fi