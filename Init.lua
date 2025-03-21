---@class BFC
local BFC = select(2, ...)
BFC.name = "BFCraftsman"
BFC.channelName = "BFCraftsman"
BFC.channelID = 0

_G.BFCraftsman = BFC

---@type AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- events
---------------------------------------------------------------------
AF.AddEventHandler(BFC)

BFC:RegisterEvent("ADDON_LOADED", function(_, _, addon)
    if addon == BFC.name then
        BFC:UnregisterEvent("ADDON_LOADED")
        if type(BFC_DB) ~= "table" then
            BFC_DB = {
                publish = {
                    enabled = false,
                    tagline = "",
                    characters = {},
                },
                list = {},
                favorite = {},
                blacklist = {},
                showStale = false,
                showBlacklisted = false,
            }
        end
    end
end)

local BNGetInfo = BNGetInfo
BFC:RegisterEvent("PLAYER_LOGIN", function()
    local bTag = select(2, BNGetInfo())
    if bTag then
        BFC.battleTag = AF.Libs.MD5.sumhexa(bTag)
    end

    BFC.UpdateLearnedProfessions()
    BFC.UpdateLearnedRecipes()
    BFC.UpdateSendingData()
    BFC.ScheduleNextSync(true)
end)

local GetChannelName = GetChannelName
local JoinPermanentChannel = JoinPermanentChannel
local function PLAYER_ENTERING_WORLD()
    BFC.channelID = GetChannelName(BFC.channelName)
    if BFC.channelID == 0 then
        JoinPermanentChannel(BFC.channelName)
        C_Timer.After(5, function()
            -- check again
            PLAYER_ENTERING_WORLD()
        end)
    end
end
BFC:RegisterEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)

---------------------------------------------------------------------
-- slash
---------------------------------------------------------------------
SLASH_BFCRAFTSMAN1 = "/bfc"
SlashCmdList["BFCRAFTSMAN"] = function()
    BFC.ShowMainFrame()
end