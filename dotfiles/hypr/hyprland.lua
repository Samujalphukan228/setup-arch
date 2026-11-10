-- Restored personal Hyprland configuration
-- Hyprland 0.57.1 — Lua

-- =========================================================
-- MONITOR
-- =========================================================

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

-- =========================================================
-- ENVIRONMENT
-- =========================================================

hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GDK_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland")

-- =========================================================
-- STARTUP APPLICATIONS
-- =========================================================

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wpaperd")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/bin/nm-applet --indicator")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
end)

-- =========================================================
-- GENERAL APPEARANCE
-- =========================================================

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 6,
        border_size = 2,
        col = {
            active_border = { colors = {"rgba(ffffffff)", "rgba(999999ff)"}, angle = 45 },
            inactive_border = "rgba(000000ff)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 16,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.98,

        shadow = {
            enabled = true,
            range = 30,
            render_power = 4,
            color = "rgba(00000077)",
            offset = "0 8",
        },

        blur = {
            enabled = true,
            size = 10,
            passes = 4,
            noise = 0.01,
            contrast = 1.1,
            brightness = 1.0,
            vibrancy = 0.15,
            new_optimizations = true,
            xray = false,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = true,
        smart_resizing = true,
    },

    master = {
        new_status = "master",
    },

    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",

        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            drag_lock = true,
            scroll_factor = 0.8,
        },
    },
})

-- =========================================================
-- ANIMATION CURVES
-- =========================================================

hl.curve("wind", {
    type = "bezier",
    points = {{0.05, 0.9}, {0.1, 1.05}},
})

hl.curve("winIn", {
    type = "bezier",
    points = {{0.1, 1.1}, {0.1, 1.1}},
})

hl.curve("winOut", {
    type = "bezier",
    points = {{0.3, -0.3}, {0, 1}},
})

hl.curve("liner", {
    type = "bezier",
    points = {{1, 1}, {1, 1}},
})

hl.curve("smooth", {
    type = "bezier",
    points = {{0.25, 1}, {0.5, 1}},
})

hl.curve("premium", {
    type = "bezier",
    points = {{0.05, 0.95}, {0.1, 1}},
})

-- =========================================================
-- ANIMATIONS
-- =========================================================

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "premium", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "smooth" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 8, bezier = "smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "smooth", style = "slidevert" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "smooth", style = "slide" })

-- =========================================================
-- DEVICE
-- =========================================================

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- =========================================================
-- KEYBINDINGS
-- =========================================================

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"

-- Applications
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("/home/samujal/.config/hypr/scripts/system-switcher.sh"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("bash -c 'if pgrep -x wofi >/dev/null; then pkill -x wofi; else wofi --show drun; fi'"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("pamac-manager"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("/home/samujal/.config/hypr/scripts/system-switcher.sh"))

-- Window controls
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + M", hl.dsp.exit())

-- Focus movement
hl.bind(mainMod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + DOWN", hl.dsp.focus({ direction = "down" }))

-- Workspace navigation
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("flameshot gui"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll between workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse window movement and resizing
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- =========================================================
-- VOLUME AND BRIGHTNESS
-- =========================================================

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Media controls
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- =========================================================
-- SCREENSHOTS AND LOCK SCREEN
-- =========================================================

hl.bind("PRINT", hl.dsp.exec_cmd('grim "$HOME/Pictures/screenshot-$(date +%F-%T).png"'))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd('grim -g "$(slurp)" "$HOME/Pictures/screenshot-$(date +%F-%T).png"'))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

