
local IFrameFactory = IFrameFactory("1.0")

IFrameManager = { List = { } }
IFrameManagerLayout = { }



--[[
		IFrameManager:Interface()

	This is an interface that all registered functions have to implement.
	It's used to get a display name, border width and other properties of
	the registered frame. Different frames can share one interface.
]]
local frameInterface = { }
local frameMetatable = { __index = frameInterface }

function frameInterface:getName(frame)
	return frame:GetName()
end

function frameInterface:getBorder(frame)
	return 0, 0, 0, 0
end

function IFrameManager:Interface()
	return setmetatable({ }, frameMetatable)
end



--[[
		IFrameManager:Register()

	Registers a frame within the IFrameManager core. Pass nil as the
	interface to remove the frame from the core.
]]
function IFrameManager:Register(frame, iface)
	self.List[frame] = iface
	IFrameManagerLayout[frame:GetName()] = IFrameManagerLayout[frame:GetName()] or { "CENTER", "UIParent", "CENTER", 0, 0 }
end



--[[
		IFrameManager:Enable()

	Initializes the edit mode where a overlay and anchor points are
	created for each frame. When the overlay is moved with the mouse,
	the underlying frame is also moved. Frames can be anchored together
	by clicking on the anchor boxes.
]]

local function CreateOverlay(frame, iface)
	local overlay = IFrameFactory:Create("IFrameManager", "Overlay")
	overlay.Parent = frame

	local t, r, b, l = iface:getBorder(frame)
	overlay:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -l, -b)
	overlay:SetPoint("TOPRIGHT", frame, "TOPRIGHT", t, r)

	overlay:EnableMouse(true)
	overlay:SetBackdropColor(0, 0, 0, 1)

	overlay.label:SetWidth(overlay:GetWidth())
	overlay.label:SetText(iface:getName(frame))

	-- Set up the anchors
	local anchors = { { }, { } }

	local height = math.floor(overlay:GetHeight() + 0.5)
	if (height >= 3 * 18) then
		table.insert(anchors[1], { "TOP", 16 })
		table.insert(anchors[1], { "", height - 2 * 18 })
		table.insert(anchors[1], { "BOTTOM", 16 })
	elseif (height >= 2 * 16) then
		table.insert(anchors[1], { "TOP", 16 })
		table.insert(anchors[1], { "BOTTOM", 16 })
	else
		table.insert(anchors[1], { "", height })
	end

	local width = math.floor(overlay:GetWidth() + 0.5)
	if (width >= 3 * 18) then
		table.insert(anchors[2], { "LEFT", 16 })
		table.insert(anchors[2], { "", width - 2 * 18 })
		table.insert(anchors[2], { "RIGHT", 16 })
	elseif (width >= 2 * 18) then
		table.insert(anchors[2], { "LEFT", 16 })
		table.insert(anchors[2], { "RIGHT", 16 })
	else
		table.insert(anchors[2], { "", width })
	end

	overlay.Anchors = { }
	for _, v in pairs(anchors[1]) do
		for _, h in pairs(anchors[2]) do
			local point = v[1] == "" and h[1] == "" and "CENTER" or v[1]..h[1]
			local anchor = IFrameFactory:Create("IFrameManager", "Anchor")
			overlay.Anchors[anchor] = point

			anchor:SetWidth(math.min(h[2], 40))
			anchor:SetHeight(math.min(v[2], 40))
			anchor:SetParent(overlay)
			anchor:SetPoint(point, overlay, point)
			anchor:Hide()
		end
	end

	return overlay
end

function IFrameManager:Enable()
	if (self.isEnabled) then
		return
	end
	
	for frame, iface in pairs(self.List) do
		frame.IFrameManager = CreateOverlay(frame, iface)
	end

	UIParent.IFrameManager:EnableMouse(false)
	UIParent.IFrameManager:SetBackdropColor(0, 0, 0, 0)

	self.isEnabled = true
end



--[[
		IFrameManager:Highlight()

	Updates the highlight colors of the frame and anchors.
]]

local function ColorizeAnchor(self, loc, ...)
	for frame, anchor in pairs(self.Anchors) do
		if (anchor == loc) then
			return frame:SetBackdropColor(...)
		end
	end
end

function IFrameManager:Highlight(frame)
	if (frame ~= UIParent.IFrameManager) then
		frame:SetBackdropColor(0, 0, 0, 1)
	end

	for anchor in pairs(frame.Anchors) do
		anchor:SetBackdropColor(0.4, 0.4, 0.4, 1)
	end

	local layout = IFrameManagerLayout[frame.Parent:GetName()]
	if (layout) then
		local target = getglobal(layout[2])
		if (MouseIsOver(frame)) then
			if (target ~= UIParent) then
				target.IFrameManager:SetBackdropColor(1, 0.4, 0.4, 1)
			end

			ColorizeAnchor(frame, layout[1], 1, 1, 0.4, 1)
			ColorizeAnchor(target.IFrameManager, layout[3], 1, 1, 0.4, 1)
		else
			if (target ~= UIParent) then
				target.IFrameManager:SetBackdropColor(0, 0, 0, 1)
			end

			ColorizeAnchor(frame, layout[1], 0.4, 0.4, 0.4, 1)
			ColorizeAnchor(target.IFrameManager, layout[3], 0.4, 0.4, 0.4, 1)
		end
	end

	if (IFrameManager.Source) then
		IFrameManager.Source:SetBackdropColor(0.4, 1, 1, 1)
	end

	for anchor in pairs(frame.Anchors) do
		if (MouseIsOver(anchor)) then
			anchor:SetBackdropColor(0, 1, 0, 1)
		end
	end
