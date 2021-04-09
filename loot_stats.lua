lootStatsButton = nil
lootStatsWindow = nil
touchAttackList = nil

itemsPanel = nil

monstersTab = nil
allLootTab = nil

panelCreatureView = nil

local mapPanel = modules.game_interface.getMapPanel()
local topMenu = modules.client_topmenu.getTopMenu()
g_ui.loadUI("loot_icons")

function init()
  lootStatsButton = modules.client_topmenu.addRightGameToggleButton('lootStatsButton', tr('Loot Stats'), 'img_loot_stats/loot_stats_img', toggle)
  lootStatsButton:setOn(false)

  lootStatsWindow = g_ui.displayUI('loot_stats')
  lootStatsWindow:setVisible(false)

  itemsPanel = lootStatsWindow:recursiveGetChildById('itemsPanel')

  monstersTab = lootStatsWindow:recursiveGetChildById('monstersTab')
  allLootTab = lootStatsWindow:recursiveGetChildById('allLootTab')

  monstersTab.onMouseRelease = whenClickMonstersTab
  allLootTab.onMouseRelease = whenClickAllLootTab

  panelCreatureView = lootStatsWindow:recursiveGetChildById('panelCreatureView')

  lootStatsWindow:recursiveGetChildById('showLootOnScreen'):setChecked(g_settings.getBoolean('loot_stats_addIconsToScreen'))

  --init all systems
  initLootChecker()
end

function terminate()
  lootStatsButton:destroy()
  lootStatsButton = nil
  lootStatsWindow:destroy()
  lootStatsWindow = nil

  itemsPanel = nil
	monstersTab = nil
	allLootTab = nil
	panelCreatureView = nil

  --terminate all systems
  terminateLootChecker()
end

function toggle()
  if lootStatsButton:isOn() then
    lootStatsWindow:setVisible(false)
    lootStatsButton:setOn(false)
  else
    lootStatsWindow:setVisible(true)
    lootStatsButton:setOn(true)

    refreshDataInUI()
  end
end

function onMiniWindowClose()
  lootStatsButton:setOn(false)
end

function clear()
  local touchAttackList = lootStatsWindow:getChildById('contentsPanel')
  touchAttackList:destroyChildren()
end

-------------------------------------------------
--Scripts----------------------------------------
-------------------------------------------------

local parsedItemsXML = nil

local loadedVersionItems = 0
local actualVisibleTab = {tab = 0, info = 0}

function initLootChecker()
  connect(g_game, {onTextMessage = checkLootTextMessage})
  initEditMonstersLootOutfit()

  connect(g_game, { onClientVersionChange = loadClientVersionItems })

  if (loadedVersionItems == 0 and g_game.getClientVersion() ~= 0) or (g_game.getClientVersion() ~= 0 and loadedVersionItems ~= g_game.getClientVersion()) then
  	loadClientVersionItems()
  end

  --Open monster tab as default
  actualVisibleTab.tab = 'monster'
  monstersTab:setOn(true)
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
    parsedItemsXML = openItemsXML('items_versions/'..version..'/items.xml')

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

    if lootStatsWindow:recursiveGetChildById('showLootOnScreen'):isChecked() then
      addToMainScreenTab(lootToScreen)
    end
    lootToScreen = {}
  end

  if lootStatsWindow:isVisible() then
		refreshDataInUI()
	end
end

