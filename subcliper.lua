local mp = require("mp")

-- table-saver functions
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- declare local variables
--// exportstring( string )
--// returns a "Lua" portable version of the string
local function exportstring( s )
	return string.format("%q", s)
end

--// The Save Function
function table.save(  tbl,filename )
	local charS,charE = "   ","\n"
	local file,err = io.open( filename, "wb" )
	if err then return err end

	-- initiate variables for save procedure
	local tables,lookup = { tbl },{ [tbl] = 1 }
	file:write( "return {"..charE )

	for idx,t in ipairs( tables ) do
		file:write( "-- Table: {"..idx.."}"..charE )
		file:write( "{"..charE )
		local thandled = {}

		for i,v in ipairs( t ) do
			thandled[i] = true
			local stype = type( v )
			-- only handle value
			if stype == "table" then
				if not lookup[v] then
					table.insert( tables, v )
					lookup[v] = #tables
				end
				file:write( charS.."{"..lookup[v].."},"..charE )
			elseif stype == "string" then
				file:write(  charS..exportstring( v )..","..charE )
			elseif stype == "number" then
				file:write(  charS..tostring( v )..","..charE )
			end
		end

		for i,v in pairs( t ) do
			-- escape handled values
			if (not thandled[i]) then

				local str = ""
				local stype = type( i )
				-- handle index
				if stype == "table" then
					if not lookup[i] then
						table.insert( tables,i )
						lookup[i] = #tables
					end
					str = charS.."[{"..lookup[i].."}]="
				elseif stype == "string" then
					str = charS.."["..exportstring( i ).."]="
				elseif stype == "number" then
					str = charS.."["..tostring( i ).."]="
				end

				if str ~= "" then
					stype = type( v )
					-- handle value
					if stype == "table" then
						if not lookup[v] then
							table.insert( tables,v )
							lookup[v] = #tables
						end
						file:write( str.."{"..lookup[v].."},"..charE )
					elseif stype == "string" then
						file:write( str..exportstring( v )..","..charE )
					elseif stype == "number" then
						file:write( str..tostring( v )..","..charE )
					end
				end
			end
		end
		file:write( "},"..charE )
	end
	file:write( "}" )
	file:close()
end

--// The Load Function
function table.load( sfile )
	local ftables,err = loadfile( sfile )
	if err then return _,err end
	local tables = ftables()
	for idx = 1,#tables do
		local tolinki = {}
		for i,v in pairs( tables[idx] ) do
			if type( v ) == "table" then
				tables[idx][i] = tables[v[1]]
			end
			if type( i ) == "table" and tables[i[1]] then
				table.insert( tolinki,{ i,tables[i[1]] } )
			end
		end
		-- link indices
		for _,v in ipairs( tolinki ) do
			tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
		end
	end
	return tables[1]
end
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--actual script

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

local function save_loops()
	assert(table.save(Regions, fn) == nil )
end

local function loop_start()
	print('start of the loop, like it')
	local loop = Regions[Index]
	loop.a = mp.get_property_number("time-pos")
	mp.set_property_number("ab-loop-a", loop.a)
end

local function loop_end()
	local loop = Regions[Index]
	print('don\'t like it, end loop')
	loop.b = mp.get_property_number("time-pos")
	set_loop()
	save_loops()
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

local function loop_add()
	local jump_to = Regions[Index].b
	Index = #Regions + 1
	Regions[Index] = Loop:new(nil, nil)
	print('adding new region')
	unset_loop()
	mp.set_property_number("time-pos", jump_to)
	Regions[Index].a = jump_to
end

local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local function init()
	unset_loop()
	local err
	fn = mp.get_property("path"):match("(.+)%..+$") .. ".lua"
	if file_exists(fn) == true then
		-- load table from file
		Regions, err = table.load(fn)

		assert(err == nil)
		Index = 1
		set_loop()
		print('Hoooraaaaay')
		mp.osd_message("loops found", 4)
	else Regions[Index] = Loop:new(nil, nil)
    end
end

local function prev_loop()
	validate_region()
	Index = id_prev()
	set_loop()
	print('it should actually loop now')
end

local function next_loop()
	validate_region()
	Index = id_next()
	set_loop()
	print('it should actually loop now')
end

local function loop_drop()
	unset_loop()
	remove_region()
	next_loop()
	save_loops()
end

mp.register_event("file-loaded", init)

mp.add_key_binding("-", "start", loop_start)
mp.add_key_binding("=", "end", loop_end)
mp.add_key_binding("+", "new", loop_add)
mp.add_key_binding("_", "remove", loop_drop)
mp.add_key_binding("g", "prev", prev_loop)
mp.add_key_binding("h", "next", next_loop)

mp.add_key_binding("§", "save", save_loops)
