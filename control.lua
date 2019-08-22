-- Remote interface
-- remote.call("instant-deconstruction-bugfix", "add", "my-entity-name")
-- remote.call("instant-deconstruction-bugfix", "add", {"entity-name-1", "entity-name-2"})
function add(name)
  if not name then return end
  if type(name) == "table" then
    for _, n in pairs(name) do
      global.names[n] = true
    end
  else
    global.names[name] = true
  end
end
remote.add_interface("instant-deconstruction-bugfix", {add = add})

function on_init()
  global.names = {}
  global.editors = {}
end

function on_player_toggled_map_editor(event)
  if game.players[event.player_index].controller_type == defines.controllers.editor then
    opened_editor(event.player_index)
  else
    closed_editor(event.player_index)
  end
end

function opened_editor(player_index)
  -- Create editor cache
  global.editors[player_index] = {}

  -- Add existing entities to cache
  local entity_names = {}
  for name in pairs(global.names) do
    table.insert(entity_names, name)
  end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = entity_names}) do
      add_to_cache(player_index, entity)
    end
  end
end

function closed_editor(player_index)
  for _, data in pairs(global.editors[player_index]) do
    -- Raise script_raised_destroy if entity was silently deleted
    if data and not data.entity.valid then
      local entity = data.properties
      entity.valid = true
      entity.name = entity.prototype.name
      entity.type = entity.prototype.type
      script.raise_event(defines.events.script_raised_destroy, {entity = entity})
    end
  end

  -- Delete editor cache
  global.editors[player_index] = nil
end

function on_built(event)
  local entity = event.created_entity or event.entity or event.destination
  if not entity or not entity.valid then return end
  if not global.names[entity.name] then return end

  -- Add entity to cache
  for player_index in pairs(global.editors) do
    add_to_cache(player_index, entity)
  end
end

function on_destroyed(event)
  if event.mod_name == "instant-deconstruction-bugfix" then return end
  local entity = event.entity
  if not entity or not entity.valid then return end
  if not global.names[entity.name] then return end

  -- Delete entity from cache
  for player_index in pairs(global.editors) do
    global.editors[player_index][entity.unit_number] = nil
  end
end

function add_to_cache(player_index, entity)
  local properties = {
    prototype = entity.prototype,
    unit_number = entity.unit_number,
    surface = entity.surface,
    force = entity.force,
    position = entity.position,
    direction = entity.direction,
  }
  global.editors[player_index][entity.unit_number] = {entity = entity, properties = properties}
end

script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_toggled_map_editor, on_player_toggled_map_editor)
script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)
script.on_event(defines.events.script_raised_revive, on_built)
script.on_event(defines.events.on_entity_cloned, on_built)
script.on_event(defines.events.on_player_mined_entity, on_destroyed)
script.on_event(defines.events.on_robot_mined_entity, on_destroyed)
script.on_event(defines.events.on_entity_died, on_destroyed)
script.on_event(defines.events.script_raised_destroy, on_destroyed)
