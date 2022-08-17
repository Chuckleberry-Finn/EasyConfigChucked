require "ISUI/ISPanelJoypad"
require "ISUI/ISButton"
require "ISUI/ISControllerTestPanel"
require "ISUI/ISVolumeControl"
require "defines"

local GameOption = ISBaseObject:derive("GameOption")

function GameOption:new(name, control, arg1, arg2)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.name = name
	o.control = control
	o.arg1 = arg1
	o.arg2 = arg2
	if control.isCombobox then
		control.onChange = self.onChange
		control.target = o
	end
	if control.isTickBox then
		control.changeOptionMethod = self.onChange
		control.changeOptionTarget = o
	end
	if control.isSlider then
		control.targetFunc = self.onChange
		control.target = o
	end

	if (not control.isCombobox) and (not control.isTickBox) and (not control.isSlider) then
		control.onChange = function() o.gameOptions.changed = true end
	end

	return o
end

function GameOption:onChange()
	self.gameOptions:onChange(self)
end

local function ecc_getText(text, notActually, suffix)
	if notActually then return text end
	suffix = suffix or ""
	return getText("UI_Config_"..text..suffix)
end

local EasyConfig_MainOptions_create = MainOptions.create
function MainOptions:create() -- override

	for modId,mod in pairs(EasyConfig_Chucked.mods) do
		EasyConfig_Chucked.prepModForLoad(mod)
	end

	if EasyConfig_MainOptions_create then
		EasyConfig_MainOptions_create(self) -- call original
	end

	local EasyConfig_self_gameOptions_toUI = self.gameOptions.toUI
	function self.gameOptions.toUI(self)
		for _,option in ipairs(self.options) do
			if option then option:toUI() end
		end
		self.changed = false
		return EasyConfig_self_gameOptions_toUI(self)
	end

	local EasyConfig_self_gameOptions_apply = self.gameOptions.apply
	function self.gameOptions.apply(self)
		for _,option in ipairs(self.options) do
			if option then
				option:apply()
			end
		end
		EasyConfig_Chucked.saveConfig()
		self.changed = false
		return EasyConfig_self_gameOptions_apply(self)
	end

	local x = self:getWidth()/2.5
	local y = 30
	local width = 200
	local height = 20

	--new addText because MainOptions doesn't have it
	function addText(text, font, r, g, b, a, customX)
		self.addY = self.addY +7
		local label = ISLabel:new(x+(customX or 20),y+self.addY,height, text, r or 1, g or 1, b or 1, a or 1, font or UIFont.Small, true)
		label:initialise()
		self.mainPanel:addChild(label)
		self.addY = self.addY + height +5
		return label
	end

	--alternative addTickBox because I didn't like the one in MainOptions
	function addTickBox(text)
		local label = ISLabel:new(x,y+self.addY,height, text, 1,1,1,1, UIFont.Small, false)
		label:initialise()
		self.mainPanel:addChild(label)
		local box = ISTickBox:new(x+20,y+self.addY, width,height)
		box.choicesColor = {r=1, g=1, b=1, a=1}
		box:initialise()
		self.mainPanel:addChild(box)
		self.mainPanel:insertNewLineOfButtons(box)
		box:addOption("", nil) -- only add a single option with no values, our tickbox can only be true/false.
		self.addY = self.addY + height +5
		return box
	end

	--new addNumberBox because MainOptions doesn't have it
	function addNumberBox(text)
		local label = ISLabel:new(x,y+self.addY,height, text, 1,1,1,1, UIFont.Small, false)
		label:initialise()
		self.mainPanel:addChild(label)
		local box = ISTextEntryBox:new("", x+20,y+self.addY, 200,20)
		box.font = UIFont.Small
		box:initialise()
		box:instantiate()
		box:setOnlyNumbers(true)
		self.mainPanel:addChild(box)
		self.mainPanel:insertNewLineOfButtons(box)
		self.addY = self.addY + height +5
		return box
	end

	--new addSpace
	function addSpace()
		self.addY = self.addY + height +5
	end

	function createElements(mod, invalidAccess)
		--addText(mod.name, UIFont.Medium)
		--addSpace()
		if (not mod) or (not mod.menu) or (not (type(mod.menu) == "table")) then
			return
		end

		for gameOptionName,menuEntry in pairs(mod.menu) do
			if gameOptionName and menuEntry then
				if (not invalidAccess) or menuEntry.alwaysAccessible then

					--- TEXT ---
					if menuEntry.type == "Text" then
						local text = ecc_getText(gameOptionName, menuEntry.noTranslate)
						if menuEntry.addAfter then text = text..menuEntry.addAfter end
						addText(text, menuEntry.font, menuEntry.r, menuEntry.g, menuEntry.b, menuEntry.a, menuEntry.customX)
					end

					--- SPACE ---
					if menuEntry.type == "Space" then
						local iteration = menuEntry.iteration or 1
						for i=1, iteration do
							addSpace()
						end
					end

					--- TICK BOX ---
					if menuEntry.type == "Tickbox" then
						local title = ecc_getText(gameOptionName, menuEntry.noTranslate)
						local box = addTickBox(title)
						local gameOption = GameOption:new(gameOptionName, box)
						function gameOption.toUI(self)
							local box = self.control
							local bool = menuEntry.selectedValue
							box.selected[1] = bool
						end
						function gameOption.apply(self)
							local box = self.control
							local bool = box.selected[1]
							menuEntry.selectedValue = bool
							menuEntry.selectedLabel = tostring(bool)
						end
						self.gameOptions:add(gameOption)
					end

					--- NUMBER BOX ---
					if menuEntry.type == "Numberbox" then
						local title = ecc_getText(gameOptionName, menuEntry.noTranslate)
						local box = addNumberBox(title)
						local gameOption = GameOption:new(gameOptionName, box)
						function gameOption.toUI(self)
							local box = self.control
							box:setText( tostring(menuEntry.selectedValue) )
						end
						function gameOption.apply(self)
							local box = self.control
							local value = box:getText()
							menuEntry.selectedValue = tonumber(value)
						end
						self.gameOptions:add(gameOption)
					end

					--- COMBO BOX ---
					if menuEntry.type == "Combobox" and menuEntry.optionLabels then
						if (type(menuEntry.optionLabels) == "table") and #menuEntry.optionLabels>0 then
							--addCombo(x,y,w,h, name,options, selected, target, onchange)
							local title = ecc_getText(gameOptionName, menuEntry.noTranslate)

							local labels = {}
							for k,option in pairs(menuEntry.optionLabels) do
								table.insert(labels, ecc_getText(option, menuEntry.noTranslate, "_option"))
							end

							local box = self:addCombo(x,y,200,20, title, labels)
							if menuEntry.tooltip then
								local tooltip = ecc_getText(gameOptionName, menuEntry.noTranslate, "_tooltip")
								box:setToolTipMap({defaultTooltip = tooltip})
							end
							local gameOption = GameOption:new(gameOptionName, box)
							function gameOption.toUI(self)
								local box = self.control
								box.selected = menuEntry.selectedIndex
							end
							function gameOption.apply(self)
								local box = self.control
								menuEntry.selectedIndex = box.selected
								menuEntry.selectedLabel = menuEntry.optionsIndexes[box.selected][1]
								menuEntry.selectedValue = menuEntry.optionsIndexes[box.selected][2]
							end
							self.gameOptions:add(gameOption)
							--self.addY = self.addY - 8
						end
					end

					--[[
					--- SPIN BOX ---
					if menuEntry.type == "Spinbox" and menuEntry.title and menuEntry.optionLabels then
						if (type(menuEntry.optionLabels) == "table") and #menuEntry.optionLabels>0 then
							--addSpinBox(x,y,w,h, name, options, selected, target, onchange)
							local box = self:addSpinBox(x,y,200,20, menuEntry.title, menuEntry.optionLabels)
							local gameOption = GameOption:new(gameOptionName, box)
							function gameOption.toUI(self)
								local box = self.control
								box.selected = menuEntry.selectedIndex
							end
							function gameOption.apply(self)
								local box = self.control
								menuEntry.selectedIndex = box.selected
								menuEntry.selectedLabel = menuEntry.optionsIndexes[box.selected][1]
								menuEntry.selectedValue = menuEntry.optionsIndexes[box.selected][2]
							end
							self.gameOptions:add(gameOption)
						end
					end
					--]]
				end
			end
		end
		self.addY = self.addY + 15
	end

	for modId,mod in pairs(EasyConfig_Chucked.mods) do

		local MODID = getTextOrNull("UI_ConfigMODID_"..mod.modId) or mod.modId or modId

		self.addY = 0
		self:addPage(string.upper(MODID))

		local invalidAccess = false

		if isClient() then
			if not (isAdmin() or isCoopHost()) then
				invalidAccess = true
				addText(getText("UI_NotHostNotAdminAccessDenied"), UIFont.Medium, 1, 1, 1, 1, -125)
			end
		end

		if (not mod.menuSpecificAccess) or (getPlayer() and mod.menuSpecificAccess=="ingame") or (not getPlayer() and mod.menuSpecificAccess=="mainmenu") then
		else
			invalidAccess = true
			if (not getPlayer() and mod.menuSpecificAccess=="ingame") then
				addText(getText("UI_InGameAccessOnly"), UIFont.Medium, 1, 1, 1, 1, -125)
			end
			if (getPlayer() and mod.menuSpecificAccess=="mainmenu") then
				addText(getText("UI_MainMenuAccessOnly1"), UIFont.Medium, 1, 1, 1, 1, -125)
				addText(getText("UI_MainMenuAccessOnly2"), UIFont.Small, 1, 1, 1, 1, -125)
			end
			addText(" ", UIFont.Medium)
		end

		createElements(mod, invalidAccess)

		self.addY = self.addY + MainOptions.translatorPane:getHeight() + 22
		self.mainPanel:setScrollHeight(self.addY + 20)
	end

end


function clientLoadConfig()
	print("ECC: OnMainMenuEnter")
	EasyConfig_Chucked.loadConfig()
end
Events.OnMainMenuEnter.Add(clientLoadConfig)

function clientLoadConfig2(key)
	local mainMenuKey = getCore():getKey("Main Menu")
	if (key == mainMenuKey) or (mainMenuKey == 0 and key == Keyboard.KEY_ESCAPE) then
		local player = getPlayer()
		if player then
			print("ECC: OnKeyPressed "..(player:getUsername()))
			EasyConfig_Chucked.loadConfig()
		end
	end
end
Events.OnKeyPressed.Add(clientLoadConfig2)