----------------------------------------------------------------------------------
--- Total RP 3
---	---------------------------------------------------------------------------
--- Copyright 2018 Renaud "Ellypse" Parize <ellypse@totalrp3.info> @EllypseCelwe
---
---	Licensed under the Apache License, Version 2.0 (the "License");
---	you may not use this file except in compliance with the License.
---	You may obtain a copy of the License at
---
---		http://www.apache.org/licenses/LICENSE-2.0
---
---	Unless required by applicable law or agreed to in writing, software
---	distributed under the License is distributed on an "AS IS" BASIS,
---	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
---	See the License for the specific language governing permissions and
---	limitations under the License.
----------------------------------------------------------------------------------

---@type TRP3_API
local _, TRP3_API = ...;
local Ellyb = TRP3_API.Ellyb;
---@type AddOn_TotalRP3
local AddOn_TotalRP3 = AddOn_TotalRP3;

local assert = assert;
local isInstanceOf = Ellyb.Assertions.isInstanceOf;
local after = C_Timer.After;
local bind = Ellyb.Functions.bind;

local MapScannersManager = {}
local registeredMapScans = {};


---@param scan MapScanner
function MapScannersManager.registerScan(scan)
	assert(isInstanceOf(scan, AddOn_TotalRP3.MapScanner, "scan"));

	registeredMapScans[scan:GetID()] = scan;
end

---@return MapScanner[]
function MapScannersManager.getAllScans()
	return registeredMapScans;
end

---@return MapScanner
function MapScannersManager.getByID(scanID)
	assert(registeredMapScans[scanID], ("Unknown scan id %s"):format(scanID));
	return registeredMapScans[scanID]
end

local displayedMapID;
function MapScannersManager.launchScan(scanID)
	assert(registeredMapScans[scanID], ("Unknown scan id %s"):format(scanID));
	---@type MapScanner
	local scan = registeredMapScans[scanID];
	TRP3_API.MapDataProvider:RemoveAllData();

	displayedMapID = AddOn_TotalRP3.Map.getDisplayedMapID()

	scan:Scan();
	local promise = Ellyb.Promise()

	if scan.duration > 0 then
		-- Resolve the promise after the scan duration
		after(scan.duration, bind(promise.Resolve, promise));
		TRP3_API.WorldMapButton.startCooldown(scan.duration);
		TRP3_API.ui.misc.playSoundKit(40216);
	else
		promise:Resolve();
	end

	promise:Success(function()
		-- If the displayed map changed
		if displayedMapID ~= AddOn_TotalRP3.Map.getDisplayedMapID() then
			return
		end
		scan:OnScanCompleted();
		TRP3_API.MapDataProvider:OnScan(scan:GetData(), scan:GetDataProviderTemplate())
		TRP3_API.ui.misc.playSoundKit(43493);
	end)

	return promise;
end

TRP3_API.MapScannersManager = MapScannersManager;