require "EasyConfigChucked1_Main"

--if isClient() then sendClientCommand(module, command, args) end -- to send here
local function onCommand(_module, _command, _dataA, _dataB)
	--serverside

	print("onCommand: _module:".._module.."  _command:".._command)

	if _module=="ConfigFile" then
		if _command=="Load" then

			print("Easy-Config-Chucked: clientToServer: LOADING  (B)")
			print(" -- _dataA:"..tostring(_dataA).." _dataD"..tostring(_dataB))
			local settings = EasyConfig_Chucked.loadConfig(nil, true)

			if not settings then
				print("Easy-Config-Chucked: ERR: No Serverside Settings To Load.")
				return
			end

			for k,v in pairs(settings) do
				print(" - "..tostring(k).." "..tostring(v))
				for kk,vv in pairs(v) do
					print(" - - "..tostring(kk).." "..tostring(vv))
				end
			end
			sendServerCommand("ConfigFile", "SendSettings", {settings=settings})
			--EasyConfig_Chucked.loadConfig(true)

		elseif _command == "Save" then
			print("Easy-Config-Chucked: clientToServer: SAVING")

			if not _dataB then
				print("Easy-Config-Chucked: ERR: No Serverside Settings To Save.")
				return
			end

			for k,v in pairs(_dataB) do
				print(" - "..tostring(k).." "..tostring(v))
				for kk,vv in pairs(v) do
					print(" - - "..tostring(kk).." "..tostring(vv))
				end
			end
			EasyConfig_Chucked.saveConfig(_dataB)
		end
	end
end
Events.OnClientCommand.Add(onCommand)--/client/ to server
--sendServerCommand("sendLooper", _dataB.command, _dataB) -- to send to /client