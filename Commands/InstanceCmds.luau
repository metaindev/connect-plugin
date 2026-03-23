local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

local Root = script:FindFirstAncestor("Metain")
local Utils = require(Root.Utils)

local InstanceCmds = {}

function InstanceCmds.create_instance(data: {[string]: any}): {[string]: any}
	local className = data.className
	if not className then
		return {success = false, message = "Missing className"}
	end

	local parent = data.parent and (Utils.findByPath(data.parent) or Utils.locationMap[data.parent]) or nil
	if not parent then
		return {success = false, message = "Invalid parent: " .. tostring(data.parent)}
	end

	local ok, instance = pcall(function()
		return Instance.new(className)
	end)
	if not ok then
		return {success = false, message = "Invalid className: " .. className}
	end

	Utils.withRecording("Create Instance", function()
		instance.Name = data.name or className
		if data.properties then
			for propName, propValue in data.properties do
				pcall(function()
					(instance :: any)[propName] = Utils.convertValue(propValue)
				end)
			end
		end
		instance.Parent = parent
	end)

	Selection:Set({instance})
	return {success = true, message = "Created: " .. instance:GetFullName()}
end

function InstanceCmds.create_ui(data: {[string]: any}): {[string]: any}
	local ui = Utils.createFromSpec(data.spec)

	local parent = StarterGui
	if data.parent then
		local resolved, resolveErr = Utils.requireTarget(data.parent)
		if resolveErr then return resolveErr end
		parent = resolved :: Instance
	end

	Utils.withRecording("Create UI", function()
		ui.Parent = parent
	end)

	Selection:Set({ui})
	return {success = true, message = "Created: " .. ui:GetFullName()}
end

function InstanceCmds.rename(data: {[string]: any}): {[string]: any}
	local target, err = Utils.requireTarget(data.path)
	if err then return err end

	local oldName = (target :: Instance).Name
	Utils.withRecording("Rename", function()
		(target :: Instance).Name = data.newName
	end)

	Selection:Set({target :: Instance})
	return {success = true, message = "Renamed: " .. oldName .. " -> " .. data.newName}
end

function InstanceCmds.move(data: {[string]: any}): {[string]: any}
	local target, err = Utils.requireTarget(data.path)
	if err then return err end

	local newParent = Utils.findByPath(data.newParent) or Utils.locationMap[data.newParent]
	if not newParent then
		return {success = false, message = "Invalid destination: " .. tostring(data.newParent)}
	end

	Utils.withRecording("Move", function()
		(target :: Instance).Parent = newParent
	end)

	Selection:Set({target :: Instance})
	return {success = true, message = "Moved to: " .. (target :: Instance):GetFullName()}
end

function InstanceCmds.delete(data: {[string]: any}): {[string]: any}
	local target = Utils.findByPath(data.path) or (Utils.locationMap[data.location] and Utils.locationMap[data.location]:FindFirstChild(data.name))
	if not target then
		return {success = false, message = "Not found"}
	end

	local fullName = target:GetFullName()
	Utils.withRecording("Delete", function()
		target.Parent = nil
	end)

	return {success = true, message = "Deleted: " .. fullName}
end

function InstanceCmds.clone(data: {[string]: any}): {[string]: any}
	local target, err = Utils.requireTarget(data.path)
	if err then return err end

	local cloned = (target :: Instance):Clone()
	if not cloned then
		return {success = false, message = "Cannot clone (Archivable is false)"}
	end

	cloned.Name = data.newName or ((target :: Instance).Name .. "_Clone")
	local newParent = data.newParent and (Utils.findByPath(data.newParent) or Utils.locationMap[data.newParent]) or (target :: Instance).Parent
	Utils.withRecording("Clone", function()
		cloned.Parent = newParent
	end)

	Selection:Set({cloned})
	return {success = true, message = "Cloned: " .. cloned:GetFullName()}
end

function InstanceCmds.insert_asset(data: {[string]: any}): {[string]: any}
	local assetId = tonumber(data.assetId)
	if not assetId then
		return {success = false, message = "Missing or invalid assetId"}
	end

	local parent = workspace
	if data.parent then
		parent = Utils.findByPath(data.parent) or Utils.locationMap[data.parent]
		if not parent then
			return {success = false, message = "Invalid parent: " .. tostring(data.parent)}
		end
	end

	local insertedInstance
	Utils.withRecording("Insert Asset", function()
		local ok, container = pcall(function()
			return game:GetService("InsertService"):LoadAsset(assetId)
		end)
		if not ok then
			error("Could not load asset: " .. tostring(container))
		end

		local children = container:GetChildren()
		if #children == 0 then
			container:Destroy()
			error("Asset is empty")
		end

		if #children == 1 then
			children[1].Parent = parent
			insertedInstance = children[1]
			container:Destroy()
		else
			container.Parent = parent
			insertedInstance = container
		end
	end)

	Selection:Set({insertedInstance})
	return {success = true, message = "Inserted: " .. insertedInstance:GetFullName(), data = {name = insertedInstance.Name}}
end

return InstanceCmds
