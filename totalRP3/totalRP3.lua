----------------------------------------------------------------------------------
--- Total RP 3
--- This file contains the addon main loading sequence.
--- ---------------------------------------------------------------------------
--- Copyright 2014 Sylvain Cossement (telkostrasz@telkostrasz.be)
--- Copyright 2014-2019 Renaud "Ellypse" Parize <ellypse@totalrp3.info> @EllypseCelwe
---
--- Licensed under the Apache License, Version 2.0 (the "License");
--- you may not use this file except in compliance with the License.
--- You may obtain a copy of the License at
---
--- 	http://www.apache.org/licenses/LICENSE-2.0
---
--- Unless required by applicable law or agreed to in writing, software
--- distributed under the License is distributed on an "AS IS" BASIS,
--- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--- See the License for the specific language governing permissions and
--- limitations under the License.
----------------------------------------------------------------------------------

---@type TRP3_API
local _, TRP3_API = ...;
---@type AddOn_TotalRP3
local AddOn_TotalRP3 = AddOn_TotalRP3;

-- Ellyb imports
local COLORS = TRP3_API.Ellyb.ColorManager;

-- Imports
local Globals = TRP3_API.globals;
local Log = TRP3_API.utils.log;
local loc = TRP3_API.loc;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- LOADING SEQUENCE
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local MAIN_SEQUENCE_ID, MAIN_SEQUENCE_DETAIL = "", "";

-- Called when TRP3 is loaded.
function Globals.addon:OnInitialize()
	TRP3_API.utils.event.registerHandler("SAVED_VARIABLES_TOO_LARGE", function(...)
		print(...);
	end);
end

local function loadingSequence()
	Log.log("OnEnable() START");

	--region Client check
	--[===[@non-debug@
	--@retail@
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		TRP3_API.Ellyb.Popups:OpenURL("https://www.curseforge.com/wow/addons/total-rp-3-classic", "You are trying to use the |cffff0000retail|r version of Total RP 3. Please install Total RP 3: Classic instead.");
		return;
	end
	--@end-retail@
	--[===[@non-retail@
	if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
		TRP3_API.Ellyb.Popups:OpenURL("https://www.curseforge.com/wow/addons/total-rp-3", "You are trying to use |cffff0000Total RP 3: Classic|r. Please install the retail version of Total RP 3 instead.");
		return;
	end
	--@end-non-retail@]===]
	--@end-non-debug@]===]
	--endregion

	MAIN_SEQUENCE_DETAIL = "VersionCheck";
	TRP3_API.checkVersion();

	-- Get info we can't have earlier
	MAIN_SEQUENCE_DETAIL = "Globals.build";
	Globals.build();

	-- Adapt saved variables structures between versions
	MAIN_SEQUENCE_DETAIL = "TRP3_API.flyway.applyPatches";
	TRP3_API.flyway.applyPatches();

	-- Inits locale
	MAIN_SEQUENCE_DETAIL = "TRP3_API.Locale.init";
	TRP3_API.Locale.init();

	MAIN_SEQUENCE_DETAIL = "TRP3_API.module.init";
	TRP3_API.module.init();

	-- Call the init callback on all modules
	MAIN_SEQUENCE_DETAIL = "TRP3_API.module.initModules";
	TRP3_API.module.initModules();

	-- Welcome \o/
	MAIN_SEQUENCE_DETAIL = "Welcome message";
	TRP3_API.utils.message.displayMessage(loc.GEN_WELCOME_MESSAGE:format(Globals.version_display));

	MAIN_SEQUENCE_DETAIL = "AddOn_TotalRP3.Communications.broadcast.init";
	AddOn_TotalRP3.Communications.broadcast.init();
	MAIN_SEQUENCE_DETAIL = "TRP3_API.profile.init";
	TRP3_API.profile.init();
	MAIN_SEQUENCE_DETAIL = "TRP3_API.dashboard.init";
	TRP3_API.dashboard.init();
	MAIN_SEQUENCE_DETAIL = "TRP3_API.navigation.init";
	TRP3_API.navigation.init();
	MAIN_SEQUENCE_DETAIL = "TRP3_API.register.init";
	TRP3_API.register.init();
	MAIN_SEQUENCE_DETAIL = "TRP3_API.popup.init";
	TRP3_API.popup.init();

	MAIN_SEQUENCE_DETAIL = "TRP3_API.events.fireEvent::WORKFLOW_ON_LOAD";
	TRP3_API.events.fireEvent(TRP3_API.events.WORKFLOW_ON_LOAD);

	-- Call module callback for all modules (onStart)
	MAIN_SEQUENCE_DETAIL = "TRP3_API.module.startModules";
	TRP3_API.module.startModules();

	-- Select first menu
	MAIN_SEQUENCE_DETAIL = "TRP3_API.navigation.menu.selectMenu";
	TRP3_API.navigation.menu.selectMenu("main_00_dashboard");

	MAIN_SEQUENCE_DETAIL = "TRP3_API.events.fireEvent::WORKFLOW_ON_LOADED";
	TRP3_API.events.fireEvent(TRP3_API.events.WORKFLOW_ON_LOADED);
	MAIN_SEQUENCE_DETAIL = "TRP3_API.events.fireEvent::WORKFLOW_ON_FINISH";
	TRP3_API.events.fireEvent(TRP3_API.events.WORKFLOW_ON_FINISH);

	MAIN_SEQUENCE_DETAIL = "TRP3_API.configuration.constructConfigPage";
	TRP3_API.configuration.constructConfigPage();

	TRP3_API.events.fireEvent(TRP3_API.events.NAVIGATION_RESIZED, TRP3_MainFramePageContainer:GetWidth(), TRP3_MainFramePageContainer:GetHeight());

	Log.log("OnEnable() DONE");
end

local MAIN_SEQUENCE_ERROR;
-- Called upon PLAYER_LOGIN after all addons are loaded.
function Globals.addon:OnEnable()
	MAIN_SEQUENCE_ID = "Globals.addon:OnEnable";
	if not Globals.DEBUG_MODE then
		local ok, errorMessage = pcall(loadingSequence);
		if not ok then
			MAIN_SEQUENCE_ERROR = errorMessage;
			TRP3_ShowErrorMessage();
			error("Error during TRP3 loading sequence: " .. errorMessage);
		end
	else
		loadingSequence();
	end
end

function TRP3_ShowErrorMessage()
	print(COLORS.ORANGE(("[TRP3: %s (%s)]"):format(TRP3_API.VERSION_DISPLAY, TRP3_API.BUILD_NUMBER)) .. " " .. COLORS.RED("Error during addon loading sequence:"));
	print(COLORS.ORANGE("Sequence ID: ") .. " " .. MAIN_SEQUENCE_ID);
	print(COLORS.ORANGE("Sub-sequence ID: ") .. " " .. MAIN_SEQUENCE_DETAIL);
	print(COLORS.ORANGE("Error message: ") .. " " .. tostring(MAIN_SEQUENCE_ERROR));
end
