---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local BFCMainFrame = AF.CreateHeaderedFrame(AF.UIParent, "BFCMainFrame", "BFCraftsman", 350, 575)
BFCMainFrame:SetPoint("LEFT", AF.UIParent, "CENTER", 200, 0)

---------------------------------------------------------------------
-- BN events
---------------------------------------------------------------------
BFCMainFrame:RegisterEvent("BN_CONNECTED")
BFCMainFrame:RegisterEvent("BN_DISCONNECTED")
BFCMainFrame:SetScript("OnEvent", function()
    if BNConnected() then
        AF.HideMask(BFCMainFrame)
    else
        AF.ShowMask(BFCMainFrame, BN_CHAT_DISCONNECTED)
    end
end)

---------------------------------------------------------------------
-- init widgets
---------------------------------------------------------------------
local slider, switch
local function InitFrameWidgets()
    -- slider
    slider = AF.CreateSlider(BFCMainFrame.header, nil, 50, 1, 2, 0.05)
    AF.SetPoint(slider, "LEFT", BFCMainFrame.header, 5, 0)
    slider:SetEditBoxShown(false)
    slider:SetValue(BFC_DB.scale)
    slider:SetAfterValueChanged(function(value)
        BFC_DB.scale = value
        BFCMainFrame:SetScale(value)
        AF.UpdatePixelsForAddon()
    end)

    -- switch
    switch = AF.CreateSwitch(BFCMainFrame, 330, 20)
    AF.SetPoint(switch, "TOPLEFT", BFCMainFrame, "TOPLEFT", 10, -10)
    switch:SetLabels({
        {
            ["text"] = L["Browse"],
            ["onClick"] = AF.GetFireFunc("BFC_ShowFrame", "Browse")
        },
        {
            ["text"] = L["Publish"],
            ["onClick"] = AF.GetFireFunc("BFC_ShowFrame", "Publish")
        }
    })
    switch:SetSelectedValue("Browse")
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
local init
function BFC.ShowMainFrame()
    if not init then
        BFCMainFrame:UpdatePixels()
        InitFrameWidgets()
        init = true
    end
    BFCMainFrame:SetShown(not BFCMainFrame:IsShown())
end