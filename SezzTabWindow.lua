--[[

	s:UI Flat Tab Window Control

	Martin Karer / Sezz, 2014
	http://www.sezz.at

--]]

local MAJOR, MINOR = "Sezz:Controls:TabWindow-0.1", 1;
local APkg = Apollo.GetPackage(MAJOR);
if (APkg and (APkg.nVersion or 0) >= MINOR) then return; end

local SezzTabWindow = APkg and APkg.tPackage or {};
local log;
local Apollo, TableUtil = Apollo, TableUtil;

-- Lua API
local tinsert, pairs, ipairs, strmatch, strlen, strsub = table.insert, pairs, ipairs, string.match, string.len, string.sub;

-----------------------------------------------------------------------------

local wndMouseDown;
local kstrTabPrefix = "SezzTabWindowTab";
local kstrTabContainerPrefix = "SezzTabWindowTabContainer";
local knTabPrefixLength = strlen(kstrTabPrefix) + 1;

-----------------------------------------------------------------------------
-- Colors/Styling
-----------------------------------------------------------------------------

local knTabHeight = 36;
local knTabWidth = 118;
local knTabButtomLineHeight = 3;
local knTabSeparatorWidth = 1;
local knBorderSize = 2; -- WTB [Working Templates]
local knIconSize = 16;
local knTabTextPadding = 7;
local knTitleWidth = 146;

local ktTabColors = {
	BG			= "ff070c0d",
	Default		= "ff252525",
	Hover		= "ff3c3c3c",
	Active		= "ff618a68",
	Separator	= "ff5b5a58",
};

local ktCloseButtonColors = {
	Default	= "ff848484",
	Hover	= "ffc4c4c4",
	Active	= "ffffffff",
};

-----------------------------------------------------------------------------
-- Window Definitions
-----------------------------------------------------------------------------

-- Tab Window Defaults
local tXmlTabWindow = {
	__XmlNode = "Forms",
	{
		Name = "SezzTabWindow",
		LAnchorPoint = 0.25, TAnchorPoint = 0.25, RAnchorPoint = 0.25, BAnchorPoint = 0.25,
		LAnchorOffset = 0, TAnchorOffset = 0, RAnchorOffset = 0, BAnchorOffset = 0,
		IgnoreMouse = 1, Escapable = 0, NoClip = 0, Border = 0, Overlapped = 0, NoClip = 0, RelativeToClient = 1,
	},
};

-- Tab Window Attributes
local tXmlTabWindowAttributes = {
	__XmlNode = "Form",
	Class = "Window",
	Sprite = "SezzTabWindowSprites:Backdrop",
	BGColor = "white",
	Picture = 1,
	Border = 0,
--	Template = "Default",
	SwallowMouseClicks = 1,
	IgnoreMouse = 0,
	-- Events
	{ __XmlNode = "Event", Name = "WindowClosed", Function = "Close" },
--	{ __XmlNode = "Event", Name = "WindowKeyEscape", Function = "Close" },
	-- Close Button
	{
		__XmlNode = "Control",
		Class = "Window",
		Picture = 1,
		Border = 0,
		Sprite = "SezzTabWindowSprites:CloseButton",
		BGColor = "ff848484",
		LAnchorPoint = 1, TAnchorPoint = 0, RAnchorPoint = 1, BAnchorPoint = 0,
		LAnchorOffset = -knBorderSize - 10 - 20, TAnchorOffset = knBorderSize + (knTabHeight / 2) - 10, RAnchorOffset = -knBorderSize - 10, BAnchorOffset = knBorderSize + (knTabHeight / 2) + 10,
		IgnoreMouse = 0,
		-- Events
		{ __XmlNode = "Event", Name = "MouseEnter",			Function = "OnCloseButtonMouseEnter" },
		{ __XmlNode = "Event", Name = "MouseExit",			Function = "OnCloseButtonMouseExit" },
		{ __XmlNode = "Event", Name = "MouseButtonDown",	Function = "OnCloseButtonMouseDown" },
		{ __XmlNode = "Event", Name = "MouseButtonUp",		Function = "OnCloseButtonMouseUp" },
	},
	-- Bottom Line
	{
		__XmlNode = "Pixie",
		Sprite = "BasicSprites:WhiteFill",
		BGColor = ktTabColors.Active,
		LAnchorPoint = 0, TAnchorPoint = 0, RAnchorPoint = 1, BAnchorPoint = 0,
		LAnchorOffset = knBorderSize, TAnchorOffset = knTabHeight + knBorderSize, RAnchorOffset = -knBorderSize, BAnchorOffset = knTabHeight + knBorderSize + knTabButtomLineHeight,
	},
};

