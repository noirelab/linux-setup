#!/bin/bash
weather=$(curl -s "wttr.in/?format=%c+%t" 2>/dev/null)
if [[ -z $weather ]] || [[ $weather == *"Unknown location"* ]]; then
    echo '{"text": "󰖐 --", "tooltip": "Weather unavailable"}'
else
    echo "{\"text\": \"$weather\", \"tooltip\": \"$(curl -s 'wttr.in/?format=%l:+%c+%t+%w+%h')\"}"
fi
