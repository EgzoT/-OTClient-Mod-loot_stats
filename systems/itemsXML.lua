function ItemsXML()
    local itemsXML = {
        isLoaded = false;
        items = {};

        parseItemsXML = function(self, path)
            self.items = {}

            local fileXML = readFileContents(path)
            local itemsXMLString = {}

            for line in fileXML:gmatch("[^\r\n]+") do
                itemsXMLString[#itemsXMLString + 1] = line
            end

            local lastTableIdBackup = 0

            for a,b in ipairs(itemsXMLString) do
                words = {}
                for word in b:gmatch("%S+") do
                    table.insert(words, word)
                end

                if words[1] == '<item' then
                    if string.sub(words[2], 0, 2) == 'id' then
                        local idFromString = tonumber(string.sub(words[2], string.find(words[2], '"') + 1, string.find(words[2], '"', string.find(words[2], '"') + 1) - 1))
                        self.items[idFromString] = {}

                        for i=3,table.size(words) do
                            if string.find(words[i], '=') then
                                local tabName = string.sub(words[i], 0, string.find(words[i], '=') - 1)
                                local checkWord = words[i]
                                while not (string.find(checkWord, '"') and string.find(checkWord, '"', string.find(checkWord, '"') + 1)) do
                                    checkWord = checkWord..' '..words[i+1]
                                    i = i + 1
                                end

                                local tabValue = string.sub(checkWord, string.find(checkWord, '"') + 1, string.find(checkWord, '"', string.find(checkWord, '"') + 1) - 1)
                                self.items[idFromString][tabName] = tabValue
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
                        self.items[lastTableIdBackup][attKey] = attValue
                    end
                end
            end

            self.isLoaded = true;
        end;

        clear = function(self)
            self.items = {}
            self.isLoaded = false
        end;

        convertPluralToSingular = function(self, searchWord)
            if not self.isLoaded then
                return false
            end

            for a,b in pairs(self.items) do
                if b.plural == searchWord then
                    return b.name
                end
            end

            return false
        end;
    }

    return itemsXML
end
