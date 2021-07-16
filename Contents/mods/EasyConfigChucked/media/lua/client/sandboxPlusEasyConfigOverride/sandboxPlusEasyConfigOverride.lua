---Override sandbox+ easyconfig entirely
function sandboxPlusEasyConfigOverride()
	for k,v in pairs(EasyConfig.mods) do
		EasyConfig_Chucked.mods[k] = v
	end
	EasyConfig.mods = {}
end

Events.OnGameBoot.Add(sandboxPlusEasyConfigOverride)