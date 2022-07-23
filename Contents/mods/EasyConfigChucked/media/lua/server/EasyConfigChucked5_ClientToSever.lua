require "EasyConfigChucked1_Main"

local function onCommand(_module, _command, _, _dataB)

	if _module=="ConfigFile" then
		if _command=="Load" then
			if getDebug() then print("Easy-Config-Chucked: clientToServer: LOADING  (B)  isServer:"..tostring(isServer()).." isClient:"..tostring(isClient())) end
			local settings = EasyConfig_Chucked.loadConfig(nil, true, true)
			sendServerCommand("ConfigFile", "SendSettings", settings)

		elseif _command == "Save" then
			if getDebug() then print("Easy-Config-Chucked: clientToServer: SAVING  isServer:"..tostring(isServer()).." isClient:"..tostring(isClient())) end
			if not _dataB then
				if getDebug() then print("Easy-Config-Chucked: ERR: No Serverside Settings To Save.") end
				return
			end
			EasyConfig_Chucked.loadConfig(_dataB, true, true)
			EasyConfig_Chucked.saveConfig(true)
			sendServerCommand("ConfigFile", "SendSettings", _dataB)
		end
	end
end
Events.OnClientCommand.Add(onCommand)--/client/ to server


function serverLoadConfig()
	if getDebug() then print("ECC: OnMainMenuEnter") end
	for _,mod in pairs(EasyConfig_Chucked.mods) do
		EasyConfig_Chucked.prepModForLoad(mod)
	end
	EasyConfig_Chucked.loadConfig()
end
Events.OnMainMenuEnter.Add(serverLoadConfig)