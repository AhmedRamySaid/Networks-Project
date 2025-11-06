#!/bin/bash
# === Baseline Local Test (Unity build launcher) ===
# Automated script to run the 'Baseline local' test scenario

set -e  # Exit immediately on errors
set -u  # Treat unset variables as errors

echo "=== Baseline Local Test (Unity build launcher) ==="

# 1) Locate the Unity build executable
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
EXE_PATH="$PROJECT_ROOT/../Bin/Sword Scuffle.exe"

# Handle Windows paths if running in Git Bash/MSYS2
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    EXE_PATH=$(cygpath -w "$EXE_PATH" 2>/dev/null || echo "$EXE_PATH")
fi

if [ ! -f "$EXE_PATH" ]; then
    echo "[ERROR] Unity executable not found at: $EXE_PATH"
    echo "Make sure your Windows build exists at Bin/Sword Scuffle.exe"
    exit 1
fi

echo "Found executable: $EXE_PATH"

# 2) Find and clean old logs in LocalLow (Unity persistentDataPath)
echo ""
echo "Cleaning existing logs under LocalLow (Unity persistentDataPath)..."

# Function to find log files recursively in LocalLow
find_logs_in_locallow() {
    local log_names=("$@")
    local local_low=""
    
    # Determine LocalLow path based on OS
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows: %LOCALAPPDATA%\..\LocalLow
        if [ -n "${LOCALAPPDATA:-}" ]; then
            local_low=$(cygpath -u "$LOCALAPPDATA/../LocalLow" 2>/dev/null || echo "")
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: ~/Library/Application Support
        local_low="$HOME/Library/Application Support"
    else
        # Linux: ~/.config/unity3d
        local_low="$HOME/.config/unity3d"
    fi
    
    if [ -z "$local_low" ] || [ ! -d "$local_low" ]; then
        return
    fi
    
    # Recursively search for log files
    local found_logs=()
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")
        for log_name in "${log_names[@]}"; do
            if [ "$basename" = "$log_name" ]; then
                found_logs+=("$file")
            fi
        done
    done < <(find "$local_low" -type f -name "*.txt" -print0 2>/dev/null || true)
    
    printf '%s\n' "${found_logs[@]}"
}

# Clean up old logs
OLD_LOGS=$(find_logs_in_locallow "client_logs.txt" "server_logs.txt")
DELETED_COUNT=0
if [ -n "$OLD_LOGS" ]; then
    while IFS= read -r log_file; do
        if [ -n "$log_file" ] && [ -f "$log_file" ]; then
            rm -f "$log_file" && ((DELETED_COUNT++)) || true
            echo "  Deleted: $log_file"
        fi
    done <<< "$OLD_LOGS"
fi
echo "Deleted $DELETED_COUNT old log file(s)."

# 3) Start server and client
SERVER_ARGS="-batchmode -nographics -scene ServerScene"
CLIENT_ARGS="-scene ClientScene"

echo ""
echo "Starting server instance..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows: use PowerShell Start-Process to handle spaces properly
    WIN_EXE_PATH=$(cygpath -w "$EXE_PATH" 2>/dev/null || echo "$EXE_PATH")
    powershell.exe -Command "Start-Process -FilePath '$WIN_EXE_PATH' -ArgumentList '$SERVER_ARGS' -WindowStyle Minimized" &
    SERVER_PID=$!
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: direct execution
    "$EXE_PATH" $SERVER_ARGS &
    SERVER_PID=$!
else
    # Mac or other Unix
    "$EXE_PATH" $SERVER_ARGS &
    SERVER_PID=$!
fi

echo "  Server PID: $SERVER_PID"
sleep 1

