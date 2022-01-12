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

local function onCommand(_module, _command, _dataA, _dataB)
	--clientside
	print("onCommand: _module:".._module.."  _command:".._command)

	if _module=="ConfigFile" then
		if _command=="SendSettings" then
			print("Easy-Config-Chucked: serverToClient: sending settings to client  (C)")
			print(" -- _dataA:"..tostring(_dataA).." _dataB:"..tostring(_dataB))

			debugArg(_dataA,"_dataA")
			debugArg(_dataB,"_dataB")

			--EasyConfig_Chucked.saveConfig(_dataA, true)
			EasyConfig_Chucked.loadConfig(_dataA, true, true)
		end
	end
end
--Events.OnClientCommand.Add(onCommand)--/client/ to server
Events.OnServerCommand.Add(onCommand)--/server/ to client