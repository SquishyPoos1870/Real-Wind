local TWO_PI = math.pi * 2

local PROFILES = {
  subtle = {
    base_speed = 0.012,
    gust_speed = 0.040,
    orientation_change = 0.000012,
    tree_scan_limit = 22,
    tree_radius = 38,
    leaf_chance = 0.42,
    leaf_bursts = 2,
    canopy_chance = 0.34,
    canopy_puffs = 1,
    forest_gust_chance = 0.08,
    sound_chance = 0.78
  },
  balanced = {
    base_speed = 0.022,
    gust_speed = 0.078,
    orientation_change = 0.000022,
    tree_scan_limit = 40,
    tree_radius = 52,
    leaf_chance = 0.68,
    leaf_bursts = 4,
    canopy_chance = 0.60,
    canopy_puffs = 3,
    forest_gust_chance = 0.18,
    sound_chance = 0.90
  },
  strong = {
    base_speed = 0.036,
    gust_speed = 0.125,
    orientation_change = 0.000036,
    tree_scan_limit = 60,
    tree_radius = 64,
    leaf_chance = 0.86,
    leaf_bursts = 6,
    canopy_chance = 0.78,
    canopy_puffs = 4,
    forest_gust_chance = 0.34,
    sound_chance = 0.96
  },
  cinematic = {
    base_speed = 0.055,
    gust_speed = 0.190,
    orientation_change = 0.000055,
    tree_scan_limit = 84,
    tree_radius = 76,
    leaf_chance = 0.96,
    leaf_bursts = 8,
    canopy_chance = 0.92,
    canopy_puffs = 6,
    forest_gust_chance = 0.52,
    sound_chance = 1.00
  }
}

local function setting_value(name)
  local entry = settings.global[name]
  return entry and entry.value
end

local function get_profile()
  return PROFILES[setting_value("real-wind-intensity") or "balanced"] or PROFILES.balanced
end

local function setup_storage()
  storage.real_wind = storage.real_wind or {}
  storage.real_wind.surfaces = storage.real_wind.surfaces or {}
  storage.real_wind.player_sounds = storage.real_wind.player_sounds or {}
  storage.real_wind.weather_boosts = storage.real_wind.weather_boosts or {}
end

local function is_nauvis_surface(surface)
  return surface and surface.valid and surface.name == "nauvis"
end

local function should_skip_surface(surface)
  if not surface or not surface.valid then return true end
  if surface.platform then return true end
  return not is_nauvis_surface(surface)
end

local function surface_state(surface)
  setup_storage()
  local states = storage.real_wind.surfaces
  local state = states[surface.index]
  if not state then
    state = {
      orientation = surface.wind_orientation or math.random(),
      target_orientation = math.random(),
      speed = surface.wind_speed or 0.022,
      target_speed = 0.022,
      next_shift = 0
    }
    states[surface.index] = state
  end
  return state
end

local function angular_delta(from_value, to_value)
  return (to_value - from_value + 0.5) % 1 - 0.5
end

local function orientation_to_vector(orientation)
  local angle = orientation * TWO_PI
  return {x = math.sin(angle), y = -math.cos(angle)}
end

