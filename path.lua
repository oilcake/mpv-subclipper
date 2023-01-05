local M = {}

function M.escape_shell(s)
   return(s:gsub('([ %(%)%\\%[%]\'"&])', '\\%1'))
end

function M.strip_path(path_to_file)
  -- returns path, filename, extension
  local path = path_to_file:match('^/?(.+)/')
  local name = path_to_file:match('.+/(.+)%..+$')
  local type = path_to_file:match('.+%.(.+)$')
  return path, name, type
end

function M.join(...)
  local slash = "/"
  local joined = ""
  for _, location in pairs(...) do
    joined = joined..slash..tostring(location)
  end
  return joined
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
function M.isdir(path)
  -- "/" works on both Unix and Windows
  return exists(path.."/")
end

-- accepts unescaped path
function M.listdir(dir)
  --Open directory look for files, save data in p. 
  --By giving '-type f' as parameter, it returns all files.     
  local files = {}
  local p = io.popen('find "'..dir..'" -type f')
  --Loop through all files
  if p == nil then return nil, error("couldn't read dir") end
  for file in p:lines() do
    table.insert(files, file)
    print(file)
  end
  return files, nil
end

function M.file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end

return M
