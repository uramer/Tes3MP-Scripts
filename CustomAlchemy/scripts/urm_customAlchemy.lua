local customAlchemy = {}

local customAlchemyFormulas = require("urm_customAlchemyFormulas")

customAlchemy.config = jsonInterface.load("config/urm_customAlchemy.json")

tableHelper.fixNumericalKeys(customAlchemy.config)

customAlchemy.container = {}
customAlchemy.containerWeight = {}

customAlchemy.burdenId = {}


function customAlchemy.updatePlayerInventory(pid)
    Players[pid]:LoadInventory()
    Players[pid]:LoadEquipment()
    Players[pid]:LoadQuickKeys() 
end

function customAlchemy.updatePlayerSpellbook(pid)
    Players[pid]:LoadSpellbook()
end


function customAlchemy.createAlchemyContainerRecord()
    local recordStore = RecordStores[customAlchemy.config.container.type]
    if recordStore.data.permanentRecords[customAlchemy.config.container.refId] == nil then
        recordStore.data.permanentRecords[customAlchemy.config.container.refId] = {
            baseId = customAlchemy.config.container.baseId,
            name = customAlchemy.config.container.name
        }
        recordStore:Save()
    end
end

function customAlchemy.getContainerCell()
    return LoadedCells[customAlchemy.config.container.cell]
end

function customAlchemy.createContainer(pid)
    local uniqueIndex = logicHandler.CreateObjectAtLocation(
        customAlchemy.config.container.cell,
        customAlchemy.config.container.location,
        customAlchemy.config.container.refId,
        "spawn"
    )
    customAlchemy.getContainerCell().data.objectData[uniqueIndex].inventory = {}
    customAlchemy.getContainerCell():Save()
    customAlchemy.container[pid] = uniqueIndex
    customAlchemy.containerWeight[pid] = 0
end

function customAlchemy.getContainerUniqueIndex(pid)
    return customAlchemy.container[pid]
end

function customAlchemy.getContainerInventory(pid)
    local uniqueIndex = customAlchemy.getContainerUniqueIndex(pid)
    return customAlchemy.getContainerCell().data.objectData[uniqueIndex].inventory
end

function customAlchemy.setContainerInventory(pid, inventory)
    local uniqueIndex = customAlchemy.getContainerUniqueIndex(pid)
    customAlchemy.getContainerCell().data.objectData[uniqueIndex].inventory = inventory
end

function customAlchemy.updateContainer(pid)
    local uniqueIndex = customAlchemy.getContainerUniqueIndex(pid)
    local cell = customAlchemy.getContainerCell()
    cell:LoadContainers(pid, cell.data.objectData, {uniqueIndex})
    logicHandler.RunConsoleCommandOnPlayer(pid, "togglemenus", false)
    logicHandler.RunConsoleCommandOnPlayer(pid, "togglemenus", false)
end

function customAlchemy.getContainerWeight(pid)
    return customAlchemy.containerWeight[pid]
end

function customAlchemy.updateContainerWeight(pid)
    local inventory = customAlchemy.getContainerInventory(pid)
    local weight = 0
    for _, item in pairs(inventory) do
        if customAlchemy.isIngredient(item.refId) then
            weight = weight + customAlchemy.config.ingredients[item.refId].weight * item.count
        end
    end
    
    customAlchemy.containerWeight[pid] = weight
    
    return customAlchemy.containerWeight[pid]
end

function customAlchemy.isContainerEmpty(pid)
    return customAlchemy.getContainerInventory(pid)[1] == nil
end

function customAlchemy.emptyContainer(pid)
    local inventory = customAlchemy.getContainerInventory(pid)
    local player = Players[pid]
    
    tes3mp.ClearInventoryChanges(pid)
    tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)

    for _, item in pairs(inventory) do
        inventoryHelper.addItem(player.data.inventory, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)
        tes3mp.AddItemChange(pid, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)
    end
    
    tes3mp.SendInventoryChanges(pid)
    
    customAlchemy.setContainerInventory(pid, {})
    local splitIndex = customAlchemy.getContainerUniqueIndex(pid):split("-")
    
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(customAlchemy.config.container.cell)
    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectRefId(customAlchemy.config.container.refId)
    tes3mp.AddObject()
    tes3mp.SetObjectListAction(enumerations.container.SET)
    tes3mp.SendContainer()
    
    customAlchemy.updateContainerWeight(pid)
    customAlchemy.applyContainerBurden(pid)
