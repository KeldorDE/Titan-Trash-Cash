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

  local trashCount = 0;
  local trashAmount = 0;

  for bag = 0, 5 do
    for slot = 1, GetContainerNumSlots(bag) do
      local count, _, quality, _, _, _, _, _, itemID = select(2, GetContainerItemInfo(bag, slot));
      if itemID ~= nil and quality == 0 then
        local itemSellPrice = select(11, GetItemInfo(itemID));
        trashCount = trashCount + 1;
        trashAmount = trashAmount + (count * tonumber(itemSellPrice));
      end
    end
  end

	return TitanTrashCash:FormatMoney(trashAmount);
end

-- **************************************************************************
-- NAME : TitanTrashCash:GetTooltipText()
-- DESC : Display tooltip text.
-- **************************************************************************
function TitanTrashCash_GetTooltipText()

	local str = 'test';

	return str;
end

-- **************************************************************************
-- NAME : TitanTrashCash_OnEvent()
-- DESC : Parse events registered to plugin and act on them.
-- **************************************************************************
function TitanTrashCash:BagUpdate(self, event, ...)


	TitanPanelButton_UpdateButton(TITAN_TRASH_CASH_ID);
end

function TitanTrashCash:FormatMoney(amount)

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

  if showIcon then
    tmpTable['Gold'] = tostring(gold) .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-GoldIcon', true);
    tmpTable['Silver'] = tostring(silver) .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-SilverIcon', true);
    tmpTable['Copper'] = tostring(copper) .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-CopperIcon', true);
  else
    tmpTable['Gold'] = tostring(gold) .. L['TITAN_GOLD_GOLD'];
    tmpTable['Silver'] = tostring(silver) .. L['TITAN_GOLD_SILVER'];
    tmpTable['Copper'] = tostring(copper) .. L['TITAN_GOLD_COPPER'];
  end

  if showColoredText then
    tmpTable['Gold'] = '|cFFFFFF00' .. tmpTable['Gold'] .. FONT_COLOR_CODE_CLOSE;
    tmpTable['Silver'] = '|cFFCCCCCC' .. tmpTable['Silver'] .. FONT_COLOR_CODE_CLOSE;
    tmpTable['Copper'] = '|cFFFF6600' .. tmpTable['Copper'] .. FONT_COLOR_CODE_CLOSE;
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
-- NAME : TitanTrashCash:GetIconString()
-- DESC : Gets an icon string.
-- **************************************************************************
function TitanTrashCash:GetIconString(icon, space)
  local fontSize = TitanPanelGetVar('FontSize');
	local str = '|T' .. icon .. ':' .. fontSize .. '|t';
	if space == true then
		str = str .. ' ';
	end
	return str;
end

function TitanTrashCash:GetColoredString()

end
