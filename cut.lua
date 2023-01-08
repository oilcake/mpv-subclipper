local path = require("path")
--
local FFMPEG = 'ffmpeg'
local SPACE = " "
local INPUT = "-i"
local FROM = "-ss"
local TO = "-to"
local DO_NOT_OVERWRITE = "-n"

local HandSaw = {
  file = nil,
  container = nil,
  output = nil,
  edges = nil, -- loop object
  clip_name = nil,
  clip_path = nil, -- full path to clip
  what_to_do = "-c copy"
}

-- new instance
function HandSaw:new(file, output_location)
  setmetatable({}, HandSaw)
  self.file = file
  local file_location, name, type = path.strip_path(file)
  self.output_dir = path.join({output_location or file_location, name})
  if not output_location then print('saving into default location') end
  path.create_dir_from(self.output_dir)
  self.container = type
  return self
end

function HandSaw:define_region(loop)
  self.edges = loop
end

-- format all needed args
function HandSaw:format_args()
  self.clip_name = string.format("%.2f-%.2f.%s", self.edges.a, self.edges.b, self.container)
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
  local args = self:format_args()
  local ok, exit, code = os.execute(args)
  return ok, exit, code
end

function HandSaw:copy_clip()
  self.what_to_do = "-c copy"
  -- return value is shell's exit code
  return self:do_thing()
end

return HandSaw
