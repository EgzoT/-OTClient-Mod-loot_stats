-- Imports
dofile('ui/ui')
dofile('systems/createStats')
dofile('ui/showLootOnScreen')
dofile('systems/itemsXML')

-- Modules
ui = UI()
createStats = CreateStats()
showLootOnScreen = ShowLootOnScreen()

function init()
  ui:init()
  createStats:init()
end

function terminate()
  ui:terminate()
  createStats:terminate()

  -- Destroy created UI items on screen
  showLootOnScreen:destroy()
end

-------------------------------------------------
--Scripts----------------------------------------
-------------------------------------------------

lootCheckerTable = {}

function helpReturnLootCheckerTable()
  return lootCheckerTable
end

function getParserType()
  if createStats.ownParser then
    return "Own XML parser"
  else
    return "OTClient inbuild XML parser"
  end
end

-------------------------------------------------
--Return Data To Show----------------------------
-------------------------------------------------

function returnAllLoot()
  local tableWithAllLoot = {}

  for a,b in pairs(lootCheckerTable) do
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
end

function returnMonsterLoot(monsterName)
  local tableWithMonsterLoot = {}

  for a,b in pairs(lootCheckerTable[monsterName].loot) do
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
end

function returnAllMonsters()
  local tableWithMonsters = {}

  for a,b in pairs(lootCheckerTable) do
    tableWithMonsters[a] = {}
    tableWithMonsters[a].count = b.count
    if b.outfit then
      tableWithMonsters[a].outfit = b.outfit
    else
      tableWithMonsters[a].outfit = false
    end
  end

  return tableWithMonsters
end

function returnMonsterCount(monsterName)
  return lootCheckerTable[monsterName].count
end

function returnAllMonsterCount()
  local monsterCount = 0

  for a,b in pairs(lootCheckerTable) do
    monsterCount = monsterCount + b.count
  end

  return monsterCount
end

-- File system

function directoryExists(path)
  return g_resources.directoryExists(path)
end

function fileExists(path)
  return g_resources.fileExists(path)
end

function readFileContents(path)
  return g_resources.readFileContents(path)
end

function loadOtb(path)
  return g_things.loadOtb(path)
end

function loadXml(path)
  return g_things.loadXml(path)
end
