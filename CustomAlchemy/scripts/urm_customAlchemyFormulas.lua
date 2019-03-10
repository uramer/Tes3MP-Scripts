local customAlchemyFormulas = {
    MORTAR = 0,
    ALEMBIC = 1,
    CALCINATOR = 2,
    RETORT = 3,
    
    fPotionStrengthMult = 0.5,
    fPotionT1DurMult = 0.5,
    fPotionT1MagMult = 1.5,
    iAlchemyMod = 2,
    
    maxPotency = 100
}


function customAlchemyFormulas.getRandom()
    math.randomseed(os.time())
    
    math.random()
    math.random()
    math.random()
    
    return math.random()
end

function customAlchemyFormulas.getAlchemy(pid)
    return Players[pid].data.skills.Alchemy
end

function customAlchemyFormulas.getIntelligence(pid)
    return Players[pid].data.attributes.Intelligence
end

function customAlchemyFormulas.getLuck(pid)
    return Players[pid].data.attributes.Luck
end


function customAlchemyFormulas.makeAlchemyStatus(pid, apparatuses, ingredients)
    local status = {
        pid = pid,
        ingredients = ingredients
    }
    
    status.mortar = apparatuses[customAlchemyFormulas.MORTAR]
    status.alembic = apparatuses[customAlchemyFormulas.ALEMBIC]
    status.calcinator = apparatuses[customAlchemyFormulas.CALCINATOR]
    status.retort = apparatuses[customAlchemyFormulas.RETORT]

    status.alchemy = customAlchemyFormulas.getAlchemy(pid)
    status.intelligence = customAlchemyFormulas.getIntelligence(pid)
    status.luck = customAlchemyFormulas.getLuck(pid)

    status.potency = customAlchemyFormulas.getPotionPotency(status)

    status.weight = customAlchemyFormulas.getPotionWeight(status)
    
    status.icon = customAlchemyFormulas.getPotionIcon(status)
    
    status.model = customAlchemyFormulas.getPotionModel(status)
    
    status.value = customAlchemyFormulas.getPotionValue(status)
    
    return status
end

function customAlchemyFormulas.getPotionPotency(status)
    local potency = status.alchemy + 0.1 * ( status.intelligence + status.luck )
    potency = potency * status.mortar * customAlchemyFormulas.fPotionStrengthMult
    
    return potency
end

function customAlchemyFormulas.getPotionValue(status)
    return customAlchemyFormulas.iAlchemyMod * status.potency
end


function customAlchemyFormulas.getPotionWeight(status)
    local total_weight = 0
    for _,ingredient in pairs(status.ingredients) do
        total_weight = total_weight + ingredient.weight
    end
    return (0.75 * total_weight + 0.35) / (0.5 + status.alembic)
end

function customAlchemyFormulas.getPotionIcon(status)
    local tier = math.floor(status.potency/18)
    if tier >= 4 then
        return "m\\tx_potion_exclusive_01.tga"
    elseif tier == 3 then
        return "m\\tx_potion_quality_01.tga"
    elseif tier == 2 then
        return "m\\tx_potion_standard_01.tga"
    elseif tier == 1 then
        return "m\\tx_potion_cheap_01.tga"
    end
    return "m\\tx_potion_bargain_01.tga"
end

function customAlchemyFormulas.getPotionModel(status)
    local tier = math.floor(status.potency/18)
    if tier >= 4 then
        return "m\\misc_potion_exclusive_01.nif"
    elseif tier == 3 then
        return "m\\misc_potion_quality_01.nif"
    elseif tier == 2 then
        return "m\\misc_potion_standard_01.nif"
    elseif tier == 1 then
        return "m\\misc_potion_cheap_01.nif"
    end
    return "m\\misc_potion_bargain_01.nif"
end


function customAlchemyFormulas.getPotionCount(status, ingredientCount)
    local n = ingredientCount
    local roll = customAlchemyFormulas.getRandom()
    local p = status.potency / customAlchemyFormulas.maxPotency
    
    local pn = (1-p)^n
    local probability = pn
    local n_choose_i = 1
    local dp = p/(1-p)
    
    for k = 1,n do
        n_choose_i = n_choose_i * (n - k + 1) / k
        pn = pn * dp
        probability = probability + n_choose_i * pn
        if probability >= roll then
            
            return k-1
        end
    end
    
    return n
end

function customAlchemyFormulas.getEffectMagnitude(status, effect)
    if not effect.hasMagnitude then
        return 0
    end
    
    local magnitude = status.potency / customAlchemyFormulas.fPotionT1MagMult / effect.cost
    
    if effect.negative then
        if status.alembic ~= 0 then
            if status.calcinator ~= 0 then
                magnitude = magnitude / ( status.alembic * 2 + status.calcinator * 3 )
            else
                magnitude = magnitude / ( status.alembic + 1 )
            end
        else
            magnitude = magnitude + status.calcinator
            if not effect.hasDuration then
                magnitude = magnitude*( status.calcinator + 0.5 ) - status.calcinator
            end
        end
    else
        local mod = status.calcinator + status.retort
        
        if status.calcinator ~= 0 and  status.retort ~= 0 then
            magnitude = magnitude  + mod + status.retort
            if not effect.hasDuration then
                magnitude = magnitude - ( mod / 3 ) - status.retort + 0.5
            end
        else
            magnitude = magnitude + mod
            if not effect.hasDuration then
                magnitude = magnitude * ( mod + 0.5 ) - mod
            end
        end
    end
    
    return magnitude
end

function customAlchemyFormulas.getEffectDuration(status, effect)
    if not effect.hasDuration then
        return 0
    end
    
    local duration = status.potency / customAlchemyFormulas.fPotionT1DurMult / effect.cost
    
    if effect.negative then
        if status.alembic ~= 0 then
            if status.calcinator ~= 0 then
                duration = duration / ( status.alembic * 2 + status.calcinator * 3 )
            else
                duration = duration / ( status.alembic + 1 )
            end
        else
            duration = duration + status.calcinator
            if not effect.hasMagnitude then
                duration = duration*(status.calcinator + 0.5) - status.calcinator
            end
        end
    else
        local mod = status.calcinator + status.retort
        
        if status.calcinator ~= 0 and  status.retort ~= 0 then
            duration = duration + mod + status.retort
            if not effect.hasMagnitude then
                duration = duration - ( mod / 3 ) - status.retort + 0.5
            end
        else
            duration = duration + mod
            if not effect.hasMagnitude then
                duration = duration * ( mod + 0.5 ) - mod
            end
        end
    end
    
    return duration
end


return customAlchemyFormulas