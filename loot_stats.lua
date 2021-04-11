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
local actualVisibleTab = {tab = 0, info = 0}
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

local lootCheckerTable = {}

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
		refreshDataInUI()
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
--Format data------------------------------------
-------------------------------------------------

function formatUINumber(value, numbers, cutDigits)
  numbers = numbers or 0
  cutDigits = cutDigits or false

  if value - math.floor(value) == 0 then
    return value
  end

  local decimalPart = 0
  local intPart = 0

  if value > 1 then
    decimalPart = value - math.floor(value)
    intPart = math.floor(value)
  else
    decimalPart = value
  end

  local firstNonZeroPos = math.floor(math.log10(decimalPart)) + 1

  local numberOfPoints = 1
  if cutDigits then
    numberOfPoints = math.pow(10, numbers - math.floor(math.log10(value)) - 1)
  else
    numberOfPoints = math.pow(10, firstNonZeroPos * -1 + numbers)
  end

  local valuePow = decimalPart * numberOfPoints
  if valuePow - math.floor(valuePow) >= 0.5 then
    valuePow = math.ceil(valuePow)
  else
    valuePow = math.floor(valuePow)
  end

  return intPart + valuePow / numberOfPoints
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

-------------------------------------------------
--Monster view show/hide-------------------------
-------------------------------------------------

function showMonsterView(creature, text)
  ui.elements.panelCreatureView:setHeight(40)
  ui.elements.panelCreatureView:setVisible(true)

  local ceatureView = ui.elements.panelCreatureView:getChildById('creatureView')
  ceatureView:setCreature(creature)

  local creatureText = ui.elements.panelCreatureView:getChildById('textCreatureView')
  creatureText:setText(text)
end

function hideMonsterView()
  ui.elements.panelCreatureView:setHeight(0)
  ui.elements.panelCreatureView:setVisible(false)
end

-------------------------------------------------
--On click UI------------------------------------
-------------------------------------------------

function changeWhenClickWidget(self, mousePosition, mouseButton)
  if mouseButton == MouseLeftButton then
    ui.elements.monstersTab:setOn(false)

    showMonsterView(self:getChildById('creature'):getCreature(), self:getText())

    local monsterName = ''
    for word in string.gmatch(self:getText(), '([^'..'\n'..']+)') do
      monsterName = word
      break
    end

    if monsterName then
      refreshLootItems(monsterName)
    end
  end
end

function whenClickMonstersTab(self, mousePosition, mouseButton)
  if mouseButton == MouseLeftButton then
    ui.elements.allLootTab:setOn(false)
    ui.elements.monstersTab:setOn(true)
    refreshLootMonsters()
    hideMonsterView()
  end
end

function whenClickAllLootTab(self, mousePosition, mouseButton)
  if mouseButton == MouseLeftButton then
    ui.elements.monstersTab:setOn(false)
    ui.elements.allLootTab:setOn(true)
    refreshLootItems('*all')
    hideMonsterView()
  end
end

-------------------------------------------------
--Add to UI--------------------------------------
-------------------------------------------------

local tableWithLootItemsUI = {}

function destroyLootAndMonsterItemsUI()
  for a,b in pairs(tableWithLootItemsUI) do
  	b:destroy()
  	tableWithLootItemsUI[a] = nil
  end
end

function refreshLootItems(monsterName)
  local itemTable = {}
  if monsterName == '*all' then
    itemTable = returnAllLoot()
  else
    itemTable = returnMonsterLoot(monsterName)
  end

  actualVisibleTab.tab = 'loot'
  actualVisibleTab.info = monsterName

  local layout = ui.elements.itemsPanel:getLayout()
  layout:disableUpdates()

  destroyLootAndMonsterItemsUI()
  ui.elements.itemsPanel:destroyChildren()

  for a,b in pairs(itemTable) do
    tableWithLootItemsUI[a] = g_ui.createWidget('LootItemBox', ui.elements.itemsPanel)

    local text = a..'\n'..'Count: '..b.count

    if not b.plural then
      local chanceToLoot = 0
      if monsterName ~= '*all' then
        chanceToLoot = b.count * 100 / returnMonsterCount(monsterName)
      else
        chanceToLoot = b.count * 100 / returnAllMonsterCount()
      end
      text = text..'\n'..'Chance: '..formatUINumber(chanceToLoot, 3, true)..' %'
    else
      local chanceToLoot = 0
      if monsterName ~= '*all' then
        if b.count > returnMonsterCount(monsterName) then
          chanceToLoot = b.count / returnMonsterCount(monsterName)
          text = text..'\n'..'Average: '..formatUINumber(chanceToLoot, 3, true)..' / 1'
        else
          chanceToLoot = b.count * 100 / returnMonsterCount(monsterName)
          text = text..'\n'..'Chance: '..formatUINumber(chanceToLoot, 3, true)..' %'
        end
      else
        if b.count > returnAllMonsterCount() then
          chanceToLoot = b.count / returnAllMonsterCount()
          text = text..'\n'..'Average: '..formatUINumber(chanceToLoot, 3, true)..' / 1'
        else
          chanceToLoot = b.count * 100 / returnAllMonsterCount()
          text = text..'\n'..'Chance: '..formatUINumber(chanceToLoot, 3, true)..' %'
        end
      end
    end

    tableWithLootItemsUI[a]:setText(text)

    local item = nil
    local findItemByName = g_things.findItemTypeByName(a)
    if findItemByName:getClientId() ~= 0 then
      item = Item.create(findItemByName:getClientId())
    else
      item = Item.create(3547)
    end

    if b.plural then
      if b.count > 100 then
        item:setCount(100)
      else
        item:setCount(b.count)
      end
    end

    local itemWidget = tableWithLootItemsUI[a]:getChildById('item')
    itemWidget:setItem(item)
  end

  layout:enableUpdates()
  layout:update()
