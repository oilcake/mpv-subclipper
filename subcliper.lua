local mp = require("mp")
local saver = require("serializer")
local path = require('path')

--actual script

local looper = {}

local loops_filename = nil
---------------------
--Loop definition
---------------------
local Loop = {a = 0, b = 0}

function Loop:new(a, b)
  self = {}
  setmetatable({}, self)
  self.a = a
  self.b = b
  return self
end

-- array of loops
local Regions = {}

Index = 1

---------------------
--utils
---------------------
local function scene_list_file_to_regions(filename)
  Regions = {}
  collectgarbage()
  for line in io.lines(filename) do
    local scene_in, scene_out = line:match("start:%s(%d+%.%d+),%send:%s(%d+%.%d+)$")
    print(tonumber(scene_in), tonumber(scene_out))
    table.insert(Regions, Loop:new(tonumber(scene_in), tonumber(scene_out)))
  end
end
---------------------
--actions
---------------------

local function id_next()
  local id = Index
  if id >= #Regions then
    id = 1
  else id = (id + 1)
  end
  return id
end

local function id_prev()
  local id = Index
  if id <= 1 then
    id = #Regions
  else id = id - 1
  end
  return id
end

local function validate_region()
  local loop = Regions[Index]
  if loop.a > loop.b then
    loop.a, loop.b = loop.b, loop.a
  end
end

local function set_loop()
  validate_region()
  local loop = Regions[Index]
  mp.set_property_number("ab-loop-a", loop.a)
  mp.set_property_number("ab-loop-b", loop.b)
  mp.set_property_number("time-pos", loop.a)
  looper.save_loops()
  local message = "from "..loop.a.." to "..loop.b
  print(message)
end

local function unset_loop()
  mp.set_property_native("ab-loop-a", 'no')
  mp.set_property_native("ab-loop-b", 'no')
end

function looper.save_loops()
  assert(saver.save(Regions, loops_filename) == nil )
end

local function remove_region()
  table.remove(Regions, Index)
  unset_loop()
  print('that\'s enough, drop it')
end

function looper.loop_start()
  local loop = Regions[Index]
  loop.a = mp.get_property_number("time-pos")
  set_loop()
end

function looper.loop_end()
  local loop = Regions[Index]
  loop.b = mp.get_property_number("time-pos")
  set_loop()
end

function looper.loop_add()
  local jump_to = Regions[Index].b
  local fin = mp.get_property_number("duration")
  if jump_to ~= fin then
    Index = #Regions + 1
    unset_loop()
    Regions[Index] = Loop:new(jump_to, fin)
    mp.set_property_number("time-pos", jump_to)
    set_loop()
  end
end

function looper.init()
  Index = 1
  unset_loop()
  local err
  loops_filename = mp.get_property("path"):match("(.+)%..+$") .. ".clp"
  local scenes_filename = mp.get_property("path"):match("(.+)%..+$") .. ".scn"
  if not path.file_exists(loops_filename) then
    if path.file_exists(scenes_filename) then
      mp.osd_message("scenes found, initializing loops", 3)
      scene_list_file_to_regions(scenes_filename)
      set_loop()
      return
    end
    -- reset loops
    Regions = {}
    table.insert(Regions, Loop:new(0, mp.get_property_number("duration")))
    return
  end
  print(loops_filename)
  print(mp.get_property('path'))
  -- load table from file
  Regions, err = saver.load(loops_filename)

  assert(err == nil)
  set_loop()
  mp.osd_message("loops found", 1)
end

function looper.reset()
  if loops_filename ~= nil then
    os.remove(loops_filename)
  end
  looper.init()
end

function looper.prev_loop()
  Index = id_prev()
  set_loop()
end

function looper.next_loop()
  Index = id_next()
  set_loop()
end

function looper.loop_drop()
  remove_region()
  if #Regions == 0 then
    if loops_filename ~= nil then
      os.remove(loops_filename)
    end
    looper.init()
    return
  end
  if not Regions[Index] then Index = id_prev() end
  set_loop()
end

function looper.insert_left()
  local loop = Regions[Index]
  local now = mp.get_property_number("time-pos")
  local new_left = Loop:new(loop.a, now)
  table.insert(Regions, Index, new_left)
  local pause = mp.get_property_native("pause")
  if pause then
    loop.a = now
  end
  set_loop()
end

function looper.insert_right()
  local loop = Regions[Index]
  local now = mp.get_property_number("time-pos")
  local new_right = Loop:new(now, loop.b)
  table.insert(Regions, Index+1, new_right)
  local pause = mp.get_property_native("pause")
  if pause then
    loop.b = now
  end
  Index = id_next()
  set_loop()
end

function looper.split_at_play_position()
  local loop = Regions[Index]
  local now = mp.get_property_number("time-pos")
  local new_right = Loop:new(now, loop.b)
  table.insert(Regions, Index+1, new_right)
  loop.b = now
  set_loop()
end

return looper
