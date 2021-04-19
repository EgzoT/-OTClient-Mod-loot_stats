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
            self.elements.delayTimeLootOnScreenLabel = self.optionPanel:recursiveGetChildById('delayTimeLootOnScreenLabel')
            self.elements.delayTimeLootOnScreen = self.optionPanel:recursiveGetChildById('delayTimeLootOnScreen')
            self.elements.ignoreMonsterLevelSystem = self.optionPanel:recursiveGetChildById('ignoreMonsterLevelSystem')
            self.elements.ignoreLastSignWhenDot = self.optionPanel:recursiveGetChildById('ignoreLastSignWhenDot')
            self.elements.clearData = self.optionPanel:recursiveGetChildById('clearData')
        end;

        setDefaultValuesToElementsUI = function(self)
            self.elements.showLootOnScreen:setChecked(store:getShowLootOnScreen())
            self.elements.amountLootOnScreenLabel:setText(tr('The amount of loot on the screen: %d', store:getAmountLootOnScreen()))
            self.elements.amountLootOnScreen:setValue(store:getAmountLootOnScreen())
            self.elements.delayTimeLootOnScreenLabel:setText(tr('Time delay to delete loot from screen: %d', store:getDelayTimeLootOnScreen()))
            self.elements.delayTimeLootOnScreen:setValue(store:getDelayTimeLootOnScreen())
            self.elements.ignoreMonsterLevelSystem:setChecked(store:getIgnoreMonsterLevelSystem())
            self.elements.ignoreLastSignWhenDot:setChecked(store:getIgnoreLastSignWhenDot())
        end;

        -- Connect

        connectElements = function(self)
            self.elements.clearData.onClick = function(widget) ui:clearData() end
        end;

        connectStoreWithElements = function(self)
            store.onChangeShowLootOnScreen.onChangeUI = function(value) self:onChangeStoreShowLootOnScreen(value) end
            store.onChangeAmountLootOnScreen.onChangeUI = function(value) self:onChangeStoreAmountLootOnScreen(value) end
            store.onChangeDelayTimeLootOnScreen.onChangeUI = function(value) self:onChangeStoreDelayTimeLootOnScreen(value) end
            store.onChangeIgnoreMonsterLevelSystem.onChangeUI = function(value) self:onChangeStoreIgnoreMonsterLevelSystem(value) end
            store.onChangeIgnoreLastSignWhenDot.onChangeUI = function(value) self:onChangeStoreIgnoreLastSignWhenDot(value) end
        end;

        connectElementsWithStore = function(self)
            self.elements.showLootOnScreen.onClick = function(widget) self:onChangeUIShowLootOnScreen(widget) end
            self.elements.amountLootOnScreen.onValueChange = function(widget, value) self:onChangeUIAmountLootOnScreen(widget, value) end
            self.elements.delayTimeLootOnScreen.onValueChange = function(widget, value) self:onChangeUIDelayTimeLootOnScreen(widget, value) end
            self.elements.ignoreMonsterLevelSystem.onClick = function(widget) self:onChangeUIIgnoreMonsterLevelSystem(widget) end
            self.elements.ignoreLastSignWhenDot.onClick = function(widget) self:onChangeUIIgnoreLastSignWhenDot(widget) end
        end;

        -- Disconnect

        disconnectElements = function(self)
            self.elements.clearData.onClick = nil
        end;

        disconnectStoreFromElements = function(self)
            store.onChangeShowLootOnScreen.onChangeUI = nil
            store.onChangeAmountLootOnScreen.onChangeUI = nil
            store.onChangeDelayTimeLootOnScreen.onChangeUI = nil
            store.onChangeIgnoreMonsterLevelSystem.onChangeUI = nil
            store.onChangeIgnoreLastSignWhenDot.onChangeUI = nil
        end;

        disconnectElementsWithStore = function(self)
            self.elements.showLootOnScreen.onClick = nil
            self.elements.amountLootOnScreen.onValueChange = nil
            self.elements.delayTimeLootOnScreen.onValueChange = nil
            self.elements.ignoreMonsterLevelSystem.onClick = nil
            self.elements.ignoreLastSignWhenDot.onClick = nil
        end;

        -- On UI change

        onChangeUIShowLootOnScreen = function(self, widget)
            local newValue = not widget:isChecked()
            widget:setChecked(newValue)
            store:setShowLootOnScreen(newValue)
        end;

        onChangeUIAmountLootOnScreen = function(self, widget, value)
            self.elements.amountLootOnScreenLabel:setText(tr('The amount of loot on the screen: %d', value))
            store:setAmountLootOnScreen(value)
        end;

        onChangeUIDelayTimeLootOnScreen = function(self, widget, value)
            self.elements.delayTimeLootOnScreenLabel:setText(tr('Time delay to delete loot from screen: %d', value))
            store:setDelayTimeLootOnScreen(value)
        end;

        onChangeUIIgnoreMonsterLevelSystem = function(self, widget)
            local newValue = not widget:isChecked()
            widget:setChecked(newValue)
            store:setIgnoreMonsterLevelSystem(newValue)
        end;

        onChangeUIIgnoreLastSignWhenDot = function(self, widget)
            local newValue = not widget:isChecked()
            widget:setChecked(newValue)
            store:setIgnoreLastSignWhenDot(newValue)
        end;

        -- On store change

        onChangeStoreShowLootOnScreen = function(self, value)
            self.elements.showLootOnScreen:setChecked(value)
        end;

        onChangeStoreAmountLootOnScreen = function(self, value)
            self.elements.amountLootOnScreen:setValue(value)
        end;

        onChangeStoreDelayTimeLootOnScreen = function(self, value)
            self.elements.delayTimeLootOnScreen:setValue(value)
        end;

        onChangeStoreIgnoreMonsterLevelSystem = function(self, value)
            self.elements.ignoreMonsterLevelSystem:setChecked(value)
        end;

        onChangeStoreIgnoreLastSignWhenDot = function(self, value)
            self.elements.ignoreLastSignWhenDot:setChecked(value)
        end;
    }

    return menuOption
end
