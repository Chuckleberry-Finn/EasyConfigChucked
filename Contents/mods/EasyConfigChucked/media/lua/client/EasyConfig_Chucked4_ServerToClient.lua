require "EasyConfigChucked1_Main"

local function onCommand(_module, _command, _dataA, _dataB)
	if _module=="ConfigFile" then
		if _command=="SendSettings" then
			if getDebug() then
				print("Easy-Config-Chucked: serverToClient: sending settings to client  (C)  isServer:"..tostring(isServer()).." isClient:"..tostring(isClient()))
			end
			EasyConfig_Chucked.loadConfig(_dataA, true, true)
		end
	end
end
Events.OnServerCommand.Add(onCommand)--/server/ to client