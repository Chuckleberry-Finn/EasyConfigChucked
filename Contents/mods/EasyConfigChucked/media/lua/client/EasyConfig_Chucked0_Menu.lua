require "ISUI/ISPanelJoypad"
require "ISUI/ISButton"
require "ISUI/ISControllerTestPanel"
require "ISUI/ISVolumeControl"
require "defines"
require "OptionScreens/MainOptions"

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
		local go = o.gameOptions
		control.onChange = function() o.gameOptions.changed = true end
	end

	return o
end

function GameOption:onChange()
	self.gameOptions:onChange(self)
end


EasyConfig_MainOptions_create = MainOptions.create

function MainOptions:create() -- override

	if EasyConfig_MainOptions_create then
		EasyConfig_MainOptions_create(self) -- call original
	end

	if isClient() then --and isIngameState() then
		if (not isAdmin()) and (not isCoopHost()) then
			print("Easy-Config-Chucked: MP GameMode Detected: Note Host/Admin: MainOptions Hidden")
			return
		end
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
		EasyConfig_Chucked.loadConfig()
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
						addText(menuEntry.text, menuEntry.font, menuEntry.r, menuEntry.g, menuEntry.b, menuEntry.a, menuEntry.customX)
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
						local box = addTickBox(menuEntry.title)
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
						local box = addNumberBox(menuEntry.title)
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
					if menuEntry.type == "Combobox" and menuEntry.title and menuEntry.optionLabels then
						if (type(menuEntry.optionLabels) == "table") and #menuEntry.optionLabels>0 then
							--addCombo(x,y,w,h, name,options, selected, target, onchange)
							local box = self:addCombo(x,y,200,20, menuEntry.title, menuEntry.optionLabels)
							if menuEntry.tooltip then
								box:setToolTipMap({defaultTooltip = menuEntry.tooltip})
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
				end
			end
		end
		self.addY = self.addY + 15
	end

	for modId,mod in pairs(EasyConfig_Chucked.mods) do

		self.addY = 0
		self:addPage(string.upper(mod.name))

		local invalidAccess = false

		if (not mod.menuSpecificAccess) or (getPlayer() and mod.menuSpecificAccess=="ingame") or (not getPlayer() and mod.menuSpecificAccess=="mainmenu") then
		else
			invalidAccess = true
			if (not getPlayer() and mod.menuSpecificAccess=="ingame") then
				addText("This mod's options can only be accessed from the in-game options menu.", UIFont.Medium, 1, 1, 1, 1, -100)
			end
			if (getPlayer() and mod.menuSpecificAccess=="mainmenu") then
				addText("This mod has options that can only be accessed from the main-menu options.", UIFont.Medium, 1, 1, 1, 1, -100)
				addText("Note: Make sure to enable this mod from the main-menu to view the options.", UIFont.Small, 1, 1, 1, 1, -100)
			end
			addText(" ", UIFont.Medium)
		end

		createElements(mod, invalidAccess)

		self.addY = self.addY + MainOptions.translatorPane:getHeight() + 22
		self.mainPanel:setScrollHeight(self.addY + 20)
	end

end