-- Tab
local tXmlTab = {
	__XmlNode = "Control",
	Class = "Window",
	Picture = 1,
	Border = 0,
	Sprite = "BasicSprites:WhiteFill",
	BGColor = ktTabColors.Default,
	RelativeToClient = 1,	
	LAnchorPoint = 0, TAnchorPoint = 0, RAnchorPoint = 0, BAnchorPoint = 0,
	LAnchorOffset = knBorderSize + knTitleWidth, TAnchorOffset = knBorderSize, RAnchorOffset = 0, BAnchorOffset = knBorderSize + knTabHeight,
	IgnoreMouse = 0,
	{
		__XmlNode = "Pixie",
		Font = "CRB_Pixel",
		BGColor = "white",
		DT_VCENTER = 1,
		LAnchorPoint = 0, TAnchorPoint = 0, RAnchorPoint = 1, BAnchorPoint = 1,
		LAnchorOffset = knTabTextPadding * 2, TAnchorOffset = 0, RAnchorOffset = 0, BAnchorOffset = -2,
	},
	-- Events
	{ __XmlNode = "Event", Name = "MouseEnter",			Function = "OnTabMouseEnter" },
	{ __XmlNode = "Event", Name = "MouseExit",			Function = "OnTabMouseExit" },
	{ __XmlNode = "Event", Name = "MouseButtonDown",	Function = "OnTabMouseDown" },
	{ __XmlNode = "Event", Name = "MouseButtonUp",		Function = "OnTabMouseUp" },
	-- Separator
	{
		__XmlNode = "Pixie",
		Sprite = "BasicSprites:WhiteFill",
		LAnchorPoint = 1, TAnchorPoint = 0, RAnchorPoint = 1, BAnchorPoint = 1,
		LAnchorOffset = -knTabSeparatorWidth, TAnchorOffset = 0, RAnchorOffset = 0, BAnchorOffset = 0,
		BGColor = ktTabColors.Separator,
	},
};

-- Tab Icon (Optional)
local tXmlPixieTabIcon = {
	__XmlNode = "Pixie",
	LAnchorPoint = 0, TAnchorPoint = 0.5, RAnchorPoint = 1, BAnchorPoint = 0.5,
	LAnchorOffset = knTabTextPadding * 2, TAnchorOffset = -knIconSize / 2, RAnchorOffset = 30, BAnchorOffset = knIconSize / 2,
	BGColor = "ffffffff",
};

-----------------------------------------------------------------------------
-- Private Methods
-----------------------------------------------------------------------------

local HideTab, ShowTab;

-----------------------------------------------------------------------------
-- Close Button Events
-----------------------------------------------------------------------------

function SezzTabWindow:OnCloseButtonMouseEnter(wndHandler, wndControl)
	if (wndHandler ~= wndControl) then return; end
	wndControl:SetBGColor(ktCloseButtonColors.Hover);
end

function SezzTabWindow:OnCloseButtonMouseExit(wndHandler, wndControl)
	if (wndHandler ~= wndControl) then return; end
	wndControl:SetBGColor(ktCloseButtonColors.Default);
end

function SezzTabWindow:OnCloseButtonMouseDown(wndHandler, wndControl, eMouseButton)
	if (wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left) then return; end
	wndMouseDown = wndControl;
	wndControl:SetBGColor(ktCloseButtonColors.Active);
end

function SezzTabWindow:OnCloseButtonMouseUp(wndHandler, wndControl, eMouseButton)
	if (wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left or wndMouseDown ~= wndControl) then return; end
	wndControl:SetBGColor(ktCloseButtonColors.Hover);
	self:Close();
end

