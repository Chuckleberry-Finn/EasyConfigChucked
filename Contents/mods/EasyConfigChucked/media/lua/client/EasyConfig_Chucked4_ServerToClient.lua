require "EasyConfigChucked1_Main"

local function onCommand(_module, _command, _dataA, _dataB)
	--clientside
	if _module=="ConfigFile" then
		if _command=="SendSettings" then
			print("Easy-Config-Chucked: serverToClient: sending settings to client  (C)")
			print(" -- _dataA:"..tostring(_dataA).." _dataD"..tostring(_dataB))
			EasyConfig_Chucked.loadConfig(_dataB.settings)
		end
	end
end
--Events.OnClientCommand.Add(onCommand)--/client/ to server
Events.OnServerCommand.Add(onCommand)--/server/ to client