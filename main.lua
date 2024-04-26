EIDD = RegisterMod("EID Duplicate", 1)
local game = Game()

EIDD.RGON = REPENTOGON
EIDD.descriptionColor = "{{ColorYellow}}"

include("eidd.baseItemDesc")
include("eidd.itemTracking")

---Add a description when multiple copies of an item are available
---@param itemID CollectibleType The item to add a description to
---@param desc string The description to add
---@param playerType? PlayerType If dependent on player (like Birthright), the player type for the description
function EIDD:addDuplicateCollectible(itemID, desc, playerType)
    playerType = playerType or nil

    if playerType ~= nil then
        if EIDD.duplicationDescList[itemID] == nil then
            EIDD.duplicationDescList[itemID] = {}
        end
        EIDD.duplicationDescList[itemID][playerType] = desc
    else
        EIDD.duplicationDescList[itemID] = desc
    end
end

---Format the description to be a certain color
---@param desc string The description for the object
---@return string formattedDesc The formatted description
function EIDD:formatDuplicateDescription(desc)
    local formatted = string.gsub(desc, "#", "#" .. EIDD.descriptionColor)
    formatted = string.gsub(formatted, "{{CR}}", "{{CR}}" .. EIDD.descriptionColor)
    return formatted
end

---Checks whether there are two items on the floor, or the possiblity of getting two of the same item
---@param obj any The descObj provided by EID, contains all information about the entity that is described
---@return boolean? doDuplicate If the description should contain a description for duplicates
local function HasItem(obj)
    -- Make sure obj is an item
    if obj ~= nil and obj.ObjType == EntityType.ENTITY_PICKUP and obj.ObjVariant == PickupVariant.PICKUP_COLLECTIBLE then

        -- More than one of the same item on the floor
        local floorCollectibleNum = EIDD:GetNumItemsOnFloor(obj.ObjSubType)
        if floorCollectibleNum >= 2 then
            return true
        end

        if obj.Entity ~= nil then
            local playerCount = game:GetNumPlayers()
            -- Loop through players
            for playerIndex = 0, playerCount - 1 do
                local player = Isaac.GetPlayer(playerIndex)
                -- Has the item already and another is in the room 
                -- OR has the item and another exists on the floor
                local playerCollectibleNum = player:GetCollectibleNum(obj.ObjSubType)
                if playerCollectibleNum > 0 or (playerCollectibleNum + floorCollectibleNum >= 2) then
                    return true
                end
                -- Has Diplopia or Crooked Penny
                for slot = ActiveSlot.SLOT_PRIMARY, ActiveSlot.SLOT_POCKET2 do
                    local activeItem = player:GetActiveItem(slot)
                    if activeItem == CollectibleType.COLLECTIBLE_DIPLOPIA or activeItem == CollectibleType.COLLECTIBLE_CROOKED_PENNY then
                        return true
                    end
                end
            end
        end
    end
end

---Adds the duplicate description to the currect description
---@param obj any The descObj provided by EID, contains all information about the entity that is described
---@return any descObj The complete description
local function AddDescription(obj)
    -- Make sure the object has an entry in the description list
    if EIDD.duplicationDescList[obj.ObjSubType] ~= nil and EIDD.duplicationDescList[obj.ObjSubType] ~= "" then
        local desc = ""
        if type(EIDD.duplicationDescList[obj.ObjSubType]) == "table" then
            -- Handle multi-character descriptions
            local entityPos = obj.Entity.Position
            local playerCount = game:GetNumPlayers()

            -- Find the nearest player to the item
            local nearestPlayer = Isaac.GetPlayer()
            local nearestDistance = math.maxinteger
            for playerIndex = 0, playerCount - 1 do
                local player = Isaac.GetPlayer(playerIndex)
                local distance = player.Position:Distance(entityPos)
                if distance < nearestDistance then
                    nearestPlayer = player
                    nearestDistance = distance
                end
            end
            -- Multi-character duplication description
            desc = EIDD.duplicationDescList[obj.ObjSubType][nearestPlayer.SubType]
        else
            -- Regular duplication description
            desc = EIDD.duplicationDescList[obj.ObjSubType]
        end
        EID:appendToDescription(obj, "#{{Collectible" .. obj.ObjSubType .. "}} " .. EIDD.descriptionColor .. EIDD:formatDuplicateDescription(desc))
    end
    return obj
end

function EIDD:Init()
    if not EID then
        error("[EIDD] EID not installed. Please install External Item Descriptions for \"[EID] Duplicate\" to function.")
    end

    EID:addDescriptionModifier("Duplicate Items", HasItem, AddDescription)
    print("EIDD LOADED")
end

if EIDD.RGON then
    EIDD:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, EIDD.Init)
else
    EIDD:Init()
end