-----------------------------------------------------------------------------
-- Constructor
-----------------------------------------------------------------------------

function SezzTabWindow:New(strTitle, tAttributes, wndParent)
	local self = setmetatable({
		wndParent = wndParent,
		tCallbacks = {},
		tTabs = {},
		tAttributes = tAttributes,
		nTabs = 0,
		strTitle = strTitle,
	}, { __index = self });

	self.tXml = TableUtil:Copy(tXmlTabWindow);

	for k, v in pairs(tAttributes) do
		if (type(k) == "number" and type(v) == "table") then
			tinsert(self.tXml[1], v);
		else
			self.tXml[1][k] = v;
		end
	end

	for k, v in pairs(tXmlTabWindowAttributes) do
		if (type(k) == "number" and type(v) == "table") then
			tinsert(self.tXml[1], v);
		else
			self.tXml[1][k] = v;
		end
	end

	return self;
end

-----------------------------------------------------------------------------
-- Show/Hide
-----------------------------------------------------------------------------

function SezzTabWindow:Show()
	if (self.bRendered and self.wndMain and self.wndMain:IsValid()) then
		self.wndMain:Show(true, true);
		self.wndMain:Enable(true);
		self.wndMain:ToFront();
	else
		self:Render();
	end

	self:Fire("WindowShow");
	return self;
end

function SezzTabWindow:Destroy()
	for strKey, tTab in pairs(self.tTabs) do
		self.tTabs[strKey] = false;
	end

	self.strActiveTab = nil;
	self.wndMain:Destroy();
	self.wndMain = nil;
	self.bRendered = false;
end

function SezzTabWindow:Close()
	self.wndMain:Show(false, true);
	self:Fire("WindowClosed");

	if (self.bDestroyOnClose) then
		self:Destroy();
	else
		self.wndMain:Enable(false);
	end
end

-----------------------------------------------------------------------------
-- Callbacks
-- I'm too stupid to use Callbackhandeler
-----------------------------------------------------------------------------

function SezzTabWindow:RegisterCallback(strEvent, strFunction, tEventHandler)
	if (not self.tCallbacks[strEvent]) then
		self.tCallbacks[strEvent] = {};
	end

	tinsert(self.tCallbacks[strEvent], { strFunction, tEventHandler });
end

function SezzTabWindow:Fire(strEvent, ...)
	if (self.tCallbacks[strEvent]) then
		for _, tCallback in ipairs(self.tCallbacks[strEvent]) do
			local strFunction = tCallback[1];
			local tEventHandler = tCallback[2];

			tEventHandler[strFunction](tEventHandler, ...);
		end
	end
end

-----------------------------------------------------------------------------
-- Add Tabs
-----------------------------------------------------------------------------

function SezzTabWindow:AddTab(strText, strIcon, strKey)
	self.nTabs = self.nTabs + 1;

	if (not strKey) then
		strKey = tostring(self.nTabs);
	end
	local strName = kstrTabPrefix..strKey;
	local strNameContainer = kstrTabContainerPrefix..strKey;

	local tXmlTab = TableUtil:Copy(tXmlTab);
	tXmlTab.Name = strName;
	tXmlTab.LAnchorOffset = tXmlTab.LAnchorOffset + (self.nTabs - 1) * (knTabWidth + knTabSeparatorWidth);
	tXmlTab.RAnchorOffset = tXmlTab.LAnchorOffset + knTabWidth + knTabSeparatorWidth;

	-- Icon
	if (strIcon) then
		local tXmlPixieTabIcon = TableUtil:Copy(tXmlPixieTabIcon);
		tXmlPixieTabIcon.Sprite = strIcon;
		tinsert(tXmlTab, tXmlPixieTabIcon);

		tXmlTab[1].LAnchorOffset = tXmlTab[1].LAnchorOffset + knIconSize + knTabTextPadding; -- Update Text Position
	end

	-- Title
	tXmlTab[1].Text = strText;

	-- Container
	tinsert(self.tXml[1], {
		__XmlNode = "Control",
		Class = "Window",
		Name = strNameContainer,
		RelativeToClient = 1,
		Movable = 0,
		Sizable = 0,
		Border = 0,
		LAnchorPoint = 0, TAnchorPoint = 0, RAnchorPoint = 1, BAnchorPoint = 1,
		LAnchorOffset = knBorderSize, TAnchorOffset = knBorderSize + knTabHeight + knTabButtomLineHeight, RAnchorOffset = -knBorderSize, BAnchorOffset = -knBorderSize,
		Visible = 0,
	});

	if (not self.strActiveTab) then
		self.strActiveTab = strKey;
	end

	-- Done
	tinsert(self.tXml[1], tXmlTab);
	self.tTabs[strKey] = false;
	return strKey;
