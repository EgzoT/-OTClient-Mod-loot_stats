function CreateStats()
    local createStats = {
        loadedVersionItems = 0;
        ownParser = false;

        _loadClientVersionItems = nil;
        _checkLootTextMessage = nil;

        init = function(self)
            self._loadClientVersionItems = function() self:loadClientVersionItems() end
            self._checkLootTextMessage = function(messageMode, message) self:checkLootTextMessage(messageMode, message) end

            connect(g_game, { onClientVersionChange = self._loadClientVersionItems })
            connect(g_game, { onTextMessage = self._checkLootTextMessage })

            if (self.loadedVersionItems == 0 and g_game.getClientVersion() ~= 0) or (g_game.getClientVersion() ~= 0 and self.loadedVersionItems ~= g_game.getClientVersion()) then
                self:loadClientVersionItems()
            end
        end;

        terminate = function(self)
            disconnect(g_game, { onClientVersionChange = self._loadClientVersionItems })
            disconnect(g_game, { onTextMessage = self._checkLootTextMessage })
        end;

        -- Load items

        loadClientVersionItems = function(self)
            local version = g_game.getClientVersion()

            if version ~= self.loadedVersionItems then
                if not directoryExists('items_versions/' .. version) then
                    pwarning("Directory: items_versions/" .. version .. "/ doesn't exist!")
                    pwarning("Add " .. version .. " directory to items_versions/ with correct version items.otb and items.xml!")
                    self.loadedVersionItems = 0
                    g_modules.getModule('loot_stats'):unload()
                    modules.client_modulemanager.refreshLoadedModules()
                    return
                end

                if not fileExists('items_versions/' .. version .. '/items.otb') then
                    pwarning("File: items_versions/" .. version .. "/ doesn't exist!")
                    pwarning("Add correct version items.otb to items_versions/" .. version .. "/!")
                    self.loadedVersionItems = 0
                    g_modules.getModule('loot_stats'):unload()
                    modules.client_modulemanager.refreshLoadedModules()
                    return
                end

                if not fileExists('items_versions/' .. version .. '/items.xml') then
                    pwarning("File: items_versions/" .. version .. " doesn't exist!")
                    pwarning("Add correct version items.xml to items_versions/" .. version .. "/!")
                    self.loadedVersionItems = 0
                    g_modules.getModule('loot_stats'):unload()
                    modules.client_modulemanager.refreshLoadedModules()
                    return
                end

                loadOtb('items_versions/' .. version .. '/items.otb')
                loadXml('items_versions/' .. version .. '/items.xml')
                self:checkParserType()

                self.loadedVersionItems = version
            end
        end;

        checkParserType = function(self)
            if g_things.findItemTypeByPluralName then
                self.ownParser = false
            else
                self.ownParser = ItemsXML()
                self.ownParser:parseItemsXML('items_versions/' .. g_game.getClientVersion() .. '/items.xml')
            end
        end;

        -- Convert plural to singular

        convertPluralToSingular = function(self, searchWord)
            if not self.ownParser then
                local item = g_things.findItemTypeByPluralName(searchWord)
                if not item:isNull() then
                    return item:getName()
                else
                    return false
                end
            else
                return self.ownParser:convertPluralToSingular(searchWord)
            end
        end;

        -- Parse message logs

        returnPluralNameFromLoot = function(lootMonsterName, itemWord)
            for a,b in pairs(lootCheckerTable[lootMonsterName].loot) do
                if b.plural == itemWord then
                    return a
                end
            end

            return false
        end;

        checkLootTextMessage = function(self, messageMode, message)
            if self.loadedVersionItems == 0 then
                return
            end

            local fromLootValue, toLootValue = string.find(message, 'Loot of ')
            if toLootValue then
                -- Return monster
                local lootMonsterName = string.sub(message, toLootValue + 1, string.find(message, ':') - 1)
                local isAFromLootValue, isAToLootValue = string.find(lootMonsterName, 'a ')
                if isAToLootValue then
                    lootMonsterName = string.sub(lootMonsterName, isAToLootValue + 1, string.len(lootMonsterName))
                end

                local isANFromLootValue, isANToLootValue = string.find(lootMonsterName, 'an ')
                if isANToLootValue then
                    lootMonsterName = string.sub(lootMonsterName, isANToLootValue + 1, string.len(lootMonsterName))
                end

                -- If no monster then add monster to table
                if not lootCheckerTable[lootMonsterName] then
                    lootCheckerTable[lootMonsterName] = { loot = {}, count = 0 }
                end

                -- Update monster kill count information
                lootCheckerTable[lootMonsterName].count = lootCheckerTable[lootMonsterName].count + 1

                -- Return Loot
                local lootString = string.sub(message, string.find(message, ': ') + 2, string.len(message))
                -- If dot at the ned of sentence (OTS only), delete it
                if string.sub(lootString, string.len(lootString)) == '.' then
                    lootString = string.sub(lootString, 0, string.len(lootString) - 1)
                end

                local lootToScreen = {}
                for word in string.gmatch(lootString, '([^,]+)') do
                    -- Delete first space
                    if string.sub(word, 0, 1) == ' ' then
                        word = string.sub(word, 2, string.len(word))
                    end

                    -- Delete 'a ' / 'an '
                    local isAToLootValue, isAFromLootValue = string.find(word, 'a ')
                    if isAFromLootValue then
                        word = string.sub(word, isAFromLootValue + 1, string.len(word))
                    end

                    local isANToLootValue, isANFromLootValue = string.find(word, 'an ')
                    if isANFromLootValue then
                        word = string.sub(word, isANFromLootValue + 1, string.len(word))
                    end

                    -- Check is first sign is number
                    if type(tonumber(string.sub(word, 0, 1))) == 'number' then
                        local itemCount = tonumber(string.match(word, "%d+"))
                        local delFN, delLN = string.find(word, itemCount)
                        local itemWord = string.sub(word, delLN + 2)
                        local isPluralNameInLoot = self.returnPluralNameFromLoot(lootMonsterName, itemWord)

                        if isPluralNameInLoot then
                            if not lootCheckerTable[lootMonsterName].loot[isPluralNameInLoot] then
                                lootCheckerTable[lootMonsterName].loot[isPluralNameInLoot] = {}
                                lootCheckerTable[lootMonsterName].loot[isPluralNameInLoot].count = 0
                            end

                            if not lootToScreen[isPluralNameInLoot] then
                                lootToScreen[isPluralNameInLoot] = {}
                                lootToScreen[isPluralNameInLoot].count = 0
                            end

                            lootCheckerTable[lootMonsterName].loot[isPluralNameInLoot].count = lootCheckerTable[lootMonsterName].loot[isPluralNameInLoot].count + itemCount
                            lootToScreen[isPluralNameInLoot].count = lootToScreen[isPluralNameInLoot].count + itemCount
                        else
                            local pluralNameToSingular = self:convertPluralToSingular(itemWord)
                            if pluralNameToSingular then
                                if not lootCheckerTable[lootMonsterName].loot[pluralNameToSingular] then
                                    lootCheckerTable[lootMonsterName].loot[pluralNameToSingular] = {}
                                    lootCheckerTable[lootMonsterName].loot[pluralNameToSingular].count = 0
                                end

                                if not lootCheckerTable[lootMonsterName].loot[pluralNameToSingular].plural then
                                    lootCheckerTable[lootMonsterName].loot[pluralNameToSingular].plural = itemWord
                                end

                                if not lootToScreen[pluralNameToSingular] then
                                    lootToScreen[pluralNameToSingular] = {}
                                    lootToScreen[pluralNameToSingular].count = 0
                                end

                                lootCheckerTable[lootMonsterName].loot[pluralNameToSingular].count = lootCheckerTable[lootMonsterName].loot[pluralNameToSingular].count + itemCount
                                lootToScreen[pluralNameToSingular].count = lootToScreen[pluralNameToSingular].count + itemCount
                            else
                                if not lootCheckerTable[lootMonsterName].loot[word] then
                                    lootCheckerTable[lootMonsterName].loot[word] = {}
                                    lootCheckerTable[lootMonsterName].loot[word].count = 0
                                end

                                if not lootToScreen[word] then
                                    lootToScreen[word] = {}
                                    lootToScreen[word].count = 0
                                end

                                lootCheckerTable[lootMonsterName].loot[word].count = lootCheckerTable[lootMonsterName].loot[word].count + 1
                                lootToScreen[word].count = lootToScreen[word].count + 1
                            end
                        end
                    else
                        if not lootCheckerTable[lootMonsterName].loot[word] then
                            lootCheckerTable[lootMonsterName].loot[word] = {}
                            lootCheckerTable[lootMonsterName].loot[word].count = 0
                        end

                        if not lootToScreen[word] then
                            lootToScreen[word] = {}
                            lootToScreen[word].count = 0
                        end

                        lootCheckerTable[lootMonsterName].loot[word].count = lootCheckerTable[lootMonsterName].loot[word].count + 1
                        lootToScreen[word].count = lootToScreen[word].count + 1
                    end
                end

                if ui.elements.showLootOnScreen:isChecked() then
                    showLootOnScreen:add(lootToScreen)
                end
                lootToScreen = {}
            end

            if ui.mainWindow:isVisible() then
                ui:refreshListElements()
            end
        end;
    }

    return createStats
end
