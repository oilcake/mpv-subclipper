local batch = require('batch')

-- setup

local args = {...}

local folder
local save_to
local downscale = false
local transcode_all = false
local hq = false
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

batch:new(save_to)
batch.to_scale = downscale
batch.transcode_all = transcode_all
batch.hq = hq
batch:process_folder(folder)
