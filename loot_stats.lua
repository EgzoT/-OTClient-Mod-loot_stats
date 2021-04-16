-- Imports
dofile('data/store')
dofile('systems/createStats')
dofile('ui/ui')
dofile('systems/itemsXML')

-- Modules
store = Store()
createStats = CreateStats()
ui = UI()

function init()
  store:init()
  createStats:init()
  ui:init()
end

function terminate()
  ui:terminate()
  createStats:terminate()
  store:terminate()
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

-- Informations

function getParserType()
  if createStats.ownParser then
    return "Own XML parser"
  else
    return "OTClient inbuild XML parser"
  end
end
