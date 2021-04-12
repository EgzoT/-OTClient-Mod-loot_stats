-- Imports
dofile('ui/ui')
dofile('ui/showLootOnScreen')
dofile('systems/itemsXML')

-- Modules
ui = UI()
showLootOnScreen = ShowLootOnScreen()

function init()
  ui:init()

  --init all systems
  initLootChecker()
end

function terminate()
  ui:terminate()

  --terminate all systems
  terminateLootChecker()

  -- Destroy created UI items on screen
  showLootOnScreen:destroy()
end

-------------------------------------------------
--Scripts----------------------------------------
-------------------------------------------------

local loadedVersionItems = 0
actualVisibleTab = { tab = 0, info = 0 }
local ownParser = false

function initLootChecker()
  connect(g_game, {onTextMessage = checkLootTextMessage})
  initEditMonstersLootOutfit()

  connect(g_game, { onClientVersionChange = loadClientVersionItems })

  if (loadedVersionItems == 0 and g_game.getClientVersion() ~= 0) or (g_game.getClientVersion() ~= 0 and loadedVersionItems ~= g_game.getClientVersion()) then
  	loadClientVersionItems()
  end

  --Open monster tab as default
  actualVisibleTab.tab = 'monster'
  ui.elements.monstersTab:setOn(true)
end

function loadClientVersionItems()
	local version = g_game.getClientVersion()

	if version ~= loadedVersionItems then
		if not g_resources.directoryExists('items_versions/'..version) then
			pwarning("Directory: items_versions/"..version.."/ doesn't exist!")
			pwarning("Add "..version.." directory to items_versions/ with correct version items.otb and items.xml!")
			loadedVersionItems = 0
			g_modules.getModule('loot_stats'):unload()
			modules.client_modulemanager.refreshLoadedModules()
			return
		end
		if not g_resources.fileExists('items_versions/'..version..'/items.otb') then
			pwarning("File: items_versions/"..version.."/ doesn't exist!")
			pwarning("Add correct version items.otb to items_versions/"..version.."/!")
			loadedVersionItems = 0
			g_modules.getModule('loot_stats'):unload()
			modules.client_modulemanager.refreshLoadedModules()
			return
		end
		if not g_resources.fileExists('items_versions/'..version..'/items.xml') then
			pwarning("File: items_versions/"..version.." doesn't exist!")
			pwarning("Add correct version items.xml to items_versions/"..version.."/!")
			loadedVersionItems = 0
			g_modules.getModule('loot_stats'):unload()
			modules.client_modulemanager.refreshLoadedModules()
			return
		end


		g_things.loadOtb('items_versions/'..version..'/items.otb')
		g_things.loadXml('items_versions/'..version..'/items.xml')
    checkParserType()

		loadedVersionItems = version
	end
end

function terminateLootChecker()
  disconnect(g_game, {onTextMessage = checkLootTextMessage})
  terminateEditMonstersLootOutfit()

  disconnect(g_game, { onClientVersionChange = loadClientVersionItems })
end

lootCheckerTable = {}

function helpReturnLootCheckerTable()
  return lootCheckerTable
end

