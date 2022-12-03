
local mp = require("mp")
local looper = require("subcliper")

mp.register_event("file-loaded", looper.init)

mp.add_key_binding("-", "start", looper.loop_start)
mp.add_key_binding("=", "end", looper.loop_end)
mp.add_key_binding("+", "new", looper.loop_add)
mp.add_key_binding("_", "remove", looper.loop_drop)
mp.add_key_binding("g", "prev", looper.prev_loop)
mp.add_key_binding("h", "next", looper.next_loop)

mp.add_key_binding("§", "save", looper.save_loops)
