require "EasyConfig/EasyConfig"

---Override sandbox+ easyconfig entirely
EasyConfig = EasyConfig or nil

function sandboxPlusEasyConfigOverride()
	local SP = SP or nil
	local SBP = false

	local activeModIDs = getActivatedMods()
	for i=1,activeModIDs:size() do
		local modID = activeModIDs:get(i-1)
		if modID == "SandboxPlus" then
			SBP = true
		end
	end

	if SBP and SP then

		if getDebug() then print("Easy-Config-Chucked: OLD Easy Config Found: "..SP.modId) end
		for kk,vv in pairs(SP) do print(" -- "..tostring(kk).." = "..tostring(vv)) end

		local newMod = {}
		newMod.modId = "SandboxPlus"
		newMod.name = "Sandbox+"
		newMod.config = {}
		for k,v in pairs(SP.config) do
			newMod.config[k] = v
		end
		newMod.menu = {}
		for k,v in pairs(SP.menu) do
			newMod.menu[k] = v
		end

		EasyConfig_Chucked = EasyConfig_Chucked or {}
		EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}
		EasyConfig_Chucked.mods[newMod.modId] = newMod
	--else
		--if not SBP then print("--Easy-Config-Chucked: SBP not found") end
		--if not SP then print("--Easy-Config-Chucked: SP not found") end
	end
end


function scrub_EasyConfig_mods()
	if EasyConfig then
		sandboxPlusEasyConfigOverride()
		EasyConfig.mods = {}
	end
end

Events.OnGameBoot.Add(scrub_EasyConfig_mods)
Events.OnServerStarted.Add(scrub_EasyConfig_mods)



