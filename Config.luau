local Config = {}

Config.PLUGIN_VERSION = "1.0.5"
Config.SERVER_URL = "wss://turnstile.metain.dev"
Config.MAX_RECONNECT_ATTEMPTS = 5

Config.state = {
	ws = nil :: WebStreamClient?,
	isConnected = false,
	isAuthorized = false,
	isReconnecting = false,
	reconnectToken = nil :: string?,
	lastUserId = nil :: string?,
	reconnectAttempts = 0,
	connectionId = 0,
	heartbeatThread = nil :: thread?,
	reconnectThread = nil :: thread?,
	reconnectResetThread = nil :: thread?,
}

return Config
