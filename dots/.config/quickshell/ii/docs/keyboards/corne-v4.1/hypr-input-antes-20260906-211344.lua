-- Custom Input Settings
hl.config({
	input = {
		kb_layout = "us, br",
		kb_variant = "intl,",
		kb_options = "",
		sensitivity = -0.1,
		accel_profile = "flat",
		touchpad = {
			natural_scroll = true,
			scroll_factor = 1,
		},
	},
})

-- Device-specific overrides
hl.device({
	name = "ven_04f3:00-04f3:32b4-touchpad",
	sensitivity = 0.7,
})
