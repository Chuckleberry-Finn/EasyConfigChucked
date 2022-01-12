require "EasyConfigChucked1_Main"

local function debugArg(n,nName)
	if type(n)=="table" then
		print(" - "..nName..":")
		for k,v in pairs(n) do
			print(" -- "..tostring(k).." "..tostring(v))
			if type(v)=="table" then
				for kk,vv in pairs(v) do
					print(" --- "..tostring(kk).." "..tostring(vv))
				end
			end
		end
	else
		print(" - "..nName..":"..tostring(n))
	end
end

--if isClient() then sendClientCommand(module, command, args) end -- to send here
local function onCommand(_module, _command, _dataA, _dataB)
	--serverside

	print("onCommand: _module:".._module.."  _command:".._command)

	if _module=="ConfigFile" then
		if _command=="Load" then
			print("Easy-Config-Chucked: clientToServer: LOADING  (B)")
			debugArg(_dataA,"_dataA")
			debugArg(_dataB,"_dataB")
			local settings = EasyConfig_Chucked.loadConfig(nil,true, true)
			if not settings then
				print("Easy-Config-Chucked: ERR: No Serverside Settings To Load.")
				return
			end
			debugArg(settings,"settings")
			sendServerCommand("ConfigFile", "SendSettings", settings)

		elseif _command == "Save" then
			print("Easy-Config-Chucked: clientToServer: SAVING")
			if not _dataB then
				print("Easy-Config-Chucked: ERR: No Serverside Settings To Save.")
				return
			end
			debugArg(_dataB,"_dataB")
			EasyConfig_Chucked.loadConfig(_dataB,true, true)
			EasyConfig_Chucked.saveConfig(_dataB, true)
			sendServerCommand("ConfigFile", "SendSettings", _dataB)
		end
	end
end
Events.OnClientCommand.Add(onCommand)--/client/ to server
--sendServerCommand("sendLooper", _dataB.command, _dataB) -- to send to /client