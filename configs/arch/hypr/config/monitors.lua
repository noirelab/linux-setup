-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

-- nwg-displays writes its config to ~/.config/hypr/monitors.lua
-- (Hyprland's configProvider is lua here, so that file is NOT read
-- by the compositor on its own). Load it explicitly so changes made
-- in nwg-displays take effect on `hyprctl reload`.
local nwg_monitors = os.getenv("HOME") .. "/.config/hypr/monitors.lua"
local f = io.open(nwg_monitors, "r")
if f then
    f:close()
    dofile(nwg_monitors)
else
    hl.monitor({
        output    = MONITOR1,
        mode      = "preferred",
        position  = "0x0",
        scale     = "1",
        transform = 1, -- 1 = 90° (portrait, flipped)
    })

    hl.monitor({
        output    = MONITOR2,
        mode      = "preferred",
        position  = "1080x0",
        scale     = "1",
    })
end
