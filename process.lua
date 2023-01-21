local batch = require('batch')

-- setup
local args = {...}
local folder
local save_to
local downscale = false
local scale_to = nil
local transcode_all = true
local hq = false
local short_clip = 13

-- parse command line arguments
for i, v in ipairs(args) do
  if v == "--input" then
    folder = args[i+1]
  end
  if v == "--output" then
    save_to = args[i+1]
  end
  if v == "--downscale" then
    downscale = true
    scale_to = args[i+1]
  end
  if v == "--short_clip" then
    short_clip = args[i+1]
  end
  if v == "--try_copy" then
    transcode_all = false
  end
  if v == "--hq" then
    hq = true
  end
end

--[[conversion]]

-- create batch processor
local b = batch:new(save_to)
-- pass args from command line
if downscale then
  b.to_scale = downscale
  b.target_scaled_height = scale_to
end
b.transcode_all = transcode_all
b.hq = hq
b.short_clip = tonumber(short_clip)

-- run process
if b ~= nil then
  b:process_folder(folder)
end
