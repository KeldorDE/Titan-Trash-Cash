-- **************************************************************************
-- * TitanTrashCash.lua
-- *
-- * By: Keldor
-- **************************************************************************

local TITAN_TRASH_CASH_ID = 'TrashCash';
local ADDON_NAME = 'Titan Trash Cash';
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local TitanTrashCash = LibStub('AceAddon-3.0'):NewAddon(TITAN_TRASH_CASH_ID, 'AceConsole-3.0', 'AceEvent-3.0');
local ADDON_VERSION = GetAddOnMetadata('TitanTrashCash', 'Version');

function TitanTrashCash_OnLoad(self)
  self.registry = {
		id = TITAN_TRASH_CASH_ID,
		category = 'Information',
		version = TITAN_VERSION,
		menuText = ADDON_NAME,
		buttonTextFunction = 'TitanTrashCash_GetButtonText',
		tooltipTitle = ADDON_NAME,
		tooltipTextFunction = 'TitanTrashCash_GetTooltipText',
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
		}
	};
end

-- **************************************************************************
-- NAME : TitanTrashCash:OnInitialize()
-- DESC : Is called by AceAddon when the addon is first loaded.
-- **************************************************************************
function TitanTrashCash:OnInitialize()
	self:RegisterEvent('BAG_UPDATE', 'BagUpdate');
end

-- **************************************************************************
-- NAME : TitanTrashCash_GetButtonText()()
-- DESC : Calculate the money amount of trash items.
-- **************************************************************************
function TitanTrashCash_GetButtonText(id)
  local trashData = TitanTrashCash:GetTrashData();
  return TitanTrashCash:FormatMoney(trashData.Amount, false);
end

-- **************************************************************************
-- NAME : TitanTrashCash:GetTooltipText()
-- DESC : Display tooltip text.
-- **************************************************************************
function TitanTrashCash_GetTooltipText()

  local trashData = TitanTrashCash:GetTrashData();
	local str = '';

  if trashData.Count > 0 then

    local textIndex = '';
    if trashData.Count == 1 then
      textIndex = 'TRASH_CASH_ITEM';
    else
      textIndex = 'TRASH_CASH_ITEMS';
    end

    str = str .. L['TRASH_CASH_TOTAL'] .. ':\t' .. TitanUtils_GetHighlightText(trashData.Count) .. ' ' .. L[textIndex] .. '\n';
		str = str .. L['TRASH_CASH_AMOUNT'] .. ':\t' .. TitanTrashCash:FormatMoney(trashData.Amount, true) .. '\n';
  else
    str = L['TRASH_CASH_NO_TRASH'];
  end

	return str;
end

-- **************************************************************************
-- NAME : TitanTrashCash:BagUpdate()
-- DESC : Parse events registered to plugin and act on them.
-- **************************************************************************
function TitanTrashCash:BagUpdate(self, event, ...)
	TitanPanelButton_UpdateButton(TITAN_TRASH_CASH_ID);
end

-- **************************************************************************
-- NAME : TitanTrashCash:GetTrashData()
-- DESC : Gets the trash money amount the and total count of trash items.
-- **************************************************************************
function TitanTrashCash:GetTrashData()

  local data = {
    Amount = 0,
    Count = 0,
  };

  for bag = 0, 5 do
    for slot = 1, GetContainerNumSlots(bag) do
      local count, _, quality, _, _, _, _, _, itemID = select(2, GetContainerItemInfo(bag, slot));
      if itemID ~= nil and quality == 0 then
        local itemSellPrice = select(11, GetItemInfo(itemID));
        data.Count = data.Count + 1;
        data.Amount = data.Amount + (count * tonumber(itemSellPrice));
      end
    end
  end

  return data;
end

-- **************************************************************************
-- NAME : TitanTrashCash:FormatMoney()
-- DESC : Formats the given amount of money in copper in human readable format.
-- **************************************************************************
function TitanTrashCash:FormatMoney(amount, tooltip)

  local str = '';
  local showIcon = TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowIcon');
  local showColoredText = TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowColoredText');
  local gold = floor(abs(amount / 10000));
  local silver = floor(abs(mod(amount / 100, 100)));
  local copper = floor(abs(mod(amount, 100)));
  local tmpTable = {
    Gold = '',
    Silver = '',
    Copper = '',
  };

  if showIcon or tooltip == true then
    tmpTable['Gold'] = tostring(gold) .. " " .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-GoldIcon');
    tmpTable['Silver'] = tostring(silver) .. " " .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-SilverIcon');
    tmpTable['Copper'] = tostring(copper) .. " " .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-CopperIcon');
  else
    tmpTable['Gold'] = tostring(gold) .. L['TITAN_GOLD_GOLD'];
    tmpTable['Silver'] = tostring(silver) .. L['TITAN_GOLD_SILVER'];
    tmpTable['Copper'] = tostring(copper) .. L['TITAN_GOLD_COPPER'];
  end

  if showColoredText or tooltip == true then
    tmpTable['Gold'] = '|cFFFFFF00' .. tmpTable['Gold'] .. FONT_COLOR_CODE_CLOSE;
    tmpTable['Silver'] = '|cFFCCCCCC' .. tmpTable['Silver'] .. FONT_COLOR_CODE_CLOSE;
    tmpTable['Copper'] = '|cFFFF6600' .. tmpTable['Copper'] .. FONT_COLOR_CODE_CLOSE;
  end

  if TitanGetVar(TITAN_TRASH_CASH_ID, 'ShowLabelText') and tooltip == false then
    str = L['TRASH_CASH_TRASH'] .. ': ';
  end

  if gold > 0 then
    str = str .. tmpTable['Gold'] .. ' ';
    str = str .. tmpTable['Silver'] .. ' ';
  elseif silver > 0 then
    str = str .. tmpTable['Silver'] .. ' ';
  end
  str = str .. tmpTable['Copper'];

  return str;
end

-- **************************************************************************
-- NAME : TitanPanelRightClickMenu_PrepareTrashCashMenu()
-- DESC : Display rightclick menu options
-- **************************************************************************
function TitanPanelRightClickMenu_PrepareTrashCashMenu(frame, level, menuList)

	if level == 1 then

		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_TRASH_CASH_ID].menuText, level);

		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddToggleIcon(TITAN_TRASH_CASH_ID);
		TitanPanelRightClickMenu_AddToggleLabelText(TITAN_TRASH_CASH_ID);
		TitanPanelRightClickMenu_AddToggleColoredText(TITAN_TRASH_CASH_ID);
		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddCommand(L['TITAN_PANEL_MENU_HIDE'], TITAN_TRASH_CASH_ID, TITAN_PANEL_MENU_FUNC_HIDE);
	end
end

-- **************************************************************************
-- NAME : TitanTrashCash:GetIconString()
-- DESC : Gets an icon string.
-- **************************************************************************
function TitanTrashCash:GetIconString(icon)
  local fontSize = TitanPanelGetVar('FontSize');
  local str = '|T' .. icon .. ':' .. fontSize .. '|t';
  return str;
end
