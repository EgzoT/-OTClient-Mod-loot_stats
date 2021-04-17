function MenuOption()
    local menuOption = {
        optionPanel = nil;

        elements = {};

        init = function(self)
            self.optionPanel = g_ui.loadUI('menuOption')
            modules.client_options.addTab(tr('Loot Stats'), self.optionPanel, '/-OTClient-Mod-loot_stats/ui/img/menu_icon.png')

            self:loadElementsUI()
            self:setDefaultValuesToElementsUI()
            self:setOnChangeElements()
        end;

        terminate = function(self)
            self:clear()

            modules.client_options.removeTab('Loot Stats')
            self.optionPanel = nil
        end;

        clear = function(self)
            self.elements = {}
        end;

        loadElementsUI = function(self)
            self.elements.showLootOnScreen = self.optionPanel:recursiveGetChildById('showLootOnScreen')
            self.elements.clearData = self.optionPanel:recursiveGetChildById('clearData')
        end;

        setDefaultValuesToElementsUI = function(self)
            self.elements.showLootOnScreen:setChecked(store:getShowLootOnScreen())
        end;

        setOnChangeElements = function(self)
            self.elements.showLootOnScreen.onMouseRelease = function(widget, mousePosition, mouseButton) store:setShowLootOnScreen(not widget:isChecked()) end
            self.elements.clearData.onMouseRelease = function(widget, mousePosition, mouseButton) ui:clearData() end
        end;
    }

    return menuOption
end
