---@class BFC
local BFC = select(2, ...)
BFC.name = "BFCraftsman"
BFC.channelName = "BFCraftsman"

_G.BFC = BFC

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
                tagline = "",
                characters = {},
                received = {},
            }
        end
    end
end)

BFC:RegisterEvent("PLAYER_LOGIN", function()
    BFC.UpdateLearnedProfessions()
    BFC.UpdateLearnedRecipes()
end)

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