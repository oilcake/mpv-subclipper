local path = require("path")
--
local FFMPEG = 'ffmpeg -hide_banner -loglevel warning -stats'
local SPACE = " "
local INPUT = "-i"
local FROM = "-ss"
local TO = "-to"
local COPY = "-c copy"
local CRF_COPY = "-c:v libx264 -preset slow -crf 18"
local DO_NOT_OVERWRITE = "-n"
local PRORES_TRANSCODE = "-c:v prores_ks -profile:v 0"
local PRORES_CONTAINER = "mov"
local MP4_CONTAINER = "mp4"
local FFPROBE = "ffprobe -v error -hide_banner -of default=noprint_wrappers=0 -print_format flat -select_streams v:0 -show_entries stream=width,height,codec_type "

-- main object that handles clip info and runs conversion process
local HandSaw = {
  file = nil,
  container_from = nil,
  container_to = nil,
  width = 0,
  height = 0,
  scaled_height = 0,
  output = nil,
  name_prefix = "",
  edges = nil, -- loop object
  clip_name = nil,
  clip_path = nil, -- full path to clip
  what_to_do = COPY,
  downscale_options = "",
  valid_video = false,
  exit_status = {
    ok = nil,
    status = nil,
    code = nil
  }
}

-- new instance
function HandSaw:new(file, output_location)
  setmetatable({}, self)
  self.__index = self
  self.file = file
  local file_location, name, type = path.strip_path(file)
  file_location = '/'..file_location
  self.output_dir = path.join({output_location or file_location, name})
  if not output_location then print('saving into default location') end
  path.create_dir_from(self.output_dir)
  self.container_from = type
  self.name_prefix = name
  self:get_info()
  self.scaled_height = self.height
  return self
end

function HandSaw:get_info()
  -- this method gets clip dimensions from ffprobe
  -- and checks if video file is valid
  local response = io.popen(FFPROBE..path.escape_shell(self.file))
  if response ~= nil then
    local ffprobe = response:read("*a")
    response:close()
    self.width = tonumber(string.match(ffprobe, ".+width=(%d+)"))
    self.height = tonumber(string.match(ffprobe, ".+height=(%d+)"))
    local codec_type = string.match(ffprobe, [[.+codec_type="(.+)"]])
    if codec_type == "video" then
      self.valid_video = true
    end
  end
end

function HandSaw:define_region(loop)
  -- region of video to cut
  self.edges = loop
end

-- format all needed args
function HandSaw:format_args()
  self.clip_name = string.format("%s-%.2f-%.2f.%s",self.name_prefix, self.edges.a, self.edges.b, self.container_to)
  self.clip_path = path.join({self.output_dir, self.clip_name})
  local args = string.format(
    "%s", FFMPEG..SPACE..
    FROM..SPACE..self.edges.a..SPACE..
    TO..SPACE..self.edges.b..SPACE..
    DO_NOT_OVERWRITE..SPACE..
    INPUT..SPACE..path.escape_shell(self.file)..SPACE..
    self.what_to_do..SPACE..
    path.escape_shell(self.clip_path)
  )
  return args
end

function HandSaw:do_thing()
  -- run ffmpeg and return results from the shell
  local args = self:format_args()
  self.exit_status.ok, self.exit_status.status, self.exit_status.code = os.execute(args)
  return self.exit_status
end

-- helper function
local function downscale_string(height)
  return string.format("-filter:v scale=-1:%d", height)
end

--[[CONVERSION METHODS]]-- 
function HandSaw:copy_clip()
  -- tries to save a lossless copy of video's section
  self.what_to_do = COPY
  self.container_to = self.container_from
  -- returns shell's exit code
  return self:do_thing()
end

function HandSaw:transcode_to_prores()
  self.what_to_do = PRORES_TRANSCODE
  self.container_to = PRORES_CONTAINER
  return self:do_thing()
end

function HandSaw:transcode_to_hq_mp4()
  self.what_to_do = CRF_COPY
  self.container_to = MP4_CONTAINER
  return self:do_thing()
end

function HandSaw:transcode_to_mp4()
  self.what_to_do = ""
  self.container_to = MP4_CONTAINER
  return self:do_thing()
end

function HandSaw:downscale_to_mp4(height)
  self.what_to_do = downscale_string(height)
  self.container_to = MP4_CONTAINER
  return self:do_thing()
end

function HandSaw:downscale_to_prores(height)
  self.what_to_do = PRORES_TRANSCODE..SPACE..downscale_string(height)
  self.container_to = PRORES_CONTAINER
  return self:do_thing()
end

return HandSaw
