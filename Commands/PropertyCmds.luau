local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Root = script:FindFirstAncestor("Metain")
local Utils = require(Root.Utils)

local PropertyCmds = {}

function PropertyCmds.set_property(data: {[string]: any}): {[string]: any}
	local target, targetErr = Utils.requireTarget(data.path)
	if targetErr then return targetErr end

	local recording = ChangeHistoryService:TryBeginRecording("Metain: Set Property")
	local ok, err = pcall(function()
		((target :: Instance) :: any)[data.property] = Utils.convertValue(data.value)
	end)
	if recording then
		ChangeHistoryService:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	end

	if ok then
		return {success = true, message = "Set " .. data.property .. " on " .. (target :: Instance).Name}
	else
		return {success = false, message = "Failed: " .. tostring(err)}
	end
end

function PropertyCmds.set_properties(data: {[string]: any}): {[string]: any}
	local target, targetErr = Utils.requireTarget(data.path)
	if targetErr then return targetErr end

	local properties = data.properties
	if not properties or typeof(properties) ~= "table" or not next(properties) then
		return {success = false, message = "Missing or empty properties table"}
	end

	local recording = ChangeHistoryService:TryBeginRecording("Metain: Set Properties")
	local set = {}
	local failed = {}

	for propName, propValue in properties do
		local ok, err = pcall(function()
			((target :: Instance) :: any)[propName] = Utils.convertValue(propValue)
		end)
		if ok then
			table.insert(set, propName)
		else
			table.insert(failed, propName .. ": " .. tostring(err))
		end
	end

	if recording then
		local operation = #set > 0 and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel
		ChangeHistoryService:FinishRecording(recording, operation)
	end

	if #failed > 0 then
		return {success = #set > 0, message = "Set " .. #set .. ", failed " .. #failed .. ": " .. table.concat(failed, "; ")}
	end
	return {success = true, message = "Set " .. table.concat(set, ", ") .. " on " .. (target :: Instance).Name}
end

function PropertyCmds.add_tag(data: {[string]: any}): {[string]: any}
	local target, err = Utils.requireTarget(data.path)
	if err then return err end

	Utils.withRecording("Add Tag", function()
		(target :: Instance):AddTag(data.tag)
	end)

	return {success = true, message = "Added tag '" .. data.tag .. "' to " .. (target :: Instance).Name}
end

function PropertyCmds.remove_tag(data: {[string]: any}): {[string]: any}
	local target, err = Utils.requireTarget(data.path)
	if err then return err end

	Utils.withRecording("Remove Tag", function()
		(target :: Instance):RemoveTag(data.tag)
	end)

	return {success = true, message = "Removed tag '" .. data.tag .. "' from " .. (target :: Instance).Name}
end

function PropertyCmds.set_attribute(data: {[string]: any}): {[string]: any}
	local target, err = Utils.requireTarget(data.path)
	if err then return err end

	Utils.withRecording("Set Attribute", function()
		(target :: Instance):SetAttribute(data.attribute, Utils.convertValue(data.value))
	end)

	return {success = true, message = "Set attribute '" .. data.attribute .. "' on " .. (target :: Instance).Name}
end

function PropertyCmds.undo(data: {[string]: any}): {[string]: any}
	local count = data.count or 1
	local undone = 0
	for i = 1, count do
		local canUndo, waypoint = ChangeHistoryService:GetCanUndo()
		if canUndo and waypoint and tostring(waypoint):find("^Metain: ") then
			ChangeHistoryService:Undo()
			undone = undone + 1
		else
			break
		end
	end
	if undone == 0 then
		return {success = false, message = "Nothing to undo"}
	end
	return {success = true, message = "Undid " .. undone .. " action(s)", data = {undone = undone}}
end

return PropertyCmds
