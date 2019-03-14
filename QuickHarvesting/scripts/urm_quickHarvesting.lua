local quickHarvesting = {}

quickHarvesting.config = jsonInterface.load("config/urm_quickHarvesting.json")
tableHelper.fixNumericalKeys(quickHarvesting.config)

quickHarvesting.plantData = jsonInterface.load(quickHarvesting.config.dataPath)

function quickHarvesting.sendObjectState(pid, cellDescription, uniqueIndex, state)
    local splitIndex = uniqueIndex:split("-")

    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectState(state)

    tes3mp.AddObject()
end

function quickHarvesting.getRandom()
    math.randomseed(os.time())
    math.random()
    math.random()
    math.random()
    return math.random()
end

function quickHarvesting.getGameTime()
  return WorldInstance.data.time.daysPassed*24 + WorldInstance.data.time.hour
end



function quickHarvesting.saveData()
    jsonInterface.save(quickHarvesting.config.dataPath, quickHarvesting.plantData)
end

function quickHarvesting.isHarvestable(refId)
    return quickHarvesting.config.plants[refId] ~= nil
end

function quickHarvesting.isReady(uniqueIndex)
    local plantData = quickHarvesting.plantData[uniqueIndex]
    if plantData == nil then
        return true
    end
    return plantData.state
end

function quickHarvesting.addIngredientToPlayer(pid,refId)
    local player = Players[pid]
    
    local plantConfig = quickHarvesting.config.plants[refId]
    
    local roll = quickHarvesting.getRandom()
    
    local skillRoll = 0
    
    if quickHarvesting.config.alchemyDeterminesChance then
        skillRoll = player.data.skills.Alchemy * 0.5 + roll * 50
    else
        skillRoll = roll * 100
    end
    
    local ingredient_count = 0
    for count, skillBracket in pairs(plantConfig.amount) do
        ingredient_count = count
        if skillBracket > skillRoll then
            break
        end
    end
    
    if ingredient_count == 0 then
        tes3mp.MessageBox(pid, quickHarvesting.config.menuId, "You failed to gather anything!")
        tes3mp.PlaySpeech(pid, "fx/item/potionFAIL.wav")
    else
        inventoryHelper.addItem(player.data.inventory, plantConfig.ingredient, ingredient_count, -1, -1, "")
        
        local message = "You gathered " .. ingredient_count.. " ingredient"
        if ingredient_count>1 then
            message = message .. "s"
        end
        
        message = message.."!"
        
        tes3mp.MessageBox(pid, quickHarvesting.config.menuId, message)
        tes3mp.PlaySpeech(pid, "fx/item/item.wav")
        
        tes3mp.ClearInventoryChanges(pid)
        tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
        tes3mp.AddItemChange(pid, plantConfig.ingredient, ingredient_count, -1, -1, "")
        tes3mp.SendInventoryChanges(pid)
    end
end

function quickHarvesting.enablePlant(pid, cellDescription, uniqueIndex)
    quickHarvesting.plantData[uniqueIndex] = nil
    LoadedCells[cellDescription].data.objectData[uniqueIndex].state = true
    
    quickHarvesting.sendObjectState(pid, cellDescription, uniqueIndex, true)
end

function quickHarvesting.disablePlant(pid, cellDescription, uniqueIndex)
    quickHarvesting.plantData[uniqueIndex] = {
        state = false,
        harvestTime = quickHarvesting.getGameTime()
    }
    LoadedCells[cellDescription].data.objectData[uniqueIndex].state = false
    
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
    
    quickHarvesting.sendObjectState(pid, cellDescription, uniqueIndex, false)
    
    tes3mp.SendObjectState(true, false)
end

function quickHarvesting.attemptHarvest(pid, cellDescription, plant)
    if quickHarvesting.isReady(plant.UniqueIndex) then
        quickHarvesting.addIngredientToPlayer(pid, plant.RefId)
        quickHarvesting.disablePlant(pid, cellDescription, plant.UniqueIndex)
    end
end

function quickHarvesting.updateCell(pid, cellDescription)
    local cell = LoadedCells[cellDescription]
    
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
    
    for uniqueIndex,object in pairs(cell.data.objectData) do
        if quickHarvesting.plantData[uniqueIndex] ~= nil then
            quickHarvesting.disablePlant(pid, cellDescription, uniqueIndex)
            local plantData = quickHarvesting.plantData[uniqueIndex]
            if not plantData.state then
                if quickHarvesting.getGameTime() - plantData.harvestTime > quickHarvesting.config.respawnTime then
                    quickHarvesting.enablePlant(pid, cellDescription, uniqueIndex)
                end
            end
        end
    end
    
    tes3mp.SendObjectState(true, false)
end



function quickHarvesting.OnObjectActivateValidator(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        if quickHarvesting.isHarvestable(object.RefId) then
            quickHarvesting.attemptHarvest(pid, cellDescription, object)
            return customEventHooks.getEventStatus(false, false)
        end
    end
end

function quickHarvesting.OnCellLoadHandler(eventStatus, pid, cellDescription)
    if eventStatus.validCustomHandlers then
        quickHarvesting.updateCell(pid, cellDescription)
        quickHarvesting.saveData()
    end
end

function quickHarvesting.OnServerExit()
    quickHarvesting.saveData()
end



customEventHooks.registerValidator("OnObjectActivate", quickHarvesting.OnObjectActivateValidator)

customEventHooks.registerHandler("OnCellLoad", quickHarvesting.OnCellLoadHandler)

customEventHooks.registerHandler("OnServerExit", quickHarvesting.OnServerExit)
