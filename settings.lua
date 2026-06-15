data:extend({
  {
    type = "string-setting",
    name = "real-wind-intensity",
    setting_type = "runtime-global",
    default_value = "balanced",
    allowed_values = {"subtle", "balanced", "strong", "cinematic"},
    order = "a"
  },
  {
    type = "bool-setting",
    name = "real-wind-enable-leaves",
    setting_type = "runtime-global",
    default_value = true,
    order = "b"
  },
  {
    type = "bool-setting",
    name = "real-wind-enable-tree-sway",
    setting_type = "runtime-global",
    default_value = true,
    order = "c"
  },
  {
    type = "bool-setting",
    name = "real-wind-enable-sounds",
    setting_type = "runtime-global",
    default_value = true,
    order = "d"
  },
  {
    type = "double-setting",
    name = "real-wind-sound-volume",
    setting_type = "runtime-global",
    default_value = 1.0,
    minimum_value = 0.0,
    maximum_value = 2.0,
    order = "e"
  },
  {
    type = "bool-setting",
    name = "real-wind-apply-surface-wind",
    setting_type = "runtime-global",
    default_value = true,
    order = "f"
  },
  {
    type = "int-setting",
    name = "real-wind-effect-interval",
    setting_type = "runtime-global",
    default_value = 45,
    minimum_value = 30,
    maximum_value = 240,
    order = "g"
  }
})
