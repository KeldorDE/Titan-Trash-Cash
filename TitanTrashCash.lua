-- **************************************************************************
-- * TitanTrashCash.lua
-- *
-- * By: Keldor
-- **************************************************************************

---@class TitanTrashCash : AceConsole, AceEvent, AceHook, AceTimer
local TitanTrashCash = LibStub('AceAddon-3.0'):NewAddon(TITAN_TRASH_CASH_ID, 'AceEvent-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)

-- Upvalues for the bag scan hot path.
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetItemInfo = C_Item.GetItemInfo
local floor = math.floor
local QUALITY_POOR = Enum.ItemQuality and Enum.ItemQuality.Poor or 0

-- Throttling / caching state for bag scans.
local updatePending = false
local maxBags

-- Reused across scans to avoid allocating a new table on every update.
local trashData = {
    Amount = 0,
    Count = 0,
    TopItem = {
        Name = '',
        Amount = 0,
    },
}

---Registers the plugin upon it loading.
---@param self any The Titan plugin button.
function TitanTrashCash_OnLoad(self)
    self.registry = {
        id = TITAN_TRASH_CASH_ID,
        name = TITAN_TRASH_CASH_ADDON_NAME,
        category = 'Information',
        version = TITAN_VERSION,
        menuText = TITAN_TRASH_CASH_ADDON_NAME,
        menuContextFunction = function(_, root) return TitanTrashCash:MenuGenerator(_, root) end,
        buttonTextFunction = function() return TitanTrashCash:GetButtonText() end,
        tooltipTitle = TITAN_TRASH_CASH_ADDON_NAME,
        tooltipTextFunction = function() return TitanTrashCash:GetTooltipText() end,
        icon = 'Interface\\AddOns\\TitanTrashCash\\TitanTrashCash',
        iconWidth = 0,
        controlVariables = {
            ShowIcon = true,
            ShowLabelText = true,
            ShowRegularText = false,
            ShowColoredText = true,
            DisplayOnRightSide = true
        },
        savedVariables = {
            ShowIcon = true,
            ShowLabelText = true,
            ShowColoredText = true,
            DisplayOnRightSide = false,
            ShowTopItem = true,
            ShowGoldOnly = false,
        },
    }
end

---Is called by AceAddon when the addon is first loaded.
function TitanTrashCash:OnInitialize()
    self:RegisterEvent('BAG_UPDATE', 'ScheduleUpdate')
    self:RegisterEvent('GET_ITEM_INFO_RECEIVED', 'ItemInfoReceived')

    maxBags = self:GetMaxBags()

    -- Prime the cache so the first render has data available.
    self:UpdateTrashData()
end

---Calculates the money amount of trash items.
---@return string text
function TitanTrashCash:GetButtonText()
    return self:FormatMoney(trashData.Amount, false)
end

---Displays the tooltip text.
---@return string text
function TitanTrashCash:GetTooltipText()
    local str = ''

    if trashData.Count > 0 then
        local textIndex = ''
        if trashData.Count == 1 then
            textIndex = 'TITAN_TRASH_CASH_ITEM'
        else
            textIndex = 'TITAN_TRASH_CASH_ITEMS'
        end

        str = str .. L['TITAN_TRASH_CASH_TOTAL'] .. ':\t' .. TitanUtils_GetHighlightText(tostring(trashData.Count)) .. ' ' .. L[textIndex] .. '\n'
        str = str .. L['TITAN_TRASH_CASH_AMOUNT'] .. ':\t' .. self:FormatMoney(trashData.Amount, true) .. '\n'

        if TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowTopItem') then
            str = str .. L['TITAN_TRASH_CASH_TOP_ITEM'] .. ':\t|c' .. TITAN_TRASH_CASH_TRASH_COLOR_HEX .. trashData.TopItem.Name .. FONT_COLOR_CODE_CLOSE .. ' | ' .. self:FormatMoney(trashData.TopItem.Amount, true) .. '\n'
        end
    else
        str = L['TITAN_TRASH_CASH_NO_TRASH']
    end

    return str
end

---Gets the maximum number of bags.
---@return number maxBags
function TitanTrashCash:GetMaxBags()
    return NUM_TOTAL_EQUIPPED_BAG_SLOTS or Constants.InventoryConstants.NumBagSlots
end

---Throttles bag scans. The triggering events (BAG_UPDATE, GET_ITEM_INFO_RECEIVED)
---can fire many times in quick succession, so the actual scan is coalesced into a
---single delayed call and the result is cached.
function TitanTrashCash:ScheduleUpdate()
    if updatePending then
        return
    end

    updatePending = true
    C_Timer.After(TITAN_TRASH_CASH_UPDATE_THROTTLE, TitanTrashCash.RunPendingUpdate)
end

---Callback of the throttle timer. Defined once so no closure is created per scan.
function TitanTrashCash.RunPendingUpdate()
    updatePending = false
    TitanTrashCash:UpdateTrashData()
    TitanPanelButton_UpdateButton(TITAN_TRASH_CASH_ID)
end

---GetItemInfo returns nil for items that are not cached yet, so their sell price is
---missing on the first scan. When the client delivers the data, re-scan so freshly
---looted trash is counted correctly.
---@param success boolean Whether the item info was successfully retrieved.
function TitanTrashCash:ItemInfoReceived(_, _, success)
    if success then
        self:ScheduleUpdate()
    end
end

---Rescans all bags and refreshes the cached trash data.
---@return table data The trash data with Amount, Count and TopItem fields.
function TitanTrashCash:UpdateTrashData()
    local amount, count = 0, 0
    local topItem = trashData.TopItem
    local topName, topAmount = '', 0

    for bag = 0, maxBags do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemInfo = GetContainerItemInfo(bag, slot)

            if itemInfo and itemInfo.quality == QUALITY_POOR then
                -- Querying by item ID avoids parsing the item link string.
                local itemName, _, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(itemInfo.itemID)

                if itemSellPrice and itemSellPrice > 0 then
                    local stackCount = itemInfo.stackCount or 1

                    count = count + stackCount
                    amount = amount + stackCount * itemSellPrice

                    if itemSellPrice > topAmount then
                        topName = itemName
                        topAmount = itemSellPrice
                    end
                end
            end
        end
    end

    trashData.Amount = amount
    trashData.Count = count
    topItem.Name = topName
    topItem.Amount = topAmount

    return trashData
end

---Formats the given amount of money in copper in human readable format.
---@param amount number The money amount in copper.
---@param tooltip boolean Whether the string is rendered in the tooltip.
---@return string text
function TitanTrashCash:FormatMoney(amount, tooltip)
    local str = ''
    local showIcon = TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowIcon')
    local showColoredText = TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowColoredText')
    amount = math.abs(amount)
    local gold = floor(amount / 10000)
    local silver = floor((amount / 100) % 100)
    local copper = floor(amount % 100)
    local amounts = {
        Gold = '',
        Silver = '',
        Copper = '',
    }

    if showIcon or tooltip then
        local fontSize = TitanPanelGetVar('FontSize')
        amounts.Gold = gold .. ' ' .. self:GetIconString('Interface\\MoneyFrame\\UI-GoldIcon', fontSize)
        amounts.Silver = silver .. ' ' .. self:GetIconString('Interface\\MoneyFrame\\UI-SilverIcon', fontSize)
        amounts.Copper = copper .. ' ' .. self:GetIconString('Interface\\MoneyFrame\\UI-CopperIcon', fontSize)
    else
        amounts.Gold = gold .. L['TITAN_GOLD_GOLD']
        amounts.Silver = silver .. L['TITAN_GOLD_SILVER']
        amounts.Copper = copper .. L['TITAN_GOLD_COPPER']
    end

    if showColoredText or tooltip then
        amounts.Gold = '|cFFFFFF00' .. amounts.Gold .. FONT_COLOR_CODE_CLOSE
        amounts.Silver = '|cFFCCCCCC' .. amounts.Silver .. FONT_COLOR_CODE_CLOSE
        amounts.Copper = '|cFFFF6600' .. amounts.Copper .. FONT_COLOR_CODE_CLOSE
    end

    if TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowLabelText') and not tooltip then
        str = L['TITAN_TRASH_CASH_TRASH'] .. ': '
    end

    if TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowGoldOnly') and not tooltip then
        str = str .. amounts.Gold
    else
        if gold > 0 then
            str = str .. amounts.Gold .. ' '
            str = str .. amounts.Silver .. ' '
        elseif silver > 0 then
            str = str .. amounts.Silver .. ' '
        end

        str = str .. amounts.Copper
    end

    return str
end

---Builds the right click menu using the modern Titan_Menu (Blizzard_Menu) API.
---Titan automatically adds the title, the control variables and the hide
---command, so they are not added here.
---@param root table The Titan_Menu root node.
function TitanTrashCash:MenuGenerator(_, root)
    local options = Titan_Menu.AddButton(root, L['TITAN_PANEL_OPTIONS'])
    Titan_Menu.AddSelector(options, TITAN_TRASH_CASH_ID, L['TITAN_TRASH_CASH_SHOW_TOP_ITEM'], 'ShowTopItem')
    Titan_Menu.AddSelector(options, TITAN_TRASH_CASH_ID, L['TITAN_TRASH_CASH_SHOW_GOLD_ONLY'], 'ShowGoldOnly')
end

---Gets an icon string.
---@param icon string The icon file path.
---@param fontSize number|nil The icon size, defaults to the Titan Panel font size.
---@return string text
function TitanTrashCash:GetIconString(icon, fontSize)
    return '|T' .. icon .. ':' .. (fontSize or TitanPanelGetVar('FontSize')) .. '|t'
end
