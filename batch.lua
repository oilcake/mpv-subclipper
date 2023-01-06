local loader = require('serializer')
local path = require('path')
local cutter = require('cut')

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
  if save_to ~= nil then path.create_dir_from(save_to) end
  -- find the name of clip table file
  local clip_table = tostring(file):match("(.+)%..+$") .. ".clp"
  assert(path.file_exists(clip_table))
  -- load table from file
  local loops, err = loader.load(clip_table)
  assert(err == nil)

  -- process all regions
  if loops ~= nil then
    local c = cutter:new(file, save_to)
    for _, loop in pairs(loops) do
      print(loop.a, loop.b)
      -- handsaw instance
      -- save a section
      c:define_region(loop)
      assert(c:copy_clip())
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


local file = '/Volumes/STUFF/[VD]/toCut/Alina Lopez & Evelyn Claire - Menage A Trois With Alina And Evelyn (11.03.2019)_720p.mp4'
local save_to = '/Volumes/STUFF/[VD]/toCut/[OUTPUT]'

process_single(file, save_to)
