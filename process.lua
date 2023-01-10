local batch = require('batch')

-- setup

local args = {...}

local folder
local save_to
local downscale = false

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
end

batch.to_scale = downscale
batch.output_folder = save_to
batch.process_folder(folder)
