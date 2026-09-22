# clear — o `clear` padrão não apaga o histórico de rolagem no kitty (o terminfo
# xterm-kitty não traz a capacidade E3), então o printcli continuava capturando
# tudo o que veio antes. Esta versão limpa a tela E o histórico.
function clear --description 'Limpa a tela e o histórico de rolagem'
    if set -q KITTY_PID
        kitty @ clear-terminal --type=reset active 2>/dev/null
        and return
    end
    printf '\033[H\033[2J\033[3J'
end
