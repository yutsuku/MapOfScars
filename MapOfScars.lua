local Addon = CreateFrame("FRAME");

local compass;

local questPointsTable = {};

local pi = math.pi;
local halfPi = pi/2;
local quarterPi = pi/4;
local threeHalfPi = 3*pi/2;
local twoPi = 2*pi;

local fiveQuarterPi = 5*pi/4;
local threeQuarterPi = 3*pi/4;
local sevenQuarterPi = 7*pi/4

local floor = math.floor;
local sqrt = math.sqrt;
local arccos = math.acos;
local arctan2 = math.atan2;

local pairs = pairs;
local select = select;

local GetPlayerFacing = GetPlayerFacing;
local GetPlayerMapPosition = GetPlayerMapPosition;

local playerX, playerY;
local playerAngle = 0;



--TODO
--Get a better compass texture

--Attention
--Use coordinates to get angle, not to get distance
--For distance use GetDistanceSqToQuest - a lot more precise



local function round(num, idp)
	local mult = 10^(idp or 0);
	return floor(num * mult + 0.5) / mult;
end



---------------------------------------------



local function createCardinalDirection(direction)
	local fontFrame = CreateFrame("FRAME", "MapOfScars"..direction, compass);

	fontFrame:SetSize(340, 30);
	fontFrame:SetPoint("CENTER");

	fontFrame.font = compass:CreateFontString("MapOfScars"..direction.."Font", "ARTWORK", "GameFontNormal");
	fontFrame.font:SetFont("Interface\\AddOns\\Rising\\Futura-Condensed-Normal.TTF", 21, "OUTLINE");
	fontFrame.font:SetTextColor(0.8, 0.8, 0.8, 1);
	fontFrame.font:SetText(direction);
	fontFrame.font:SetPoint("CENTER", fontFrame, "CENTER", 0, 0);

	return fontFrame;
end


local function createQuestIcon(questID)
	local questFrame = CreateFrame("FRAME", "MapOfScarsQuestFrame"..questID, compass);

	questFrame.questID = questID;
	questFrame:SetSize(50, 50);
	questFrame:SetPoint("CENTER");

	questFrame.texture = questFrame:CreateTexture("MapOfScarsQuestFrame"..questID.."Texture");
	questFrame.texture:SetAllPoints(questFrame);
	questFrame.texture:SetTexture("Interface\\AddOns\\MapOfScars\\questIcon.blp");
	questFrame.texture:SetBlendMode("BLEND");
	questFrame.texture:SetVertexColor(1, 1, 1, 1);
	questFrame.texture:SetDrawLayer("OVERLAY", 5);

	questFrame:SetFrameStrata("HIGH");

	questFrame:Hide();

	questFrame:SetScript("OnEvent", function(self, event)
		if not select(2,QuestPOIGetIconInfo(self.questID)) then
			questPointsTable[self.questID] = nil;
			questFrame:Hide();
		end
	end);

	questFrame:RegisterEvent("QUEST_LOG_UPDATE");

	return questFrame;
end


local function createCompass()
	compass = CreateFrame("FRAME", "MapOfScars", UIParent);

	compass:SetSize(512, 64);
	compass:SetPoint("TOP", 0, -30);

	compass.texture = compass:CreateTexture("MapOfScarsBg");
	compass.texture:SetAllPoints(compass);
	compass.texture:SetTexture("Interface\\AddOns\\MapOfScars\\compass.blp")
	compass.texture:SetBlendMode("BLEND")
	compass.texture:SetVertexColor(0.9, 0.9, 1, 1)

	compass.north = createCardinalDirection("N");
	compass.south = createCardinalDirection("S");
	compass.west = createCardinalDirection("W");
	compass.east = createCardinalDirection("E");
end


local function getPlayerPosition()
	local x, y = GetPlayerMapPosition("player");
	return round(x*100,3), round(y*100,3); --, GetZoneText();
end

--you can also get the distance in yards with GetDistanceSqToQuest(questIDlog)
--used to measure angles
local function getDistanceTo(x, y)
	return sqrt((x-playerX)^2+(y-playerY)^2);
end

local function getPlayerFacing()
	local angle = threeHalfPi-GetPlayerFacing();
	if angle < 0 then
		return angle + twoPi;
	end
	return angle;
end

