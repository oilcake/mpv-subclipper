local loader = require("serializer")
local path = require("path")
local cutter = require("cut")

local DEFINITION_THRESHOLD = 721

local Batch = {
	transcode_all = false,
	hq = false,
	to_scale = false,
	target_scaled_height = 0,
	output_folder = nil,
	short_clip = 7, -- threshold after which a clip is considered 'long'
	log = nil,
	remove_original = true,
}

function Batch:new(output_folder)
	-- setmetatable({}, self)
	self.output_folder = output_folder
	local logname = output_folder .. "/log.txt"
	self.log = io.open(logname, "w")
	io.output(self.log)
	return self
end

function Batch:process_single_clip(clip, loop)
	-- mostly choose correct type of processing here
	-- check if that's a short one
	local len = loop.b - loop.a
	-- short clips better be transcoded to non-temporal codec
	-- cause they are more likely to be played backwards
	if len < self.short_clip then
		return clip:transcode_to_prores()
	end
	-- copy flag
	if not self.transcode_all then
		return clip:copy_clip()
	end
	-- hiQ flag
	if self.to_scale and clip.height > DEFINITION_THRESHOLD then
		return clip:downscale_to_mp4(self.target_scaled_height)
	end
	-- not copy flag
	if self.transcode_all then
		if self.hq then
			return clip:transcode_to_hq_mp4()
		else
			return clip:transcode_to_mp4()
		end
	end
end

function Batch:process_single(file)
	if not path.file_exists(file) then
		return true
	end
	-- find the name of clip table file
	local clip_table = tostring(file):match("(.+)%..+$") .. ".clp"
	if not path.file_exists(clip_table) then
		return true
	end
	-- handsaw instance
	local clip = cutter:new(file, self.output_folder)
	if not clip.valid_video then
		return true
	end
	io.write("processing file:\n", file, "\n")
	io.write(string.format("\nwidth = %d\nheight = %d\n", clip.width, clip.height))
	-- create output dir if it doesn't exist
	if self.output_folder ~= nil then
		path.create_dir_from(self.output_folder)
	end
	-- load table from file
	local loops, err = loader.load(clip_table)
	if err ~= nil then
		io.write(file, "\n: couldn't open loops\n")
		return true
	end

	-- process all regions
	if loops ~= nil then
		-- initialize shell's response
		local status = {}
		for _, loop in pairs(loops) do
			-- to save a section from current clip
			clip:define_region(loop)
			status = self:process_single_clip(clip, loop)

			if status.code ~= 0 then
				io.write(string.format("\nok - %s\nexit - %s\ncode - %s\n", status.ok, status.exit, status.code))
				if status.code == 255 then
					io.write(string.format("\nmost probably incomplete and will be deleted:\n%s\n", clip.clip_name))
					os.remove(clip.clip_path)
					return nil
				elseif status.code == 1 and path.exists(clip.clip_path) then
					io.write(string.format("looks like file exists, skipping\n"))
				else
					io.write("\nunexpected error\n")
					return false
				end
			end
		end
		local ready
		ready, err = path.listdir(clip.output_dir)
		if err ~= nil then
			io.write("\nsomething is terribly wrong with:\n ", clip.output_dir, "\n")
		end
		if #ready == #loops then
			io.write(string.format("\nprocessed successfully:\n%s\n", clip.name_prefix))
		else
			io.write(string.format("\nsome files are missing:\n%s\n", clip.name_prefix))
		end
	end
	if self.remove_original then
		local bin = path.join({ self.output_folder, "__READY" })
		path.move(file, bin)
		path.move(clip_table, bin)
		io.write(string.format("\nvideo and it's loop-file moved to bin\n\n"))
	end
	return true
end

function Batch:process_folder(folder)
	local done
	local files, err = path.listdir(folder)
	assert(err == nil)
	if files ~= nil then
		for _, file in pairs(files) do
			local _, _, type = path.strip_path(file)
			if type ~= "clp" then
				done = Batch:process_single(file)
				if done == nil then
					io.write("\nstop requested\n")
					return
				elseif done == false then
					io.write("\nerrors occurred\n")
					return
				end
			end
		end
	end
	io.write("\nsuccess!\n")
	self.log:close()
end

return Batch
