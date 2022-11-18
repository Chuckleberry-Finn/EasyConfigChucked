Events.OnGameBoot.Add(print("Easy-Config-Chucked: ver:0.3-MainMenuESC-HOTFIX"))
---Original EasyConfig found in Sandbox+ (author: derLoko)

EasyConfig_Chucked = EasyConfig_Chucked or {}
EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}


function EasyConfig_Chucked.prepModForLoad(mod)
	--link all the things!
	for _,menuEntry in pairs(mod.menu) do
		if menuEntry and menuEntry.options then
			menuEntry.optionsIndexes = menuEntry.options
			menuEntry.optionsKeys = {}
			menuEntry.optionsValues = {}
			menuEntry.optionLabels = {} -- passed on to UI elements

			for i,table in ipairs(menuEntry.optionsIndexes) do
				menuEntry.optionLabels[i] = table[1]
				local k = table[1]
				local v = table[2]
				menuEntry.optionsKeys[k] = {i, v}
				menuEntry.optionsValues[v] = {i, k}
			end
		end
	end
	for gameOptionName,value in pairs(mod.config) do
		local menuEntry = mod.menu[gameOptionName]
		if menuEntry then
			if menuEntry.options then
				menuEntry.selectedIndex = menuEntry.optionsValues[value][1]
				menuEntry.selectedLabel = menuEntry.optionsValues[value][2]
			end
			menuEntry.selectedValue = value
		end
	end
end


function EasyConfig_Chucked.getConfigProcessor(modId, command, server)
	if not modId or not command then
		return
	end

	local configSavePath = "config"..getFileSeparator()..modId..".config"
	local world = getWorld()

	if server then
		local relPath = "EasyConfigChuckedServerConfigs"..getFileSeparator()..string.gsub(world:getWorld(), "_player", "").."_"..configSavePath
		if getDebug() then print("ECC-FILESYSTEM: expected-MP:"..world:getGameMode().." "..command.." absPath: "..relPath) end
		if command == "write" then
			return getFileWriter(relPath, true, false)
		elseif command == "read" then
			return getFileReader(relPath, false)
		end
	else
		if getDebug() then print("ECC-FILESYSTEM: expected-SP:"..world:getGameMode().." "..command.." absPath: "..configSavePath) end
		if command == "write" then
			return getModFileWriter(modId, configSavePath, true, false)
		elseif command == "read" then
			return getModFileReader(modId, configSavePath, false)
		end
	end
end


function EasyConfig_Chucked.saveConfig(override)

	if not override and isClient() then
		if isAdmin() or isCoopHost() then
			if getDebug() then print("Easy-Config-Chucked: settings to *save* passed onto server") end
			local settingsToSend = {}
			for modId,mod in pairs(EasyConfig_Chucked.mods) do
				if getDebug() then print(" -- mod: "..modId) end
				local menu = mod.menu
				local config = mod.config
				for option,value in pairs(menu) do
					--if getDebug() then print(" ---- "..option.." = "..tostring(value)) end
					settingsToSend[modId] = settingsToSend[modId] or {}
					settingsToSend[modId][option] = menu[option].selectedValue
					config = menu[option].selectedValue
				end
			end
			sendClientCommand("ConfigFile", "Save", settingsToSend)
		else
			if getDebug() then print("Easy-Config-Chucked: MP GameMode Detected: Not Host/Admin: Saving Prevented") end
			return
		end
	else

		for modId,mod in pairs(EasyConfig_Chucked.mods) do
			local config = mod.config
			local menu = mod.menu

			local fileWriter  = EasyConfig_Chucked.getConfigProcessor(modId, "write", override)
			if not fileWriter then
				if getDebug() then print("ERROR: Easy-Config-Chucked: fileReader not found in saving") end
			else
				if getDebug() then print("Easy-Config-Chucked: saving: modId:"..modId) end
				for gameOptionName,_ in pairs(config) do
					local menuEntry = menu[gameOptionName]
					local configEntry = config[gameOptionName]
					if menuEntry then
						if menuEntry.selectedLabel then
							local menuEntry_selectedLabel = menuEntry.selectedLabel
							configEntry = menuEntry.selectedLabel
							if type(menuEntry.selectedLabel) == "boolean" then
								menuEntry_selectedLabel = tostring(menuEntry_selectedLabel)
							end
							if menuEntry_selectedLabel then
								fileWriter:write(gameOptionName.."="..menuEntry_selectedLabel..",\r")
							else
								if getDebug() then print("WARN: Easy-Config-Chucked: "..gameOptionName..": menuEntry_selectedLabel=null (saveConfig) aborted.") end
							end
						elseif menuEntry.selectedValue then
							local menuEntry_selectedValue = menuEntry.selectedValue
							configEntry = menuEntry.selectedValue
							if type(menuEntry.selectedValue) == "boolean" then
								menuEntry_selectedValue = tostring(menuEntry_selectedValue)
							end
							if menuEntry_selectedValue then
								fileWriter:write(gameOptionName.."="..menuEntry_selectedValue..",\r")
							else
								if getDebug() then print("WARN: Easy-Config-Chucked: "..gameOptionName..": menuEntry_selectedValue=null (saveConfig) aborted.") end
							end
						else
							if getDebug() then print("WARN: Easy-Config-Chucked: "..gameOptionName..": selectedLabel and selectedValue = null (saveConfig)") end
						end
					else
						if getDebug() then print("WARN: Easy-Config-Chucked: "..gameOptionName..": menuEntry=null (saveConfig)") end
					end
				end
				fileWriter:close()
			end
		end
	end
