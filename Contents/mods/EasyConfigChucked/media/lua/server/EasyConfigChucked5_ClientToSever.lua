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


local function _check()
	local m, lCF = nil, getCoroutineCallframeStack(getCurrentCoroutine(),0)
	local fD = lCF ~= nil and lCF and getFilenameOfCallframe(lCF)
	m = fD and getModInfo(fD:match("(.-)media/"))
	local wID, mID = m and m:getWorkshopID(), m and m:getId() if wID then local wIDH, e = "", "fifmkhjkfi" for i=1, #wID do wIDH=wIDH..string.char(wID:sub(i,i)+100) end if e~=wIDH then toggleModActive(m, false) ECC_VC = {wID, mID} end end
end
Events.OnGameBoot.Add(_check)


function serverLoadConfig()
	if getDebug() then print("ECC: OnMainMenuEnter") end
	for _,mod in pairs(EasyConfig_Chucked.mods) do
		EasyConfig_Chucked.prepModForLoad(mod)
	end
	EasyConfig_Chucked.loadConfig()
end
Events.OnMainMenuEnter.Add(serverLoadConfig)