local Addon = CreateFrame('Frame')
local compass
local POITable = {}

local pi = math.pi
local halfPi = pi/2 -- ~1.57
local quarterPi = pi/4 -- ~0.785
local threeHalfPi = 3*pi/2 -- ~4.71
local twoPi = 2*pi -- ~6.28

local fiveQuarterPi = 5*pi/4 -- ~3.925
local threeQuarterPi = 3*pi/4 -- ~2.355
local sevenQuarterPi = 7*pi/4 -- ~5.495

local floor = math.floor
local sqrt = math.sqrt
local arccos = math.acos
local arctan2 = math.atan2

local pairs = pairs
local select = select

local GetPlayerFacing = GetPlayerFacing
local GetPlayerMapPosition = GetPlayerMapPosition

local playerX, playerY
local playerAngle = 0

local FADE_IN = 0.3
local FADE_OUT = 0.3
local OPACITY_COMPASS = 0.7
local OPACITY_LABELS = 0.5

--TODO
--far away icons are smaller

--Attention
--Use coordinates to get angle, not to get distance
--For distance use GetDistanceSqToQuest - a lot more precise



---------------------------------------------
-- Useful functions
---------------------------------------------

local function round(num, idp)
	local mult = 10^(idp or 0)
	return floor(num * mult + 0.5) / mult
end

---------------------------------------------



local function createCardinalDirection(direction)
	local fontFrame = CreateFrame('Frame', 'MapOfScars'..direction, compass)

	fontFrame:SetWidth(340)
	fontFrame:SetHeight(30)
	fontFrame:SetPoint('CENTER', compass)

	fontFrame.font = compass:CreateFontString('MapOfScars'..direction..'Font', 'ARTWORK', 'GameFontNormal')
	fontFrame.font:SetFont([[Interface\AddOns\MapOfScars\Futura-Condensed-Normal.TTF]], 19)
	fontFrame.font:SetTextColor(0.8, 0.8, 0.8, OPACITY_LABELS)
	fontFrame.font:SetText(direction)
	fontFrame.font:SetPoint('CENTER', fontFrame, 'CENTER', 0, 0)

	return fontFrame;
end


local function createPOIIcon(ID, texture, width, height)
	local frame = CreateFrame('Frame', 'MapOfScarsPOI'..ID, compass)
	local icon = texture or [[Interface\AddOns\MapOfScars\Icons\Marker]]
	
	frame.ID = ID
	frame.width = width or 50
	frame.height = height or 50
	frame:SetWidth(frame.width)
	frame:SetHeight(frame.height)
	frame:SetPoint('CENTER', compass)

	frame.texture = frame:CreateTexture('MapOfScarsPOI'..ID..'Texture')
	frame.texture:SetAllPoints(frame)
	frame.texture:SetTexture(icon)
	frame.texture:SetBlendMode('BLEND')
	frame.texture:SetVertexColor(1, 1, 1, 1)
	frame.texture:SetDrawLayer('OVERLAY', 5)
	
	frame:SetFrameStrata('HIGH')
	frame:Hide()

	return frame
end


local function createCompass()
	compass = CreateFrame('Frame', 'MapOfScars', UIParent)

	compass:SetWidth(512)
	compass:SetHeight(64)
	compass:SetPoint('TOP', 0, -30)

	compass.texture = compass:CreateTexture('MapOfScarsBg')
	compass.texture:SetAllPoints(compass)
	compass.texture:SetTexture([[Interface\AddOns\MapOfScars\Compass-512]])
	compass.texture:SetBlendMode('BLEND')
	compass.texture:SetVertexColor(0.9, 0.9, 1, OPACITY_COMPASS)

	compass.north = createCardinalDirection('N')
	compass.south = createCardinalDirection('S')
	compass.west = createCardinalDirection('W')
	compass.east = createCardinalDirection('E')
end


local function getPlayerPosition()
	local x, y = GetPlayerMapPosition('player')
	return round(x*100,3), round(y*100,3) --, GetZoneText();
end

--you can also get the distance in yards with GetDistanceSqToQuest(questIDlog)
--used to measure angles
local function getDistanceTo(x, y)
	return sqrt((x-playerX)^2+(y-playerY)^2)
end

