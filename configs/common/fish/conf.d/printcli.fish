# Ctrl+L do fish só repinta a tela; aqui ele passa a limpar o histórico também,
# para o printcli capturar apenas o que veio depois.
if status is-interactive
    bind ctrl-l 'clear; commandline -f repaint'
end
