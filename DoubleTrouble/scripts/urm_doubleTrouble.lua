local scandir = function(directory)
    local CMDa
    local CMDb
    if tes3mp.GetOperatingSystemType() == "Windows" then
        CMDa = 'dir "'
        CMDb = '"'
    else
        CMDa = 'ls -a "'
        CMDb = '"'
    end

    local i, t, popen = 0, {}, io.popen
    local pfile = io.popen(CMDa..directory..CMDb)
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    
    pfile:close()
    
    return t
end

local doubleTrouble = {}
doubleTrouble.visited = {}
doubleTrouble.config = jsonInterface.load("config/urm_doubleTrouble.json")
doubleTrouble.creatureCheck = {}

for k, v in pairs(doubleTrouble.config.creatures) do
    doubleTrouble.creatureCheck[v] = true
end

function doubleTrouble.OnServerPostInit()
    local cellFiles = scandir(tes3mp.GetModDir().."/cell")

    for k, v in pairs(cellFiles) do
        doubleTrouble.visited[v] = true
    end
end

function doubleTrouble.isCreature(refId)
    return doubleTrouble.creatureCheck[refId] ~= nil
end

function doubleTrouble.duplicate(cellDescription)
    local cellData = LoadedCells[cellDescription].data
    if cellData~=nil then
        local creatures = {}
        for _, uniqueIndex in pairs(cellData.packets.actorList) do
            if cellData.objectData[uniqueIndex].location ~= nil and doubleTrouble.isCreature(cellData.objectData[uniqueIndex].refId) then
                table.insert(creatures, uniqueIndex)
            end
        end
        
        tes3mp.LogMessage(enumerations.log.INFO, "[urm_doubleTrouble] Cloning "..#creatures.."("..#cellData.packets.actorList..") creatures:")
        for _, uniqueIndex in pairs(creatures) do
            local creature = cellData.objectData[uniqueIndex]
            tes3mp.LogMessage(enumerations.log.INFO, creature.refId..", ")
            for i=2, doubleTrouble.config.copies do
                logicHandler.CreateObjectAtLocation(cellDescription, creature.location, creature.refId, "spawn")
            end
        end
        tes3mp.LogMessage(enumerations.log.INFO, "\n")
    end
end

function doubleTrouble.OnActorList(eventStatus, pid, cellDescription)
    if doubleTrouble.visited[cellDescription] == nil then
        doubleTrouble.visited[cellDescription] = true
        doubleTrouble.duplicate(cellDescription)
    end
end

customEventHooks.registerHandler("OnActorList", doubleTrouble.OnActorList)
customEventHooks.registerHandler("OnServerPostInit", doubleTrouble.OnServerPostInit)

return doubleTrouble
