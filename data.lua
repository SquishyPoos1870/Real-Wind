local function smoke_animation(scale)
  return {
    filename = "__base__/graphics/entity/smoke-fast/smoke-fast.png",
    priority = "high",
    width = 50,
    height = 50,
    frame_count = 16,
    line_length = 16,
    animation_speed = 0.25,
    scale = scale
  }
end

local function sound_variation(filename, volume)
  return {
    filename = filename,
    volume = volume
  }
end

data:extend({
  {
    type = "trivial-smoke",
    name = "real-wind-leaf-mote",
    duration = 150,
    fade_in_duration = 8,
    fade_away_duration = 82,
    spread_duration = 120,
    start_scale = 0.05,
    end_scale = 0.50,
    color = {r = 0.34, g = 0.28, b = 0.13, a = 0.34},
    cyclic = false,
    affected_by_wind = true,
    show_when_smoke_off = false,
    movement_slow_down_factor = 0.992,
    render_layer = "smoke",
    animation = smoke_animation(0.34)
  },
  {
    type = "trivial-smoke",
    name = "real-wind-leaf-sweep",
    duration = 170,
    fade_in_duration = 6,
    fade_away_duration = 95,
    spread_duration = 145,
    start_scale = 0.08,
    end_scale = 0.78,
    color = {r = 0.24, g = 0.34, b = 0.10, a = 0.24},
    cyclic = false,
    affected_by_wind = true,
    show_when_smoke_off = false,
    movement_slow_down_factor = 0.995,
    render_layer = "smoke",
    animation = smoke_animation(0.44)
  },
  {
    type = "trivial-smoke",
    name = "real-wind-canopy-ripple",
    duration = 95,
    fade_in_duration = 5,
    fade_away_duration = 58,
    spread_duration = 82,
    start_scale = 0.05,
    end_scale = 0.58,
    color = {r = 0.18, g = 0.38, b = 0.12, a = 0.16},
    cyclic = false,
    affected_by_wind = true,
    show_when_smoke_off = false,
    movement_slow_down_factor = 0.997,
    render_layer = "smoke",
    animation = smoke_animation(0.36)
  },
  {
    type = "trivial-smoke",
    name = "real-wind-branch-shiver",
    duration = 72,
    fade_in_duration = 4,
    fade_away_duration = 44,
    spread_duration = 60,
    start_scale = 0.04,
    end_scale = 0.42,
    color = {r = 0.14, g = 0.30, b = 0.10, a = 0.18},
    cyclic = false,
    affected_by_wind = true,
    show_when_smoke_off = false,
    movement_slow_down_factor = 0.998,
    render_layer = "smoke",
    animation = smoke_animation(0.30)
  },
  {
    type = "trivial-smoke",
    name = "real-wind-forest-gust",
    duration = 220,
    fade_in_duration = 10,
    fade_away_duration = 130,
    spread_duration = 185,
    start_scale = 0.10,
    end_scale = 1.25,
    color = {r = 0.28, g = 0.32, b = 0.18, a = 0.16},
    cyclic = false,
    affected_by_wind = true,
    show_when_smoke_off = false,
    movement_slow_down_factor = 0.994,
    render_layer = "smoke",
    animation = smoke_animation(0.66)
  },
  {
    type = "sound",
    name = "real-wind-gust-whoosh",
    variations = {
      sound_variation("__real-wind__/sounds/real-wind-gust-whoosh.ogg", 0.95)
    }
  }
})
