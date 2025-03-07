-- @file godot_pool_byte_array.lua  Wrapper for GDNative's PoolByteArray
-- This file is part of Godot Lua PluginScript: https://github.com/gilzoide/godot-lua-pluginscript
--
-- Copyright (C) 2021 Gil Barbosa Reis.
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the “Software”), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.

--- PoolByteArray metatype, wrapper for `godot_pool_byte_array`
-- @classmod PoolByteArray

local byte = ffi_typeof('uint8_t')

--- PoolByteArray.Read access metatype, wrapper for `godot_pool_byte_array_read_access`.
-- @type PoolByteArray.Read
local Read = ffi_metatype('godot_pool_byte_array_read_access', {
	__index = {
		--- Create a copy of Read access.
		-- @function Read:copy
		-- @treturn Read
		copy = function(self)
			return ffi_gc(api.godot_pool_byte_array_read_access_copy(self), self.destroy)
		end,
		--- Destroy a Read access.
		-- Holding a valid access object may lock a PoolByteArray, so this
		-- method should be called manually when access is no longer needed.
		-- @function Read:destroy
		destroy = function(self)
			ffi_gc(self, nil)
			api.godot_pool_byte_array_read_access_destroy(self)
		end,
		--- Get Read access pointer.
		-- @function Read:ptr
		-- @return[type=const uint8_t *]
		ptr = api.godot_pool_byte_array_read_access_ptr,
		--- Assign a new Read access.
		-- @function Read:assign
		-- @tparam Read other
		assign = api.godot_pool_byte_array_read_access_operator_assign,
	},
})

--- PoolByteArray.Write access metatype, wrapper for `godot_pool_byte_array_write_access`.
-- @type PoolByteArray.Write
local Write = ffi_metatype('godot_pool_byte_array_write_access', {
	__index = {
		--- Create a copy of Write access.
		-- @function Write:copy
		-- @treturn Write
		copy = function(self)
			return ffi_gc(api.godot_pool_byte_array_write_access_copy(self), godot_pool_byte_array_write_access_destroy)
		end,
		--- Destroy a Write access.
		-- Holding a valid access object may lock a PoolByteArray, so this
		-- method should be called manually when access is no longer needed.
		-- @function Write:destroy
		destroy = function(self)
			ffi_gc(self, nil)
			api.godot_pool_byte_array_write_access_destroy(self)
		end,
		--- Get Write access pointer.
		-- @function Write:ptr
		-- @return[type=uint8_t *]
		ptr = api.godot_pool_byte_array_write_access_ptr,
		--- Assign a new Write access.
		-- @function Write:assign
		-- @tparam Write other
		assign = api.godot_pool_byte_array_write_access_operator_assign,
	},
})
--- @type end

