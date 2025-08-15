#! /bin/bash

# Try to reach the server given in $1. If it's down, try waking it up, then block for up to 20 seconds until it is reachable.

SERVER="$1"

if ! ping -c 1 "$SERVER" &> /dev/null; then
    echo "Server $SERVER is down. Trying to wake it up..."
    
    echo "wake" | nc -N stream-condense 9253
fi

# Wait for the server to be reachable
for i in {1..20}; do
    if ping -c 1 "$SERVER" &> /dev/null; then
        echo "Server $SERVER is up!"
        exit 0
    fi
    sleep 1
done

echo "Server $SERVER did not come up in time."
exit 1