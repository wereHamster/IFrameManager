
local FactoryInterface = { }
IFrameFactory("1.0"):Register("IFrameManager", "Anchor", FactoryInterface)

local backdropTable = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\AddOns\\IFrameManager\\Textures\\Border2.tga",
	tile = true, tileSize = 12, edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local function OnShow(self)
	self:SetBackdropColor(0.4, 0.4, 0.4, 1)
end

local function OnEnter(self)
	self:SetBackdropColor(0, 1, 0)
end

local function getRoot(frame)
	local layout = IFrameManagerLayout[frame:GetName()]
	if (layout[2] == "UIParent") then
		return frame
	end

	return getRoot(getglobal(layout[2]))
end

local function OnMouseDown(self)
	if (IFrameManager.Source == nil) then
		if (self:GetParent().Parent:GetName() == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("invalid source")
			self:SetBackdropColor(0.4, 0.4, 0.4, 1)
			return
		end

		IFrameManager.Source = self
		return
	end

	local src = IFrameManager.Source:GetParent()
	if (src == self:GetParent()) then
		DEFAULT_CHAT_FRAME:AddMessage("resetting layout")
		IFrameManagerLayout[src.Parent:GetName()] = { "CENTER", "UIParent", "CENTER", 0, 0 }
		IFrameManager:Update(src.Parent)
		return
	end

	local dst = self:GetParent()
	if (src.Parent == getRoot(dst.Parent)) then
		DEFAULT_CHAT_FRAME:AddMessage("circular dependency")
		return
	end

	local layout = IFrameManagerLayout[src.Parent:GetName()]
	layout[1] = src.Anchors[IFrameManager.Source]
	layout[2] = dst.Parent:GetName()
	layout[3] = dst.Anchors[self]
	IFrameManager:Update(src.Parent)

	IFrameManager.Source:SetBackdropColor(0.4, 0.4, 0.4, 1)
	self:SetBackdropColor(0.4, 0.4, 0.4, 1)

	IFrameManager.Source = nil
end

local function OnLeave(self)
	if (IFrameManager.Source ~= self) then
		self:SetBackdropColor(0.4, 0.4, 0.4, 1)
	end
end

function FactoryInterface:Create()
	local frame = CreateFrame("Frame")
	frame:EnableMouse(true)
	frame:SetFrameStrata("HIGH")

	frame:SetBackdrop(backdropTable)
	frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
	frame:SetBackdropColor(0.4, 0.4, 0.4, 1)

	frame:SetScript("OnShow", OnShow)
	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnMouseDown", OnMouseDown)
	frame:SetScript("OnLeave", OnLeave)
	
	return frame
end

function FactoryInterface:Destroy(frame)
	return frame
end

