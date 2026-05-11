local batch = require("batch")

-- setup
local args = { ... }
local input_folder
local output_folder
local downscale = false
local scale_to = nil
local transcode_all = true
local hq = false
local short_clip = 13
local remove_original = true

-- parse command line arguments
for i, v in ipairs(args) do
	if v == "--input" then
		input_folder = args[i + 1]
	end
	if v == "--output" then
		output_folder = args[i + 1]
	end
	if v == "--downscale" then
		downscale = true
		scale_to = tonumber(args[i + 1])
	end
	if v == "--short-clip" then
		short_clip = args[i + 1]
	end
	if v == "--copy" then
		transcode_all = false
	end
	if v == "--hq" then
		hq = true
	end
	if v == "--keeporiginal" then
		remove_original = false
	end
end

--[[conversion]]
-- create batch processor
local b = batch:new(output_folder)
-- pass args from command line
if downscale then
	b.to_scale = downscale
	b.target_scaled_height = scale_to
end
b.transcode_all = transcode_all
b.hq = hq
b.short_clip = tonumber(short_clip)
b.remove_original = remove_original

-- run process
if b ~= nil then
	b:process_folder(input_folder)
end
