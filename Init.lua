---@class BFC
local BFC = select(2, ...)
BFC.name = "BFCraftsman"
BFC.channelName = "BFCraftsman"
BFC.channelID = 0

_G.BFCraftsman = BFC

local L = BFC.L

---@type AbstractFramework
local AF = _G.AbstractFramework

AF.RegisterAddon(BFC.name, "BFC")


---------------------------------------------------------------------
-- functions
---------------------------------------------------------------------
function BFC.IsStale(lastUpdate)
    return time() - lastUpdate > 1800 -- 30 minutes
end

function BFC.GetProfessionString(profs, size)
    local text = ""
    for id in pairs(profs) do
        local icon = AF.GetProfessionIcon(id)
        text = text .. AF.EscapeIcon(icon, size)
    end
    return text
end

local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_DeactivateChat = ChatEdit_DeactivateChat
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend

function BFC.SendWhisper(name)
    local editBox = ChatEdit_ChooseBoxForSend()
    ChatEdit_DeactivateChat(editBox)
    ChatEdit_ActivateChat(editBox)
    editBox:SetText("/w " .. name .. " ")
end

---------------------------------------------------------------------
-- events
---------------------------------------------------------------------
AF.AddEventHandler(BFC)
BFC:RegisterEvent("ADDON_LOADED", function(_, _, addon)
    if addon == BFC.name then
        -- BFC:UnregisterEvent("ADDON_LOADED")
        if type(BFC_DB) ~= "table" then
            BFC_DB = {
                scale = 1,
                publish = {
                    enabled = false,
                    tagline = "",
                    characters = {
                        -- {
                        --     name = (string),
                        --     class = (string),
                        --     prof1 = {
                        --         id = (number),
                        --         lastScanned = (number),
                        --         recipes = {},
                        --         allRecipesLearned = false,
                        --     },
                        --     prof2 = {...},
                        -- },
                    },
                },
                list = {},
                favorite = {},
                blacklist = {},
                showStale = false,
                showBlacklisted = false,
            }
        end
        BFCMainFrame:SetScale(BFC_DB.scale)

    elseif addon == "Blizzard_ProfessionsCustomerOrders" then
        BFC:UnregisterEvent("ADDON_LOADED")

        -- order form button
        local button = AF.CreateButton(ProfessionsCustomerOrdersFrame.Form, L["Find Craftsmen"], "accent", 120, 20)
        AF.SetPoint(button, "BOTTOMRIGHT", ProfessionsCustomerOrdersFrame.Form, "TOPRIGHT", -2, 7)
        button:SetOnClick(BFC.ShowListFrame)
        button:SetOnHide(BFC.HideListFrame)

        -- hooksecurefunc(Professions, "CreateNewOrderInfo", function(...)
        --     print(...)
        -- end)

        -- hooksecurefunc(ProfessionsCustomerOrdersFrame.Form, "Init", function(_, order)
        --     -- texplore(order)
        --     local recipeID = order.spellID
        --     -- texplore(C_TradeSkillUI.GetRecipeInfo(recipeID))
        --     texplore(C_TradeSkillUI.GetProfessionInfoByRecipeID(recipeID))
        -- end)

        -- prepare order info
        hooksecurefunc(ProfessionsCustomerOrdersFrame.Form, "InitSchematic", BFC.HandleOrderData)
    end
end)

local BNGetInfo = BNGetInfo
local ChatFrame_RemoveChannel = ChatFrame_RemoveChannel
BFC:RegisterEvent("PLAYER_LOGIN", function()
    -- disable channel message
    for i = 1, 10 do
        if _G["ChatFrame" .. i] then
            ChatFrame_RemoveChannel(_G["ChatFrame" .. i], BFC.channelName)
        end
    end

    -- prepare
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
-- disable ChatConfigFrame interaction
---------------------------------------------------------------------
hooksecurefunc("ChatConfig_CreateCheckboxes", function(frame, checkBoxTable, checkBoxTemplate, title)
    local name = frame:GetName()
    if name == "ChatConfigChannelSettingsLeft" then
        for i = 1, #checkBoxTable do
            local checkBox = _G[name .. "Checkbox" .. i]
            if checkBoxTable[i].channelName == BFC.channelName then
                AF.ShowMask(checkBox, L["Disabled by BFCraftsman"])
            else
                AF.HideMask(checkBox)
            end
        end
    end
end)

---------------------------------------------------------------------
-- slash
---------------------------------------------------------------------
SLASH_BFCRAFTSMAN1 = "/bfc"
SlashCmdList["BFCRAFTSMAN"] = function(msg)
    if msg == "reset" then
        BFC_DB = nil
        ReloadUI()
    elseif msg == "clear list" then
        wipe(BFC_DB.list)
        BFC.UpdateList()
    elseif msg == "clear favorite" then
        wipe(BFC_DB.favorite)
        BFC.UpdateList()
    elseif msg == "clear blacklist" then
        wipe(BFC_DB.blacklist)
        BFC.UpdateList()

    --@debug@
    elseif msg == "test" then
        local validSkillLine = {164, 165, 171, 197, 202, 333, 773, 755}
        for i = 1, 30 do
            BFC_DB.list["player" .. i] = {
               name = "Player" .. i,
               class = AF.GetClassFile(random(1, 13)),
               tagline = "This is a tagline " .. i,
               lastUpdate = time() - random(1, 10000),
               previousNames = {
                  ["Player" .. i] = true,
               },
               learnedRecipes = {},
               professions = {},
            }
            for j = 1, random(1, 3) do
                BFC_DB.list["player" .. i]["professions"][validSkillLine[random(1, 8)]] = (random() >= 0.5) and true or false
            end
        end
        BFC.UpdateList()
    --@end-debug@

    else
        BFC.ShowMainFrame()
    end
end