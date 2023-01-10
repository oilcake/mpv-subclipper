local loader = require('serializer')
local path = require('path')
local cutter = require('cut')

local batch = {
  to_scale = false,
  output_folder = nil,
  with_log = true,
  short_clip = 11 -- threshold after wich a clip is considered 'long'
}

function batch:process_single(file)
  if not path.file_exists(file) then return true end
  -- find the name of clip table file
  local clip_table = tostring(file):match("(.+)%..+$") .. ".clp"
  if not path.file_exists(clip_table) then return true end
  -- create output dir if it doesn't exist
  if self.output_folder ~= nil then path.create_dir_from(self.output_folder) end
  -- load table from file
  local loops, err = loader.load(clip_table)
  assert(err == nil)

  -- process all regions
  if loops ~= nil then
    -- initialize shell's response
    local ok, exit, code
    -- handsaw instance
    local c = cutter:new(file, self.output_folder)
    for _, loop in pairs(loops) do
      -- to save a section from current loop
      c:define_region(loop)
      -- check if that's a short one
      local len = loop.b - loop.a
      -- check if it's hiQ
      if self.to_scale and (c.height > 721) then c:set_downscaled_height_to(540) end
      if len < self.short_clip then
        ok, exit, code = c:transcode_to_prores()
      elseif c.container_from == "mp4" then
        ok, exit, code = c:copy_clip()
      else
        ok, exit, code = c:transcode_to_mp4()
      end

      if code ~= 0 then
        print("\n", ok, exit, code)
        print(c.clip_path, " is most probably incomplete and will be deleted")
        os.remove(c.clip_path)
        return false
      end
    end
    local ready
    ready, err = path.listdir(c.output_dir)
    print('files Q', #ready)
    print('loops Q', #loops)
    assert(err == nil)
    assert(#ready == #loops)
    print('ALL DONE My Lord!!!')
  end
  local bin = path.join({self.output_folder, '[READY]'})
  path.move_to_bin(file, bin)
  path.move_to_bin(clip_table, bin)
  return true
end

function batch.process_folder(folder)
  local files, err = path.listdir(folder)
  assert(err == nil)
  if files ~= nil then
    for _, file in pairs(files) do
      local _, _, type = path.strip_path(file)
      if type ~= 'clp' then
        print("processing ", file)
        if not batch:process_single(file) then print("errors occured"); return end
      end
    end
  end
end

return batch
