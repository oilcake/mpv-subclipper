local path = require("path")
--
local ffmpeg = 'ffmpeg'
local space = " "
--
--
local HandSaw = {
  file = nil,
  container = nil,
  output = nil,
  input = "-i",
  edges = nil, -- loop object
  from = "-ss",
  to = "-to",
  what_to_do = "-c copy"
}

-- new instance
function HandSaw:new(file, edges)
  setmetatable({}, HandSaw)
  self.file = file
  self.edges = edges
  return self
end

-- format all needed args
function HandSaw:format_args()
  local clip_name = string.format("%.2f-%.2f.%s", self.edges.a, self.edges.b, self.container)
  local args = string.format(
    "%s", ffmpeg..space..
    self.from..space..self.edges.a..space..
    self.to..space..self.edges.b..space..
    self.input..space..path.escape_shell(self.file)..space..
    self.what_to_do..space..
    path.escape_shell(path.join({self.output, clip_name}))
  )
  return args
end

function HandSaw:do_thing()
  os.execute(self:format_args())
end

local function create_dir_from(name)
  if not path.isdir(name) then
    os.execute("mkdir "..path.escape_shell(name))
  end
end

function HandSaw.carve_section(file, loop)
  local saw = HandSaw:new(file, loop)
  local out_path, name, type = path.strip_path(file)
  saw.output = path.join({out_path, name})
  create_dir_from(saw.output)
  saw.container = type
  print(saw:format_args())
  saw:do_thing()
end

return HandSaw
