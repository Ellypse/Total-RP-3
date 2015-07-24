----------------------------------------------------------------------------------
-- Total RP 3
--	---------------------------------------------------------------------------
--	Copyright 2015 Sylvain Cossement (telkostrasz@totalrp3.info)
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

-- WOW API
local loc = Storyline_API.locale.getText;
local pairs, tinsert = pairs, tinsert;
local CreateFrame = CreateFrame;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- CHOICE SELECTION
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local GetNumGossipOptions, GetGossipOptions, SelectGossipOption = GetNumGossipOptions, GetGossipOptions, SelectGossipOption;
local GetNumGossipAvailableQuests, GetGossipAvailableQuests, SelectGossipAvailableQuest = GetNumGossipAvailableQuests, GetGossipAvailableQuests, SelectGossipAvailableQuest;
local GetNumGossipActiveQuests, GetNumActiveQuests, GetNumAvailableQuests = GetNumGossipActiveQuests, GetNumActiveQuests, GetNumAvailableQuests;
local SelectAvailableQuest, SelectActiveQuest, SelectGossipActiveQuest = SelectAvailableQuest, SelectActiveQuest, SelectGossipActiveQuest;
local GetAvailableTitle, GetActiveTitle, GetAvailableQuestInfo, GetGossipActiveQuests = GetAvailableTitle, GetActiveTitle, GetAvailableQuestInfo, GetGossipActiveQuests;

local getQuestIcon, getQuestActiveIcon = Storyline_API.getQuestIcon, Storyline_API.getQuestActiveIcon;
local getQuestTriviality = Storyline_API.getQuestTriviality;

local selectionStrings = {};

