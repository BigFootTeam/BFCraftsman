---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local browseFrame
local function CreateBrowseFrame()
    browseFrame = AF.CreateBorderedFrame(BFCMainFrame, "BFCBrowseFrame", 280, 400)
    AF.SetPoint(browseFrame, "TOPLEFT", BFCMainFrame, "TOPLEFT", 10, -40)
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFC_ShowFrame", function(which)
    if which == "Browse" then
        if not browseFrame then
            CreateBrowseFrame()
        end
        browseFrame:Show()
    else
        if browseFrame then
            browseFrame:Hide()
        end
    end
end)