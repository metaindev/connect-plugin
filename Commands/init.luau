local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScriptCmds = require(script.Parent.ScriptCmds)
local InstanceCmds = require(script.Parent.InstanceCmds)
local PropertyCmds = require(script.Parent.PropertyCmds)

local function run_luau(data: {[string]: any}): {[string]: any}
	local code = data.code
	if not code or code == "" then
		return {success = false, message = "Missing code"}
	end

	local moduleSource = [[
local __output = {}
local __totalChars = 0
local __MAX = 8000

local function print(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end
	local line = table.concat(parts, "\t")
	if __totalChars + #line <= __MAX then
		__totalChars = __totalChars + #line + 1
		table.insert(__output, line)
	end
end

local function warn(...)
	print(...)
end

]] .. code .. "\nreturn table.concat(__output, '\\n')"

	local tempMod = Instance.new("ModuleScript")
	tempMod.Source = moduleSource
	tempMod.Parent = ReplicatedStorage

	local ok, result = pcall(require, tempMod)
	tempMod:Destroy()

	if not ok then
		return {success = false, message = "Error: " .. tostring(result)}
	end
	return {success = true, message = "OK", data = {output = tostring(result or "")}}
end

local handlers = {
	run_luau = run_luau,
	read_script = ScriptCmds.read_script,
	create_script = ScriptCmds.create_script,
	update_script = ScriptCmds.update_script,
	edit_script = ScriptCmds.edit_script,
	create_instance = InstanceCmds.create_instance,
	create_ui = InstanceCmds.create_ui,
	rename = InstanceCmds.rename,
	move = InstanceCmds.move,
	delete = InstanceCmds.delete,
	clone = InstanceCmds.clone,
	insert_asset = InstanceCmds.insert_asset,
	set_property = PropertyCmds.set_property,
	set_properties = PropertyCmds.set_properties,
	add_tag = PropertyCmds.add_tag,
	remove_tag = PropertyCmds.remove_tag,
	set_attribute = PropertyCmds.set_attribute,
	undo = PropertyCmds.undo,
}

local function handleCommand(data: {[string]: any}): {[string]: any}
	local cmd = data.type

	if cmd == "ping" then
		return {success = true, message = "pong"}
	end

	local handler = handlers[cmd]
	if handler then
		return handler(data)
	end

	return {success = false, message = "Unknown command: " .. tostring(cmd)}
end

return handleCommand
