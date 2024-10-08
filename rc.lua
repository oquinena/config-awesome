pcall(require, "luarocks.loader")

local awesome       = awesome
local client        = client
local screen        = screen
local gears         = require("gears")
local awful         = require("awful")
local config_table  = awful.util.table
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local dpi           = require("beautiful.xresources").apply_dpi
local bling         = require("bling")
local helpers       = require("helpers")
local theme         = require("theme")
local xrandr        = require("xrandr")
                      require("awful.autofocus")
                      require("awful.hotkeys_popup.keys")

-- {{{ Error handling
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Errors during startup!",
		text = awesome.startup_errors,
	})
end
-- }}}

-- {{{ Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		if in_error then
			return
		end
		in_error = true

		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Configuration error!",
			text = tostring(err),
		})
		in_error = false
	end)
end
-- }}}

-- {{{ Notifications
naughty.config.defaults.ontop = true
-- }}}

local modkey             = "Mod4"
local altkey             = "Mod1"
local terminal           = "alacritty"
local editor             = os.getenv("EDITOR") or "vim"
local scrlocker          = "betterlockscreen -l dim"
local password_generator = "/home/nomad/go/bin/go-pass"

awful.util.terminal      = terminal
awful.util.tagnames      = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
awful.layout.layouts     = { awful.layout.suit.tile }

-- {{{ Taglist buttons
awful.util.taglist_buttons = config_table.join(
  -- focus tag on click (using left mouse click)
	awful.button({}, 1, function(t)
		t:view_only()
	end),
  -- move client to tag (using modkey + left click)
	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
  -- focus next tag (using mouse scroll wheel up)
	awful.button({}, 5, function(t)
		awful.tag.viewnext(t.screen)
	end),
  -- focus previous tag (using mouse scroll wheel down)
	awful.button({}, 4, function(t)
		awful.tag.viewprev(t.screen)
	end)
)
-- }}}

-- {{{ Tasklist buttons
awful.util.tasklist_buttons = config_table.join(
  -- left click to minimize/un-minimize client
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c.minimized = false
			if not c:isvisible() and c.first_tag then
				c.first_tag:view_only()
			end
			-- This will also un-minimize the client, if needed
			client.focus = c
			c:raise()
		end
	end),
  -- middle click to close client
	awful.button({}, 2, function(c)
		c:kill()
	end),
  -- right click to toggle floating
	awful.button({}, 3, function()
		local instance = nil

		return function()
			if instance and instance.wibox.visible then
				instance:hide()
				instance = nil
			else
				instance = awful.menu.clients({ theme = { width = dpi(150) } })
			end
		end
	end)
)
-- }}}

-- {{{ Initialize theme
beautiful.init(theme)
-- }}}

-- {{{ Scratchpad
S_width = awful.screen.focused().geometry.width
S_height = awful.screen.focused().geometry.height
local term_scratch = bling.module.scratchpad({
	command = "alacritty --class spad", -- How to spawn the scratchpad
	rule = { instance = "spad" }, -- The rule that the scratchpad will be searched by
	sticky = true, -- Whether the scratchpad should be sticky
	autoclose = false, -- Whether it should hide itself when losing focus
	floating = true, -- Whether it should be floating (MUST BE TRUE FOR ANIMATIONS)
	ontop = true,
	-- geometry = { x = 700, y = 200, height = 900, width = 1200 }, -- The geometry in a floating state
	geometry = { x = ((S_width/2)-600), y = ((S_height/2)-450), height = 900, width = 1200 }, -- The geometry in a floating state
	reapply = true, -- Whether all those properties should be reapplied on every new opening of the scratchpad (MUST BE TRUE FOR ANIMATIONS)
	dont_focus_before_close = true, -- When set to true, the scratchpad will be closed by the toggle function regardless of whether its focused or not. When set to false, the toggle function will first bring the scratchpad into focus and only close it on a second call
})
-- }}}

-- {{{ Screen
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
	-- Wallpaper
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		-- If wallpaper is a function, call it with the screen
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end)

-- No borders when rearranging only 1 non-floating or maximized client
screen.connect_signal("arrange", function(s)
	local only_one = #s.tiled_clients == 1
	for _, c in pairs(s.clients) do
		if only_one and not c.floating or c.maximized then
			c.border_width = 0
		else
			c.border_width = beautiful.border_width
		end
	end
end)
-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s)
	beautiful.at_screen_connect(s)
end)
-- }}}

