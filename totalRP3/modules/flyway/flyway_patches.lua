----------------------------------------------------------------------------------
--- Total RP 3
--- Schema migration tool : Patches
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

TRP3_API.flyway.patches = {};

local Globals, Utils = TRP3_API.globals, TRP3_API.utils;
local pairs, wipe = pairs, wipe;

-- Delete notification system
TRP3_API.flyway.patches["3"] = function()
	if TRP3_Characters then
		for _, character in pairs(TRP3_Characters) do
			if 	character.notifications then
				wipe(character.notifications);
			end
			character.notifications = nil;
		end
	end
end

TRP3_API.flyway.patches["4"] = function()
	if TRP3_Configuration and TRP3_Configuration["register_mature_filter"] and TRP3_Configuration["register_mature_filter"] == "0" then
		TRP3_Configuration["register_mature_filter"] = false;
	end
end

TRP3_API.flyway.patches["5"] = function()
	-- Sanitize existing profiles
	TRP3_API.events.listenToEvent(TRP3_API.events.WORKFLOW_ON_FINISH, function()
		if TRP3_API.configuration.getValue("register_sanitization") then
			local sanitizeFullProfile = TRP3_API.register.sanitizeFullProfile;
			for _, profile in pairs(TRP3_Register.profiles) do
				sanitizeFullProfile(profile);
			end
		end
	end)
end

TRP3_API.flyway.patches["6"] = function()
	if not TRP3_Profiles then return end
	-- Run through all the profiles and upgrade the personality traits
	-- structure to upscale the values and copy them to a new field.
	--
	-- As the old maximum doesn't easily divide (or multiply) into whole
	-- numbers at most of the steps, we'll round the value to the nearest
	-- whole integer.
	--
	-- The field with the new value is called V2; we leave VA intact for
	-- backwards compatibility.
	--
	-- If for some reason there's already a V2 present, we leave it alone
	-- and don't migrate the value over.
	local scale = Globals.PSYCHO_MAX_VALUE_V2 / Globals.PSYCHO_MAX_VALUE_V1;
	for _, profile in pairs(TRP3_Profiles) do
		if profile.player then
			local characteristics = profile.player.characteristics;
			local psycho = characteristics and characteristics.PS;

			if psycho then
				for i = 1, #psycho do
					local trait = psycho[i];
					local value = trait.VA or Globals.PSYCHO_DEFAULT_VALUE_V1;

					trait.V2 = trait.V2 or math.floor((value * scale) + 0.5);
				end
			end
		end
	end
end

-- Patches potentially badly created profiles from chat links
TRP3_API.flyway.patches["7"] = function()
	if not (TRP3_Register and TRP3_Register.profiles) then return end
	for _, profile in pairs(TRP3_Register.profiles) do
		if not profile.link then
			profile.link = {};
		end
	end
end

-- Remove voting feature
TRP3_API.flyway.patches["8"] = function()
	if not TRP3_Profiles then return end
	for _, profile in pairs(TRP3_Profiles) do
		if profile.about then
			profile.about.vote = nil;
		end
	end
end

-- Reset glance bar coordinates
TRP3_API.flyway.patches["9"] = function()
	TRP3_API.events.listenToEvent(TRP3_API.events.WORKFLOW_ON_FINISH, function()
		if TRP3_API.register.resetGlanceBar then
			TRP3_API.register.resetGlanceBar();
		end
	end)
end

TRP3_API.flyway.patches["10"] = function()
	-- Migrate contrast settings to the new common one
	if TRP3_Configuration then
		if TRP3_Configuration["chat_color_contrast"] or TRP3_Configuration["tooltip_char_contrast"] then
			TRP3_Configuration["increase_color_contrast"] = true;
		end

		TRP3_Configuration["chat_color_contrast"] = nil;
		TRP3_Configuration["tooltip_char_contrast"] = nil;
	end

	-- Migrate music paths to music IDs
	if TRP3_Profiles then
		for _, profile in pairs(TRP3_Profiles) do
			if profile.player and profile.player.about and profile.player.about.MU and type(profile.player.about.MU) == "string" then
				profile.player.about.MU = Utils.music.convertPathToID(profile.player.about.MU);
			end
		end
	end

	if TRP3_Register and TRP3_Register.profiles then
		for _, profile in pairs(TRP3_Register.profiles) do
			if profile.about and profile.about.MU and type(profile.about.MU) == "string" then
				profile.about.MU = Utils.music.convertPathToID(profile.about.MU) or tonumber(profile.about.MU);
			end
		end
	end
end

TRP3_API.flyway.patches["11"] = function()
	-- Add in the Roleplay Language (LC) field.
	if TRP3_Profiles then
		for _, profile in pairs(TRP3_Profiles) do
			if profile.player and profile.player.character then
				profile.player.character.LC = TRP3_Configuration["AddonLocale"] or GetLocale();
			end
		end
	end
end

-- Migrate from register from "BlackList" to "BlockList" and "WhiteList" to "SafeList" naming conventions.
TRP3_API.flyway.patches["12"] = function()
	if not TRP3_Register then return end
	if TRP3_Register.blackList then
		TRP3_Register.blockList = TRP3_Register.blackList;
		TRP3_Register.blackList = nil;
	end
	if not TRP3_Register.whiteList then
		TRP3_Register.safeList = TRP3_Register.whiteList;
		TRP3_Register.whiteList = nil;
	end
end