local function distance_squared(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y
  return dx * dx + dy * dy
end

local function clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function copy_profile(profile)
  local out = {}
  for key, value in pairs(profile) do
    out[key] = value
  end
  return out
end

local function current_weather_boost(surface, tick)
  setup_storage()
  local boosts = storage.real_wind.weather_boosts
  local boost = boosts and boosts[surface.index]
  if not boost then return nil end

  if (boost.expires_tick or 0) < tick then
    boosts[surface.index] = nil
    return nil
  end

  return boost
end

local function weather_adjusted_profile(surface, profile, tick)
  local boost = current_weather_boost(surface, tick or game.tick)
  if not boost then return profile end

  local storm = clamp(tonumber(boost.storm_factor) or 1, 0.5, 3.0)
  local rain_strength = clamp(tonumber(boost.rain_strength) or 1, 0.0, 1.0)
  local multiplier = 1.0 + rain_strength * (0.30 + storm * 0.22)

  local out = copy_profile(profile)
  out.base_speed = profile.base_speed * multiplier
  out.gust_speed = profile.gust_speed * (1.0 + rain_strength * (0.45 + storm * 0.28))
  out.orientation_change = profile.orientation_change * (1.0 + rain_strength * (1.0 + storm * 0.45))
  out.leaf_chance = clamp(profile.leaf_chance + rain_strength * (0.12 + storm * 0.06), 0, 1)
  out.canopy_chance = clamp(profile.canopy_chance + rain_strength * (0.10 + storm * 0.05), 0, 1)
  out.forest_gust_chance = clamp(profile.forest_gust_chance + rain_strength * (0.16 + storm * 0.08), 0, 1)
  out.sound_chance = clamp(profile.sound_chance + rain_strength * 0.08, 0, 1)
  out.leaf_bursts = profile.leaf_bursts + math.floor(1 + storm * 0.8)
  out.canopy_puffs = profile.canopy_puffs + math.floor(1 + storm * 0.7)
  return out
end

local function choose_surface_targets(state, profile, tick)
  if tick < state.next_shift then return end

  state.target_orientation = (state.orientation + (math.random() * 0.46 - 0.23)) % 1

  if math.random() < 0.54 then
    state.target_speed = profile.gust_speed * (0.82 + math.random() * 0.58)
  else
    state.target_speed = profile.base_speed * (0.85 + math.random() * 0.52)
  end

  state.next_shift = tick + math.random(660, 1860)
end

local function update_surface_wind(surface, profile, tick)
  local state = surface_state(surface)
  local adjusted_profile = weather_adjusted_profile(surface, profile, tick)
  choose_surface_targets(state, adjusted_profile, tick)

  local boost = current_weather_boost(surface, tick)
  if boost then
    local storm = clamp(tonumber(boost.storm_factor) or 1, 0.5, 3.0)
    local rain_strength = clamp(tonumber(boost.rain_strength) or 1, 0.0, 1.0)
    local pushed_speed = (tonumber(boost.wind_speed) or 0)
    if pushed_speed <= 0 then
      pushed_speed = adjusted_profile.gust_speed * (0.62 + storm * 0.18) * math.max(0.25, rain_strength)
    end
    state.target_speed = math.max(state.target_speed, pushed_speed)

    if type(boost.wind_orientation) == "number" then
      state.target_orientation = boost.wind_orientation % 1
    elseif boost.wind_bucket == "left" then
      state.target_orientation = 0.78
    elseif boost.wind_bucket == "right" then
      state.target_orientation = 0.22
    elseif boost.wind_bucket == "gust" then
      state.target_orientation = 0.82
    end
  end

  local delta = angular_delta(state.orientation, state.target_orientation)
  state.orientation = (state.orientation + delta * 0.052) % 1
  state.speed = state.speed + (state.target_speed - state.speed) * 0.070

  if setting_value("real-wind-apply-surface-wind") then
    surface.wind_orientation = state.orientation
    surface.wind_speed = math.max(0.0001, state.speed)
    surface.wind_orientation_change = adjusted_profile.orientation_change
  end
end

local function create_smoke(surface, name, position)
  surface.create_trivial_smoke{
    name = name,
    position = position
  }
end

local function create_leaf_mote(surface, position)
  create_smoke(surface, "real-wind-leaf-mote", position)
end

local function create_leaf_sweep(surface, position)
  create_smoke(surface, "real-wind-leaf-sweep", position)
end

local function create_canopy_ripple(surface, position)
  create_smoke(surface, "real-wind-canopy-ripple", position)
end

local function create_branch_shiver(surface, position)
  create_smoke(surface, "real-wind-branch-shiver", position)
end

local function create_forest_gust(surface, position)
  create_smoke(surface, "real-wind-forest-gust", position)
end

local function player_ready(player)
  return player and player.valid and player.connected and player.character and player.surface and player.surface.valid
end

local function find_nearby_trees(player, profile)
  if not player_ready(player) then return nil end
  local surface = player.surface
  if should_skip_surface(surface) then return nil end

  local pos = player.position
  local radius = profile.tree_radius
  return surface.find_entities_filtered{
    area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}},
    type = "tree",
    limit = profile.tree_scan_limit
  }
end

local function spawn_tree_wind_fx(surface, tree, profile, state)
  local wind = orientation_to_vector(state.orientation)
  local tree_position = tree.position
  local strong_gust = state.speed > profile.base_speed * 1.7

  if setting_value("real-wind-enable-leaves") then
    local bursts = strong_gust and profile.leaf_bursts + 1 or profile.leaf_bursts
    for _ = 1, bursts do
      local side = math.random() * 2.5
      local pos = {
        x = tree_position.x - wind.x * side + (math.random() * 2 - 1) * 1.25,
        y = tree_position.y - wind.y * side + (math.random() * 2 - 1) * 1.25
      }
      if math.random() < 0.38 then
        create_leaf_sweep(surface, pos)
      else
        create_leaf_mote(surface, pos)
      end
    end
  end

  if setting_value("real-wind-enable-tree-sway") then
    create_branch_shiver(surface, {
      x = tree_position.x + (math.random() * 2 - 1) * 0.60,
      y = tree_position.y + (math.random() * 2 - 1) * 0.60
    })

    if math.random() < profile.canopy_chance then
      local ripples = strong_gust and profile.canopy_puffs + 2 or profile.canopy_puffs
      for _ = 1, ripples do
        local pos = {
          x = tree_position.x + wind.x * (math.random() * 2.2) + (math.random() * 2 - 1) * 1.0,
          y = tree_position.y + wind.y * (math.random() * 2.2) + (math.random() * 2 - 1) * 1.0
        }
        create_canopy_ripple(surface, pos)
      end
    end

    if strong_gust and math.random() < profile.forest_gust_chance then
      local pos = {
        x = tree_position.x - wind.x * math.random(2, 5) + (math.random() * 2 - 1) * 1.5,
        y = tree_position.y - wind.y * math.random(2, 5) + (math.random() * 2 - 1) * 1.5
      }
      create_forest_gust(surface, pos)
    end
  end
