local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")

local Root = script:FindFirstAncestor("Metain")
local Config = require(Root.Config)
local UI = require(Root.UI)
local handleCommand = require(Root.Commands.init)

local Connection = {}

local function startHeartbeat(currentWs: WebStreamClient)
	local state = Config.state
	if state.heartbeatThread then
		pcall(task.cancel, state.heartbeatThread)
		state.heartbeatThread = nil
	end

	state.heartbeatThread = task.spawn(function()
		while state.isConnected and state.isAuthorized do
			task.wait(30)
			if not state.isConnected or not state.isAuthorized then break end
			pcall(function()
				currentWs:Send("ping")
			end)
		end
	end)
end

local function stopHeartbeat()
	local state = Config.state
	if state.heartbeatThread then
		pcall(task.cancel, state.heartbeatThread)
		state.heartbeatThread = nil
	end
end

local attemptReconnect: () -> ()

local function closeOldWebSocket()
	local state = Config.state
	if state.ws then
		state.connectionId = state.connectionId + 1
		pcall(function() (state.ws :: WebStreamClient):Close() end)
		state.ws = nil
	end
end

local function setupWebSocket(currentWs: WebStreamClient, authMessage: {[string]: any})
	local state = Config.state
	local myConnId = state.connectionId

	currentWs.Opened:Connect(function(_statusCode: number, _headers: string)
		if myConnId ~= state.connectionId then return end
		state.isConnected = true
		state.isReconnecting = false
		UI.updateUI()
		currentWs:Send(HttpService:JSONEncode(authMessage))
	end)

	currentWs.MessageReceived:Connect(function(message: string)
		if myConnId ~= state.connectionId then return end

		if message == "pong" then return end

		local parseOk, data = pcall(HttpService.JSONDecode, HttpService, message)
		if not parseOk or not data then return end

		if data.type == "auth_status" then
			if data.status == "authorized" then
				state.isAuthorized = true
				if data.reconnectToken then
					state.reconnectToken = data.reconnectToken
				end
				startHeartbeat(currentWs)
				if state.reconnectResetThread then
					pcall(task.cancel, state.reconnectResetThread)
				end
				state.reconnectResetThread = task.delay(10, function()
					state.reconnectResetThread = nil
					if state.isConnected and state.isAuthorized then
						state.reconnectAttempts = 0
					end
				end)
			elseif data.status == "rejected" then
				state.isAuthorized = false
				state.reconnectToken = nil
				warn("[Metain] " .. (data.reason or "Connection rejected"))
			elseif data.status == "disconnected" then
				state.isAuthorized = false
			end
			UI.updateUI()
			return
		end

		if not state.isAuthorized and data.type ~= "ping" then
			return
		end

		local ok, response = pcall(handleCommand, data)
		if not ok then
			response = {success = false, message = "Error: " .. tostring(response)}
		end
		if data.requestId then
			response.requestId = data.requestId
		end
		currentWs:Send(HttpService:JSONEncode(response))
	end)

	local connectionLostHandled = false
	local function handleConnectionLost()
		if myConnId ~= state.connectionId then return end
		if connectionLostHandled then return end
		connectionLostHandled = true
		state.isConnected = false
		state.isAuthorized = false
		state.isReconnecting = false
		state.ws = nil
		stopHeartbeat()
		UI.toggleButton:SetActive(false)
		UI.updateUI()
		attemptReconnect()
	end

	currentWs.Closed:Connect(handleConnectionLost)

	currentWs.Error:Connect(function(statusCode: number, errorMessage: string)
		if not errorMessage:find("err: 0") then
			warn("[Metain] WebSocket error:", statusCode, errorMessage)
		end
		handleConnectionLost()
	end)
end

local function createWebSocket(userId: string): (boolean, WebStreamClient | string)
	closeOldWebSocket()

	local ok, result = pcall(function()
		return HttpService:CreateWebStreamClient(
			Enum.WebStreamClientType.WebSocket,
			{Url = Config.SERVER_URL .. "/?userId=" .. userId}
		)
	end)

	return ok, result
end

attemptReconnect = function()
	local state = Config.state
	if state.isReconnecting or state.isConnected then return end
	if not state.reconnectToken or not state.lastUserId then return end
	if state.reconnectAttempts >= Config.MAX_RECONNECT_ATTEMPTS then
		state.reconnectToken = nil
		state.reconnectAttempts = 0
		state.isReconnecting = false
		UI.updateUI()
		return
	end

	state.isReconnecting = true
	state.reconnectAttempts = state.reconnectAttempts + 1
	local delay = math.min(2 ^ state.reconnectAttempts, 30)

	UI.updateUI()

	if state.reconnectThread then
		pcall(task.cancel, state.reconnectThread)
		state.reconnectThread = nil
	end

	state.reconnectThread = task.delay(delay, function()
		state.reconnectThread = nil
		if state.isConnected then
			state.isReconnecting = false
			UI.updateUI()
			return
		end

		local token = state.reconnectToken
		local userId = state.lastUserId
		if not token or not userId then
			state.isReconnecting = false
			UI.updateUI()
			return
		end

		local ok, result = createWebSocket(userId)

		if not ok then
			state.isReconnecting = false
			UI.updateUI()
			attemptReconnect()
			return
		end

		state.ws = result
		setupWebSocket(state.ws :: WebStreamClient, {
			type = "plugin_reconnect",
			userId = userId,
			reconnectToken = token,
			pluginVersion = Config.PLUGIN_VERSION,
			universeId = tostring(game.GameId),
		})
	end)
end

function Connection.connect(connectionCode: string)
	local state = Config.state
	if state.isConnected then return end
	if connectionCode == "" then
		warn("[Metain] Enter a connection code first")
		return
	end

	UI.toggleButton:SetActive(true)
	state.reconnectAttempts = 0
	if state.reconnectResetThread then
		pcall(task.cancel, state.reconnectResetThread)
		state.reconnectResetThread = nil
	end

	local studioUserId = tostring(StudioService:GetUserId())
	state.lastUserId = studioUserId

	local ok, result = createWebSocket(studioUserId)

	if not ok then
		UI.toggleButton:SetActive(false)
		warn("[Metain] Failed to create WebSocket:", result)
		return
	end

	state.ws = result
	setupWebSocket(state.ws :: WebStreamClient, {
		type = "plugin_ready",
		userId = studioUserId,
		connectionCode = connectionCode:upper(),
		pluginVersion = Config.PLUGIN_VERSION,
		universeId = tostring(game.GameId),
	})
end

function Connection.disconnect()
	local state = Config.state
	state.reconnectToken = nil
	state.reconnectAttempts = 0
	state.isReconnecting = false
	stopHeartbeat()

	if state.reconnectResetThread then
		pcall(task.cancel, state.reconnectResetThread)
		state.reconnectResetThread = nil
	end

	if state.reconnectThread then
		pcall(task.cancel, state.reconnectThread)
		state.reconnectThread = nil
	end

	closeOldWebSocket()

	state.isConnected = false
	state.isAuthorized = false
	UI.toggleButton:SetActive(false)
	UI.updateUI()
end

return Connection