--angle to a certain point
local function getPlayerFacingAngle(x, y)
	local angle = arctan2(x-playerX, y-playerY);

	if angle > halfPi then
		angle = angle-halfPi;
	else
		angle = halfPi-angle;
	end


	--3rd quarter
	--if playerX > x and playerY > y then
	--4th quarter
	if playerX < x and playerY > y then
		angle = twoPi-angle;
		if angle > threeHalfPi and playerAngle < halfPi then
			angle = angle - twoPi;
		end
		--2nd quarter
	--elseif playerX > x and playerY < y then
		--1st quarter
	elseif playerX < x and playerY < y then
		if playerAngle > threeHalfPi then
			playerAngle = playerAngle - twoPi;
		end
	end

	return angle-playerAngle;
	
end



local function hideOtherCardinals(cardinal)
	compass.north.font:Hide();
	compass.south.font:Hide();
	compass.west.font:Hide();
	compass.east.font:Hide();
	cardinal.font:Show();
end


local function setCardinalDirections()
	if playerAngle < quarterPi then
		compass.east:SetPoint("CENTER", compass, "CENTER", (-playerAngle)*210, 0);
		hideOtherCardinals(compass.east);
	elseif playerAngle > sevenQuarterPi then
		compass.east:SetPoint("CENTER", compass, "CENTER", (twoPi-playerAngle)*210, 0);
		hideOtherCardinals(compass.east);
	elseif playerAngle < threeQuarterPi and playerAngle > quarterPi then
		compass.south:SetPoint("CENTER", compass, "CENTER", (halfPi-playerAngle)*210, 0);
		hideOtherCardinals(compass.south)
	elseif playerAngle < fiveQuarterPi and playerAngle > threeQuarterPi then
		compass.west:SetPoint("CENTER", compass, "CENTER", (pi-playerAngle)*210, 0);
		hideOtherCardinals(compass.west)
	else
		compass.north:SetPoint("CENTER", compass, "CENTER", (threeHalfPi-playerAngle)*210, 0);
		hideOtherCardinals(compass.north)
	end
end


local function setQuestsIcons()
	for questID, table in pairs(questPointsTable) do
		local angle = getPlayerFacingAngle(table.x, table.y);
		if table.frame then
			if angle < quarterPi and angle > -quarterPi then
				table.frame:SetPoint("CENTER", compass, "CENTER", angle*210, 0);
				table.frame:Show();
			else
				table.frame:Hide();
			end
		end
	end
end



local total = 0;
Addon:SetScript("OnUpdate", function(self, elapsed)
	total = total + elapsed;
	if(total > 0.02) then
		total = 0;
		playerAngle = getPlayerFacing();
		playerX, playerY = getPlayerPosition();
		setCardinalDirections();
		setQuestsIcons();
	end
end);


Addon:SetScript("OnEvent", function(self, event, ...)

		if event == "QUEST_LOG_UPDATE" or event == "QUEST_ACCEPTED" or event == "QUEST_POI_UPDATE" or event == "ZONE_CHANGED" then
			local numLines, numQuests = GetNumQuestLogEntries();
			for i = 1, numLines do
				local questID = select(9, GetQuestLogTitle(i));
				local _, x, y = QuestPOIGetIconInfo(questID);
				if x then	--if x is OK then y is aswell
					if type(questPointsTable[questID]) ~= "table" then
						questPointsTable[questID] = {};
					end
    				questPointsTable[questID].x = x*100; --{ x = x*100, y = y*100 , dist = sqrt(GetDistanceSqToQuest(i)) };
    				questPointsTable[questID].y = y*100;
    				questPointsTable[questID].dist = sqrt(GetDistanceSqToQuest(i));

    				if not questPointsTable[questID].frame then
    					questPointsTable[questID].frame = createQuestIcon(questID);
    				end
				end
			end
		elseif event == "PLAYER_ENTERING_WORLD" then
			playerX, playerY = getPlayerPosition();
			playerAngle = getPlayerFacing();
		elseif event == "PLAYER_LOGIN" then
			createCompass();
		end
		setQuestsIcons();
		setCardinalDirections();
		
end);


Addon:RegisterEvent("PLAYER_LOGIN");
Addon:RegisterEvent("PLAYER_ENTERING_WORLD");
--Addon:RegisterEvent("WORLD_MAP_UPDATE");
Addon:RegisterEvent("ZONE_CHANGED");
Addon:RegisterEvent("QUEST_ACCEPTED");
Addon:RegisterEvent("QUEST_LOG_UPDATE");
Addon:RegisterEvent("QUEST_POI_UPDATE");