function openItemsXML(path)
  local tableWithItems = {}

  local xml = g_resources.readFileContents(path)
  local itemsXMLString = {}

  for line in xml:lines() do
    itemsXMLString[#itemsXMLString + 1] = line
  end

  xml:close()

  local lastTableIdBackup = 0

  for a,b in ipairs(itemsXMLString) do
    words = {}
    for word in b:gmatch("%S+") do
      table.insert(words, word)
    end

    if words[1] == '<item' then
      if string.sub(words[2], 0, 2) == 'id' then
        local idFromString = tonumber(string.sub(words[2], string.find(words[2], '"') + 1, string.find(words[2], '"', string.find(words[2], '"') + 1) - 1))
        tableWithItems[idFromString] = {}

        for i=3,table.size(words) do
          if string.find(words[i], '=') then
            local tabName = string.sub(words[i], 0, string.find(words[i], '=') - 1)
            local checkWord = words[i]
            while not (string.find(checkWord, '"') and string.find(checkWord, '"', string.find(checkWord, '"') + 1)) do
              checkWord = checkWord..' '..words[i+1]
              i = i + 1
            end

            local tabValue = string.sub(checkWord, string.find(checkWord, '"') + 1, string.find(checkWord, '"', string.find(checkWord, '"') + 1) - 1)
            tableWithItems[idFromString][tabName] = tabValue
          end
        end

        lastTableIdBackup = idFromString
      elseif words[1] == '<attribute' then
        local attKey = string.sub(words[2], string.find(words[2], '"') + 1, string.find(words[2], '"', string.find(words[2], '"') + 1) - 1)

        local restWords = ''
        for i=3,table.size(words) do
          if restWords == '' then
            restWords = words[i]
          else
            restWords = restWords..' '..words[i]
          end
        end
        local attValue = string.sub(restWords, string.find(restWords, '"') + 1, string.find(restWords, '"', string.find(restWords, '"') + 1) - 1)
        tableWithItems[lastTableIdBackup][attKey] = attValue
      end
    end
  end

  return tableWithItems
end

function convertPluralToSingular(searchWord)
  for a,b in pairs(parsedItemsXML) do
    if b.plural == searchWord then
      return b.name
    end
  end

  return false
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
  panelCreatureView:setHeight(40)
  panelCreatureView:setVisible(true)

  local ceatureView = panelCreatureView:getChildById('creatureView')
  ceatureView:setCreature(creature)

  local creatureText = panelCreatureView:getChildById('textCreatureView')
  creatureText:setText(text)
end

function hideMonsterView()
  panelCreatureView:setHeight(0)
  panelCreatureView:setVisible(false)
end

-------------------------------------------------
--On click UI------------------------------------
-------------------------------------------------

function changeWhenClickWidget(self, mousePosition, mouseButton)
  if mouseButton == MouseLeftButton then
    monstersTab:setOn(false)

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
    allLootTab:setOn(false)
    monstersTab:setOn(true)
    refreshLootMonsters()
    hideMonsterView()
  end
end

function whenClickAllLootTab(self, mousePosition, mouseButton)
  if mouseButton == MouseLeftButton then
    monstersTab:setOn(false)
    allLootTab:setOn(true)
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

  local layout = itemsPanel:getLayout()
  layout:disableUpdates()

  destroyLootAndMonsterItemsUI()
  itemsPanel:destroyChildren()

  for a,b in pairs(itemTable) do
    tableWithLootItemsUI[a] = g_ui.createWidget('LootItemBox', itemsPanel)

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
  local layout = itemsPanel:getLayout()
  layout:disableUpdates()

  destroyLootAndMonsterItemsUI()
  itemsPanel:destroyChildren()

  actualVisibleTab.tab = 'monster'
  actualVisibleTab.info = 0

  for a,b in pairs(returnAllMonsters()) do
    tableWithLootItemsUI[a] = g_ui.createWidget('LootMonsterBox', itemsPanel)

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
    local layout = itemsPanel:getLayout()
    layout:disableUpdates()

    destroyLootAndMonsterItemsUI()
    itemsPanel:destroyChildren()

    allLootTab:setOn(false)
    monstersTab:setOn(false)
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
  		local creatureText = panelCreatureView:getChildById('textCreatureView')

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

local mainScreenTab = {}

local tableDepth = 5 --later replace to top

local cacheLastTime = {t = 0, i = 1}

local lootIconOnScreen = {}

function addToMainScreenTab(tab)
	for i = 1, tableDepth do
		mainScreenTab[i] = {}
		if i + 1 <= tableDepth then
			mainScreenTab[i] = mainScreenTab[i+1]
		else
			if tab ~= nil then
				mainScreenTab[i].loot = tab
				if g_clock.millis() == cacheLastTime.t then
					mainScreenTab[i].id = g_clock.millis() * 100 + cacheLastTime.i
					cacheLastTime.i = cacheLastTime.i + 1

					--delete value after x time
					scheduleDisappearIcon(mainScreenTab[i].id)
				else
					mainScreenTab[i].id = g_clock.millis()
					cacheLastTime.t = g_clock.millis()
					cacheLastTime.i = 1

					--delete value after x time
					scheduleDisappearIcon(mainScreenTab[i].id)
				end
			else
				mainScreenTab[i] = nil
			end
		end
	end

	if tab == nil and table.size(mainScreenTab) then
		mainScreenTab[#mainScreenTab] = nil
	end

	refreshMainScreenTab()
end

function scheduleDisappearIcon(id)
	scheduleEvent(function()
		for a,b in pairs(mainScreenTab) do
    	if mainScreenTab[a].id == id then
    		mainScreenTab[a] = nil
    		addToMainScreenTab(nil)
    		refreshMainScreenTab()
        break
    	end
    end
  end, 2000)
end

function refreshMainScreenTab()
	destroyLootIconOnScreen()

	local actualX = 0
	local actualY = 0

	if topMenu:isVisible() then
		actualY = topMenu:getHeight()
	end

	for a,b in pairs(mainScreenTab) do
		if actualY <= mapPanel:getHeight() - 32 then
			for c,d in pairs(b.loot) do
				if actualX <= mapPanel:getWidth() - 32 then
					lootIconOnScreen[c..a] = g_ui.createWidget("LootIcon", mapPanel)

					local findItemByName = g_things.findItemTypeByName(c)
    			if findItemByName:getClientId() ~= 0 then
      			lootIconOnScreen[c..a]:setItemId(findItemByName:getClientId())
    			else
      			lootIconOnScreen[c..a]:setItemId(3547)
    			end

					lootIconOnScreen[c..a]:setVirtual(true)
					lootIconOnScreen[c..a]:setX(actualX + mapPanel:getX())
					actualX = actualX + 32
					lootIconOnScreen[c..a]:setY(actualY)
					if d.count > 1 then
						lootIconOnScreen[c..a]:setItemCount(d.count)
					end
				end
			end
		end

		actualX = 0
		actualY = actualY + 32
	end
end

function destroyLootIconOnScreen()
	for a,b in pairs(lootIconOnScreen) do
		lootIconOnScreen[a]:destroy()
		lootIconOnScreen[a] = nil
	end
end

function saveCheckboxIconsOnScreen()
  if lootStatsWindow:recursiveGetChildById('showLootOnScreen'):isChecked() then
    g_settings.set('loot_stats_addIconsToScreen', false)
  else
    g_settings.set('loot_stats_addIconsToScreen', true)
  end
end