end

local function play_positional_for_player(player, path, source_position, volume)
  if not source_position or not volume or volume <= 0 then return false end

  local ok = pcall(function()
    player.play_sound{
      path = path,
      position = source_position,
      volume_modifier = volume,
      override_sound_type = "environment"
    }
  end)

  return ok
end

local function get_player_sound_state(player)
  setup_storage()
  local player_sounds = storage.real_wind.player_sounds
  local sound_state = player_sounds[player.index]

  if type(sound_state) ~= "table" then
    sound_state = {
      next_whoosh = tonumber(sound_state) or 0
    }
    player_sounds[player.index] = sound_state
  end

  sound_state.next_whoosh = sound_state.next_whoosh or 0
  return sound_state
end

local function closest_tree_to_player(player, trees)
  if not trees or #trees == 0 then return nil, nil, nil end

  local player_position = player.position
  local closest_tree = nil
  local closest_distance_sq = nil

  for _, tree in pairs(trees) do
    if tree and tree.valid then
      local distance_sq = distance_squared(player_position, tree.position)
      if not closest_distance_sq or distance_sq < closest_distance_sq then
        closest_tree = tree
        closest_distance_sq = distance_sq
      end
    end
  end

  if not closest_tree then return nil, nil, nil end
  return closest_tree, math.sqrt(closest_distance_sq), closest_distance_sq
end

local function maybe_play_sound(player, profile, state, trees)
  if not setting_value("real-wind-enable-sounds") then return end
  if not player_ready(player) then return end
  if should_skip_surface(player.surface) then return end
  if not trees or #trees <= 0 then return end

  local closest_tree, distance = closest_tree_to_player(player, trees)
  if not closest_tree or not closest_tree.valid or not distance then return end

  local base_volume = tonumber(setting_value("real-wind-sound-volume")) or 1.0
  if base_volume <= 0 then return end

  local tick = game.tick
  local sound_state = get_player_sound_state(player)
  local source_position = closest_tree.position
  local radius = math.max(12, profile.tree_radius or 52)
  local distance_factor = clamp((radius - distance) / math.max(1, radius - 4), 0.0, 1.0)
  if distance_factor <= 0 then return end

  local wind_factor = clamp(state.speed / math.max(0.001, profile.gust_speed), 0.35, 1.15)
  local strong_gust = state.speed > profile.base_speed * 1.75
  local whoosh_chance = clamp(0.04 + (profile.sound_chance or 0.80) * 0.08 + wind_factor * 0.04, 0.06, 0.18)

  if tick >= sound_state.next_whoosh and (strong_gust or math.random() < whoosh_chance) then
    local whoosh_volume = base_volume * (0.35 + wind_factor * 0.55) * (0.20 + distance_factor * 0.80)
    whoosh_volume = clamp(whoosh_volume, 0.05, 1.85)

    if play_positional_for_player(player, "real-wind-gust-whoosh", source_position, whoosh_volume) then
      sound_state.next_whoosh = tick + math.random(900, 1800)
    else
      sound_state.next_whoosh = tick + math.random(1200, 2200)
    end
  end
end