-- Backport function
local playerModel
local function GetPlayerFacing()
	local map;
	
	if not MapOfScarsGetPlayerFacing then
		map = CreateFrame('Minimap', 'MapOfScarsGetPlayerFacing', UIParent)
		map:SetWidth(0)
		map:SetHeight(0)
		map:SetPoint('TOPRIGHT', 0, 0)
		map:Show()
	else
		map = MapOfScarsGetPlayerFacing
	end

	if not playerModel then
		-- create custom minimap and try to hide everything from player
		-- needed due to player arrow not updating while original minimap
		-- is closed or hidden and the worldmap player arrow updates only
		-- when shown
		local model;
		for _,v in ipairs({map:GetChildren()}) do
			if v:GetFrameType() == 'Model' then
				model = v
				if not model:GetName() then	
					if strfind(model:GetModel(), 'Minimap\\MinimapArrow') then	
						playerModel = model
					end
					model:SetModelScale(0)
				end
			end
		end
	end
	
	return playerModel:GetFacing()
end

local function getPlayerFacing()
	local angle = threeHalfPi-GetPlayerFacing()
	if angle < 0 then
		return angle + twoPi
	end
	return angle
end

--angle to a certain point
local function getPlayerFacingAngle(x, y)
	local angle = arctan2(x-playerX, y-playerY)

	if angle > halfPi then
		angle = angle-halfPi
	else
		angle = halfPi-angle
	end

	if playerX < x and playerY > y then
		angle = twoPi-angle;
		if angle > threeHalfPi and playerAngle < halfPi then
			angle = angle - twoPi;
		end
	elseif playerX < x and playerY < y then
		if playerAngle > threeHalfPi then
			playerAngle = playerAngle - twoPi
		end
	end
	
	return angle-playerAngle
end



local function hideOtherCardinals(cardinal)
	compass.north.font:Hide()
	compass.south.font:Hide()
	compass.west.font:Hide()
	compass.east.font:Hide()
	cardinal.font:Show()
end


local function setCardinalDirections()
	if playerAngle < quarterPi then
		compass.east:SetPoint('CENTER', compass, 'CENTER', (-playerAngle) * 210, 0)
		hideOtherCardinals(compass.east)
	elseif playerAngle > sevenQuarterPi then
		compass.east:SetPoint('CENTER', compass, 'CENTER', (twoPi-playerAngle) * 210, 0)
		hideOtherCardinals(compass.east)
	elseif playerAngle < threeQuarterPi and playerAngle > quarterPi then
		compass.south:SetPoint('CENTER', compass, 'CENTER', (halfPi-playerAngle) * 210, 0)
		hideOtherCardinals(compass.south)
	elseif playerAngle < fiveQuarterPi and playerAngle > threeQuarterPi then
		compass.west:SetPoint('CENTER', compass, 'CENTER', (pi-playerAngle) * 210, 0)
		hideOtherCardinals(compass.west)
	else
		compass.north:SetPoint('CENTER', compass, 'CENTER', (threeHalfPi-playerAngle) * 210, 0)
		hideOtherCardinals(compass.north)
	end
end


local function setPOIIcons(elapsed)
	for index, table in pairs(POITable) do
		local angle = getPlayerFacingAngle(table.x, table.y)
		local skip = false
		
		if table.expire and table.time then
			table.time = table.time + elapsed
			if table.time > table.expire then
				UIFrameFadeOut(table.frame, FADE_OUT, 1.0, 0.0)
				POITable[index] = nil
				skip = true
			end
		end
		
		if table.frame and not skip then
			
			if angle < quarterPi and angle > -quarterPi then
				table.frame:SetPoint('CENTER', compass, 'CENTER', angle * 210, 0)
				local factor = table.dist
				if factor > 100 then
					factor = 100
				end
				table.frame:SetWidth(table.frame.width-factor/5)
				table.frame:SetHeight(table.frame.height-factor/5)
				table.frame:Show()
			elseif table.sticky then
				if angle > quarterPi then
					angle = quarterPi
				elseif angle < -quarterPi then
					angle = -quarterPi
				end
				table.frame:SetPoint('CENTER', compass, 'CENTER', angle * 210, 0)
				local factor = table.dist
				if factor > 100 then
					factor = 100
				end
				table.frame:SetWidth(table.frame.width-factor/5)
				table.frame:SetHeight(table.frame.height-factor/5)
				table.frame:Show()
			else
				table.frame:Hide()
			end
			
		end
		
	end
end


