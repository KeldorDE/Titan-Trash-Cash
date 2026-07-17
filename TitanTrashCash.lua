-- **************************************************************************
-- * TitanTrashCash.lua
-- *
-- * By: Keldor
-- **************************************************************************

local TITAN_TRASH_CASH_ID = 'TrashCash'
local ADDON_NAME = 'Titan Trash Cash'
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true)
local TitanTrashCash = LibStub('AceAddon-3.0'):NewAddon(TITAN_TRASH_CASH_ID, 'AceEvent-3.0')
local TRASH_COLOR_HEX = ''

-- Throttling / caching state for bag scans.
local UPDATE_THROTTLE = 0.1
local updatePending = false
local cachedTrashData
local maxBags

---Registers the plugin upon it loading.
---@param self Button The Titan plugin button.
function TitanTrashCash_OnLoad(self)
    self.registry = {
        id = TITAN_TRASH_CASH_ID,
        category = 'Information',
        version = TITAN_VERSION,
        menuText = ADDON_NAME,
        menuContextFunction = function(_, root) return TitanTrashCash:MenuGenerator(_, root) end,
        buttonTextFunction = function() return TitanTrashCash:GetButtonText() end,
        tooltipTitle = ADDON_NAME,
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
    self:RegisterEvent('BAG_UPDATE', 'BagUpdate')
    self:RegisterEvent('GET_ITEM_INFO_RECEIVED', 'ItemInfoReceived')

    TRASH_COLOR_HEX = select(4, C_Item.GetItemQualityColor(0))
    maxBags = self:GetMaxBags()

    -- Prime the cache so the first render has data available.
    cachedTrashData = self:GetTrashData()
end

---Calculates the money amount of trash items.
---@return string text
function TitanTrashCash:GetButtonText()
    local trashData = cachedTrashData or self:GetTrashData()
    return self:FormatMoney(trashData.Amount, false)
end

---Displays the tooltip text.
---@return string text
function TitanTrashCash:GetTooltipText()
    local trashData = cachedTrashData or self:GetTrashData()
    local str = ''

    if trashData.Count > 0 then
        local textIndex = ''
        if trashData.Count == 1 then
            textIndex = 'TRASH_CASH_ITEM'
        else
            textIndex = 'TRASH_CASH_ITEMS'
        end

        str = str .. L['TRASH_CASH_TOTAL'] .. ':\t' .. TitanUtils_GetHighlightText(trashData.Count) .. ' ' .. L[textIndex] .. '\n'
        str = str .. L['TRASH_CASH_AMOUNT'] .. ':\t' .. self:FormatMoney(trashData.Amount, true) .. '\n'

        if TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowTopItem') then
            str = str .. L['TRASH_CASH_TOP_ITEM'] .. ':\t|c' .. TRASH_COLOR_HEX .. trashData.TopItem.Name .. FONT_COLOR_CODE_CLOSE .. ' | ' .. self:FormatMoney(trashData.TopItem.Amount, true) .. '\n'
        end
    else
        str = L['TRASH_CASH_NO_TRASH']
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

    C_Timer.After(UPDATE_THROTTLE, function()
        updatePending = false
        cachedTrashData = self:GetTrashData()
        TitanPanelButton_UpdateButton(TITAN_TRASH_CASH_ID)
    end)
end

---Parses events registered to the plugin and acts on them.
function TitanTrashCash:BagUpdate()
    self:ScheduleUpdate()
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

---Gets the trash money amount and the total count of trash items.
---@return table data The trash data with Amount, Count and TopItem fields.
function TitanTrashCash:GetTrashData()
    local data = {
        Amount = 0,
        Count = 0,
        TopItem = {
            Name = '',
            Amount = 0,
        },
    }

    for bag = 0, maxBags do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)

            if itemInfo and itemInfo.quality == 0 then -- Check if the item's quality is "poor" (gray items)
                local itemName, _, _, _, _, _, _, _, _, _, itemSellPrice = C_Item.GetItemInfo(itemInfo.hyperlink)

                if itemSellPrice and itemSellPrice > 0 then
                    local stackCount = itemInfo.stackCount or 1
                    local itemTotalAmount = stackCount * itemSellPrice

                    data.Count = data.Count + stackCount
                    data.Amount = data.Amount + itemTotalAmount

                    if itemSellPrice > data.TopItem.Amount then
                        data.TopItem.Name = itemName
                        data.TopItem.Amount = itemSellPrice
                    end
                end
            end
        end
    end

    return data
end

---Formats the given amount of money in copper in human readable format.
---@param amount number The money amount in copper.
---@param tooltip boolean Whether the string is rendered in the tooltip.
---@return string text
function TitanTrashCash:FormatMoney(amount, tooltip)
    local str = ''
    local showIcon = TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowIcon')
    local showColoredText = TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowColoredText')
    local gold = math.floor(math.abs(amount / 10000))
    local silver = math.floor(math.abs((amount / 100) % 100))
    local copper = math.floor(math.abs(amount % 100))
    local amounts = {
        Gold = '',
        Silver = '',
        Copper = '',
    }

    if showIcon or tooltip then
        amounts.Gold = gold .. ' ' .. self:GetIconString('Interface\\MoneyFrame\\UI-GoldIcon')
        amounts.Silver = silver .. ' ' .. self:GetIconString('Interface\\MoneyFrame\\UI-SilverIcon')
        amounts.Copper = copper .. ' ' .. self:GetIconString('Interface\\MoneyFrame\\UI-CopperIcon')
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
        str = L['TRASH_CASH_TRASH'] .. ': '
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
    local id = TITAN_TRASH_CASH_ID

    local options = Titan_Menu.AddButton(root, L['TITAN_PANEL_OPTIONS'])
    Titan_Menu.AddSelector(options, id, L['TRASH_CASH_SHOW_TOP_ITEM'], 'ShowTopItem')
    Titan_Menu.AddSelector(options, id, L['TRASH_CASH_SHOW_GOLD_ONLY'], 'ShowGoldOnly')
end

---Gets an icon string.
---@param icon string The icon file path.
---@return string text
function TitanTrashCash:GetIconString(icon)
    local fontSize = TitanPanelGetVar('FontSize')
    return '|T' .. icon .. ':' .. fontSize .. '|t'
end