local function spawn_tree_effects_for_player(player, profile)
  if not setting_value("real-wind-enable-leaves") and not setting_value("real-wind-enable-tree-sway") and not setting_value("real-wind-enable-sounds") then return end

  local trees = find_nearby_trees(player, profile)
  if not trees or #trees == 0 then return end

  local surface = player.surface
  local state = surface_state(surface)

  -- Wind audio is checked before the visual density roll so gusts remain responsive.
  maybe_play_sound(player, profile, state, trees)

  if not setting_value("real-wind-enable-leaves") and not setting_value("real-wind-enable-tree-sway") then return end
  if math.random() > profile.leaf_chance then return end

  local trees_to_use = math.min(#trees, math.max(2, math.floor(profile.tree_scan_limit * 0.42)))
  for _ = 1, trees_to_use do
    local tree = trees[math.random(1, #trees)]
    if tree and tree.valid then
      spawn_tree_wind_fx(surface, tree, profile, state)
    end
  end
end

local function main_tick(event)
  setup_storage()

  local interval = tonumber(setting_value("real-wind-effect-interval")) or 45
  local profile = get_profile()

  for _, surface in pairs(game.surfaces) do
    if not should_skip_surface(surface) then
      update_surface_wind(surface, profile, event.tick)
    end
  end

  storage.real_wind.next_effect_tick = storage.real_wind.next_effect_tick or 0
  if event.tick < storage.real_wind.next_effect_tick then return end
  storage.real_wind.next_effect_tick = event.tick + interval

  for _, player in pairs(game.connected_players) do
    if player and player.valid and player.surface and player.surface.valid then
      spawn_tree_effects_for_player(player, weather_adjusted_profile(player.surface, profile, event.tick))
    end
  end
end

script.on_init(function()
  setup_storage()
end)

script.on_configuration_changed(function()
  setup_storage()
end)

script.on_nth_tick(30, main_tick)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event and string.sub(event.setting or "", 1, 9) == "real-wind" then
    setup_storage()
    storage.real_wind.next_effect_tick = 0
    storage.real_wind.player_sounds = {}
    local player = event.player_index and game.get_player(event.player_index)
    if player and player.valid then
      player.print({"real-wind.message-settings-updated"})
    end
  end
end)

local function resolve_surface(surface_index)
  if type(surface_index) ~= "number" then return nil end
  return game.surfaces[surface_index]
end

remote.add_interface("real-wind", {
  set_weather_boost = function(surface_index, boost)
    local surface = resolve_surface(surface_index)
    if should_skip_surface(surface) then return false end
    if type(boost) ~= "table" then boost = {} end

    setup_storage()
    local ttl = clamp(math.floor(tonumber(boost.ttl) or 120), 30, 600)
    storage.real_wind.weather_boosts[surface.index] = {
      expires_tick = game.tick + ttl,
      storm_factor = clamp(tonumber(boost.storm_factor) or 1, 0.5, 3.0),
      rain_strength = clamp(tonumber(boost.rain_strength) or 1, 0.0, 1.0),
      wind_speed = tonumber(boost.wind_speed) or nil,
      wind_orientation = tonumber(boost.wind_orientation) or nil,
      wind_bucket = boost.wind_bucket,
      source = boost.source or "unknown"
    }
    return true
  end,

  clear_weather_boost = function(surface_index)
    local surface = resolve_surface(surface_index)
    if not surface then return false end
    setup_storage()
    storage.real_wind.weather_boosts[surface.index] = nil
    return true
  end,

  get_wind = function(surface_index)
    local surface = resolve_surface(surface_index)
    if should_skip_surface(surface) then return nil end

    setup_storage()
    local state = surface_state(surface)
    local boost = current_weather_boost(surface, game.tick)
    return {
      speed = state.speed or surface.wind_speed or 0,
      target_speed = state.target_speed or 0,
      orientation = state.orientation or surface.wind_orientation or 0,
      orientation_change = surface.wind_orientation_change or 0,
      boosted = boost ~= nil,
      storm_factor = boost and boost.storm_factor or 1,
      rain_strength = boost and boost.rain_strength or 0,
      wind_bucket = boost and boost.wind_bucket or nil
    }
  end
})

commands.add_command("real-wind", {"real-wind.command-help"}, function(command)
  local player = command.player_index and game.get_player(command.player_index)
  local profile_name = setting_value("real-wind-intensity") or "balanced"
  local profile = get_profile()
  local target = player or game
  target.print({"real-wind.message-status", profile_name, string.format("%.4f", profile.base_speed), string.format("%.4f", profile.gust_speed)})
end)

commands.add_command("real-wind-gust", {"real-wind.command-gust-help"}, function(command)
  local player = command.player_index and game.get_player(command.player_index)
  if player and not player.admin then
    player.print({"real-wind.message-admin-only"})
    return
  end

  setup_storage()
  local profile = get_profile()
  for _, surface in pairs(game.surfaces) do
    if not should_skip_surface(surface) then
      local state = surface_state(surface)
      state.target_speed = profile.gust_speed * 1.55
      state.target_orientation = (state.orientation + (math.random() * 0.60 - 0.30)) % 1
      state.next_shift = game.tick + 900
    end
  end

  storage.real_wind.player_sounds = {}

  local target = player or game
  target.print({"real-wind.message-gust"})
end)
