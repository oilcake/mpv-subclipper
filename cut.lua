local path = require("path")
--
local FFMPEG = 'ffmpeg'
local SPACE = " "
local INPUT = "-i"
local FROM = "-ss"
local TO = "-to"

--
local function create_dir_from(name)
  if not path.isdir(name) then
    os.execute("mkdir "..path.escape_shell(name))
  end
end

--
local HandSaw = {
  file = nil,
  container = nil,
  output = nil,
  edges = nil, -- loop object
  what_to_do = "-c copy"
}

-- new instance
function HandSaw:new(file, edges)
  setmetatable({}, HandSaw)
  self.file = file
  self.edges = edges
  local out_path, name, type = path.strip_path(file)
  self.output = path.join({out_path, name})
  create_dir_from(self.output)
  self.container = type
  return self
end

-- format all needed args
function HandSaw:format_args()
  local clip_name = string.format("%.2f-%.2f.%s", self.edges.a, self.edges.b, self.container)
  local args = string.format(
    "%s", FFMPEG..SPACE..
    FROM..SPACE..self.edges.a..SPACE..
    TO..SPACE..self.edges.b..SPACE..
    INPUT..SPACE..path.escape_shell(self.file)..SPACE..
    self.what_to_do..SPACE..
    path.escape_shell(path.join({self.output, clip_name}))
  )
  return args
end

function HandSaw:do_thing()
  os.execute(self:format_args())
end

function HandSaw:copy_clip()
  self.what_to_do = "-c copy"
  self:do_thing()
end

function HandSaw.carve_section(file, loop)
  local saw = HandSaw:new(file, loop)
  saw:copy_clip()
end

return HandSaw
