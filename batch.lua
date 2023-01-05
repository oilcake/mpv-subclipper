local loader = require('serializer')
local path = require('path')
local cutter = require('cut')


local function process_single(file)
  -- find the name of clip table file
  local clip_table = tostring(file):match("(.+)%..+$") .. ".clp"
  assert(path.file_exists(clip_table))
  -- load table from file
  local loops, err = loader.load(clip_table)
  assert(err == nil)

  if loops ~= nil then
    for _, loop in pairs(loops) do
      print(loop.a, loop.b)
      -- handsaw instance
      local c = cutter:new(file, loop)
      -- save a section
      c:copy_clip()
    end
  end
end

local file = '/Volumes/STUFF/[VD]/toCut/Alina Lopez & Evelyn Claire - Menage A Trois With Alina And Evelyn (11.03.2019)_720p.mp4'

process_single(file)
