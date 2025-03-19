---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework

local MIN_SYNC_INTERVAL = 7 * 60
local MAX_SYNC_INTERVAL = 13 * 60
local BFC_PUBLISH_DELAY = 60
local BFC_PUBLISH_PREFIX = "BFC_PUB"
local BFC_UNPUBLISH_PREFIX = "BFC_UNPUB"

---------------------------------------------------------------------
-- timer
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
        timer = C_Timer.NewTimer(random(MIN_SYNC_INTERVAL, MAX_SYNC_INTERVAL), function()
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
-- receiving
---------------------------------------------------------------------
local function BFCPublishReceived(data, _, channel)
    if channel ~= BFC.channelName then return end
    print(data)
end
AF.RegisterComm(BFC_PUBLISH_PREFIX, BFCPublishReceived)

local function PFCUnpublishReceived(id, _, channel)
    if channel ~= BFC.channelName then return end
    print(id)
end
AF.RegisterComm(BFC_UNPUBLISH_PREFIX, PFCUnpublishReceived)

---------------------------------------------------------------------
-- sending
---------------------------------------------------------------------
local data = {}
function BFC.UpdateSendingData()
    data = {
        id = BFC.battleTag,
        name = AF.player.fullName,
        class = AF.player.class,
        tagline = BFC_DB.publish.tagline,
        prof = BFC.GetLearnedProfessionString(),
    }
end

function BFC.Publish()
    if BFC.channelID == 0 then return end
    if AF.IsBlank(data.prof) or AF.IsBlank(data.id) then return end
    AF.SendCommMessage_Channel(BFC_PUBLISH_PREFIX, data, BFC.channelName)
end

function BFC.NotifyUnpublish()
    if BFC.channelID == 0 then return end
    if AF.IsBlank(BFC.battleTag) then return end
    AF.SendCommMessage_Channel(BFC_UNPUBLISH_PREFIX, BFC.battleTag, BFC.channelName)
end