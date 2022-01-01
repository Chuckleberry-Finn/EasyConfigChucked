---Original EasyConfig found in Sandbox+ (author: derLoko)
EasyConfig_Chucked = EasyConfig_Chucked or {}
EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}

function EasyConfig_Chucked.prepModForLoad(mod)

	--link all the things!
	for gameOptionName,menuEntry in pairs(mod.menu) do
		if menuEntry then
			if menuEntry.options then
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


function EasyConfig_Chucked.saveConfig()

	if isClient() then
		if (not isAdmin()) and (not isCoopHost()) then
			print("Easy-Config-Chucked: MP GameMode Detected: Note Host/Admin: Saving Prevented")
			return
		end
	end

	for modId,mod in pairs(EasyConfig_Chucked.mods) do
		local config = mod.config
		local menu = mod.menu
		local configFile = "media/config/"..modId..".config"
		local fileWriter = getModFileWriter(modId, configFile, true, false)
		if fileWriter then
			print("Easy-Config-Chucked: modId: "..modId.." saving")
			for gameOptionName,_ in pairs(config) do
				local menuEntry = menu[gameOptionName]
				if menuEntry then
					if menuEntry.selectedLabel then
						local menuEntry_selectedLabel = menuEntry.selectedLabel
						if type(menuEntry.selectedLabel) == "boolean" then
							menuEntry_selectedLabel = tostring(menuEntry_selectedLabel)
						end
						fileWriter:write(gameOptionName.."="..menuEntry_selectedLabel..",\r")
					elseif menuEntry.selectedValue then
						local menuEntry_selectedValue = menuEntry.selectedValue
						if type(menuEntry.selectedValue) == "boolean" then
							menuEntry_selectedValue = tostring(menuEntry_selectedValue)
						end
						fileWriter:write(gameOptionName.."="..menuEntry_selectedValue..",\r")
					else
						print("ERROR: Easy-Config-Chucked: "..gameOptionName..": selectedLabel and selectedValue = null (saveConfig)")
					end
				else
					print("WARN: Easy-Config-Chucked: "..gameOptionName..": menuEntry=null (saveConfig)")
				end
			end
			fileWriter:close()
		end
	end
end

function EasyConfig_Chucked.loadConfig()

	for modId,mod in pairs(EasyConfig_Chucked.mods) do

		EasyConfig_Chucked.prepModForLoad(mod)

		local config = mod.config
		local menu = mod.menu
		local configFile = "media/config/"..modId..".config"
		local fileReader = getModFileReader(modId, configFile, false)
		if fileReader then
			print("modId: "..modId.." loading")
			for _,_ in pairs(config) do
				local line = fileReader:readLine()
				if not line then break end
				for gameOptionName,label in string.gmatch(line, "([^=]*)=([^=]*),") do
					local menuEntry = menu[gameOptionName]
					if menuEntry then
						if menuEntry.options then
							if menuEntry.optionsKeys[label] then
								menuEntry.selectedIndex = menuEntry.optionsKeys[label][1]
								menuEntry.selectedValue = menuEntry.optionsKeys[label][2]
								menuEntry.selectedLabel = label
							end
						else
							if label == "true" then menuEntry.selectedValue = true
							elseif label == "false" then menuEntry.selectedValue = false
							else menuEntry.selectedValue = tonumber(label) end
						end
						config[gameOptionName] = menuEntry.selectedValue
					else
						print("ERROR: Easy-Config-Chucked: menuEntry=null (loadConfig)")
					end
				end
			end
			fileReader:close()
		end
	end
end

--Events.OnGameBoot.Add(EasyConfig_Chucked.loadConfig)
Events.OnMainMenuEnter.Add(EasyConfig_Chucked.loadConfig)