-- {{{ Key bindings
Globalkeys = config_table.join(
	-- X screen locker
	awful.key({ altkey, "Control" }, "l", function()
		os.execute(scrlocker)
	end, { description = "lock screen", group = "hotkeys" }),

	-- scratchpad
	awful.key({ modkey }, "l", function()
		term_scratch:toggle()
	end, { description = "Scratchpad terminal", group = "hotkeys" }),
	-- Hotkeys
	awful.key({ modkey }, "s", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),

	-- {{{ By idx client focus
	awful.key({ modkey }, "n", function()
		awful.client.focus.byidx(1)
		if client.focus then
			client.focus:raise()
		end
	end, { description = "focus down", group = "client" }),
	awful.key({ modkey }, "e", function()
		awful.client.focus.byidx(-1)
		if client.focus then
			client.focus:raise()
		end
	end, { description = "focus up", group = "client" }),
  -- }}}

	-- awful.key({ modkey }, "w", function()
	-- 	awful.util.mymainmenu:show()
	-- end, { description = "show main menu", group = "awesome" }),

	awful.key({ modkey, "Shift" }, "n", function()
		awful.client.swap.byidx(1)
	end, { description = "swap with next client by index", group = "client" }),

	awful.key({ modkey, "Shift" }, "e", function()
		awful.client.swap.byidx(-1)
	end, { description = "swap with previous client by index", group = "client" }),

	-- Layout manipulation
	awful.key({ modkey }, "m", function()
		awful.tag.incmwfact(-0.05)
	end, { description = "decrease master width factor", group = "layout" }),

	awful.key({ modkey }, "i", function()
		awful.tag.incmwfact(0.05)
	end, { description = "increase master width factor", group = "layout" }),

	awful.key({ modkey, "Control" }, "n", function()
		awful.screen.focus_relative(1)
	end, { description = "focus the next screen", group = "screen" }),

	awful.key({ modkey, "Control" }, "e", function()
		awful.screen.focus_relative(-1)
	end, { description = "focus the previous screen", group = "screen" }),

	-- awful.key({ modkey, }, "u", awful.client.urgent.jumpto,
	--   { description = "jump to urgent client", group = "client" }),

	-- awful.key({ modkey }, "Tab", function()
	-- 	awful.client.focus.history.previous()
	-- 	if client.focus then
	-- 		client.focus:raise()
	-- 	end
	-- end, { description = "go back", group = "client" }),

	-- On the fly useless gaps change
	-- awful.key({ altkey, "Control" }, "+", function()
	-- 	lain.util.useless_gaps_resize(1)
	-- end, { description = "increment useless gaps", group = "tag" }),
	-- awful.key({ altkey, "Control" }, "-", function()
	-- 	lain.util.useless_gaps_resize(-1)
	-- end, { description = "decrement useless gaps", group = "tag" }),

	-- Dynamic tagging
	-- awful.key({ modkey, "Shift" }, "y", function()
	--     lain.util.add_tag()
	-- end, { description = "add new tag", group = "tag" }),
	-- awful.key({ modkey, "Shift" }, "r", function()
	--     lain.util.rename_tag()
	-- end, { description = "rename tag", group = "tag" }),

	-- awful.key({ modkey, "Shift" }, "Left", function()
	-- 	lain.util.move_tag(-1)
	-- end, { description = "move tag to the left", group = "tag" }),

	-- awful.key({ modkey, "Shift" }, "Right", function()
	-- 	lain.util.move_tag(1)
	-- end, { description = "move tag to the right", group = "tag" }),

	-- awful.key({ modkey, "Shift" }, "d", function()
	-- 	lain.util.delete_tag()
	-- end, { description = "delete tag", group = "tag" }),
	--  xrandr
	awful.key({ modkey }, "j", function()
		xrandr.xrandr()
	end, { description = "xrandr", group = "awesome" }),

	-- Standard program
	awful.key({ modkey }, "Return", function()
		awful.spawn(terminal)
	end, { description = "open a terminal", group = "launcher" }),

	awful.key({ modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),

	awful.key({ modkey, "Shift" }, "x", awesome.quit, { description = "quit awesome", group = "awesome" }),

	awful.key({ modkey, "Shift" }, "h", function()
		awful.tag.incnmaster(1, nil, true)
	end, { description = "increase the number of master clients", group = "layout" }),

	awful.key({ modkey, "Shift" }, "l", function()
		awful.tag.incnmaster(-1, nil, true)
	end, { description = "decrease the number of master clients", group = "layout" }),

	awful.key({ modkey, "Control" }, "h", function()
		awful.tag.incncol(1, nil, true)
	end, { description = "increase the number of columns", group = "layout" }),

	awful.key({ modkey, "Control" }, "l", function()
		awful.tag.incncol(-1, nil, true)
	end, { description = "decrease the number of columns", group = "layout" }),

	-- awful.key({ modkey }, "space", function()
	-- 	awful.layout.inc(1)
	-- end, { description = "select next", group = "layout" }),

	-- awful.key({ modkey, "Shift" }, "space", function()
	-- 	awful.layout.inc(-1)
	-- end, { description = "select previous", group = "layout" }),

	-- Brightness
	awful.key({}, "XF86MonBrightnessUp", function()
		os.execute("sudo light -A 10")
	end, { description = "+10%", group = "hotkeys" }),
	awful.key({}, "XF86MonBrightnessDown", function()
		os.execute("sudo light -U 10")
	end, { description = "-10%", group = "hotkeys" }),

	-- PulseAudio volume control
	awful.key({}, "XF86AudioRaiseVolume", function()
		os.execute(string.format("pactl set-sink-volume @DEFAULT_SINK@ +10%%"))
	end, { description = "volume up", group = "hotkeys" }),
	awful.key({}, "XF86AudioLowerVolume", function()
		os.execute(string.format("pactl set-sink-volume @DEFAULT_SINK@ -10%%"))
	end, { description = "volume down", group = "hotkeys" }),
	awful.key({}, "XF86AudioMute", function()
		os.execute(string.format("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
	end, { description = "volume mute", group = "hotkeys" }),
	awful.key({}, "XF86AudioMicMute", function()
		os.execute(string.format("pactl set-source-mute 1 toggle"))
	end, { description = "microphone mute", group = "hotkeys" }),

	-- User programs
	-- awful.key({ modkey }, "q", function()
	--     awful.spawn(browser)
	-- end, { description = "run browser", group = "launcher" }),
	-- awful.key({ modkey }, "y", function()
	--     awful.spawn(guieditor)
	-- end, { description = "run gui editor", group = "launcher" }),
	awful.key({}, "XF86Calculator", function()
		awful.spawn("galculator")
	end, { description = "run calculator", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "m", function()
		awful.spawn("toggle_touchpad.sh")
	end, { description = "Toggle touchpad active/inactive", group = "hotkeys" }),
	awful.key({ modkey }, "v", function()
		awful.spawn(password_generator)
	end, { description = "Generate password and place in clipboard buffer", group = "launcher" }),

	awful.key({ modkey, "Control" }, "u", function()
		local c = awful.client.restore()
		-- Focus restored client
		if c then
			client.focus = c
			c:raise()
		end
	end, { description = "restore minimized", group = "client" }),

	-- Prompt
	-- awful.key({ modkey }, "r", function() awful.screen.focused().mypromptbox:run() end,
	--   { description = "run prompt", group = "launcher" }),
	-- Rofi promt
	awful.key({ modkey }, "p", function()
		awful.spawn("rofi -show run")
	end, { description = "run prompt", group = "launcher" }),

	-- Rofi greenclip
	awful.key({ altkey, "Control" }, "h", function()
		awful.spawn("rofi -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}'")
	end, { description = "run prompt", group = "launcher" }),

	awful.key({ modkey }, "x", function()
		awful.prompt.run({
			prompt = "Run Lua code: ",
			textbox = awful.screen.focused().mypromptbox.widget,
			exe_callback = awful.util.eval,
			history_path = awful.util.get_cache_dir() .. "/history_eval",
		})
	end, { description = "lua execute prompt", group = "awesome" })
	--]]
)

clientkeys = config_table.join(
	-- awful.key({ altkey, "Shift" }, "m", lain.util.magnify_client, { description = "magnify client", group = "client" }),
	awful.key({ modkey }, "f", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, { description = "toggle fullscreen", group = "client" }),

	awful.key({ modkey, "Shift" }, "q", function(c)
		c:kill()
	end, { description = "close", group = "client" }),

	-- awful.key({ modkey, "Control" }, "space",
	-- 	awful.client.floating.toggle,
	-- 	{ description = "toggle floating", group = "client" }
	-- ),
	-- awful.key({ modkey, "Control" }, "Return", function(c)
	-- 	c:swap(awful.client.getmaster())
	-- end, { description = "move to master", group = "client" }),

	awful.key({ modkey }, "o", function(c)
		c:move_to_screen()
	end, { description = "move to screen", group = "client" }),

	-- awful.key({ modkey }, "t", function(c)
	-- 	c.ontop = not c.ontop
	-- end, { description = "toggle keep on top", group = "client" }),

	awful.key({ modkey }, "u", function(c)
		-- The client currently has the input focus, so it cannot be
		-- minimized, since minimized clients can't have the focus.
		c.minimized = true
	end, { description = "minimize", group = "client" }),

	awful.key({ modkey, "Shift" }, "f", function(c)
		c.maximized = not c.maximized
		c:raise()
	end, { description = "toggle maximize", group = "client" })
)

-- Bind all key numbers to tags.
for i = 1, 9 do
	-- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
	local descr_view, descr_toggle, descr_move, descr_toggle_focus
	if i == 1 or i == 9 then
		descr_view = { description = "view tag #", group = "tag" }
		descr_toggle = { description = "toggle tag #", group = "tag" }
		descr_move = { description = "move focused client to tag #", group = "tag" }
		descr_toggle_focus = { description = "toggle focused client on tag #", group = "tag" }
	end
	Globalkeys = config_table.join(
		Globalkeys,
		-- View tag only.
		awful.key({ modkey }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, descr_view),
		-- Toggle tag display.
		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end, descr_toggle),
		-- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, descr_move),
		-- Toggle tag on focused client.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end, descr_toggle_focus)
	)
end

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
	end),
	awful.button({ modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.move(c)
	end),
	awful.button({ modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.resize(c)
	end)
)

-- Set keys
root.keys(Globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules =
	{
		-- All clients will match this rule.
		{
			rule = {},
			properties = {
				border_width = beautiful.border_width,
				border_color = beautiful.border_normal,
				focus = awful.client.focus.filter,
				raise = true,
				keys = clientkeys,
				buttons = clientbuttons,
				screen = awful.screen.preferred,
				placement = awful.placement.no_overlap + awful.placement.no_offscreen,
				size_hints_honor = false,
			},
		},
		-- Titlebars
		{ rule_any = { type = { "dialog", "normal" } }, properties = { titlebars_enabled = false } },
		{ rule = { class = "Gimp", role = "gimp-image-window" }, properties = { maximized = true } },

		{
			rule = { instance = "galculator" },
			properties = { floating = true, ontop = true, placement = awful.placement.centered },
		},

		-- Zoom
		{
			rule = { name = "zoom" },
			properties = { floating = true, titlebars_enabled = false },
		},
		{
			rule = { name = "Zoom Meeting" },
			properties = { floating = true, titlebars_enabled = false },
		},
	},
	-- }}}
	-- Enable sloppy focus, so that focus follows mouse.
	client.connect_signal("mouse::enter", function(c)
		c:emit_signal("request::activate", "mouse_enter", { raise = true })
	end)

