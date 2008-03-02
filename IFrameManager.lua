
local IFrameFactory = IFrameFactory("1.0")

IFrameManager = { Registry = { } }
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
	self.Registry[frame] = iface
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
	if (self.Stack) then
		return
	end

	self.Stack = { }
	for frame, iface in pairs(self.Registry) do
		frame.IFrameManager = CreateOverlay(frame, iface)
		table.insert(self.Stack, frame.IFrameManager)
	end

	UIParent.IFrameManager:EnableMouse(false)
	UIParent.IFrameManager:SetBackdropColor(0, 0, 0, 0)
end



--[[
		IFrameManager:Highlight()

	Updates the highlight colors of all overlays and anchors.
]]

local function hiAnchor(overlay, loc, ...)
	for anchor, pos in pairs(overlay.Anchors) do
		if (pos == loc) then
			return anchor:SetBackdropColor(...)
		end
	end
end

local function hiOverlay(overlay)
	if (overlay.Parent ~= UIParent) then
		overlay:SetBackdropColor(0, 0, 0, 1)
	end

	for anchor in pairs(overlay.Anchors) do
		anchor:SetBackdropColor(0.4, 0.4, 0.4, 1)
	end
end

function IFrameManager:Highlight(overlay)
	for _, frame in ipairs(self.Stack) do
		hiOverlay(frame)
	end

	if (overlay and overlay.Parent ~= UIParent) then
		local layout = IFrameManagerLayout[overlay.Parent:GetName()]
		local target = getglobal(layout[2])

		if (target ~= UIParent) then
			target.IFrameManager:SetBackdropColor(1, 0.4, 0.4, 1)
		end

		hiAnchor(overlay, layout[1], 1, 1, 0.4, 1)
		hiAnchor(target.IFrameManager, layout[3], 1, 1, 0.4, 1)
	end

	if (IFrameManager.Source) then
		IFrameManager.Source:SetBackdropColor(0.4, 1, 1, 1)
	end
end



--[[
		IFrameManager:Raise()

	Raises the frame to the top of the stack.
]]

local function overlayIndex(overlay)
	for index, frame in ipairs(IFrameManager.Stack) do
		if (frame == overlay) then
			return index
		end
	end
end

function IFrameManager:Raise(frame)
	local index = overlayIndex(frame.IFrameManager)
	table.remove(self.Stack, index)
	table.insert(self.Stack, frame.IFrameManager)

	for index, overlay in ipairs(self.Stack) do
		overlay:SetFrameLevel(index)

		for anchor in pairs(overlay.Anchors) do
			anchor:SetFrameLevel(index + 1)
		end
	end
end



--[[
		IFrameManager:Update()

	Updates the anchors and position of the frame. Saves the data in the
	layout cache.
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
	if (self.Stack == nil) then
		return
	end

	for _, overlay in pairs(self.Stack) do
		for anchor in pairs(overlay.Anchors) do
			IFrameFactory:Destroy("IFrameManager", "Anchor", anchor)
		end

		IFrameFactory:Destroy("IFrameManager", "Overlay", overlay)
		overlay.Parent.IFrameManager = nil
	end

	self.Stack = nil
end

function IFrameManager:Toggle()
	if (self.Stack) then
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
		for name, layout in pairs(IFrameManagerLayout) do
			local frame = getglobal(name)
			if (frame) then
				local target = getglobal(layout[2])
				if (target == nil) then
					layout[1] = "CENTER"
					layout[2] = "UIParent"
					layout[3] = "CENTER"
					layout[4] = 0
					layout[5] = 0
				end

				local s = frame:GetEffectiveScale()
				local a1, a2, a3, a4, a5 = unpack(layout)

				frame:ClearAllPoints()
				frame:SetPoint(a1, a2, a3, a4 / s, a5 / s)
			end
		end
	elseif (event == "MODIFIER_STATE_CHANGED") then
		local key, value = ...
		if (key == "LCTRL" and IFrameManager.Stack) then
			IFrameManager.Source = nil

			if (value == 1) then
				for _, overlay in pairs(IFrameManager.Stack) do
					overlay.label:Hide()
					for anchor in pairs(overlay.Anchors) do
						anchor:Show()
					end
				end
			else
				for _, overlay in pairs(IFrameManager.Stack) do
					overlay.label:Show()
					for anchor in pairs(overlay.Anchors) do
						anchor:Hide()
					end
				end
			end

			--[[
				Since GetMouseFocus() doesn't want to reture the IFM frames,
				we use this hack to get the overlays to redraw the highlight.
			]]
			for _, overlay in pairs(IFrameManager.Stack) do
				overlay:Hide()
				overlay:Show()
			end
		end
	end
end


IFrameManager.Slave = CreateFrame("Frame")
IFrameManager.Slave:RegisterEvent("VARIABLES_LOADED")
IFrameManager.Slave:RegisterEvent("MODIFIER_STATE_CHANGED")

IFrameManager.Slave:SetScript("OnEvent", onEvent)



--[[
	UIParent is special. We can't use IFrameManager:Register() because
	that would load a default layout that has UIParent as its parent,
	which would create a circular dependency.
]]
IFrameManager.Registry[UIParent] = IFrameManager:Interface()



--[[
	FIXME: Find a better solution, get someone to write a nice UI.
]]
SLASH_IFrameManager1 = "/ifm"
SlashCmdList["IFrameManager"] = function()
	IFrameManager:Toggle()
end