echo "Starting client instance..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows: use PowerShell Start-Process to handle spaces properly
    WIN_EXE_PATH=$(cygpath -w "$EXE_PATH" 2>/dev/null || echo "$EXE_PATH")
    powershell.exe -Command "Start-Process -FilePath '$WIN_EXE_PATH' -ArgumentList '$CLIENT_ARGS'" &
    CLIENT_PID=$!
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: direct execution
    "$EXE_PATH" $CLIENT_ARGS &
    CLIENT_PID=$!
else
    # Mac or other Unix
    "$EXE_PATH" $CLIENT_ARGS &
    CLIENT_PID=$!
fi

echo "  Client PID: $CLIENT_PID"

# 4) Wait for communication
WAIT_SECS=5
echo ""
echo "Waiting ${WAIT_SECS}s for communication..."
sleep $WAIT_SECS

# 5) Stop both processes
echo ""
echo "Stopping instances..."

# Function to safely kill a process
safe_kill() {
    local pid=$1
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        sleep 0.5
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
}

safe_kill $CLIENT_PID
safe_kill $SERVER_PID

# Wait for processes to flush logs
echo "Waiting for processes to flush logs..."
sleep 2

# 6) Verify logs were created
echo ""
echo "Searching for log files in LocalLow..."

FOUND_LOGS=$(find_logs_in_locallow "client_logs.txt" "server_logs.txt")

CLIENT_FOUND=false
SERVER_FOUND=false
CLIENT_LOG_PATH=""
SERVER_LOG_PATH=""

if [ -n "$FOUND_LOGS" ]; then
    while IFS= read -r log_file; do
        if [ -n "$log_file" ]; then
            basename=$(basename "$log_file")
            if [ "$basename" = "client_logs.txt" ]; then
                CLIENT_FOUND=true
                CLIENT_LOG_PATH="$log_file"
            elif [ "$basename" = "server_logs.txt" ]; then
                SERVER_FOUND=true
                SERVER_LOG_PATH="$log_file"
            fi
        fi
    done <<< "$FOUND_LOGS"
fi

echo ""
echo "=== Results ==="
echo "client_logs.txt created: $CLIENT_FOUND"
echo "server_logs.txt created: $SERVER_FOUND"

if [ "$CLIENT_FOUND" = true ]; then
    echo "  Client log: $CLIENT_LOG_PATH"
    if [ -f "$CLIENT_LOG_PATH" ]; then
        FILE_SIZE=$(stat -f%z "$CLIENT_LOG_PATH" 2>/dev/null || stat -c%s "$CLIENT_LOG_PATH" 2>/dev/null || echo "unknown")
        echo "    Size: $FILE_SIZE bytes"
    fi
else
    echo "  [WARNING] Client log not found. Possible reasons:"
    echo "    - Client scene didn't load correctly"
    echo "    - Client script didn't run"
    echo "    - Log file written to different location"
fi

if [ "$SERVER_FOUND" = true ]; then
    echo "  Server log: $SERVER_LOG_PATH"
    if [ -f "$SERVER_LOG_PATH" ]; then
        FILE_SIZE=$(stat -f%z "$SERVER_LOG_PATH" 2>/dev/null || stat -c%s "$SERVER_LOG_PATH" 2>/dev/null || echo "unknown")
        echo "    Size: $FILE_SIZE bytes"
    fi
else
    echo "  [WARNING] Server log not found. Possible reasons:"
    echo "    - Server scene didn't load correctly"
    echo "    - Server script didn't run"
    echo "    - Log file written to different location"
fi

# Show where we searched
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    if [ -n "${LOCALAPPDATA:-}" ]; then
        SEARCH_DIR=$(cygpath -u "$LOCALAPPDATA/../LocalLow" 2>/dev/null || echo "unknown")
    else
        SEARCH_DIR="unknown"
    fi
else
    SEARCH_DIR="${local_low:-unknown}"
fi
echo ""
echo "Searched in: $SEARCH_DIR"

echo ""
echo "Done."

if [ "$CLIENT_FOUND" = true ] && [ "$SERVER_FOUND" = true ]; then
    exit 0
else
    exit 2
fi