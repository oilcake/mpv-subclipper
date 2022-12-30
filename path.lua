local m = {}

local ESCAPERS = {" ", "[", "]", "(", ")", "&" }
local escape_plan = {}
-- fills table with substitutions
for _, escaper in pairs(ESCAPERS) do
	escape_plan[escaper] = "\\"..escaper
end

-- escapes all symbols to use string as shell token
function m.unixize(path)
	local token, _ = path:gsub(".", escape_plan)
	return token
end

function m.strip_path(path_to_file)
	-- returns path, filename, extension
	local path = path_to_file:match('^(/?.+/)')
	local name = path_to_file:match('.+/(.+)%..+$')
	local type = path_to_file:match('.+%.(.+)$')
	return path, name, type
end

--- Check if a file or directory exists in this path
local function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

--- Check if a directory exists in this path
function m.isdir(path)
   -- "/" works on both Unix and Windows
   return exists(path.."/")
end

return m
