#!/bin/bash
count=$(checkupdates 2>/dev/null | wc -l)
if (( count > 0 )); then
    echo "{\"text\": \"󰏗 $count\", \"class\": \"updates\", \"tooltip\": \"$count package update(s) available\"}"
else
    echo '{"text": "󰏗", "tooltip": "System up to date"}'
fi