end

function refreshLootMonsters()
  local layout = ui.elements.itemsPanel:getLayout()
  layout:disableUpdates()

  destroyLootAndMonsterItemsUI()
  ui.elements.itemsPanel:destroyChildren()

  actualVisibleTab.tab = 'monster'
  actualVisibleTab.info = 0

  for a,b in pairs(returnAllMonsters()) do
    tableWithLootItemsUI[a] = g_ui.createWidget('LootMonsterBox', ui.elements.itemsPanel)

    local text = a..'\n'..'Count: '..b.count

    local chanceMonster = b.count * 100 / returnAllMonsterCount()
    text = text..'\n'..'Chance: '..formatUINumber(chanceMonster, 3, true)..' %'

    tableWithLootItemsUI[a]:setText(text)

    local uiCreature = Creature.create()
    uiCreature:setDirection(2)

    if b.outfit then
      uiCreature:setOutfit(b.outfit)
    else
      local noOutfit = {type = 160, feet = 114, addons = 0, legs = 114, auxType = 7399, head = 114, body = 114}
      uiCreature:setOutfit(noOutfit)
    end

    local itemWidget = tableWithLootItemsUI[a]:getChildById('creature')
    itemWidget:setCreature(uiCreature)

    --On click action
    tableWithLootItemsUI[a].onMouseRelease = changeWhenClickWidget
  end

  layout:enableUpdates()
  layout:update()
end

function clearAllUIAndTable()
  local yesCallback = function()
    local layout = ui.elements.itemsPanel:getLayout()
    layout:disableUpdates()

    destroyLootAndMonsterItemsUI()
    ui.elements.itemsPanel:destroyChildren()

    ui.elements.allLootTab:setOn(false)
    ui.elements.monstersTab:setOn(false)
    hideMonsterView()
    lootCheckerTable = {}

    layout:enableUpdates()
    layout:update()

    saveOverWindow:destroy()
    saveOverWindow=nil
  end

  local noCallback = function()
    saveOverWindow:destroy()
    saveOverWindow=nil
  end

  if not saveOverWindow then
    saveOverWindow = displayGeneralBox(tr('Clear all values'), tr('Do you want clear all values?\nYou will lost all loot data!'), {
      { text=tr('Yes'), callback = yesCallback},
      { text=tr('No'), callback = noCallback},
    anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
  end
end

function refreshDataInUI()
	if actualVisibleTab.tab == 'loot' then
  	refreshLootItems(actualVisibleTab.info)
  	if actualVisibleTab.info ~= '*all' then
  		local creatureText = ui.elements.panelCreatureView:getChildById('textCreatureView')

  		local monster = returnAllMonsters()[actualVisibleTab.info]
  		local text = actualVisibleTab.info..'\n'..'Count: '..monster.count

    	local chanceMonster = monster.count * 100 / returnAllMonsterCount()
    	text = text..'\n'..'Chance: '..formatUINumber(chanceMonster, 3, true)..' %'
    	creatureText:setText(text)
  	end
  elseif actualVisibleTab.tab == 'monster' then
  	refreshLootMonsters()
  end
end

-------------------------------------------------
--Show loot on screen----------------------------
-------------------------------------------------

function saveCheckboxIconsOnScreen()
  if ui.elements.showLootOnScreen:isChecked() then
    g_settings.set('loot_stats_addIconsToScreen', false)
  else
    g_settings.set('loot_stats_addIconsToScreen', true)
  end
end