end

function customAlchemy.destroyContainer(pid)
    customAlchemy.emptyContainer(pid)
    customAlchemy.getContainerCell():DeleteObjectData(customAlchemy.getContainerUniqueIndex(pid))
    customAlchemy.container[pid] = nil
    customAlchemy.getContainerCell():Save()
end

function customAlchemy.showContainer(pid)
    logicHandler.ActivateObjectForPlayer(
        pid,
        customAlchemy.config.container.cell,
        customAlchemy.getContainerUniqueIndex(pid)
    )
end

function customAlchemy.filterContainerIngredients(pid, objectIndex)
    local nonIngredients = false
    
    tes3mp.ClearInventoryChanges(pid)
    tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
    
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(customAlchemy.config.container.cell)
    
    local splitIndex = customAlchemy.getContainerUniqueIndex(pid):split("-")
    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectRefId(customAlchemy.config.container.refId)
    
    for itemIndex = 0, tes3mp.GetContainerChangesSize(objectIndex) - 1 do
        local item = {
            refId = tes3mp.GetContainerItemRefId(objectIndex, itemIndex),
            count = tes3mp.GetContainerItemCount(objectIndex, itemIndex),
            charge = tes3mp.GetContainerItemCharge(objectIndex, itemIndex),
            enchantmentCharge = tes3mp.GetContainerItemEnchantmentCharge(objectIndex, itemIndex),
            soul = tes3mp.GetContainerItemSoul(objectIndex, itemIndex)
        }
        
        if not customAlchemy.isIngredient(item.refId) then
            nonIngredients = true
            
            inventoryHelper.addItem(Players[pid].data.inventory, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)
            tes3mp.AddItemChange(pid, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)
            
            tes3mp.SetContainerItemRefId(item.refId)
            tes3mp.SetContainerItemCount(item.count)
            tes3mp.SetContainerItemCharge(item.charge)
            tes3mp.SetContainerItemEnchantmentCharge(item.enchantmentCharge)
            tes3mp.SetContainerItemSoul(item.soul)
            
            tes3mp.AddContainerItem()
        end
    end
    
    tes3mp.AddObject()
    tes3mp.SetObjectListAction(enumerations.container.REMOVE)
     
    if nonIngredients then
        tes3mp.SendInventoryChanges(pid)
        
        tes3mp.SendContainer()
        
        return true
    end
    
    return false
end


function customAlchemy.updateContainerBurden(pid)
    local recordStore = RecordStores["spell"]
    local id = customAlchemy.burdenId[pid]
    
    tableHelper.removeValue(Players[pid].data.spellbook, id)
    customAlchemy.updatePlayerSpellbook(pid)
    
    tableHelper.removeValue(Players[pid].generatedRecordsReceived, id)
    recordStore:LoadGeneratedRecords(pid, recordStore.data.generatedRecords, {id})
    
    table.insert(Players[pid].data.spellbook, id)
    customAlchemy.updatePlayerSpellbook(pid)
end

function customAlchemy.createContainerBurden(pid)
    local recordStore = RecordStores["spell"]
    local id = customAlchemy.config.burden.id .. Players[pid].accountName    
    customAlchemy.burdenId[pid] = id
    
    local recordTable = {
        name = "Weight of ingredients",
        subtype = 2,
        effects = {{
            id = 7,
            attribute = -1,
            skill = -1,
            rangeType = 0,
            area = 0,
            magnitudeMin = 0,
            magnitudeMax = 0
        }}
    }
    
    recordStore.data.generatedRecords[id] = recordTable
    
    recordStore:AddLinkToPlayer(id, Players[pid])
    Players[pid]:AddLinkToRecord("spell", id)
    recordStore:Save()
    
    if not tableHelper.containsValue(Players[pid].data.spellbook, id) then
        table.insert(Players[pid].data.spellbook, id)
    end
    
    customAlchemy.updateContainerBurden(pid)
    --customAlchemy.updatePlayerSpellbook(pid)
end

function customAlchemy.applyContainerBurden(pid)
    local weight = math.ceil(customAlchemy.getContainerWeight(pid))
    
    local recordStore = RecordStores["spell"]
    local id = customAlchemy.burdenId[pid]
    
    recordStore.data.generatedRecords[id].effects[1].magnitudeMin = weight
    recordStore.data.generatedRecords[id].effects[1].magnitudeMax = weight

    customAlchemy.updateContainerBurden(pid)
