function Store()
    local store = {
        lootStatsTable = {};

        clear = function(self)
            lootStatsTable = {}
        end;

        -- Get data

        getLootStatsTable = function(self)
            return self.lootStatsTable
        end;

        returnAllLoot = function(self)
            local tableWithAllLoot = {}

            for a,b in pairs(self.lootStatsTable) do
                for c,d in pairs(b.loot) do
                    if not tableWithAllLoot[c] then
                        tableWithAllLoot[c] = {}
                        tableWithAllLoot[c].count = 0
                    end

                    if d.plural and not tableWithAllLoot[c].plural then
                        tableWithAllLoot[c].plural = true
                    end
                    tableWithAllLoot[c].count = tableWithAllLoot[c].count + d.count
                end
            end

            return tableWithAllLoot
        end;

        returnMonsterLoot = function(self, monsterName)
            local tableWithMonsterLoot = {}

            for a,b in pairs(self.lootStatsTable[monsterName].loot) do
                if not tableWithMonsterLoot[a] then
                    tableWithMonsterLoot[a] = {}
                    tableWithMonsterLoot[a].count = 0
                end

                if b.plural and not tableWithMonsterLoot[a].plural then
                    tableWithMonsterLoot[a].plural = true
                end
                tableWithMonsterLoot[a].count = tableWithMonsterLoot[a].count + b.count
            end

            return tableWithMonsterLoot
        end;

        returnAllMonsters = function(self)
            local tableWithMonsters = {}

            for a,b in pairs(self.lootStatsTable) do
                tableWithMonsters[a] = {}
                tableWithMonsters[a].count = b.count
                if b.outfit then
                    tableWithMonsters[a].outfit = b.outfit
                else
                    tableWithMonsters[a].outfit = false
                end
            end

            return tableWithMonsters
        end;

        returnMonsterCount = function(self, monsterName)
            return self.lootStatsTable[monsterName].count
        end;

        returnAllMonsterCount = function(self)
            local monsterCount = 0

            for a,b in pairs(self.lootStatsTable) do
                monsterCount = monsterCount + b.count
            end

            return monsterCount
        end;
    }

    return store
end
