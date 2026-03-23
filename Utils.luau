local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Utils = {}

Utils.locationMap = {
	ServerScriptService = ServerScriptService,
	ServerStorage = ServerStorage,
	ReplicatedStorage = ReplicatedStorage,
	StarterGui = StarterGui,
	StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts"),
	StarterCharacterScripts = StarterPlayer:WaitForChild("StarterCharacterScripts"),
	Workspace = workspace,
}

function Utils.findByPath(path: string): Instance?
	local segments = path:split(".")
	local current: Instance? = nil

	for i, segment in segments do
		if i == 1 then
			current = Utils.locationMap[segment] or game:FindFirstChild(segment)
		else
			if current then
				current = current:FindFirstChild(segment)
			end
		end
		if not current then return nil end
	end

	return current
end

function Utils.convertValue(value: any): any
	if typeof(value) ~= "table" then
		return value
	end

	local t = value._type
	if t == "UDim2" then
		local xScale = value.XScale or 0
		local xOffset = value.XOffset or 0
		local yScale = value.YScale or 0
		local yOffset = value.YOffset or 0
		return UDim2.new(xScale, xOffset, yScale, yOffset)
	elseif t == "Color3" then
		if value.Hex then
			return Color3.fromHex(value.Hex)
		else
			return Color3.fromRGB(value.R, value.G, value.B)
		end
	elseif t == "Vector2" then
		return Vector2.new(value.X, value.Y)
	elseif t == "Vector3" then
		return Vector3.new(value.X, value.Y, value.Z)
	elseif t == "UDim" then
		return UDim.new(value.Scale, value.Offset)
	elseif t == "CFrame" then
		local cf = CFrame.new(value.X, value.Y, value.Z)
		if value.RX or value.RY or value.RZ then
			cf = cf * CFrame.Angles(
				math.rad(value.RX or 0),
				math.rad(value.RY or 0),
				math.rad(value.RZ or 0)
			)
		end
		return cf
	elseif t == "Enum" then
		return Enum[value.EnumType][value.EnumItem]
	elseif t == "BrickColor" then
		if value.Name then
			return BrickColor.new(value.Name)
		elseif value.Number then
			return BrickColor.new(value.Number)
		end
	elseif t == "NumberRange" then
		return NumberRange.new(value.Min, value.Max)
	elseif t == "Rect" then
		return Rect.new(value.MinX, value.MinY, value.MaxX, value.MaxY)
	elseif t == "NumberSequence" then
		local keypoints = {}
		for _, kp in value.Keypoints do
			table.insert(keypoints, NumberSequenceKeypoint.new(kp.Time, kp.Value, kp.Envelope or 0))
		end
		return NumberSequence.new(keypoints)
	elseif t == "ColorSequence" then
		local keypoints = {}
		for _, kp in value.Keypoints do
			local color = Color3.fromRGB(kp.Color.R, kp.Color.G, kp.Color.B)
			table.insert(keypoints, ColorSequenceKeypoint.new(kp.Time, color))
		end
		return ColorSequence.new(keypoints)
	elseif t == "Font" then
		if value.EnumFont then
			return Font.fromEnum(Enum.Font[value.EnumFont])
		else
			local weight = value.Weight and Enum.FontWeight[value.Weight] or Enum.FontWeight.Regular
			local style = value.Style and Enum.FontStyle[value.Style] or Enum.FontStyle.Normal
			return Font.new(value.Family, weight, style)
		end
	end

	return value
end

function Utils.createFromSpec(spec: {[string]: any}): Instance
	local className = spec.ClassName
	if not className then
		error("Missing ClassName in spec")
	end

	local instance = Instance.new(className)

	for propName, propValue in spec do
		if propName == "ClassName" or propName == "Children" or propName == "Parent" then
			continue
		end

		pcall(function()
			(instance :: any)[propName] = Utils.convertValue(propValue)
		end)
	end

	if spec.Children then
		for _, childSpec in spec.Children do
			local child = Utils.createFromSpec(childSpec)
			child.Parent = instance
		end
	end

	return instance
end

function Utils.requireTarget(path: string): (Instance?, {[string]: any}?)
	local target = Utils.findByPath(path)
	if not target then
		return nil, {success = false, message = "Not found: " .. tostring(path)}
	end
	return target, nil
end

function Utils.requireScript(path: string): (Instance?, {[string]: any}?)
	local target = Utils.findByPath(path)
	if not target or not target:IsA("LuaSourceContainer") then
		return nil, {success = false, message = "Script not found: " .. tostring(path)}
	end
	return target, nil
end

function Utils.withRecording(label: string, fn: () -> ())
	local recording = ChangeHistoryService:TryBeginRecording("Metain: " .. label)
	local ok, err = pcall(fn)
	if recording then
		ChangeHistoryService:FinishRecording(recording,
			ok and Enum.FinishRecordingOperation.Commit
				or Enum.FinishRecordingOperation.Cancel)
	end
	if not ok then
		error(err)
	end
end

return Utils
