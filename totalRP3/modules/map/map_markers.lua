----------------------------------------------------------------------------------
-- Total RP 3
-- Map marker and coordinates system
--	---------------------------------------------------------------------------
--	Copyright 2014 Sylvain Cossement (telkostrasz@telkostrasz.be)
--
--	Licensed under the Apache License, Version 2.0 (the "License");
--	you may not use this file except in compliance with the License.
--	You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
--	Unless required by applicable law or agreed to in writing, software
--	distributed under the License is distributed on an "AS IS" BASIS,
--	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--	See the License for the specific language governing permissions and
--	limitations under the License.
----------------------------------------------------------------------------------

TRP3_API.map = {};

local Utils, Events, Globals = TRP3_API.utils, TRP3_API.events, TRP3_API.globals;
local Comm = TRP3_API.communication;
local setupIconButton = TRP3_API.ui.frame.setupIconButton;
local displayDropDown = TRP3_API.ui.listbox.displayDropDown;
local loc = TRP3_API.locale.getText;
local tinsert, assert, tonumber, pairs, _G, wipe = tinsert, assert, tonumber, pairs, _G, wipe;
local CreateFrame = CreateFrame;
local after = C_Timer.After;
local playAnimation = TRP3_API.ui.misc.playAnimation;
local tsize = Utils.table.size;
local getConfigValue = TRP3_API.configuration.getValue;

local CONFIG_UI_ANIMATIONS = "ui_animations";

local TRP3_ScanLoaderFramePercent, TRP3_ScanLoaderFrame = TRP3_ScanLoaderFramePercent, TRP3_ScanLoaderFrame;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Utils
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local GetPlayerMapPosition = GetPlayerMapPosition;
local GetPlayerMapAreaID = GetPlayerMapAreaID;
local GetCurrentMapAreaID = GetCurrentMapAreaID;

function TRP3_API.map.getCurrentCoordinates()
	local mapID = GetPlayerMapAreaID("player");
	local x, y = GetPlayerMapPosition("player");
	return mapID, x, y;
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Marker logic
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local WorldMapTooltip, WorldMapPOIFrame = WorldMapTooltip, WorldMapPOIFrame;
local MARKER_NAME_PREFIX = "TRP3_WordMapMarker";

local MAX_DISTANCE_MARKER = math.sqrt(0.5 * 0.5 + 0.5 * 0.5);

local function hideAllMarkers()
	local i = 1;
	while(_G[MARKER_NAME_PREFIX .. i]) do
		local marker = _G[MARKER_NAME_PREFIX .. i];
		marker:Hide();
		marker.scanLine = nil;
		i = i + 1;
	end
end

local function getMarker(i, tooltip)
	local marker = _G[MARKER_NAME_PREFIX .. i];
	if not marker then
		marker = CreateFrame("Frame", MARKER_NAME_PREFIX .. i, WorldMapButton, "TRP3_WorldMapUnit");
		marker:SetScript("OnEnter", function(self)
			WorldMapPOIFrame.allowBlobTooltip = false;
			WorldMapTooltip:Hide();
			WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			WorldMapTooltip:AddLine(self.tooltip, 1, 1, 1, true);
			local j = 1;
			while(_G[MARKER_NAME_PREFIX .. j]) do
				local markerWidget = _G[MARKER_NAME_PREFIX .. j];
				if markerWidget:IsVisible() and markerWidget:IsMouseOver() then
					local scanLine = markerWidget.scanLine;
					if scanLine then
						WorldMapTooltip:AddLine(scanLine, 1, 1, 1, true);
					end
				end
				j = j + 1;
			end
			WorldMapTooltip:Show();
		end);
		marker:SetScript("OnLeave", function()
			WorldMapPOIFrame.allowBlobTooltip = true;
			WorldMapTooltip:Hide();
		end);
	end
	marker.tooltip = "|cffff9900" .. (tooltip or "");
	return marker;
end

local function placeMarker(marker, x, y)
	local x = (x or 0) * WorldMapDetailFrame:GetWidth();
	local y = - (y or 0) * WorldMapDetailFrame:GetHeight();
	marker:ClearAllPoints();
	marker:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", x, y);
end

local function animateMarker(marker, x, y, directAnimation)
	if getConfigValue(CONFIG_UI_ANIMATIONS) then

		local distanceX = 0.5 - x;
		local distanceY = 0.5 - y;
		local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY);
		local factor = distance/MAX_DISTANCE_MARKER;

		if not directAnimation then
			after(4 * factor, function()
				marker:Show();
				marker:SetAlpha(0);
				playAnimation(_G[marker:GetName() .. "Bounce"]);
			end);
		else
			marker:Show();
			marker:SetAlpha(0);
			playAnimation(_G[marker:GetName() .. "Bounce"]);
		end
	else
		marker:Show();
	end
