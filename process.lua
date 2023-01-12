local batch = require('batch')

-- setup
local args = {...}
local folder
local save_to
local downscale = false
local transcode_all = false
local hq = false
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
  end
  if v == "--transcode_all" then
    transcode_all = true
  end
  if v == "--hq" then
    hq = true
  end
end

--[[conversion]]

-- create batch processor
local b = batch:new(save_to)
-- pass args from command line
b.to_scale = downscale
b.transcode_all = transcode_all
b.hq = hq

-- run process
if b ~= nil then
  b:process_folder(folder)
end
