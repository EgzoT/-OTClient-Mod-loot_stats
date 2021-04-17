function MenuOption()
    local menuOption = {
        optionPanel = nil;

        elements = {};

        init = function(self)
            self.optionPanel = g_ui.loadUI('menuOption')
            modules.client_options.addTab(tr('Loot Stats'), self.optionPanel, '/-OTClient-Mod-loot_stats/ui/img/menu_icon.png')

            self:loadElementsUI()
            self:setDefaultValuesToElementsUI()

            self:connectElements()
            self:connectStoreWithElements()
            self:connectElementsWithStore()
        end;

        terminate = function(self)
            self:disconnectElements()
            self:disconnectStoreFromElements()    
            self:disconnectElementsWithStore()

            self:clear()

            modules.client_options.removeTab('Loot Stats')
            self.optionPanel = nil
        end;

        clear = function(self)
            self.elements = {}
        end;

        loadElementsUI = function(self)
            self.elements.showLootOnScreen = self.optionPanel:recursiveGetChildById('showLootOnScreen')
            self.elements.amountLootOnScreenLabel = self.optionPanel:recursiveGetChildById('amountLootOnScreenLabel')
            self.elements.amountLootOnScreen = self.optionPanel:recursiveGetChildById('amountLootOnScreen')
            self.elements.clearData = self.optionPanel:recursiveGetChildById('clearData')
        end;

        setDefaultValuesToElementsUI = function(self)
            self.elements.showLootOnScreen:setChecked(store:getShowLootOnScreen())
            self.elements.amountLootOnScreenLabel:setText(tr('The amount of loot on the screen: %d', store:getAmountLootOnScreen()))
            self.elements.amountLootOnScreen:setValue(store:getAmountLootOnScreen())
        end;

        -- Connect

        connectElements = function(self)
            self.elements.clearData.onMouseRelease = function(widget, mousePosition, mouseButton) ui:clearData() end
        end;

        connectStoreWithElements = function(self)
            store.onChangeShowLootOnScreen.onChangeUI = function(value) self:onChangeStoreShowLootOnScreen(value) end
            store.onChangeAmountLootOnScreen.onChangeUI = function(value) self:onChangeStoreAmountLootOnScreen(value) end
        end;

        connectElementsWithStore = function(self)
            self.elements.showLootOnScreen.onMouseRelease = function(widget, mousePosition, mouseButton) store:setShowLootOnScreen(not widget:isChecked()) end
            self.elements.amountLootOnScreen.onValueChange = function(widget, value) self:onChangeUIAmountLootOnScreen(widget, value) end
        end;

        -- Disconnect

        disconnectElements = function(self)
            self.elements.clearData.onMouseRelease = nil
        end;

        disconnectStoreFromElements = function(self)
            store.onChangeShowLootOnScreen.onChangeUI = nil
            store.onChangeAmountLootOnScreen.onChangeUI = nil
        end;

        disconnectElementsWithStore = function(self)
            self.elements.showLootOnScreen.onMouseRelease = nil
            self.elements.amountLootOnScreen.onValueChange = nil
        end;

        -- On UI change

        onChangeUIAmountLootOnScreen = function(self, widget, value)
            self.elements.amountLootOnScreenLabel:setText(tr('The amount of loot on the screen: %d', value))
            store:setAmountLootOnScreen(value)
        end;

        -- On store change

        onChangeStoreShowLootOnScreen = function(self, value)
            self.elements.showLootOnScreen:setChecked(value)
        end;

        onChangeStoreAmountLootOnScreen = function(self, value)
            self.elements.amountLootOnScreen:setValue(value)
        end;
    }

    return menuOption
end
