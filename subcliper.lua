local mp = require("mp")
local saver = require("serializer")

--actual script

local looper = {}

local fn = nil
---------------------
--Loop definition
---------------------
local Loop = {a = 0, b = 0}

function Loop:new(a, b)
	self = {}
	setmetatable({}, self)
	self.a = a
	self.b = b
	return self
end

-- array of loops
local Regions = {}

Index = 1

---------------------
--actions
---------------------
local function set_loop()
	local loop = Regions[Index]
	mp.set_property_number("ab-loop-a", loop.a)
	mp.set_property_number("ab-loop-b", loop.b)
	mp.set_property_number("time-pos", loop.a)
end

local function unset_loop()
	mp.set_property_native("ab-loop-a", 'no')
	mp.set_property_native("ab-loop-b", 'no')
end

function looper.save_loops()
	assert(saver.save(Regions, fn) == nil )
end

function looper.loop_start()
	print('start of the loop, like it')
	local loop = Regions[Index]
	loop.a = mp.get_property_number("time-pos")
	mp.set_property_number("ab-loop-a", loop.a)
	looper.save_loops()
end

function looper.loop_end()
	local loop = Regions[Index]
	print('don\'t like it, end loop')
	loop.b = mp.get_property_number("time-pos")
	set_loop()
	looper.save_loops()
end

local function id_next()
	local id = Index
	if id >= #Regions then
		id = 1
	else id = (id + 1)
	end
	return id
end

local function id_prev()
	local id = Index
	if id <= 1 then
		id = #Regions
	else id = id - 1
	end
	return id
end

local function remove_region()
	table.remove(Regions, Index)
	unset_loop()
	print('that\'s enough, drop it')
end

local function validate_region()
	local loop = Regions[Index]
	if loop.a == nil or loop.b == nil then
		remove_region()
	end
end

function looper.loop_add()
	unset_loop()
	local jump_to = Regions[Index].b
	Index = #Regions + 1
	local fin = mp.get_property_number("duration")
	Regions[Index] = Loop:new(jump_to, fin)
	print('adding new region')
	mp.set_property_number("time-pos", jump_to)
	set_loop()
	looper.save_loops()
end

local function file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

function looper.init()
	unset_loop()
	local err
	fn = mp.get_property("path"):match("(.+)%..+$") .. ".clp"
	if file_exists(fn) == true then
		-- load table from file
		Regions, err = saver.load(fn)

		assert(err == nil)
		Index = 1
		set_loop()
		print('Hoooraaaaay')
		mp.osd_message("loops found", 4)
	else Regions[Index] = Loop:new(0, nil)
	end
end

function looper.prev_loop()
	validate_region()
	Index = id_prev()
	set_loop()
	print('it should actually loop now')
end

function looper.next_loop()
	validate_region()
	Index = id_next()
	set_loop()
	print('it should actually loop now')
end

function looper.loop_drop()
	remove_region()
	Index = id_next()
	set_loop()
	looper.save_loops()
end

return looper