end

function customAlchemy.destroyContainerBurden(pid)
    local recordStore = RecordStores["spell"]
    local id = customAlchemy.burdenId[pid]
    customAlchemy.burdenId[pid] = nil
    
    recordStore.data.generatedRecords[id] = nil
    
    recordStore:RemoveLinkToPlayer(id, Players[pid])
    Players[pid]:RemoveLinkToRecord("spell", id)
    recordStore:Save()
    
    Players[pid]:CleanSpellbook()
    
    customAlchemy.updatePlayerSpellbook(pid)
end


function customAlchemy.isApparatus(refId)
    return customAlchemy.config.apparatuses[refId]~=nil
end

function customAlchemy.getApparatus(refId)
    return customAlchemy.config.apparatuses[refId]
end

function customAlchemy.isIngredient(refId)
    return customAlchemy.config.ingredients[refId]~=nil
end

function customAlchemy.determineApparatuses(pid)
    local player_apparatuses = {}
    for i = 0, 3 do
        player_apparatuses[i] = 0
    end
    
    local inventory = Players[pid].data.inventory
    for _, item in pairs(inventory) do
        if customAlchemy.isApparatus(item.refId) then
            local apparatus = customAlchemy.getApparatus(item.refId)
            player_apparatuses[apparatus.type] = math.max(player_apparatuses[apparatus.type], apparatus.quality)
        end
    end
    return player_apparatuses
end

customAlchemy.skillEffects = {}
customAlchemy.skillEffects[21]=true
customAlchemy.skillEffects[26]=true
customAlchemy.skillEffects[78]=true
customAlchemy.skillEffects[83]=true
customAlchemy.skillEffects[89]=true

customAlchemy.attributeEffects = {}
customAlchemy.attributeEffects[17]=true
customAlchemy.attributeEffects[22]=true
customAlchemy.attributeEffects[74]=true
customAlchemy.attributeEffects[79]=true
customAlchemy.attributeEffects[85]=true

function customAlchemy.needsCombinedId(id)  
    return customAlchemy.attributeEffects[id]~=nil or customAlchemy.skillEffects[id]~=nil
end

function customAlchemy.isSkillEffect(id)
    return customAlchemy.skillEffects[id]
end

function customAlchemy.isAttributeEffect(id)
    return customAlchemy.attributeEffects[id]
end

customAlchemy.maxEffectId = 256

function customAlchemy.makeCombinedId(id, parameter)
    return (parameter + 1) * customAlchemy.maxEffectId + id
end

function customAlchemy.isCombinedId(id)
    return id >= customAlchemy.maxEffectId
end

function customAlchemy.parseCombinedId(combinedId)
    local id = combinedId % customAlchemy.maxEffectId
    local parameter = math.floor(combinedId / customAlchemy.maxEffectId) - 1
    
    return {
        effectId = id,
        parameter = parameter
    }
end


function customAlchemy.failure(pid,label)
    tes3mp.MessageBox(pid,customAlchemy.config.menu.failure_id,label)
    tes3mp.PlaySpeech(pid, "fx/item/potionFAIL.wav")
end

function customAlchemy.success(pid,count)
    local message = "You have sucessfully brewed "
    if count == 1 then
        message = message .. "a potion!"
    else
        message = message .. count .. " potions!"
    end
    tes3mp.MessageBox(pid,customAlchemy.config.menu.success_id,message)
    tes3mp.PlaySpeech(pid, "fx/item/potion.wav")
end

