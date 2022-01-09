local function onCommand(_module, _command, _dataA, _dataB)
	--clientside
end
--Events.OnClientCommand.Add(onCommand)--/client/ to server
Events.OnServerCommand.Add(onCommand)--/server/ to client