end


function EasyConfig_Chucked.setMenuEntry(menu,gameOptionName,label)
	local menuEntry = menu[gameOptionName]
	if menuEntry then
		local _label = tostring(label)
		if menuEntry.options then
			if menuEntry.optionsKeys and menuEntry.optionsKeys[_label] then
				menuEntry.selectedIndex = menuEntry.optionsKeys[_label][1]
				menuEntry.selectedValue = menuEntry.optionsKeys[_label][2]
				menuEntry.selectedLabel = _label
			end
		else
			if _label == "true" then menuEntry.selectedValue = true
			elseif _label == "false" then menuEntry.selectedValue = false
			else menuEntry.selectedValue = tonumber(_label) end
		end

		return menuEntry.selectedValue
	else
		if getDebug() then print("ERROR: Easy-Config-Chucked: menuEntry=null (gameOptionName:"..tostring(gameOptionName).."=label:"..tostring(label)..") (loadConfig)") end
	end
end

function EasyConfig_Chucked.loadConfig(sentSettings, overrideClient, serverside)
	if not overrideClient and isClient() then
		if getDebug() then print("Easy-Config-Chucked: loading request passed onto server  (A)") end
		sendClientCommand("ConfigFile", "Load", nil)
	else

		if sentSettings then
			if getDebug() then print("Easy-Config-Chucked: Loaded settings from server  (D)") end
			for modId,settings in pairs(sentSettings) do
				if getDebug() then print(" -- mod: "..modId) end

				local modFound = EasyConfig_Chucked.mods[modId]
				if modFound then
					local config = modFound.config
					local menu = modFound.menu
					for option,value in pairs(settings) do
						--if getDebug() then print(" ---- "..option.." = "..tostring(value)) end

						local returnedValue = EasyConfig_Chucked.setMenuEntry(menu,option,value)
						config[option] = returnedValue
					end
				end
			end
			return
		end

		local returnSettings = {}
		for modId,mod in pairs(EasyConfig_Chucked.mods) do
			local config = mod.config
			local menu = mod.menu

			if not config or not menu then
				if getDebug() then print("ERROR: Easy-Config-Chucked: config=null or menu=null "..modId.." (loadConfig)") end
				break
			end

			local fileReader = EasyConfig_Chucked.getConfigProcessor(modId, "read", (overrideClient and serverside))
			if fileReader then
				if getDebug() then print("Easy-Config-Chucked: loading: modId: "..modId) end
				for _,_ in pairs(config) do
					local line = fileReader:readLine()
					if not line then
						break
					end
					for gameOptionName,label in string.gmatch(line, "([^=]*)=([^=]*),") do
						local returnedValue = EasyConfig_Chucked.setMenuEntry(menu,gameOptionName,label)
						config[gameOptionName] = returnedValue
						returnSettings[modId] = returnSettings[modId] or {}
						returnSettings[modId][gameOptionName] = returnedValue
					end
				end
				fileReader:close()
			else
				if getDebug() then print("ERROR: Easy-Config-Chucked: fileReader not found in loading") end
			end
		end
		return returnSettings
	end
end
