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
-- DESC : Calculate the item count of the tracked farm item and displays it.
-- **************************************************************************
function TitanTrashCash_GetButtonText(id)

	local str = 'test';

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