end

local DECORATION_TYPES = {
	HOUSE = "house",
	CHARACTER = "character"
}
TRP3_API.map.DECORATION_TYPES = DECORATION_TYPES;

local function decorateMarker(marker, decorationType)
	if not decorationType or decorationType == DECORATION_TYPES.CHARACTER then
		_G[marker:GetName() .. "Icon"]:SetTexture("Interface\\Minimap\\OBJECTICONS");
		_G[marker:GetName() .. "Icon"]:SetTexCoord(0, 0.125, 0, 0.125);
	elseif decorationType == DECORATION_TYPES.HOUSE then
		_G[marker:GetName() .. "Icon"]:SetTexture("Interface\\Minimap\\POIICONS");
		_G[marker:GetName() .. "Icon"]:SetTexCoord(0.357143, 0.422, 0, 0.036);
	end
end

local function displayMarkers(structure)
	if not WorldMapFrame:IsVisible() then
		return;
	end

	local count = tsize(structure.saveStructure);
	local i = 1;
	for key, entry in pairs(structure.saveStructure) do
		local marker = getMarker(i, structure.scanTitle);
		placeMarker(marker, entry.x, entry.y);

		decorateMarker(marker, DECORATION_TYPES.CHARACTER);

		-- Implementation can be adapted by decorator
		if structure.scanMarkerDecorator then
			structure.scanMarkerDecorator(key, entry, marker);
		end

		animateMarker(marker, entry.x, entry.y);
		i = i + 1;
	end
end

function TRP3_API.map.placeSingleMarker(x, y, tooltip, decorationType)
	hideAllMarkers();
	local marker = getMarker(1, tooltip);
	placeMarker(marker, x, y);
	animateMarker(marker, x, y, true);
	decorateMarker(marker, decorationType);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Scan logic
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local SCAN_STRUCTURES = {};
local currentMapID;

local function registerScan(structure)
	assert(structure and structure.id, "Must have a structure and a structure.id!");
	SCAN_STRUCTURES[structure.id] = structure;
	if structure.scanResponder and structure.scanCommand then
		Comm.broadcast.registerCommand(structure.scanCommand, structure.scanResponder);
	end
	if not structure.saveStructure then
		structure.saveStructure = {};
	end
	if structure.scanAssembler and structure.scanCommand then
		Comm.broadcast.registerP2PCommand(structure.scanCommand, function(...)
			structure.scanAssembler(structure.saveStructure, ...);
		end)
	end

end
TRP3_API.map.registerScan = registerScan;

local function launchScan(scanID)
	assert(SCAN_STRUCTURES[scanID], ("Unknown scan id %s"):format(scanID));
	local structure = SCAN_STRUCTURES[scanID];
	if structure.scan then
		hideAllMarkers();
		wipe(structure.saveStructure);
		structure.scan(structure.saveStructure);
		if structure.scanDuration then
			local mapID = GetCurrentMapAreaID();
			currentMapID = mapID;
			TRP3_WorldMapButton:Disable();
			setupIconButton(TRP3_WorldMapButton, "ability_mage_timewarp");
			TRP3_ScanLoaderFrame.time = structure.scanDuration;
			TRP3_ScanLoaderFrame:Show();
			TRP3_ScanLoaderAnimationRotation:SetDuration(structure.scanDuration);
			TRP3_ScanLoaderGlowRotation:SetDuration(structure.scanDuration);
			TRP3_ScanLoaderBackAnimation1Rotation:SetDuration(structure.scanDuration);
			TRP3_ScanLoaderBackAnimation2Rotation:SetDuration(structure.scanDuration);
			playAnimation(TRP3_ScanLoaderAnimation);
			playAnimation(TRP3_ScanFadeIn);
			playAnimation(TRP3_ScanLoaderGlow);
			playAnimation(TRP3_ScanLoaderBackAnimation1);
			playAnimation(TRP3_ScanLoaderBackAnimation2);
			TRP3_API.ui.misc.playSoundKit(40216);
			after(structure.scanDuration, function()
				TRP3_WorldMapButton:Enable();
				setupIconButton(TRP3_WorldMapButton, "icon_treasuremap");
				if mapID == GetCurrentMapAreaID() then
					if structure.scanComplete then
						structure.scanComplete(structure.saveStructure);
					end
					displayMarkers(structure);
					TRP3_API.ui.misc.playSoundKit(43493);
				end
				playAnimation(TRP3_ScanLoaderBackAnimationGrow1);
				playAnimation(TRP3_ScanLoaderBackAnimationGrow2);
				playAnimation(TRP3_ScanFadeOut);
				if getConfigValue(CONFIG_UI_ANIMATIONS) then
					after(1, function()
						TRP3_ScanLoaderFrame:Hide();
						TRP3_ScanLoaderFrame:SetAlpha(1);
					end);
				else
					TRP3_ScanLoaderFrame:Hide();
				end
			end);
		else
			if structure.scanComplete then
				structure.scanComplete(structure.saveStructure);
			end
			displayMarkers(structure);
			TRP3_API.ui.misc.playSoundKit(43493);
		end
	end
