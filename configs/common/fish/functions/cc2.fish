function cc2
    set -lx CLAUDE_CONFIG_DIR "$HOME/.claude-conta2"
    command claude --dangerously-skip-permissions $argv
end