local function getSelectionFontString(placeOn)
	local available;
	for _, button in pairs(selectionStrings) do
		if not button:IsShown() then
			available = button;
			break;
		end
	end
	if not available then
		available = CreateFrame("Button", "TRP3_StorylineChoiceString" .. #selectionStrings, TRP3_NPCDialogFrameGossipChoices, "TRP3_StorylineMultiChoiceButton");
		tinsert(selectionStrings, available);
	end
	available:Show();
	available:ClearAllPoints();
	available:SetPoint("LEFT", 10, 0);
	available:SetPoint("RIGHT", -10, 0);
	available:SetPoint("TOP", placeOn, "BOTTOM", 0, -5);
	return available;
end

function Storyline_API.selectFirstGossip()
	SelectGossipOption(1);
end

function Storyline_API.selectMultipleGossip(button)
	for _, button in pairs(selectionStrings) do
		button:Hide();
	end
	TRP3_API.ui.frame.configureHoverFrame(TRP3_NPCDialogFrameGossipChoices, button, "TOP");
	TRP3_NPCDialogFrameGossipChoices.Title:SetText(loc("SL_SELECT_DIALOG_OPTION"));
	local previous = TRP3_NPCDialogFrameGossipChoices.Title;
	local data = { GetGossipOptions() };
	local height = 40;
	for i = 1, GetNumGossipOptions() do
		local gossip, gossipType = data[(i * 2) - 1], data[(i * 2)];
		previous = getSelectionFontString(previous);
		previous.Text:SetText("|TInterface\\GossipFrame\\" .. gossipType .. "GossipIcon:25:25|t" .. gossip);
		previous:SetScript("OnClick", function(self)
			SelectGossipOption(i);
		end);
		height = height + 25;
	end
	TRP3_NPCDialogFrameGossipChoices:SetHeight(height);
end

function Storyline_API.selectFirstAvailable()
	SelectGossipAvailableQuest(1);
end

function Storyline_API.selectFirstGreetingAvailable()
	SelectAvailableQuest(1);
end
function Storyline_API.selectFirstGreetingActive()
	SelectActiveQuest(1);
end

function Storyline_API.selectMultipleAvailable(button)
	for _, button in pairs(selectionStrings) do
		button:Hide();
	end
	TRP3_API.ui.frame.configureHoverFrame(TRP3_NPCDialogFrameGossipChoices, button, "TOP");
	TRP3_NPCDialogFrameGossipChoices.Title:SetText(loc("SL_SELECT_AVAILABLE_QUEST"));
	local previous = TRP3_NPCDialogFrameGossipChoices.Title;
	local data = { GetGossipAvailableQuests() };
	local height = 40;
	for i = 1, GetNumGossipAvailableQuests() do
		local title, lvl, isTrivial, frequency, isRepeatable, isLegendary =
		data[(i * 6) - 5], data[(i * 6) - 4], data[(i * 6) - 3], data[(i * 6) - 2], data[(i * 6) - 1], data[(i * 6)];
		previous = getSelectionFontString(previous);
		previous.Text:SetText("|T" .. getQuestIcon(frequency, isRepeatable, isLegendary) .. ":20:20|t" .. title .. getQuestTriviality(isTrivial));
		previous:SetScript("OnClick", function(self)
			SelectGossipAvailableQuest(i);
		end);
		height = height + 25;
	end
	TRP3_NPCDialogFrameGossipChoices:SetHeight(height);
end

function Storyline_API.selectFirstActive()
	SelectGossipActiveQuest(1);
end

function Storyline_API.selectMultipleActive(button)
	for _, button in pairs(selectionStrings) do
		button:Hide();
	end
	TRP3_API.ui.frame.configureHoverFrame(TRP3_NPCDialogFrameGossipChoices, button, "TOP");
	TRP3_NPCDialogFrameGossipChoices.Title:SetText(loc("SL_SELECT_AVAILABLE_QUEST"));
	local previous = TRP3_NPCDialogFrameGossipChoices.Title;
	local data = { GetGossipActiveQuests() };
	local height = 40;
	for i = 1, GetNumGossipActiveQuests() do
		local title, lvl, isTrivial, isComplete, isRepeatable = data[(i * 5) - 4], data[(i * 5) - 3], data[(i * 5) - 2], data[(i * 5) - 1], data[(i * 5)];
		previous = getSelectionFontString(previous);
		previous.Text:SetText("|T" .. getQuestActiveIcon(isComplete) .. ":20:20|t" .. title .. getQuestTriviality(isTrivial));
		previous:SetScript("OnClick", function(self)
			SelectGossipActiveQuest(i);
		end);
		height = height + 25;
	end
	TRP3_NPCDialogFrameGossipChoices:SetHeight(height);
end

function Storyline_API.selectMultipleActiveGreetings(button)
	for _, button in pairs(selectionStrings) do
		button:Hide();
	end
	TRP3_API.ui.frame.configureHoverFrame(TRP3_NPCDialogFrameGossipChoices, button, "TOP");
	TRP3_NPCDialogFrameGossipChoices.Title:SetText(loc("SL_SELECT_AVAILABLE_QUEST"));
	local previous = TRP3_NPCDialogFrameGossipChoices.Title;
	local height = 40;
	for i = 1, GetNumActiveQuests() do
		local title, isComplete = GetActiveTitle(i);
		local isTrivial, frequency, isRepeatable, isLegendary = GetAvailableQuestInfo(i);
		previous = getSelectionFontString(previous);
		previous.Text:SetText("|T" .. getQuestActiveIcon(isComplete) .. ":20:20|t" .. title .. getQuestTriviality(isTrivial));
		previous:SetScript("OnClick", function(self)
			SelectActiveQuest(i);
		end);
		height = height + 25;
	end
	TRP3_NPCDialogFrameGossipChoices:SetHeight(height);
end

function Storyline_API.selectMultipleAvailableGreetings(button)
	local numActiveQuests = GetNumActiveQuests();
	local numAvailableQuests = GetNumAvailableQuests();

	for _, button in pairs(selectionStrings) do
		button:Hide();
	end
	TRP3_API.ui.frame.configureHoverFrame(TRP3_NPCDialogFrameGossipChoices, button, "TOP");
	TRP3_NPCDialogFrameGossipChoices.Title:SetText(loc("SL_SELECT_AVAILABLE_QUEST"));
	local previous = TRP3_NPCDialogFrameGossipChoices.Title;
	local height = 40;
	for i = 1, numAvailableQuests do
		local title, isComplete = GetAvailableTitle(i);
		local isTrivial, frequency, isRepeatable, isLegendary = GetAvailableQuestInfo(numActiveQuests + i);
		previous = getSelectionFontString(previous);
		previous.Text:SetText("|T" .. getQuestIcon(frequency, isRepeatable, isLegendary) .. ":20:20|t" .. title .. getQuestTriviality(isTrivial));
		previous:SetScript("OnClick", function(self)
			SelectAvailableQuest(i);
		end);
		height = height + 25;
	end
	TRP3_NPCDialogFrameGossipChoices:SetHeight(height);
end