function customAlchemy.brewPotions(pid, name)
    local containerInventory = customAlchemy.getContainerInventory(pid)
    
    --if there are too many different ingredients (>4 by default), we can't brew a potion
    if #containerInventory <= customAlchemy.config.maximumIngredientCount then
        local potion_effects = {} --keeping track of all effects of our ingredients
        local min_ingredient_count = nil --how many potions we can brew
        
        for _, item in pairs(containerInventory) do
            if min_ingredient_count == nil then
                min_ingredient_count = item.count
            else
                min_ingredient_count = math.min(min_ingredient_count, item.count)
            end
            
            local ingredient = customAlchemy.config.ingredients[item.refId]
            
            if ingredient~=nil then
                
                for index, id in pairs(ingredient.effects) do
                    if id~=-1 then
                        local effectId = id
                        if customAlchemy.isSkillEffect(id) then
                            effectId = customAlchemy.makeCombinedId(id, ingredient.skills[index])
                        elseif customAlchemy.isAttributeEffect(id) then
                            effectId = customAlchemy.makeCombinedId(id, ingredient.attributes[index])
                        end
                        
                        if potion_effects[effectId] == nil then
                            potion_effects[effectId] = 1
                        else
                            potion_effects[effectId] = 1 + potion_effects[effectId]
                        end
                    end
                end
                
            end
        end
        
        --removing ingredients that we ended up using
        for _, item in pairs(containerInventory) do
            inventoryHelper.removeItem(containerInventory, item.refId, min_ingredient_count, item.charge, item.enchantmentCharge, item.soul)
        end
        
        --return whatever is left to the player
        customAlchemy.emptyContainer(pid)        
        
        local player_apparatuses = customAlchemy.determineApparatuses(pid)
        
        local potency = customAlchemyFormulas.getPotionPotency(pid, player_apparatuses)
        
        local potion_count = customAlchemyFormulas.getPotionCount(potency,min_ingredient_count)
        
        local recordTable = {
            name = name,
            weight = customAlchemyFormulas.getPotionWeight(pid, player_apparatuses, customAlchemy.getContainerWeight(pid)),
            icon = customAlchemyFormulas.getPotionIcon(potency),
            model = customAlchemyFormulas.getPotionModel(potency)
        }
        
        recordTable.effects = {}

        for combinedId, count in pairs(potion_effects) do
            --if there are fewer than necessary (2 by default) ingredients with the same effect, don't add it
            if count >= customAlchemy.config.potionEffectTreshold then
                local effectId = 0
                local skill = -1
                local attribute = -1
                
                if customAlchemy.isCombinedId(combinedId) then
                    local parsed = customAlchemy.parseCombinedId(combinedId)
                    effectId = parsed.effectId
                    if customAlchemy.isSkillEffect(effectId) then
                        skill = parsed.parameter
                    else
                        attribute = parsed.parameter
                    end
                else
                    effectId = combinedId
                end
                
                local effectData = customAlchemy.config.effects[effectId]
                
                if effectData == nil then
                    
                end
                
                local magnitude = customAlchemyFormulas.getPotionMagnitude(pid, player_apparatuses, potency, effectData)
                local duration = customAlchemyFormulas.getPotionDuration(pid, player_apparatuses, potency, effectData)
                
                local effect = {
                    id = effectId,
                    attribute = attribute,
                    skill = skill,
                    rangeType = 0,
                    area = 0,
                    magnitudeMin = magnitude,
                    magnitudeMax = magnitude,
                    duration = duration
                }
                table.insert(recordTable.effects, effect)
            end
        end
        
        if recordTable.effects[1] ~= nil then
        
            if potion_count < 1 then
                customAlchemy.failure(pid,"You failed to brew anything!")
                customAlchemy.updateContainer(pid)
                return
            end
            
            local recordStore = RecordStores["potion"]
            local potionId = recordStore:GenerateRecordId()
            
            recordStore.data.generatedRecords[potionId] = recordTable
            recordStore:AddLinkToPlayer(potionId, Players[pid])
            Players[pid]:AddLinkToRecord("potion", potionId)
            recordStore:Save()
            recordStore:LoadGeneratedRecords(pid, recordStore.data.generatedRecords, {potionId})
            
            inventoryHelper.addItem(Players[pid].data.inventory, potionId, potion_count, -1, -1, "")
            
            tes3mp.ClearInventoryChanges(pid)
            tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
            tes3mp.AddItemChange(pid, potionId, potion_count, -1, -1, "")
            tes3mp.SendInventoryChanges(pid)
            
            customAlchemy.success(pid,potion_count)
            
            customAlchemy.updateContainer(pid)
        else
           customAlchemy.failure(pid,"This potion is useless!")
           customAlchemy.setContainerInventory(pid,{})
           customAlchemy.updateContainer(pid)
        end
    else
        customAlchemy.failure(pid,"Too many ingredients!")
        customAlchemy.cancel(pid)
    end
end

function customAlchemy.addIngredient(pid)
    customAlchemy.showContainer(pid)
end

function customAlchemy.cancel(pid)
    customAlchemy.emptyContainer(pid)
end


function customAlchemy.getApparatusGUIId()
    return customAlchemy.config.menu.apparatus_id
end

function customAlchemy.getPotionNameGUIId()
    return customAlchemy.config.menu.potionName_id
