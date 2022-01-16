require "EasyConfigChucked1_Main"

local function onCommand(_module, _command, _dataA, _dataB)
	--clientside
	--if getDebug() then print("onCommand: _module:".._module.."  _command:".._command) end
	if _module=="ConfigFile" then
		if _command=="SendSettings" then
			if getDebug() then
				print("Easy-Config-Chucked: serverToClient: sending settings to client  (C)  isServer:"..tostring(isServer()).." isClient:"..tostring(isClient()))
			 	--print(" -- _dataA:"..tostring(_dataA).." _dataB:"..tostring(_dataB))
			end
			EasyConfig_Chucked.loadConfig(_dataA, true, true)
		end
	end
end
--Events.OnClientCommand.Add(onCommand)--/client/ to server
Events.OnServerCommand.Add(onCommand)--/server/ to client