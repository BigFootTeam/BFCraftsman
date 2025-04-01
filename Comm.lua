---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework

local SYNC_INTERVAL = 5 * 60 -- 5 minutes
-- local MIN_SYNC_INTERVAL = 5 * 60
-- local MAX_SYNC_INTERVAL = 10 * 60
local BFC_PUBLISH_DELAY = 30
local BFC_PUBLISH_PREFIX = "BFC_PUB"
local BFC_UNPUBLISH_PREFIX = "BFC_UNPUB"
local BFC_CHK_CRAFT_PREFIX = "BFC_CHK_CRAFT"
local BFC_CAN_CRAFT_PREFIX = "BFC_CAN_CRAFT"

---------------------------------------------------------------------
-- publish timer
---------------------------------------------------------------------
local timer
function BFC.ScheduleNextSync(useDelay)
    if useDelay then
        timer = C_Timer.NewTimer(BFC_PUBLISH_DELAY, function()
            if BFC_DB.publish.enabled then
                BFC.Publish()
                BFC.ScheduleNextSync()
            else
                BFC.NotifyUnpublish()
            end
        end)
    else
        timer = C_Timer.NewTimer(SYNC_INTERVAL, function()
            BFC.Publish()
            BFC.ScheduleNextSync()
        end)
    end
end

function BFC.CancelNextSync()
    if timer then
        timer:Cancel()
        timer = nil
    end
end

---------------------------------------------------------------------
-- receiving publish
---------------------------------------------------------------------
local function ProfessionProcessor(_, id)
    if id:find("!$") then
        return tonumber(id:sub(1, -2)), true
    else
        return tonumber(id), false
    end
end

local function PublishReceived(data, _, channel)
    if BFC_DB.blacklist[data[1]] then return end

    if not BFC_DB.list[data[1]] then
        BFC_DB.list[data[1]] = {
            previousNames = {},
            learnedRecipes = {},
        }
    end

    BFC_DB.list[data[1]].name = data[2]
    BFC_DB.list[data[1]].class = data[3]
    BFC_DB.list[data[1]].tagline = data[4]
    BFC_DB.list[data[1]].professions = AF.ConvertTable(AF.StringToTable(data[5], ","), ProfessionProcessor)
    BFC_DB.list[data[1]].lastUpdate = time()
    BFC_DB.list[data[1]].previousNames[strlower(AF.ToShortName(data[2]))] = true

    BFC.UpdateList()
end
AF.RegisterComm(BFC_PUBLISH_PREFIX, PublishReceived)

local function UnpublishReceived(id, _, channel)
    if BFC_DB.blacklist[id] then return end
    BFC_DB.list[id] = nil
    BFC.UpdateList()
end
AF.RegisterComm(BFC_UNPUBLISH_PREFIX, UnpublishReceived)

---------------------------------------------------------------------
-- sending publish
---------------------------------------------------------------------
local data = {}
function BFC.UpdateSendingData()
    data = {
        BFC.battleTag,
        AF.player.fullName,
        AF.player.class,
        BFC_DB.publish.tagline,
        BFC.GetLearnedProfessionString(),
    }
end

function BFC.Publish()
    if BFC.channelID == 0 then return end
    if AF.IsBlank(data[1]) then return end
    AF.SendCommMessage_Channel(BFC_PUBLISH_PREFIX, data, BFC.channelName)
end

function BFC.NotifyUnpublish()
    if BFC.channelID == 0 then return end
    if AF.IsBlank(BFC.battleTag) then return end
    AF.SendCommMessage_Channel(BFC_UNPUBLISH_PREFIX, BFC.battleTag, BFC.channelName)
end

---------------------------------------------------------------------
-- can craft
---------------------------------------------------------------------
function BFC.CheckCanCraft(id, recipeID)
    if BFC.channelID == 0 then return end
    AF.SendCommMessage_Channel(BFC_CHK_CRAFT_PREFIX, {id, recipeID}, BFC.channelName)
end

local function CheckCanCraftReceived(data, _, channel)
    if data[1] == BFC.battleTag then
        AF.SendCommMessage_Channel(BFC_CAN_CRAFT_PREFIX, {BFC.battleTag, data[2], BFC.learnedRecipes[data[2]]}, BFC.channelName)
    end
end
AF.RegisterComm(BFC_CHK_CRAFT_PREFIX, CheckCanCraftReceived)

local function CanCraftReceived(data, _, channel)
    local id, recipeID, canCraft = AF.Unpack3(data)
    if not BFC_DB.blacklist[id] and BFC_DB.list[id] then
        BFC_DB.list[id].learnedRecipes[recipeID] = canCraft
        BFC.NotifyCanCraft(id, recipeID, canCraft)
    end
end
AF.RegisterComm(BFC_CAN_CRAFT_PREFIX, CanCraftReceived)