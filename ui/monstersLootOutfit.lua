function MonstersLootOutfit()
    local monstersLootOutfit = {
        isInit = false;

        _onLootMonsters = nil;

        init = function(self)
            self._onLootMonsters = function(creature) self:onLootMonsters(creature) end

            if not self.isInit then
                connect(Creature, { onDeath = self._onLootMonsters })

                self.isInit = true
            end
        end;

        terminate = function(self)
            if self.isInit then
                disconnect(Creature, { onDeath = self._onLootMonsters })

                self.isInit = false
            end
        end;

        onLootMonsters = function(self, creature)
            scheduleEvent(function()
                local name = creature:getName()
                if store.lootStatsTable[string.lower(name)] then
                    if not store.lootStatsTable[string.lower(name)].outfit then
                        store.lootStatsTable[string.lower(name)].outfit = creature:getOutfit()
                    end
                -- Ignore bracket [] text, fix for monster level systems
                elseif string.find(name, '%[') and string.find(name, '%]') then
                    local nameWithoutBracket = string.sub(name, 0, string.find(name, '%[') - 1)
                    if string.sub(nameWithoutBracket, string.len(nameWithoutBracket)) == ' ' then
                        nameWithoutBracket = string.sub(name, 0, string.len(nameWithoutBracket) - 1)
                    end

                    if store.lootStatsTable[string.lower(nameWithoutBracket)] then
                        if not store.lootStatsTable[string.lower(nameWithoutBracket)].outfit then
                            store.lootStatsTable[string.lower(nameWithoutBracket)].outfit = creature:getOutfit()
                        end
                    end
                end
            end, 1000)
        end;
    }

    return monstersLootOutfit
end