-- Signals
-- ===================================================================
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
	-- For debugging awful.rules
	-- print('c.class = '..c.class)
	-- print('c.instance = '..c.instance)
	-- print('c.name = '..c.name)

	-- Set every new window as a slave,
	-- i.e. put it at the end of others instead of setting it master.
	if not awesome.startup then
		awful.client.setslave(c)
	end

	-- if awesome.startup
	-- and not c.size_hints.user_position
	-- and not c.size_hints.program_position then
	--     -- Prevent clients from being unreachable after screen count changes.
	--     awful.placement.no_offscreen(c)
	--     awful.placement.no_overlap(c)
	-- end
end)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- Rounded cornered windows
client.connect_signal("manage", function(c)
	c.shape = function(cr, w, h)
		gears.shape.rounded_rect(cr, w, h, 6)
	end
end)

helpers.Spawn_on_tag("MOZ_DBUS_REMOTE=1 firefox -P Private", "firefox", screen[1].tags[1], "class")
helpers.Spawn_on_tag("MOZ_DBUS_REMOTE=1 firefox -P Work", "firefox", screen[1].tags[1], "class")
helpers.Spawn_on_tag("slack", "Slack", screen[1].tags[2], "class")
helpers.Spawn_on_tag(terminal, "Alacritty", screen[1].tags[3], "class")