local methods = {
	fillvariant = api.godot_variant_new_pool_byte_array,
	varianttype = VariantType.PoolByteArray,

	--- Get the byte at `index`.
	-- Unlike Lua tables, indices start at 0 instead of 1.
	-- For 1-based indexing, use the idiom `array[index]` instead.
	--
	-- If `index` is invalid (`index < 0` or `index >= size()`), the application will crash.
	-- For a safe version that returns `nil` if `index` is invalid, use `safe_get` or the idiom `array[index]` instead.
	-- @function get
	-- @tparam int index
	-- @treturn int
	-- @see safe_get
	get = api.godot_pool_byte_array_get,
	--- Get the byte at `index`.
	-- Unlike Lua tables, indices start at 0 instead of 1.
	-- For 1-based indexing, use the idiom `array[index]` instead.
	--
	-- The idiom `array[index]` also calls this method.
	-- @function safe_get
	-- @tparam int index
	-- @treturn[1] int
	-- @treturn[2] nil  If index is invalid (`index < 0` or `index >= size()`)
	-- @see get
	safe_get = array_safe_get,
	--- Set a new byte for `index`.
	-- Unlike Lua tables, indices start at 0 instead of 1.
	-- For 1-based indexing, use the idiom `array[index] = value` instead.
	--
	-- If `index` is invalid (`index < 0` or `index >= size()`), the application will crash.
	-- For a safe approach that `resize`s if `index >= size()`, use `safe_set` or the idiom `array[index] = value` instead.
	-- @function set
	-- @tparam int index
	-- @tparam int byte
	-- @see safe_set
	set = api.godot_pool_byte_array_set,
	--- Set a new byte for `index`.
	-- Unlike Lua tables, indices start at 0 instead of 1.
	-- For 1-based indexing, use the idiom `array[index] = value` instead.
	--
	-- If `index >= size()`, the array is `resize`d first.
	-- The idiom `array[index] = value` also calls this method.
	-- @function safe_set
	-- @tparam int index
	-- @tparam int byte
	-- @raise If `index < 0`
	-- @see set
	safe_set = array_safe_set,
	--- Inserts a new element at a given position in the array.
	-- The position must be valid, or at the end of the array (`idx == size()`).
	-- @function insert
	-- @tparam int index
	-- @tparam int byte
	insert = api.godot_pool_byte_array_insert,
	--- Reverses the order of the elements in the array.
	-- @function invert
	invert = api.godot_pool_byte_array_invert,
	--- Append elements at the end of the array.
	-- @function push_back
	-- @param ...  Bytes to be appended
	push_back = function(self, ...)
		for i = 1, select('#', ...) do
			local v = select(i, ...)
			api.godot_pool_byte_array_push_back(self, v)
		end
	end,
	--- Removes an element from the array by index.
	-- @function remove
	-- @tparam int index
	remove = api.godot_pool_byte_array_remove,
	--- Sets the size of the array.
	-- If the array is grown, reserves elements at the end of the array.
	-- If the array is shrunk, truncates the array to the new size.
	-- @function resize
	-- @tparam int size
	resize = api.godot_pool_byte_array_resize,
	--- Returns the size of the array.
	-- @function size
	-- @treturn int
	size = api.godot_pool_byte_array_size,
	--- Returns `true` if the array is empty.
	-- @function empty
	-- @treturn bool
	empty = array_empty,
	--- Returns the [Read](#Class_PoolByteArray._Read) access for the array.
	-- @function read
	-- @treturn Read
	read = function(self)
		return ffi_gc(api.godot_pool_byte_array_read(self), Read.destroy)
	end,
	--- Returns the [Write](#Class_PoolByteArray_Write) access for the array.
	-- @function write
	-- @treturn Write
	write = function(self)
		return ffi_gc(api.godot_pool_byte_array_write(self), Write.destroy)
	end,
}

--- Alias for `push_back`.
-- @function append
-- @param ...
-- @see push_back
methods.append = methods.push_back

--- Append all bytes of `iterable` at the end of Array.
-- @function extend
-- @param iterable  If a Lua string is passed, its bytes are appended.
--  Otherwise, it must be an object iterable by `ipairs`, including Lua tables, `Array`s and `Pool*Array`s.
methods.extend = function(self, iterable)
	if type(iterable) == 'string' then
		local size = #self
		self:resize(size + #iterable)
		local write = self:write()
		ffi_copy(write:ptr() + size, iterable, #iterable)
		write:destroy()
	elseif ffi_istype(PoolByteArray, iterable) then
		api.godot_pool_byte_array_append_array(self, iterable)
	else
		for _, b in ipairs(iterable) do
			self:push_back(b)
		end
	end
end

--- Returns a String with each element of the array joined with the given `delimiter`.
-- @function join
-- @param[opt=""] delimiter  
-- @treturn String
methods.join = array_join

--- Returns a Lua string with the array's bytes.
-- @function get_string
-- @treturn string
methods.get_string = function(self)
	local read = self:read()
	local str = ffi_string(read:ptr(), #self)
	read:destroy()
	return str
end

--- Returns a hexadecimal representation of this array as a String.
-- @function hex_encode
-- @treturn String
-- @see String.hex_encode_buffer
methods.hex_encode = function(self)
	local read = self:read()
	local str = String.hex_encode_buffer(read:ptr(), #self)
	read:destroy()
	return str
end

--- Static Functions.
-- These don't receive `self` and should be called directly as `PoolByteArray.static_function(...)`
-- @section static_funcs

--- Create a new array with the elements from `iterable`.
-- @usage
--     local array = PoolByteArray.from(some_table_or_other_iterable)
-- @function from
-- @param iterable  If another PoolByteArray is passed, return a copy of it.
--  Otherwise, the new array is `extend`ed with `iterable`.
-- @treturn PoolByteArray
-- @see extend
methods.from = function(value)
	local self = PoolByteArray()
	if ffi_istype(PoolByteArray, value) then
		api.godot_pool_byte_array_new_copy(self, value)
	elseif ffi_istype(Array, value) then
		api.godot_pool_byte_array_new_with_array(self, value)
	else
		methods.extend(self, value)
	end
	return self
end

--- Metamethods
-- @section metamethods
PoolByteArray = ffi_metatype('godot_pool_byte_array', {
	--- PoolByteArray constructor, called by the idiom `PoolByteArray(...)`.
	-- @function __new
	-- @param ...  Initial elements, added with `push_back`
	-- @treturn PoolByteArray
	__new = function(mt, ...)
		local self = ffi_new(mt)
		api.godot_pool_byte_array_new(self)
		methods.push_back(self, ...)
		return self
	end,
	__gc = api.godot_pool_byte_array_destroy,
	--- Returns method named `index` or the result of `safe_get(index - 1)`.
	-- 
	-- Like Lua tables, this uses 1-based indexing. For 0-based indexing, call
	-- `get` or `safe_get` directly.
	-- @function __index
	-- @param index
	-- @return Method or element or `nil`
	-- @see safe_get
	__index = array_generate__index(methods),
	--- Alias for `safe_set(index - 1, value)`.
	--
	-- Like Lua tables, indices start at 1. For 0-based indexing, call `set` or
	-- `safe_set` directly.
	-- @function __newindex
	-- @tparam int index
	-- @param value
	-- @see safe_set
	__newindex = array__newindex,
	--- Returns a Lua string representation of this array.
	-- To get a string with the array contents, use `get_string` instead.
	-- @function __tostring
	-- @treturn string
	-- @see get_string
	__tostring = gd_tostring,
	--- Concatenates values.
	-- @function __concat
	-- @param a  First value, stringified with `GD.str`
	-- @param b  First value, stringified with `GD.str`
	-- @treturn String
	__concat = concat_gdvalues,
	--- Alias for `size`.
	-- @function __len
	-- @treturn int
	-- @see size
	__len = array__len,
	--- Returns an iterator for array's elements, called by the idiom `ipairs(array)`.
	-- @usage
	--     for i, byte in ipairs(array) do
	--         -- do something
	--     end
	-- @function __ipairs
	-- @treturn function
	-- @treturn PoolByteArray  self
	-- @treturn int  0
	__ipairs = array_ipairs,
	--- Alias for `__ipairs`, called by the idiom `pairs(array)`.
	-- @function __pairs
	-- @treturn function
	-- @treturn PoolByteArray  self
	-- @treturn int  0
	-- @see __ipairs
	__pairs = array_ipairs,
})