end

--[[
		IFrameManager:Update()

	Updates the anchors and position of a frame.
]]
local AnchorCoordinates = {
	["TOPLEFT"]	= function(self) return self:GetLeft(), self:GetTop() end,
	["LEFT"]	= function(self) return self:GetLeft(), self:GetBottom() + self:GetHeight() / 2 end,
	["BOTTOMLEFT"]	= function(self) return self:GetLeft(), self:GetBottom() end,
	["TOP"]		= function(self) return self:GetLeft() + self:GetWidth() / 2, self:GetTop() end,
	["CENTER"]	= function(self) return self:GetLeft() + self:GetWidth() / 2, self:GetBottom() + self:GetHeight() / 2 end,
	["BOTTOM"]	= function(self) return self:GetLeft() + self:GetWidth() / 2, self:GetBottom() end,
	["TOPRIGHT"]	= function(self) return self:GetRight(), self:GetTop() end,
	["RIGHT"]	= function(self) return self:GetRight(), self:GetBottom() + self:GetHeight() / 2 end,
	["BOTTOMRIGHT"]	= function(self) return self:GetRight(), self:GetBottom() end,
}

function IFrameManager:Update(frame)
	local layout = IFrameManagerLayout[frame:GetName()]

	local s, r = frame:GetEffectiveScale(), getglobal(layout[2]):GetEffectiveScale()
	local sX, sY = AnchorCoordinates[layout[1]](frame)
	local dX, dY = AnchorCoordinates[layout[3]](getglobal(layout[2]))
	
	layout[4] = sX * s - dX * r
	layout[5] = sY * s - dY * r

	local a1, a2, a3, a4, a5 = unpack(layout)

	frame:ClearAllPoints()
	frame:SetPoint(a1, a2, a3, a4 / s, a5 / s)
end



--[[
		IFrameManager:Disable()

	Disengages the edit mode. Destroys the overlay frames and anchors.
]]
function IFrameManager:Disable()
	if (self.isEnabled == nil) then
		return
	end

	for frame, iface in pairs(self.List) do
		for anchor in pairs(frame.IFrameManager.Anchors) do
			IFrameFactory:Destroy("IFrameManager", "Anchor", anchor)
		end

		IFrameFactory:Destroy("IFrameManager", "Overlay", frame.IFrameManager)
		frame.IFrameManager = nil
	end

	self.isEnabled = nil
end

function IFrameManager:Toggle()
	if (self.isEnabled) then
		IFrameManager:Disable()
	else
		IFrameManager:Enable()
	end
end



--[[
	Event handling
]]
local function onEvent(self, event, ...)
	if (event == "VARIABLES_LOADED") then
		return this:Show()
	end

	local key, value = select(1, ...), select(2, ...)
	if (key == "LCTRL") then
		if (value == 1) then
			IFrameManager.Source = nil

			for frame, iface in pairs(IFrameManager.List) do
				if (frame.IFrameManager) then
					frame.IFrameManager.label:Hide()
					for anchor, point in pairs(frame.IFrameManager.Anchors) do
						anchor:Show()
					end

					IFrameManager:Highlight(frame.IFrameManager)
				end
			end
		else
			for frame, iface in pairs(IFrameManager.List) do
				if (frame.IFrameManager) then
					frame.IFrameManager.label:Show()
					for anchor in pairs(frame.IFrameManager.Anchors) do
						anchor:Hide()
					end
				end
			end
		end
	end
end

local function onUpdate(self)
	self:Hide()

	for name, layout in pairs(IFrameManagerLayout) do
		local frame = getglobal(name)
		if (frame) then
			local target = getglobal(layout[2])
			if (target == nil) then	
				layout[2] = "UIParent"
			end

			local s = frame:GetEffectiveScale()
			local a1, a2, a3, a4, a5 = unpack(layout)

			frame:ClearAllPoints()
			frame:SetPoint(a1, a2, a3, a4 / s, a5 / s)
		end
	end
end

IFrameManager.Slave = CreateFrame("Frame")
IFrameManager.Slave:RegisterEvent("VARIABLES_LOADED")
IFrameManager.Slave:RegisterEvent("MODIFIER_STATE_CHANGED")

IFrameManager.Slave:SetScript("OnEvent", onEvent)
IFrameManager.Slave:SetScript("OnUpdate", onUpdate)



--[[
	UIParent is special. We can't use IFrameManager:Register() because
	that would load a default layout that has UIParent as its parent,
	which would create a circular dependency.
]]
IFrameManager.List[UIParent] = IFrameManager:Interface()



--[[
	FIXME: Find a better solution, get someone to write a nice UI.
]]
SLASH_IFrameManager1 = "/ifm"
SlashCmdList["IFrameManager"] = function()
	IFrameManager:Toggle()
end

