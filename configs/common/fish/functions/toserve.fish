function toserve --description 'Serve a pasta atual via HTTP na IP Tailscale (abrir no navegador do tablet)'
    set -l ip (tailscale ip -4)
    set -l port 8000
    test (count $argv) -gt 0; and set port $argv[1]
    echo "No tablet, abra: http://$ip:$port"
    echo "Ctrl+C para parar."
    python3 -m http.server $port --bind $ip
end
