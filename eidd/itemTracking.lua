EIDD.lastRoomIndex = Game():GetLevel():GetCurrentRoomDesc().SafeGridIndex
EIDD.trackedRooms = {}
EIDD.trackedCurrentRoom = {}

---Count the amount of a specific item on the floor
---@param itemID CollectibleType The itemID to count
---@return integer amount The amount of the item on the floor
function EIDD:GetNumItemsOnFloor(itemID)
    local amount = 0
    for _, room in pairs(EIDD.trackedRooms) do
        if room[itemID] ~= nil then
            amount = amount + room[itemID]
        end
    end

    for _, item in ipairs(EIDD.trackedCurrentRoom) do
        if item.SubType == itemID then
            amount = amount + 1
        end
    end

    return amount
end

---Append an item to the room, for tracking
---@param itemID CollectibleType The itemID to track within the room
---@param roomID integer The SafeGridIndex of the room the item is in [RoomDescriptor.SafeGridIndex]
function EIDD:TrackAppend(itemID, roomID)
    if EIDD.trackedRooms[roomID] == nil then
        EIDD.trackedRooms[roomID] = {}
    end
    if EIDD.trackedRooms[roomID][itemID] == nil then
        EIDD.trackedRooms[roomID][itemID] = 0
    end

    EIDD.trackedRooms[roomID][itemID] = EIDD.trackedRooms[roomID][itemID] + 1
end

---Get all items in the room and set them to a variable
function EIDD:TrackPostUpdate()
    EIDD.trackedCurrentRoom = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, true)
end

---Keep track of all items in the previous room and get ready to track the current room
function EIDD:TrackNewRoom()
    for _, item in ipairs(EIDD.trackedCurrentRoom) do
        EIDD:TrackAppend(item.SubType, EIDD.lastRoomIndex)
    end
    EIDD.lastRoomIndex = Game():GetLevel():GetCurrentRoomDesc().SafeGridIndex
    EIDD.trackedRooms[EIDD.lastRoomIndex] = {}
    EIDD.trackedCurrentRoom = {}
end

---Reset variables for a new floor
function EIDD:TrackNewLevel()
    EIDD.trackedRooms = {}
end

EIDD:AddCallback(ModCallbacks.MC_POST_UPDATE, EIDD.TrackPostUpdate)
EIDD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, EIDD.TrackNewRoom)
EIDD:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, EIDD.TrackNewLevel)