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


function customAlchemyFormulas.getPotionPotency(pid, player_apparatuses)
    local alchemy = customAlchemyFormulas.getAlchemy(pid)
    local intelligence = customAlchemyFormulas.getIntelligence(pid)
    local luck = customAlchemyFormulas.getLuck(pid)
    
    local x = alchemy + 0.1 * ( intelligence + luck )
    x = x * player_apparatuses[customAlchemyFormulas.MORTAR] * customAlchemyFormulas.fPotionStrengthMult
    
    return x
end

function customAlchemyFormulas.getPotionCount(potency, n)
    local roll = customAlchemyFormulas.getRandom()
    local p = potency / customAlchemyFormulas.maxPotency
    
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

function customAlchemyFormulas.getPotionMagnitude(pid, player_apparatuses, potency, effect)
    if not effect.hasMagnitude then
        return 0
    end
    
    local magnitude = potency / customAlchemyFormulas.fPotionT1MagMult / effect.cost
    
    local mortar = player_apparatuses[customAlchemyFormulas.MORTAR]
    local alembic = player_apparatuses[customAlchemyFormulas.ALEMBIC]
    local calcinator = player_apparatuses[customAlchemyFormulas.CALCINATOR]
    local retort = player_apparatuses[customAlchemyFormulas.RETORT]
    
    if effect.negative then
        if alembic ~= 0 then
            if calcinator ~= 0 then
                magnitude = magnitude / ( alembic * 2 + calcinator * 3 )
            else
                magnitude = magnitude / ( alembic + 1 )
            end
        else
            magnitude = magnitude + calcinator
            if not effect.hasDuration then
                magnitude = magnitude*(calcinator + 0.5) - calcinator
            end
        end
    else
        local mod = calcinator + retort
        
        if calcinator ~= 0 and  retort ~= 0 then
            magnitude = magnitude  + mod + retort
            if not effect.hasDuration then
                magnitude = magnitude - ( mod / 3 ) - retort + 0.5
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

function customAlchemyFormulas.getPotionDuration(pid, player_apparatuses, potency, effect)
    if not effect.hasDuration then
        return 0
    end
    
    local duration = potency / customAlchemyFormulas.fPotionT1DurMult / effect.cost
    
    local mortar = player_apparatuses[customAlchemyFormulas.MORTAR]
    local alembic = player_apparatuses[customAlchemyFormulas.ALEMBIC]
    local calcinator = player_apparatuses[customAlchemyFormulas.CALCINATOR]
    local retort = player_apparatuses[customAlchemyFormulas.RETORT]
    
    if effect.negative then
        if alembic ~= 0 then
            if calcinator ~= 0 then
                duration = duration / ( alembic * 2 + calcinator * 3 )
            else
                duration = duration / ( alembic + 1 )
            end
        else
            duration = duration + calcinator
            if not effect.hasMagnitude then
                duration = duration*(calcinator + 0.5) - calcinator
            end
        end
    else
        local mod = calcinator + retort
        
        if calcinator ~= 0 and  retort ~= 0 then
            duration = duration + mod + retort
            if not effect.hasMagnitude then
                duration = duration - ( mod / 3 ) - retort + 0.5
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

function customAlchemyFormulas.getPotionWeight(pid, player_apparatuses, total_weight)
    return (0.75 * total_weight + 0.35) / (0.5 + player_apparatuses[customAlchemyFormulas.MORTAR])
end

function customAlchemyFormulas.getPotionIcon(potency)
    local tier = math.floor(potency/18)
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

function customAlchemyFormulas.getPotionModel(potency)
    local tier = math.floor(potency/18)
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


return customAlchemyFormulas