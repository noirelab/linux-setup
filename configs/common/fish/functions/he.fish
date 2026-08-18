function he --description "Abre herdr com dois Claude Code lado a lado em auto mode"
    set -l herdr ~/.local/bin/herdr
    set -l cwd (pwd)

    if not pgrep -f "kitty herdr" >/dev/null
        kitty herdr &
        disown
        set -l tries 0
        while not $herdr status >/dev/null 2>&1; and test $tries -lt 20
            sleep 0.5
            set tries (math $tries + 1)
        end
    else
        hyprctl dispatch focuswindow 'title:^herdr - herdr$' >/dev/null 2>&1
    end

    set -l suffix (date +%s)

    set -l pane1 ($herdr workspace create --cwd "$cwd" --label claude --focus | jq -r '.result.root_pane.pane_id')
    set -l pane2 ($herdr pane split --pane $pane1 --direction right --cwd "$cwd" | jq -r '.result.pane.pane_id')

    $herdr agent start "c1-$suffix" --kind claude --pane $pane1 -- --permission-mode auto >/dev/null
    $herdr agent start "c2-$suffix" --kind claude --pane $pane2 -- --permission-mode auto >/dev/null
end