end

-----------------------------------------------------------------------------
-- Tab Events
-----------------------------------------------------------------------------

function SezzTabWindow:OnTabMouseEnter(wndHandler, wndControl)
	if (wndHandler ~= wndControl) then return; end

	local strKey = strsub(wndControl:GetName(), knTabPrefixLength);
	if (not self.strActiveTab or self.strActiveTab ~= strKey) then
		wndControl:SetBGColor(ktTabColors.Hover);
	end
end

function SezzTabWindow:OnTabMouseExit(wndHandler, wndControl)
	if (wndHandler ~= wndControl) then return; end

	local strKey = strsub(wndControl:GetName(), knTabPrefixLength);
	if (not self.strActiveTab or self.strActiveTab ~= strKey) then
		wndControl:SetBGColor(ktTabColors.Default);
	end
end

function SezzTabWindow:OnTabMouseDown(wndHandler, wndControl, eMouseButton)
	if (wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left) then return; end

	wndMouseDown = wndControl;
	wndControl:SetBGColor(ktTabColors.Active);
end

function SezzTabWindow:OnTabMouseUp(wndHandler, wndControl, eMouseButton)
	if (wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left or wndMouseDown ~= wndControl) then return; end

	local strKey = strsub(wndControl:GetName(), knTabPrefixLength);

	if (not self.strActiveTab or self.strActiveTab ~= strKey) then
		self:SelectTab(strKey);
	end
end

-----------------------------------------------------------------------------
-- Tab Window Properties/Methods
-----------------------------------------------------------------------------

function SezzTabWindow:IsValid()
	return self.wndMain and self.wndMain:IsValid();
end

-----------------------------------------------------------------------------
-- Tab Properties/Methods
-----------------------------------------------------------------------------

local function HideTab(self, strKey, bDontUnsetActiveTab)
	if (not self.tTabs[strKey]) then return; end

	local tTab = self.tTabs[strKey];
	tTab.wndTab:SetBGColor(ktTabColors.Default);
	tTab.wndContainer:Enable(false);
	tTab.wndContainer:Show(false, true);

	if (not bDontUnsetActiveTab) then
		self.strActiveTab = nil;
	end
end

local function ShowTab(self, strKey)
	if (not self.tTabs[strKey]) then return; end

	if (self.strActiveTab) then
		HideTab(self, self.strActiveTab);
	end

	local tTab = self.tTabs[strKey];

	self.strActiveTab = strKey;
	tTab.wndTab:SetBGColor(ktTabColors.Active);
	tTab.wndContainer:Enable(true);
	tTab.wndContainer:Show(true, true);

	self:Fire("TabShow", strKey);
end

function SezzTabWindow:SelectTab(strKey)
	if (not self.tTabs[strKey]) then return; end

	self:Fire("TabSelected", strKey);
	ShowTab(self, strKey);
end

function SezzTabWindow:GetTabContainer(strKey)
	if (not self.tTabs[strKey]) then return; end

	return self.tTabs[strKey].wndContainer;
end

-----------------------------------------------------------------------------
-- Render (Load Form)
-----------------------------------------------------------------------------

