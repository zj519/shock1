#!/bin/bash
# Monitor LAMMPS shock stage progress

LOGFILE="shock.log"
SHOCK_START=240000    # Steps before shock stage (minimization + equilibration)
SHOCK_STEPS=100000     # Steps in shock stage
TOTAL_STEPS=$((SHOCK_START + SHOCK_STEPS))
CHECK_INTERVAL=30      # seconds

if [ ! -f "$LOGFILE" ]; then
    echo "Log file $LOGFILE not found!"
    exit 1
fi

echo "Monitoring LAMMPS shock stage..."
echo "Shock stage starts at step $SHOCK_START"
echo "Press Ctrl+C to stop monitoring"
echo ""

START_TIME=$(date +%s)

while true; do
    # Get current step from log file - only get lines that start with whitespace followed by digits
    # Filter out "Loop time" and other non-step lines
    CURRENT_STEP=$(grep "^[[:space:]]*[0-9]" "$LOGFILE" | grep -v "%" | tail -1 | awk '{print $1}')
    
    # Remove any non-numeric characters
    CURRENT_STEP=$(echo "$CURRENT_STEP" | sed 's/[^0-9]//g')
    
    if [ -z "$CURRENT_STEP" ] || [ "$CURRENT_STEP" = "0" ]; then
        echo "Waiting for simulation to start..."
        sleep $CHECK_INTERVAL
        continue
    fi
    
    if [ "$CURRENT_STEP" -lt "$SHOCK_START" ]; then
        EQUIL_PROGRESS=$(awk "BEGIN {printf \"%.1f\", $CURRENT_STEP / $SHOCK_START * 100}")
        echo -ne "\rEquilibrating... Step: $CURRENT_STEP/$SHOCK_START (${EQUIL_PROGRESS}%)     "
        sleep $CHECK_INTERVAL
        continue
    fi
    
    # Calculate shock stage progress
    SHOCK_CURRENT=$((CURRENT_STEP - SHOCK_START))
    PROGRESS=$(awk "BEGIN {printf \"%.1f\", $SHOCK_CURRENT / $SHOCK_STEPS * 100}")
    
    # Calculate time elapsed in shock stage
    if [ ! -f ".shock_start_time" ]; then
        date +%s > .shock_start_time
    fi
    
    SHOCK_START_TIME=$(cat .shock_start_time)
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - SHOCK_START_TIME))
    
    # Estimate remaining time
    if [ "$SHOCK_CURRENT" -gt 0 ] && [ "$ELAPSED" -gt 0 ]; then
        TOTAL_TIME=$(awk "BEGIN {printf \"%.0f\", $ELAPSED * $SHOCK_STEPS / $SHOCK_CURRENT}")
        REMAINING=$((TOTAL_TIME - ELAPSED))
        
        if [ "$REMAINING" -lt 0 ]; then
            REMAINING=0
        fi
        
        HOURS=$((REMAINING / 3600))
        MINUTES=$(((REMAINING % 3600) / 60))
        SECONDS=$((REMAINING % 60))
        
        echo -ne "\rShock Stage - Step: $SHOCK_CURRENT/$SHOCK_STEPS (${PROGRESS}%) | Elapsed: ${ELAPSED}s | ETA: ${HOURS}h ${MINUTES}m ${SECONDS}s     "
    else
        echo -ne "\rShock Stage - Step: $SHOCK_CURRENT/$SHOCK_STEPS (${PROGRESS}%)     "
    fi
    
    # Check if shock stage is done
    if [ "$CURRENT_STEP" -ge "$TOTAL_STEPS" ]; then
        echo -e "\n\nShock simulation complete!"
        rm -f .shock_start_time
        break
    fi
    
    sleep $CHECK_INTERVAL
done

