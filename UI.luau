local Root = script:FindFirstAncestor("Metain")
local Config = require(Root.Config)

local UI = {}

local statusDot
local statusLabel
local connectBtn
local codeInput
local noticeLabel
local noticeThread

local function getColor(styleColor: Enum.StudioStyleGuideColor): Color3
	return settings().Studio.Theme:GetColor(styleColor)
end

function UI.updateUI()
	local state = Config.state
	if state.isConnected and state.isAuthorized then
		statusDot.BackgroundColor3 = Color3.fromRGB(74, 222, 128)
		statusLabel.Text = "Connected"
		connectBtn.Text = "Disconnect"
		connectBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		connectBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		codeInput.TextEditable = false
		codeInput.TextTransparency = 0.5
	elseif state.isConnected or state.isReconnecting then
		statusDot.BackgroundColor3 = Color3.fromRGB(251, 191, 36)
		statusLabel.Text = state.isReconnecting and "Reconnecting..." or "Connecting..."
		connectBtn.Text = "Cancel"
		connectBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		connectBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		codeInput.TextEditable = false
		codeInput.TextTransparency = 0.5
	else
		statusDot.BackgroundColor3 = Color3.fromRGB(248, 113, 113)
		statusLabel.Text = "Not connected"
		connectBtn.Text = "Connect"
		connectBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		connectBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
		codeInput.TextEditable = true
		codeInput.TextTransparency = 0
	end
end

function UI.showNotice(message: string, duration: number?)
	noticeLabel.Text = message
	if noticeThread then
		pcall(task.cancel, noticeThread)
	end
	noticeThread = task.delay(duration or 10, function()
		noticeThread = nil
		noticeLabel.Text = ""
	end)
end

function UI.init(pluginInstance)
	local toolbar = pluginInstance:CreateToolbar("Metain")
	UI.toggleButton = toolbar:CreateButton(
		"Metain",
		"Open Metain panel",
		"rbxassetid://93855725349422"
	)

	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Right,
		false,
		false,
		260, 240,
		220, 220
	)
	UI.widget = pluginInstance:CreateDockWidgetPluginGuiAsync("MetainPanel", widgetInfo)
	UI.widget.Title = "Metain"

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.Parent = UI.widget

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 24)
	padding.PaddingBottom = UDim.new(0, 24)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 16)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = frame

	local statusFrame = Instance.new("Frame")
	statusFrame.Size = UDim2.new(0, 160, 0, 50)
	statusFrame.BackgroundTransparency = 1
	statusFrame.LayoutOrder = 1
	statusFrame.Parent = frame

	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Vertical
	statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statusLayout.Padding = UDim.new(0, 6)
	statusLayout.Parent = statusFrame

	statusDot = Instance.new("Frame")
	statusDot.Size = UDim2.fromOffset(14, 14)
	statusDot.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	statusDot.BorderSizePixel = 0
	statusDot.LayoutOrder = 1
	statusDot.Parent = statusFrame

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(1, 0)
	statusCorner.Parent = statusDot

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.fromOffset(160, 24)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Not connected"
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.TextSize = 18
	statusLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)
	statusLabel.LayoutOrder = 2
	statusLabel.Parent = statusFrame

	local codeLabel = Instance.new("TextLabel")
	codeLabel.Size = UDim2.new(1, 0, 0, 18)
	codeLabel.BackgroundTransparency = 1
	codeLabel.Text = "Enter your connection code"
	codeLabel.TextXAlignment = Enum.TextXAlignment.Center
	codeLabel.TextSize = 12
	codeLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular)
	codeLabel.LayoutOrder = 2
	codeLabel.Parent = frame

	codeInput = Instance.new("TextBox")
	codeInput.Size = UDim2.new(1, 0, 0, 44)
	codeInput.Text = ""
	codeInput.PlaceholderText = "XXXXXX"
	codeInput.TextSize = 22
	codeInput.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	codeInput.ClearTextOnFocus = false
	codeInput.TextXAlignment = Enum.TextXAlignment.Center
	codeInput.LayoutOrder = 3
	codeInput.Parent = frame

	codeInput:GetPropertyChangedSignal("Text"):Connect(function()
		local clean = codeInput.Text:upper():gsub("[^A-Z0-9]", ""):sub(1, 6)
		if codeInput.Text ~= clean then
			codeInput.Text = clean
		end
	end)

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = codeInput

	connectBtn = Instance.new("TextButton")
	connectBtn.Size = UDim2.new(1, 0, 0, 40)
	connectBtn.Text = "Connect"
	connectBtn.TextSize = 14
	connectBtn.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	connectBtn.LayoutOrder = 4
	connectBtn.AutoButtonColor = true
	connectBtn.Parent = frame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = connectBtn

	noticeLabel = Instance.new("TextLabel")
	noticeLabel.Size = UDim2.new(1, 0, 0, 16)
	noticeLabel.BackgroundTransparency = 1
	noticeLabel.Text = ""
	noticeLabel.TextXAlignment = Enum.TextXAlignment.Center
	noticeLabel.TextSize = 11
	noticeLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular)
	noticeLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
	noticeLabel.TextWrapped = true
	noticeLabel.LayoutOrder = 5
	noticeLabel.Parent = frame

	UI.codeInput = codeInput
	UI.connectBtn = connectBtn

	local function applyTheme()
		frame.BackgroundColor3 = getColor(Enum.StudioStyleGuideColor.MainBackground)
		statusLabel.TextColor3 = getColor(Enum.StudioStyleGuideColor.MainText)
		codeLabel.TextColor3 = getColor(Enum.StudioStyleGuideColor.SubText)
		codeInput.BackgroundColor3 = getColor(Enum.StudioStyleGuideColor.InputFieldBackground)
		codeInput.TextColor3 = getColor(Enum.StudioStyleGuideColor.MainText)
		codeInput.PlaceholderColor3 = getColor(Enum.StudioStyleGuideColor.DimmedText)
		codeInput.BorderSizePixel = 0
		connectBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		connectBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
		connectBtn.BorderSizePixel = 0
	end

	applyTheme()
	settings().Studio.ThemeChanged:Connect(function()
		applyTheme()
		UI.updateUI()
	end)

	UI.updateUI()
end

return UI