function SezzTabWindow:Render()
	if (self.wndMain and self.wndMain:IsValid()) then
		Print("GTFO");
	end

	local xmlDoc = XmlDoc.CreateFromTable(self.tXml);
	self.wndMain = Apollo.LoadForm(xmlDoc, self.tXml[1].Name, self.wndParent, self);

	-- Add Pixies
	-- Sometimes the order gets f*cked up, so we're doing this here...

	-- Add Background Bar
	self.wndMain:AddPixie({
		strSprite = "BasicSprites:WhiteFill",
		cr = ktTabColors.BG,
		loc = {
			fPoints = { 0, 0, 1, 0 },
			nOffsets = { knBorderSize, knBorderSize, -knBorderSize, knTabHeight + knBorderSize },
		},
	});

	-- Add Title
	self.wndMain:AddPixie({
		strFont = "CRB_Pixel",
		cr = "white",
		loc = {
			fPoints = { 0, 0, 0, 0 },
			nOffsets = { knBorderSize, knBorderSize, knBorderSize + knTitleWidth, knTabHeight + knBorderSize },
		},
		flagsText = { DT_VCENTER = true, DT_CENTER = true },
		strText = self.strTitle,
	});

	-- Add Separator
	self.wndMain:AddPixie({
		cr = ktTabColors.Separator,
		strSprite = "BasicSprites:WhiteFill",
		loc = {
			fPoints = { 0, 0, 0, 0 },
			nOffsets = { knBorderSize + knTitleWidth - knTabSeparatorWidth, knBorderSize, knBorderSize + knTitleWidth, knTabHeight + knBorderSize },
		},
	});

	-- Done
	self.bRendered = true;

	-- Assign Tab References, Select Tab
	local strFirstTab;
	for strKey, wndTab in pairs(self.tTabs) do
		self.tTabs[strKey] = {
			wndTab = self.wndMain:FindChild(kstrTabPrefix..strKey),
			wndContainer = self.wndMain:FindChild(kstrTabContainerPrefix..strKey),
		};

		if (self.strActiveTab and self.strActiveTab == strKey) then
			self:SelectTab(strKey);
		else
			if (not strFirstTab) then
				strFirstTab = strKey;
			end

			HideTab(self, strKey, true);
		end
	end

	if ((not self.strActiveTab or (self.strActiveTab and not self.tTabs[self.strActiveTab]))) then
		self.strActiveTab = nil;
		if (strFirstTab) then
			self:SelectTab(strFirstTab);
		end
	end

	return self.wndMain;
end

-----------------------------------------------------------------------------
-- Apollo Registration
-----------------------------------------------------------------------------

function SezzTabWindow:OnLoad()
	-- Sprite loading snippet by Wildstar NASA (MIT)
	local strPrefix = Apollo.GetAssetFolder();
	local tToc = XmlDoc.CreateFromFile(Apollo.GetAssetFolder() .. "\\toc.xml"):ToTable();
	for k, v in ipairs(tToc) do
		local strPath = strmatch(v.Name, "(.*)[\\/]SezzTabWindow");
		if (strPath ~= nil and strPath ~= "") then
			strPrefix = strPrefix .. "\\" .. strPath .. "\\";
			break;
		end
	end

	local tSpritesXML = {
		__XmlNode = "Sprites",
		{
			__XmlNode="Sprite", Name="Backdrop", Cycle="1",
			{
				__XmlNode="Frame", Texture= strPrefix .."Backdrop.tga",
				x0="0", x1="0", x2="0", x3="2", x4="50", x5="52",
				y0="0", y1="0", y2="0", y3="2", y4="50", y5="52",
				HotspotX="0", HotspotY="0", Duration="1.000",
				StartColor="white", EndColor="white",
			},
		},
		{
			__XmlNode="Sprite", Name="CloseButton", Cycle="1",
			{
				__XmlNode="Frame", Texture= strPrefix .."CloseButton.tga",
				x0="0", x1="0", x2="0", x3="0", x4="0", x5="20",
				y0="0", y1="0", y2="0", y3="0", y4="0", y5="20",
				HotspotX="0", HotspotY="0", Duration="1.000",
				StartColor="white", EndColor="white",
			},
		},
	};

	local xmlSprites = XmlDoc.CreateFromTable(tSpritesXML);
	Apollo.LoadSprites(xmlSprites, "SezzTabWindowSprites");
end

function SezzTabWindow:OnDependencyError(strDep, strError)
	return false;
end

-----------------------------------------------------------------------------

Apollo.RegisterPackage(SezzTabWindow, MAJOR, MINOR, {});
