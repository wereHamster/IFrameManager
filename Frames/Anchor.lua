
local FactoryInterface = { }
IFrameFactory("1.0"):Register("IFrameManager", "Anchor", FactoryInterface)

local backdropTable = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\AddOns\\IFrameManager\\Textures\\Border2.tga",
	tile = true, tileSize = 12, edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local function OnShow(self)
	--self:SetBackdropColor(0.4, 0.4, 0.4, 1)
end

local function OnEnter(self)
	IFrameManager:Highlight(self:GetParent())
end

local function getRoot(frame)
	local layout = IFrameManagerLayout[frame:GetName()]
	if (layout[2] == "UIParent") then
		return frame
	end

	local root, parent = getRoot(getglobal(layout[2]))
	return root, parent or frame
end

local function OnMouseDown(self)
	if (IFrameManager.Source == nil) then
		if (self:GetParent().Parent == UIParent) then
			return DEFAULT_CHAT_FRAME:AddMessage("invalid source")
		end

		IFrameManager.Source = self
		return
	end

	local src = IFrameManager.Source:GetParent()
	if (src == self:GetParent()) then
		DEFAULT_CHAT_FRAME:AddMessage("resetting layout")

		local parent = getglobal(IFrameManagerLayout[src.Parent:GetName()][2])
		IFrameManagerLayout[src.Parent:GetName()] = { "CENTER", "UIParent", "CENTER", 0, 0 }
		IFrameManager:Update(src.Parent)

		IFrameManager.Source = nil
		IFrameManager:Highlight(self:GetParent())
		IFrameManager:Highlight(parent.IFrameManager)

		return
	end

	local dst = self:GetParent()
	if (dst.Parent ~= UIParent and src.Parent == getRoot(dst.Parent)) then
		DEFAULT_CHAT_FRAME:AddMessage("circular dependency: "..(select(2, getRoot(dst.Parent)):GetName()))
		return
	end

	local layout = IFrameManagerLayout[src.Parent:GetName()]
	layout[1] = src.Anchors[IFrameManager.Source]
	layout[2] = dst.Parent:GetName()
	layout[3] = dst.Anchors[self]
	IFrameManager:Update(src.Parent)

	IFrameManager.Source = nil
	IFrameManager:Highlight(src)	
	IFrameManager:Highlight(dst)
end

local function OnLeave(self)
	IFrameManager:Highlight(self:GetParent())
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

