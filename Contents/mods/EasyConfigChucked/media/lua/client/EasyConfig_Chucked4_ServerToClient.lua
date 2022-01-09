local function onCommand(_module, _command, _dataA, _dataB)
	--clientside
	if _module=="ConfigFile" then
		if _command=="Load" then
			print("Easy-Config-Chucked: serverToClient: sending settings to client: C")
			--sendServerCommand("ConfigFile", "Load", _dataB)
			EasyConfig_Chucked.loadConfig(true, _dataB)
		end
	end
end
--Events.OnClientCommand.Add(onCommand)--/client/ to server
Events.OnServerCommand.Add(onCommand)--/server/ to client