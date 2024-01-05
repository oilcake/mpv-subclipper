local mp = require("mp")
local looper = require("subcliper")

mp.register_event("file-loaded", looper.init)

mp.add_key_binding("^", "start", looper.loop_start)
mp.add_key_binding("&", "end", looper.loop_end)
mp.add_key_binding("+", "new", looper.loop_add)
mp.add_key_binding("H", "remove", looper.loop_drop)
mp.add_key_binding("g", "prev", looper.prev_loop)
mp.add_key_binding("h", "next", looper.next_loop)
mp.add_key_binding("(", "right", looper.insert_right)
mp.add_key_binding(")", "left", looper.insert_left)
mp.add_key_binding("k", "split", looper.split_at_play_position)
mp.add_key_binding("K", "reset", looper.reset)

--[[
mp.add_key_binding("§", "save", add your function here)
--]]
