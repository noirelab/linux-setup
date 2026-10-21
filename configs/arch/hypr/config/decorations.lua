-- Look and feel configuration

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 12,
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            -- Nava pastels: ice to lilac on the focused window, a faint hairline elsewhere
            active_border = {
                colors = { "rgba(a9c4efff)", "rgba(c5b3f0ff)" },
                angle = 45,
            },
            inactive_border = "rgba(ffffff2e)",
        },
    },
    group = {
        col = {
            border_active = CACHYLBLUE,
            border_inactive = CACHYGRAY,
            border_locked_active = CACHYDBLUE,
            border_locked_inactive = CACHYGRAY,
        },
        groupbar = {
            col = {
                active = CACHYLGREEN,
                inactive = CACHYGRAY,
                locked_active = CACHYDBLUE,
                locked_inactive = CACHYGRAY,
            },
        },
    },
    decoration = {
        dim_special = 0.3,
        rounding = 16,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1,
        blur = {
            -- milky glass: wide blur, a little grain and lift so dark panes read as frosted
            size = 10,
            passes = 3,
            noise = 0.03,
            brightness = 0.9,
            contrast = 0.9,
            vibrancy = 0.25,
            special = true,
        },
        shadow = {
            enabled = true,
            range = 28,
            render_power = 3,
            color = "rgba(00000066)",
        },
    },
})
