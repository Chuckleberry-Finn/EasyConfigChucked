---Override sandbox+ easyconfig entirely
EasyConfig = EasyConfig or nil
function sandboxPlusEasyConfigOverride()
	if EasyConfig then
		for k,v in pairs(EasyConfig.mods) do
			EasyConfig_Chucked.mods[k] = v
		end
		EasyConfig.mods = {}
	end
end

Events.OnGameBoot.Add(sandboxPlusEasyConfigOverride)