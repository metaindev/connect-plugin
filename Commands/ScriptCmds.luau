local ScriptEditorService = game:GetService("ScriptEditorService")
local Selection = game:GetService("Selection")

local Root = script:FindFirstAncestor("Metain")
local Utils = require(Root.Utils)

local ScriptCmds = {}

function ScriptCmds.read_script(data: {[string]: any}): {[string]: any}
	local target, err = Utils.requireScript(data.path)
	if err then return err end

	local source = ""
	pcall(function()
		source = ScriptEditorService:GetEditorSource(target :: Instance)
	end)

	return {
		success = true,
		source = source,
		name = (target :: Instance).Name,
		className = (target :: Instance).ClassName,
		path = (target :: Instance):GetFullName(),
		message = "Read: " .. (target :: Instance):GetFullName()
	}
end

function ScriptCmds.create_script(data: {[string]: any}): {[string]: any}
	local scriptType = data.scriptType or "Script"

	local parent
	if data.parent then
		parent = Utils.findByPath(data.parent) or Utils.locationMap[data.parent]
	else
		parent = Utils.locationMap[data.location]
	end

	if not parent then
		return {success = false, message = "Invalid location/parent: " .. tostring(data.parent or data.location)}
	end

	if not data.source then
		return {success = false, message = "Missing source code - cannot create script"}
	end

	local newScript = Instance.new(scriptType)
	newScript.Name = data.name or "NewScript";
	(newScript :: any).Source = data.source
	Utils.withRecording("Create Script", function()
		newScript.Parent = parent
	end)

	Selection:Set({newScript})
	return {success = true, message = "Created: " .. newScript:GetFullName()}
end

function ScriptCmds.update_script(data: {[string]: any}): {[string]: any}
	local target = Utils.findByPath(data.path) or (Utils.locationMap[data.location] and Utils.locationMap[data.location]:FindFirstChild(data.name))
	if not target or not target:IsA("LuaSourceContainer") then
		return {success = false, message = "Script not found"}
	end

	if not data.source or data.source == "" then
		return {success = false, message = "Missing source code - cannot update script"}
	end

	local parent = target.Parent
	local replacement = target:Clone();
	(replacement :: any).Source = data.source
	Utils.withRecording("Update Script", function()
		replacement.Parent = parent
		target.Parent = nil
	end)

	Selection:Set({replacement})
	return {success = true, message = "Updated: " .. replacement:GetFullName()}
end

function ScriptCmds.edit_script(data: {[string]: any}): {[string]: any}
	local target, err = Utils.requireScript(data.path)
	if err then return err end

	if not data.edits or typeof(data.edits) ~= "table" or #data.edits == 0 then
		return {success = false, message = "Missing or empty edits array"}
	end

	local currentSource = ""
	pcall(function()
		currentSource = ScriptEditorService:GetEditorSource(target :: Instance)
	end)

	local editCount = 0
	local failedEdits = {}
	for i, edit in data.edits do
		if not edit.old_text or edit.old_text == "" then
			table.insert(failedEdits, "Edit " .. i .. ": missing old_text")
		elseif edit.new_text == nil then
			table.insert(failedEdits, "Edit " .. i .. ": missing new_text")
		else
			local startPos, endPos = currentSource:find(edit.old_text, 1, true)
			if not startPos then
				table.insert(failedEdits, "Edit " .. i .. ": text not found")
			else
				currentSource = currentSource:sub(1, startPos - 1) .. edit.new_text .. currentSource:sub(endPos + 1)
				editCount = editCount + 1
			end
		end
	end

	if editCount == 0 then
		return {success = false, message = "No edits applied: " .. table.concat(failedEdits, ", ")}
	end

	local editTarget = target :: Instance
	local editParent = editTarget.Parent
	local replacement = editTarget:Clone();
	(replacement :: any).Source = currentSource
	Utils.withRecording("Edit Script", function()
		replacement.Parent = editParent
		editTarget.Parent = nil
	end)

	Selection:Set({replacement})
	local msg = "Edited " .. editCount .. "/" .. #data.edits .. " in " .. replacement.Name
	if #failedEdits > 0 then
		msg = msg .. " (failed: " .. table.concat(failedEdits, ", ") .. ")"
	end
	return {success = true, message = msg}
end

return ScriptCmds
