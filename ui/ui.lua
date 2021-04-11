function UI()
    local ui = {
        moduleButton = nil;
        mainWindow = nil;

        elements = {};

        init = function(self)
            g_ui.loadUI("loot_icons")

            self.moduleButton = modules.client_topmenu.addRightGameToggleButton('lootStatsButton', tr('Loot Stats'), 'img/icon', function() self:toggle() end)
            self.moduleButton:setOn(false)

            self.mainWindow = g_ui.displayUI('loot_stats')
            self.mainWindow:setVisible(false)

            self:loadElementsUI()
            self:setDefaultValuesToElementsUI()
            self:setOnChangeElements()
        end;

        terminate = function(self)
            self.mainWindow:destroy()
            self.moduleButton:destroy()

            self:clear()
        end;

        clear = function(self)
            self.moduleButton = nil
            self.mainWindow = nil

            self.elements = {}
        end;

        toggle = function(self)
            if self.moduleButton:isOn() then
                self.mainWindow:setVisible(false)
                self.moduleButton:setOn(false)
            else
                self.mainWindow:setVisible(true)
                self.moduleButton:setOn(true)

                refreshDataInUI()
            end
        end;

        onMiniWindowClose = function(self)
            self.moduleButton:setOn(false)
        end;

        loadElementsUI = function(self)
            self.elements.itemsPanel = self.mainWindow:recursiveGetChildById('itemsPanel')
            self.elements.monstersTab = self.mainWindow:recursiveGetChildById('monstersTab')
            self.elements.allLootTab = self.mainWindow:recursiveGetChildById('allLootTab')
            self.elements.panelCreatureView = self.mainWindow:recursiveGetChildById('panelCreatureView')
            self.elements.showLootOnScreen = self.mainWindow:recursiveGetChildById('showLootOnScreen')
        end;

        setDefaultValuesToElementsUI = function(self)
            self.elements.showLootOnScreen:setChecked(g_settings.getBoolean('loot_stats_addIconsToScreen'))
        end;

        setOnChangeElements = function(self)
            self.elements.monstersTab.onMouseRelease = whenClickMonstersTab
            self.elements.allLootTab.onMouseRelease = whenClickAllLootTab
        end;
    }

    return ui
end
