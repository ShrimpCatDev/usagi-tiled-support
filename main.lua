function _config()
  ---@type Usagi.Config
  return { name = "Tiled Demo", game_id = "com.usagiengine.TILEDDEMO" }
end

function _init()
  -- Live reload preserves globals across saved edits but resets locals.
  -- Stash mutable game state in a capitalized global like `State` so it
  -- survives reloads; F5 calls _init again to reset.
  State = {}
  Tiled=require("tiled")
  Map=Tiled:init("maps.map")
  time=0
end

function _update(dt)
  Map:update(dt)
  time+=dt
end

function _draw(dt)
  gfx.clear(gfx.COLOR_BLACK)
  Map:draw(math.cos(time*2)*12,0)
  gfx.text("Hello, Usagi!", 10, 10, gfx.COLOR_WHITE)
end
