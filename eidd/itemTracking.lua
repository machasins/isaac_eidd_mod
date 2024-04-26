local json = require("json")

EIDD.lastRoomIndex = Game():GetLevel():GetCurrentRoomDesc().SafeGridIndex
EIDD.trackedRooms = {}
EIDD.trackedCurrentRoom = {}

---Load saved config data
function EIDD:Load()
    if not EIDD:HasData() then
        return
    end

    local jsonString = EIDD:LoadData()
    local reformat = json.decode(jsonString)
    for idx, room in pairs(reformat) do
        EIDD.trackedRooms[tonumber(idx)] = {}
        for item, amt in pairs(room) do
            EIDD.trackedRooms[tonumber(idx)][tonumber(item)] = amt
        end
    end
end

---Save config data
function EIDD:Save()
    local reformat = {}
    for idx, room in pairs(EIDD.trackedRooms) do
        reformat[idx .. ""] = {}
        for item, amt in pairs(room) do
            reformat[idx .. ""][item .. ""] = amt
        end
    end
    local jsonString = json.encode(reformat)
    EIDD:SaveData(jsonString)
end

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

    for _, item in pairs(EIDD.trackedCurrentRoom) do
        if item == itemID then
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

if not EIDD.RGON then
    ---Get all items in the room and set them to a variable
    function EIDD:TrackPostUpdate()
        local items = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, true)
        for idx, item in pairs(items) do
            EIDD.trackedCurrentRoom[idx] = item.SubType
        end
    end
else
    ---Get all items in the room and set them to a variable
    function EIDD:TrackPostUpdate()
        EIDD.trackedCurrentRoom = {}

        local items = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, true)
        for _, i in pairs(items) do
            table.insert(EIDD.trackedCurrentRoom, i.SubType)
            local cycle = i:ToPickup():GetCollectibleCycle()
            for _, c in pairs(cycle) do
                table.insert(EIDD.trackedCurrentRoom, c)
            end
        end
    end
end

---Keep track of all items in the previous room and get ready to track the current room
function EIDD:TrackNewRoom()
    for _, item in ipairs(EIDD.trackedCurrentRoom) do
        EIDD:TrackAppend(item, EIDD.lastRoomIndex)
    end
    EIDD.lastRoomIndex = Game():GetLevel():GetCurrentRoomDesc().SafeGridIndex
    EIDD.trackedRooms[EIDD.lastRoomIndex] = {}
    EIDD.trackedCurrentRoom = {}
end

---Reset variables for a new floor
function EIDD:TrackNewLevel()
    EIDD.trackedRooms = {}
end

function EIDD:StartGame(isCont)
    if isCont then
        EIDD:Load()
    end
end

function EIDD:EndGame(doSave)
    if doSave then
        EIDD:Save()
    end
end

EIDD:AddCallback(ModCallbacks.MC_POST_UPDATE, EIDD.TrackPostUpdate)
EIDD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, EIDD.TrackNewRoom)
EIDD:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, EIDD.TrackNewLevel)
EIDD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, EIDD.StartGame)
EIDD:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, EIDD.EndGame)