end
TRP3_API.map.launchScan = launchScan;

local function onButtonClicked(self)
	local structure = {};
	for scanID, scanStructure in pairs(SCAN_STRUCTURES) do
		if not scanStructure.canScan or scanStructure.canScan() == true then
			tinsert(structure, { Utils.str.icon(scanStructure.buttonIcon or "Inv_misc_enggizmos_20", 25) .. " " .. (scanStructure.buttonText or scanID), scanID});
		end
	end
	if #structure == 0 then
		tinsert(structure, {loc("MAP_BUTTON_NO_SCAN"), nil});
	end
	displayDropDown(self, structure, launchScan, 0, true);
end

local function onWorldMapUpdate()
	local mapID = GetCurrentMapAreaID();
	if currentMapID ~= mapID and not TRP3_WorldMapButton.doNotHide then
		currentMapID = mapID;
		hideAllMarkers();
	end
end

TRP3_API.events.listenToEvent(TRP3_API.events.WORKFLOW_ON_LOAD, function()
	setupIconButton(TRP3_WorldMapButton, "icon_treasuremap");
	TRP3_WorldMapButton.title = loc("MAP_BUTTON_TITLE");
	TRP3_WorldMapButton.subtitle = "|cffff9900" .. loc("MAP_BUTTON_SUBTITLE");
	TRP3_WorldMapButton:SetScript("OnClick", onButtonClicked);
	TRP3_ScanLoaderFrameScanning:SetText(loc("MAP_BUTTON_SCANNING"));

	TRP3_ScanLoaderFrame:SetScript("OnShow", function(self)
		self.refreshTimer = 0;
	end);
	TRP3_ScanLoaderFrame:SetScript("OnUpdate", function(self, elapsed)
		self.refreshTimer = self.refreshTimer + elapsed;
		local percent = math.ceil((self.refreshTimer / self.time) * 100);
		-- TRP3_ScanLoaderFramePercent:SetText(percent .. "%");
	end);

	Utils.event.registerHandler("WORLD_MAP_UPDATE", onWorldMapUpdate);
end);

local CONFIG_MAP_BUTTON_POSITION = "MAP_BUTTON_POSITION";
local getConfigValue, registerConfigKey = TRP3_API.configuration.getValue, TRP3_API.configuration.registerConfigKey;

local function placeMapButton(position)
	position = position or "BOTTOMLEFT";
	TRP3_WorldMapButton:SetParent(WorldMapFrame.UIElementsFrame);
	TRP3_ScanLoaderFrame:SetParent(WorldMapFrame.UIElementsFrame);
	TRP3_WorldMapButton:ClearAllPoints();
	TRP3_WorldMapButton:SetPoint(position, WorldMapFrame, position, position:find("LEFT") and 10 or -10, position:find("BOTTOM") and 10 or -10);
end

TRP3_API.events.listenToEvent(TRP3_API.events.WORKFLOW_ON_LOADED, function()
	registerConfigKey(CONFIG_MAP_BUTTON_POSITION, "BOTTOMLEFT");

	tinsert(TRP3_API.configuration.CONFIG_FRAME_PAGE.elements, {
		inherit = "TRP3_ConfigH1",
		title = loc("CO_MAP_BUTTON"),
	});

	tinsert(TRP3_API.configuration.CONFIG_FRAME_PAGE.elements, {
		inherit = "TRP3_ConfigDropDown",
		widgetName = "TRP3_ConfigurationFrame_MapButtonWidget",
		title = loc("CO_MAP_BUTTON_POS"),
		listContent = {
			{loc("CO_ANCHOR_BOTTOM_LEFT"), "BOTTOMLEFT"},
			{loc("CO_ANCHOR_TOP_LEFT"), "TOPLEFT"},
			{loc("CO_ANCHOR_BOTTOM_RIGHT"), "BOTTOMRIGHT"},
			{loc("CO_ANCHOR_TOP_RIGHT"), "TOPRIGHT"}
		},
		listCallback = placeMapButton,
		listCancel = true,
		configKey = CONFIG_MAP_BUTTON_POSITION,
	});

	placeMapButton(getConfigValue(CONFIG_MAP_BUTTON_POSITION));

end);