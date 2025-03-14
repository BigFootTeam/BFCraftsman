---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local BFCMainFrame = AF.CreateHeaderedFrame(AF.UIParent, "BFCMainFrame", "BFCraftsman", 300, 510)
BFCMainFrame:SetPoint("LEFT", AF.UIParent, "CENTER", 200, 0)

---------------------------------------------------------------------
-- init widgets
---------------------------------------------------------------------
local switch
local function InitFrameWidgets()
    switch = AF.CreateSwitch(BFCMainFrame, 280, 20)
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