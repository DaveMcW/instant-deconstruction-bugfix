### Features
---
The Factorio map editor (/editor) does not support instant deconstruction of complex entities ([72215](https://forums.factorio.com/72215)). Using a deconstruction planner in the map editor will leave pieces of entities behind.

This mod cleans up the broken entities by calling script_raise_destroy after the map editor closes.

### For Modders
---
You must register your entities with the mod to get the script_raise_destroy events.

In info.json, add a dependency on this mod:
```
  "dependencies": ["base", "instant-deconstruction-bugfix"],
```

In control.lua, register your entities in on_init(), and optionally in on_configuration_changed() too:
```
script.on_init(function()
  if remote.interfaces["instant-deconstruction-bugfix"] then
    remote.call("instant-deconstruction-bugfix", "add", "my-entity-name")
    -- Also supports a table of names
    remote.call("instant-deconstruction-bugfix", "add", {"entity-name-1", "entity-name-2"})
  end
end)
```

And of course, it is your job to listen for the script_raise_destroy event and do the appropriate cleanup.
