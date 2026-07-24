source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# node (nvm)
fish_add_path /home/noirelab/.nvm/versions/node/v22.23.1/bin

# opencode
fish_add_path /home/noirelab/.opencode/bin

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/noirelab/miniconda3/bin/conda
    eval /home/noirelab/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/noirelab/miniconda3/etc/fish/conf.d/conda.fish"
        . "/home/noirelab/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/noirelab/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