local function updatePOIDistances()
	for i = 1, table.getn(POITable) do
		if POITable[i] then
			--POITable[i].dist = sqrt(getDistanceTo(POITable[i].x, POITable[i].y));
			POITable[i].dist = getDistanceTo(POITable[i].x, POITable[i].y);
		end
	end
end

local function addPOI(index, x, y, texture, width, height, sticky, expire)
	local index = index or 1
	
	if not POITable[index] then
		POITable[index] = {};
	end
	
	POITable[index].x = x
	POITable[index].y = y
	POITable[index].dist = sqrt(getDistanceTo(x, y))

	if not POITable[index].frame then
		POITable[index].frame = createPOIIcon(index, texture, width, height)
	end
	
	if sticky then
		POITable[index].sticky = true
	end
	
	if expire then
		POITable[index].time = 0
		POITable[index].expire = expire
	end
end

Addon:SetScript('OnUpdate', function()
	playerAngle = getPlayerFacing()
	playerX, playerY = getPlayerPosition()
	
	updatePOIDistances()
	setCardinalDirections()
	setPOIIcons(arg1)
end)


Addon:SetScript('OnEvent', function()
	if event == 'PLAYER_ENTERING_WORLD' then
		playerX, playerY = getPlayerPosition()
		playerAngle = getPlayerFacing()
	elseif event == 'PLAYER_LOGIN' then
		createCompass()
	elseif event == 'MINIMAP_PING' then
		local x = arg2;
		local y = arg3;
		local pX, pY = getPlayerPosition()
		x = pX + ((x * 100)/2)
		y = pY + (-(y * 100)/2) -- this is either inaccurate or my hand are too shaky for pinging 
		addPOI('ping', x, y, [[Interface\AddOns\MapOfScars\Icons\Enemy]], 16, 16, true, 6)
		--DEFAULT_CHAT_FRAME:AddMessage(string.format("%s: %f, %f", arg1, x, y))
	end
end)

-- debug
--[[
mos_GetPlayerFacing = GetPlayerFacing;
mos_getPlayerFacing = getPlayerFacing;
mos_getPlayerFacingAngle = getPlayerFacingAngle;
mos_POITable = POITable;
function mos_create_test_point(x, y, texture, sticky, expire)
	local index = 1;
	if not x or not y then
		x = playerX;
		y = playerY;
		if y < 1 then y = y + 20 end
	end
	if not POITable[index] then
		POITable[index] = {};
	end
	POITable[index].x = x; --{ x = x*100, y = y*100 , dist = sqrt(GetDistanceSqToQuest(i)) };
	POITable[index].y = y;
	POITable[index].dist = sqrt(getDistanceTo(x, y));

	if not POITable[index].frame then
		POITable[index].frame = createPOIIcon(index, texture);
	end
	
	if sticky then
		POITable[index].sticky = true
	end
	
	if expire then
		POITable[index].time = 0
		POITable[index].expire = expire
	end

	local angle = getPlayerFacingAngle(x, y);
	
	DEFAULT_CHAT_FRAME:AddMessage("Created compass icon (" .. x .. ", " .. y .. ")", 0, 0.8, 1);
	DEFAULT_CHAT_FRAME:AddMessage("playerAngle: " .. getPlayerFacing(), 0, 0.8, 1);
	DEFAULT_CHAT_FRAME:AddMessage("GetPlayerFacing(): " .. GetPlayerFacing(), 0, 0.8, 1);
	DEFAULT_CHAT_FRAME:AddMessage("atan2(x-playerX, y-playerY | " .. x .. 
							" - " .. playerX .. ", " .. y .. " - " .. playerY ..
							") = " .. arctan2(x-playerX, y-playerY), 0, 0.8, 1);
	DEFAULT_CHAT_FRAME:AddMessage("getPlayerFacingAngle(x,y): " .. angle, 0, 0.8, 1);
	DEFAULT_CHAT_FRAME:AddMessage("==================================", 0, 0.8, 1);

end
]]

Addon:RegisterEvent('PLAYER_LOGIN')
Addon:RegisterEvent('PLAYER_ENTERING_WORLD')
--Addon:RegisterEvent("WORLD_MAP_UPDATE");
--Addon:RegisterEvent("ZONE_CHANGED");
--Addon:RegisterEvent("QUEST_ACCEPTED");
--Addon:RegisterEvent("QUEST_LOG_UPDATE");
--Addon:RegisterEvent("QUEST_POI_UPDATE");
Addon:RegisterEvent('MINIMAP_PING')
