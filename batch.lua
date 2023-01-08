local loader = require('serializer')
local path = require('path')
local cutter = require('cut')

local SHORT_CLIP = 11

-- setup

local args = {...}

local folder
local save_to

for i, v in ipairs(args) do
  if v == "--input" then
    folder = args[i+1]
  end
  if v == "--output" then
    save_to = args[i+1]
  end
end

--helper
local function move_to_bin(file, bin)
  local _, name, ext = path.strip_path(file)
  local full_name = name..'.'..ext
  path.create_dir_from(bin)
  print('filename = ', full_name)
  print('bin location = ', bin)
  local trashed_file = path.join({bin, full_name})
  print('file will be moved to = ', trashed_file)
  os.rename(file, trashed_file)
  print('File moved My Lord!!!')
end

local function process_single(file, save_to)
  -- find the name of clip table file
  local clip_table = tostring(file):match("(.+)%..+$") .. ".clp"
  if not path.file_exists(clip_table) then return end
  -- create output dir if it doesn't exist
  if save_to ~= nil then path.create_dir_from(save_to) end
  -- load table from file
  local loops, err = loader.load(clip_table)
  assert(err == nil)

  -- process all regions
  if loops ~= nil then
    -- handsaw instance
    local c = cutter:new(file, save_to)
    for _, loop in pairs(loops) do
      print(loop.a, loop.b)
      -- save a section
      c:define_region(loop)
      -- check if that's a short one
      local len = loop.b - loop.a
      local ok, exit, code
      if len < SHORT_CLIP then
        ok, exit, code = c:transcode_to_prores()
      elseif c.container_from == "mp4" then
        ok, exit, code = c:copy_clip()
      else
        ok, exit, code = c:transcode_to_mp4()
      end

      if code ~= 0 then
        if code == 2 and exit == "signal" then
          print("\n", ok, exit, code)
          print(c.clip_path)
          return
        end
      end
    end
    local ready
    ready, err = path.listdir(c.output_dir)
    print('files Q', #ready)
    print('loops Q', #loops)
    assert(err == nil)
    assert(#ready == #loops)
    print('ALL DONE My Lord!!!')
  end
  local bin = path.join({save_to, '[READY]'})
  move_to_bin(file, bin)
  move_to_bin(clip_table, bin)
end

local files, err = path.listdir(folder)
assert(err == nil)
if files ~= nil then
  for _, file in pairs(files) do
    local _, _, type = path.strip_path(file)
    if type ~= 'clp' then
      process_single(file, save_to)
    end
  end
end