end

function customAlchemy.showApparatusGUI(pid)
    tes3mp.CustomMessageBox(pid, customAlchemy.getApparatusGUIId(), "", "Brew;Add ingredient;Cancel")
end

function customAlchemy.showPotionNameGUI(pid)
    tes3mp.InputDialog(pid, customAlchemy.getPotionNameGUIId(), "Name your potions:", "")
end


function customAlchemy.OnServerPostInit()
    io.write("OnServerPostInit\n")
    customAlchemy.createAlchemyContainerRecord()
    logicHandler.LoadCell(customAlchemy.config.container.cell)
end

function customAlchemy.OnCellUnloadValidator(eventStatus, pid, cellDescription)
    if cellDescription == customAlchemy.config.container.cell then
        return customEventHooks.getEventStatus(false, false)
    end
end

function customAlchemy.OnServerExit(eventStatus)
    logicHandler.UnloadCell(customAlchemy.config.container.cell)
end

function customAlchemy.OnPlayerAuthentified(eventStatus, pid)
   customAlchemy.createContainer(pid)
   customAlchemy.createContainerBurden(pid)
end

function customAlchemy.OnPlayerDisconnectValidator(eventStatus, pid)
   customAlchemy.destroyContainer(pid)
   customAlchemy.destroyContainerBurden(pid)
end

function customAlchemy.OnPlayerItemUseValidator(eventStatus, pid, refId)
    if customAlchemy.isApparatus(refId) then
        customAlchemy.showContainer(pid)
        
        if not customAlchemy.isContainerEmpty(pid) then
            customAlchemy.showApparatusGUI(pid)
        end
        
        return customEventHooks.getEventStatus(false, nil)
    end
end

function customAlchemy.OnContainerValidator(eventStatus, pid, cellDescription, containers)
    local nonIngredients = false
    for objectIndex = 0, tes3mp.GetObjectListSize() - 1 do
        local uniqueIndex = tes3mp.GetObjectRefNum(objectIndex) .. "-" .. tes3mp.GetObjectMpNum(objectIndex)
        
        if uniqueIndex == customAlchemy.getContainerUniqueIndex(pid) then
            if customAlchemy.filterContainerIngredients(pid, objectIndex) then
                return customEventHooks.getEventStatus(false, false)
            end
            break
        end
    end
end

function customAlchemy.OnContainer(eventStatus, pid, cellDescription, containers)
    if eventStatus.validCustomHandlers then
        for _, container in pairs(containers) do        
            if container.UniqueIndex == customAlchemy.getContainerUniqueIndex(pid) then
                customAlchemy.updateContainerWeight(pid)
                customAlchemy.applyContainerBurden(pid)
            end
        end
   end
end

function customAlchemy.OnGUIAction(eventStatus, pid, idGui, data)
    if idGui==customAlchemy.getApparatusGUIId() then
        if data~=nil then
            local button = tonumber(data)
            
            customAlchemy.handleGUIButton(pid, button)
        end
        return customEventHooks.getEventStatus(false, nil)
    elseif idGui == customAlchemy.getPotionNameGUIId() then
        if data~=nil then
            customAlchemy.brewPotions(pid, data)
        end
    end
end

function customAlchemy.handleGUIButton(pid, button)
    if button == 0 then
        customAlchemy.showPotionNameGUI(pid)
    elseif button == 1 then
        customAlchemy.addIngredient(pid)
    elseif button == 2 then
        customAlchemy.cancel(pid)
    end
end


customEventHooks.registerHandler("OnServerPostInit", customAlchemy.OnServerPostInit)

customEventHooks.registerValidator("OnCellUnload", customAlchemy.OnCellUnloadValidator)

customEventHooks.registerHandler("OnServerExit", customAlchemy.OnCellUnloadValidator)

customEventHooks.registerHandler("OnPlayerAuthentified", customAlchemy.OnPlayerAuthentified)

customEventHooks.registerValidator("OnPlayerDisconnect", customAlchemy.OnPlayerDisconnectValidator)

customEventHooks.registerValidator("OnPlayerItemUse", customAlchemy.OnPlayerItemUseValidator)

customEventHooks.registerValidator("OnContainer", customAlchemy.OnContainerValidator)
customEventHooks.registerHandler("OnContainer", customAlchemy.OnContainer)

customEventHooks.registerHandler("OnGUIAction", customAlchemy.OnGUIAction)