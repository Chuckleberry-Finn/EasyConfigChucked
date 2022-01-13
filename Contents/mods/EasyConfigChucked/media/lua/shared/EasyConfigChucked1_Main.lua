Events.OnGameBoot.Add(print("Easy-Config-Chucked: ver:0.3-MP-READY"))
---Original EasyConfig found in Sandbox+ (author: derLoko)


--https://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
function table:copy(o, seen)
	seen = seen or {}
	if o == nil then return nil end
	if seen[o] then return seen[o] end

	local no = {}
	seen[o] = no
	setmetatable(no, table:copy(getmetatable(o), seen))

	for k, v in next, o, nil do
		k = (type(k) == 'table') and k:copy(seen) or k
		v = (type(v) == 'table') and v:copy(seen) or v
		no[k] = v
	end
	return no
end


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


function EasyConfig_Chucked.getConfigProcessor(modId, command, server)
	if not modId or not command then
		return
	end

	local configSavePath = "config"..getFileSeparator()..modId..".config"
	local world = getWorld()

	if server then
		local relPath = "EasyConfigChuckedServerConfigs"..getFileSeparator()..string.gsub(world:getWorld(), "_player", "").."_"..configSavePath
		print("ECC-FILESYSTEM: expected-MP:"..world:getGameMode().." "..command.." absPath: "..relPath)
		if command == "write" then
			return getFileWriter(relPath, true, false)
		elseif command == "read" then
			return getFileReader(relPath, false)
		end
	else
		print("ECC-FILESYSTEM: expected-SP:"..world:getGameMode().." "..command.." absPath: "..configSavePath)
		if command == "write" then
			return getModFileWriter(modId, configSavePath, true, false)
		elseif command == "read" then
			return getModFileReader(modId, configSavePath, false)
		end
	end
end


function EasyConfig_Chucked.saveConfig(settingsReceived)

	if not settingsReceived and isClient() then
		if isAdmin() or isCoopHost() then
			print("Easy-Config-Chucked: settings to *save* passed onto server")
			sendClientCommand("ConfigFile", "Save", EasyConfig_Chucked.mods)
		else
			print("Easy-Config-Chucked: MP GameMode Detected: Not Host/Admin: Saving Prevented")
			return
		end
	else

		if settingsReceived then
			print("Easy-Config-Chucked: Loaded settings from user  (D)")
			EasyConfig_Chucked.mods = table.copy(settingsReceived)
		end

		for modId,mod in pairs(EasyConfig_Chucked.mods) do
			local config = mod.config
			local menu = mod.menu

			local fileWriter  = EasyConfig_Chucked.getConfigProcessor(modId, "write", (not not settingsReceived))
			if not fileWriter then
				print("ERROR: Easy-Config-Chucked: fileReader not found in saving")
			else
				print("Easy-Config-Chucked: saving: modId:"..modId)
				for gameOptionName,_ in pairs(config) do
					local menuEntry = menu[gameOptionName]
					if menuEntry then
						if menuEntry.selectedLabel then
							local menuEntry_selectedLabel = menuEntry.selectedLabel
							if type(menuEntry.selectedLabel) == "boolean" then
								menuEntry_selectedLabel = tostring(menuEntry_selectedLabel)
							end
							if menuEntry_selectedLabel then
								fileWriter:write(gameOptionName.."="..menuEntry_selectedLabel..",\r")
							else
								print("WARN: Easy-Config-Chucked: "..gameOptionName..": menuEntry_selectedLabel=null (saveConfig) aborted.")
							end
						elseif menuEntry.selectedValue then
							local menuEntry_selectedValue = menuEntry.selectedValue
							if type(menuEntry.selectedValue) == "boolean" then
								menuEntry_selectedValue = tostring(menuEntry_selectedValue)
							end
							if menuEntry_selectedValue then
								fileWriter:write(gameOptionName.."="..menuEntry_selectedValue..",\r")
							else
								print("WARN: Easy-Config-Chucked: "..gameOptionName..": menuEntry_selectedValue=null (saveConfig) aborted.")
							end
						else
							print("WARN: Easy-Config-Chucked: "..gameOptionName..": selectedLabel and selectedValue = null (saveConfig)")
						end
					else
						print("WARN: Easy-Config-Chucked: "..gameOptionName..": menuEntry=null (saveConfig)")
					end
				end
				fileWriter:close()
			end
		end
	end
end

--[[
local world = getWorld()
    local relPath = world:getGameMode() .. getFileSeparator() .. world:getWorld()
    local savePath = getAbsoluteSaveFolderName(relPath)
--]]

function EasyConfig_Chucked.applySettings(fromTable,toTable)
	for option,value in pairs(toTable) do
		local menuEntry = fromTable.menu[option]
		if menuEntry then
			if menuEntry.options then
				if menuEntry.optionsKeys[value] then
					menuEntry.selectedIndex = menuEntry.optionsKeys[value][1]
					menuEntry.selectedValue = menuEntry.optionsKeys[value][2]
					menuEntry.selectedLabel = value
				end
			else
				if value == "true" then menuEntry.selectedValue = true
				elseif value == "false" then menuEntry.selectedValue = false
				elseif type(value)=="boolean" then menuEntry.selectedValue = value
				else menuEntry.selectedValue = tonumber(value) end
			end
			toTable[option] = menuEntry.selectedValue
		end
	end
end


function EasyConfig_Chucked.loadConfig(sentSettings, overrideClient, serverside)
	if not overrideClient and isClient() then
		print("Easy-Config-Chucked: loading request passed onto server  (A)")
		sendClientCommand("ConfigFile", "Load", nil)
	else

		if sentSettings then
			print("Easy-Config-Chucked: Loaded settings from server  (D)")
			EasyConfig_Chucked.mods = table.copy(sentSettings)
			return
		end

		for modId,mod in pairs(EasyConfig_Chucked.mods) do
			EasyConfig_Chucked.prepModForLoad(mod)
			local config = mod.config
			local menu = mod.menu

			if not config or not menu then
				print("ERROR: Easy-Config-Chucked: config=null or menu=null "..modId.." (loadConfig)")
				break
			end

			local fileReader = EasyConfig_Chucked.getConfigProcessor(modId, "read", (overrideClient and serverside))
			if fileReader then
				print("Easy-Config-Chucked: loading: modId: "..modId)
				for _,_ in pairs(config) do
					local line = fileReader:readLine()
					if not line then
						break
					end
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
			else
				print("ERROR: Easy-Config-Chucked: fileReader not found in loading")
			end
		end
		return EasyConfig_Chucked.mods
	end
end



function loadConfig_OnMainMenuEnter()
	print("ECC: OnMainMenuEnter")
	EasyConfig_Chucked.loadConfig()
end
Events.OnMainMenuEnter.Add(loadConfig_OnMainMenuEnter)


function loadConfig_OnKeyPressed_MainMenu(key)
	local mainMenuKey = getCore():getKey("Main Menu")
	if (key == mainMenuKey) or (mainMenuKey == 0 and key == Keyboard.KEY_ESCAPE) then
		print("ECC: OnKeyPressed "..(getPlayer():getUsername()))
		EasyConfig_Chucked.loadConfig()
	end
end
Events.OnKeyPressed.Add(loadConfig_OnKeyPressed_MainMenu)
