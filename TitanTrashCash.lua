-- **************************************************************************
-- * TitanTrashCash.lua
-- *
-- * By: Keldor
-- **************************************************************************

local TITAN_TRASH_CASH_ID = 'TrashCash';
local ADDON_NAME = 'Titan Trash Cash';
local L = LibStub('AceLocale-3.0'):GetLocale('Titan', true);
local TitanTrashCash = LibStub('AceAddon-3.0'):NewAddon(TITAN_TRASH_CASH_ID, 'AceConsole-3.0', 'AceHook-3.0');
local ADDON_VERSION = GetAddOnMetadata('TitanTrashCash', 'Version');

-- **************************************************************************
-- NAME : TitanTrashCash:OnInitialize()
-- DESC : Is called by AceAddon when the addon is first loaded.
-- **************************************************************************
function TitanTrashCash:OnInitialize()
  --LibStub('AceConfig-3.0'):RegisterOptionsTable(ADDON_NAME, TitanFarmBuddy:GetConfigOption());
  LibStub('AceConfigDialog-3.0'):AddToBlizOptions(ADDON_NAME);
end

-- **************************************************************************
-- NAME : TitanTrashCash_OnLoad()
-- DESC : Registers the plugin upon it loading.
-- **************************************************************************
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

	self:RegisterEvent('BAG_UPDATE');
end




-- **************************************************************************
-- NAME : TitanTrashCash_GetButtonText()
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
        trashAmount = trashAmount + (count * tonumber(select(11, GetItemInfo(itemID))));
      end
    end
  end

	return TitanTrashCash:FormatMoney(trashAmount);
end

function TitanTrashCash:FormatMoney(amount)

  local str = '';
  local oneGold = 10000;
  local oneSilver = 100;

  gold = (math.floor(amount / oneGold) or 0)
  amount = amount - (gold * oneGold);
  silver = (math.floor(amount / oneSilver) or 0)
  copper = amount - (silver * oneSilver)

  if gold > 0 then
    str = TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-GoldIcon', true) .. tostring(gold) .. ' ';
    str = str .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-SilverIcon', true) .. tostring(silver) .. ' ';
  elseif silver > 0 then
    str = str .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-SilverIcon', true) .. tostring(silver) .. ' ';
  end
  str = str .. TitanTrashCash:GetIconString('Interface\\MoneyFrame\\UI-CopperIcon', true) .. tostring(copper);

  return str;
end

-- **************************************************************************
-- NAME : TitanTrashCash:GetIconString()
-- DESC : Gets an icon string.
-- **************************************************************************
function TitanTrashCash:GetIconString(icon, space)
  local fontSize = TitanPanelGetVar('FontSize');
	local str = '|T' .. icon .. ':' .. fontSize .. ':' .. fontSize .. ':2:0|t';
	if space == true then
		str = str .. ' ';
	end
	return str;
end


-- **************************************************************************
-- NAME : TitanTrashCash_OnClick()
-- DESC : Handles click events to the Titan Button.
-- **************************************************************************
function TitanTrashCash_OnClick(self, button)
	if (button == 'LeftButton') then
		-- Workarround for opening controls instead of AddOn options
		-- Call it two times to ensure the AddOn panel is opened
		--InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
		--InterfaceOptionsFrame_OpenToCategory(ADDON_NAME);
 	end
end

-- **************************************************************************
-- NAME : TitanTrashCash_GetTooltipText()
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
function TitanTrashCash_OnEvent(self, event, ...)


	TitanPanelButton_UpdateButton(TITAN_TRASH_CASH_ID);
end

-- **************************************************************************
-- NAME : TitanTrashCash_OnShow()
-- DESC : Display button when plugin is visible.
-- **************************************************************************
function TitanTrashCash_OnShow(self)
	TitanPanelButton_OnShow(self);
end