function checkLootTextMessage(messageMode, message)
	if loadedVersionItems == 0 then
		return
	end

  local fromLootValue, toLootValue = string.find(message, 'Loot of ')
  if toLootValue then
    --Return Monster
    local lootMonsterName = string.sub(message, toLootValue + 1, string.find(message, ':') - 1)
    local isAFromLootValue, isAToLootValue = string.find(lootMonsterName, 'a ')
    if isAToLootValue then
      lootMonsterName = string.sub(lootMonsterName, isAToLootValue + 1, string.len(lootMonsterName))
    end
    local isANFromLootValue, isANToLootValue = string.find(lootMonsterName, 'an ')
    if isANToLootValue then
      lootMonsterName = string.sub(lootMonsterName, isANToLootValue + 1, string.len(lootMonsterName))
    end
    --If no monster then add Monster to table
    if not lootCheckerTable[lootMonsterName] then
      lootCheckerTable[lootMonsterName] = {loot = {}, count = 0}
    end
    --Update monster kill count information
    lootCheckerTable[lootMonsterName].count = lootCheckerTable[lootMonsterName].count + 1

    --Return Loot
    local lootString = string.sub(message, string.find(message, ': ') + 2, string.len(message))
    --If dot at the ned of sentence (OTS only), delete it.
    if string.sub(lootString, string.len(lootString)) == '.' then
      lootString = string.sub(lootString, 0, string.len(lootString) - 1)
    end

    local lootToScreen = {}
    for word in string.gmatch(lootString, '([^,]+)') do
      --delete first space
      if string.sub(word, 0, 1) == ' ' then
        word = string.sub(word, 2, string.len(word))
      end

      --delete 'a ' / 'an '
      local isAToLootValue, isAFromLootValue = string.find(word, 'a ')
      if isAFromLootValue then
        word = string.sub(word, isAFromLootValue + 1, string.len(word))
      end
      local isANToLootValue, isANFromLootValue = string.find(word, 'an ')
      if isANFromLootValue then
        word = string.sub(word, isANFromLootValue + 1, string.len(word))
      end

      --Check is first sign is number
      if type(tonumber(string.sub(word, 0, 1))) == 'number' then
        local itemCount = tonumber(string.match(word, "%d+"))
        local delFN, delLN = string.find(word, itemCount)
        local itemWord = string.sub(word, delLN + 2)

        function returnPluralNameFromLoot()
          for a,b in pairs(lootCheckerTable[lootMonsterName].loot) do
            if b.plural == itemWord then
              return a
            end
          end

          return false
        end

        local isPluralNameInLoot = returnPluralNameFromLoot()
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
          local pluralNameToSingular = convertPluralToSingular(itemWord)
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
end

function checkParserType()
  if g_things.findItemTypeByPluralName then
    ownParser = false
  else
    ownParser = ItemsXML()
    ownParser:parseItemsXML(g_resources.readFileContents('items_versions/' .. g_game.getClientVersion() .. '/items.xml'))
  end
end

function convertPluralToSingular(searchWord)
  if not ownParser then
    local item = g_things.findItemTypeByPluralName(searchWord)
    if not item:isNull() then
      return item:getName()
    else
      return false
    end
  else
    return ownParser:convertPluralToSingular(searchWord)
  end
end

function getParserType()
  if ownParser then
    return "Own XML parser"
  else
    return "OTClient inbuild XML parser"
  end
end

-------------------------------------------------
--Add monster outfit-----------------------------
-------------------------------------------------

function initEditMonstersLootOutfit()
  connect(Creature, {onDeath = editMonstersLootOutfit})
end

function terminateEditMonstersLootOutfit()
  disconnect(Creature, {onDeath = editMonstersLootOutfit})
end

function editMonstersLootOutfit(creature)
  scheduleEvent(function()
    local name = creature:getName()
    if lootCheckerTable[string.lower(name)] then
      if not lootCheckerTable[string.lower(name)].outfit then
        lootCheckerTable[string.lower(name)].outfit = creature:getOutfit()
      end
    --Ignore bracket [] text, fix for monster level systems
    elseif string.find(name, '%[') and string.find(name, '%]') then
      local nameWithoutBracket = string.sub(name, 0, string.find(name, '%[') - 1)
      if string.sub(nameWithoutBracket, string.len(nameWithoutBracket)) == ' ' then
        nameWithoutBracket = string.sub(name, 0, string.len(nameWithoutBracket) - 1)
      end
      if lootCheckerTable[string.lower(nameWithoutBracket)] then
        if not lootCheckerTable[string.lower(nameWithoutBracket)].outfit then
          lootCheckerTable[string.lower(nameWithoutBracket)].outfit = creature:getOutfit()
        end
      end
    end
  end, 1000)
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
