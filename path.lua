local M = {}

function M.escape_shell(s)
  -- only for paths and names
  -- do not use it if you want to pass literal "&" or "&&" to your shell
  return(s:gsub('([ %(%)%\\%[%]\'"&])', '\\%1'))
end

function M.strip_path(path_to_file)
  -- returns path, filename, extension
  local path = path_to_file:match('^/?(.+)/')
  local name = path_to_file:match('.+/(.+)%..+$')
  local type = path_to_file:match('.+%.(.+)$')
  return path, name, type
end

function M.join(parts)
  -- joins parts of the full path, substitution of python's path.join
  local slash = "/"
  local joined = ""
  joined = table.concat(parts, slash)
  return joined
end

function M.exists(file)
  --- checks if a file or directory exists in this path
  local ok, err, code = os.rename(file, file)
  if not ok then
    if code == 13 then
      -- permission denied, but it exists
      return true
    end
  end
  return ok, err
end

function M.isdir(path)
  -- checks if a directory exists in this path
  -- "/" works on both Unix and Windows
  return M.exists(path.."/")
end

function M.listdir(dir)
  -- opens directory looks for files
  -- accepts unescaped path
  local files = {}
  local p = io.popen('find "'..dir..'" -type f')
  -- loop through all files
  if p == nil then return nil, error("couldn't read dir") end
  for file in p:lines() do
    if not file:match('^.+/%..+') then
      table.insert(files, file)
    end
  end
  return files, nil
end

function M.file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end

function M.create_dir_from(name)
  if not M.isdir(name) then
    os.execute("mkdir "..M.escape_shell(name))
  end
end

function M.move(file, new_path)
  -- moves file to new location
  local _, name, ext = M.strip_path(file)
  local full_name = name..'.'..ext
  M.create_dir_from(new_path)
  local moved = M.join({new_path, full_name})
  os.rename(file, moved)
end

return M
