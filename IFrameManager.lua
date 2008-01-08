
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
	IFrameManagerLayout[frame:GetName()] = IFrameManagerLayout[frame:GetName()] or { "CENTER", "UIParent", "CENTER" }
end

IFrameManager:Register(UIParent, IFrameManager:Interface())


--[[
		IFrameManager:Enable()

	Initializes the edit mode where a overlay and anchor points are
	created for each frame. When the overlay is moved with the mouse,
	the underlying frame is also moved. Frames can be anchored together
	by clicking on the anchor boxes.
]]

local function CreateOverlay(frame, iface)
	local overlay = IFrameFactory:Create("IFrameManager", "Overlay")
	overlay = IFrameFactory:Create("IFrameManager", "Overlay")
	overlay.Parent = frame

	local t, r, b, l = iface:getBorder(frame)
	overlay:SetWidth(frame:GetWidth() + l + r)
	overlay:SetHeight(frame:GetHeight() + t + b)
	overlay:SetScale(frame:GetScale())
	overlay:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -l, -b)

	overlay.label:SetWidth(overlay:GetWidth())
	overlay.label:SetText(iface:getName(frame))

	-- Set up the anchors
	local anchors = { { }, { } }

	local height = overlay:GetHeight()
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

	local width = overlay:GetWidth()
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

	UIParent.IFrameManager:Hide()

	self.isEnabled = true
end

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

--[[
		IFrameManager:Update()

	Updates the anchors and position of a frame.
]]
function IFrameManager:Update(frame)
	local layout = IFrameManagerLayout[frame:GetName()]

	local sX, sY = AnchorCoordinates[layout[1]](frame)
	local dX, dY = AnchorCoordinates[layout[3]](getglobal(layout[2]))

	layout[4] = sX - dX
	layout[5] = sY - dY

	frame:ClearAllPoints()
	frame:SetPoint(unpack(layout))
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


SLASH_IFrameManager1 = "/ifm"

SlashCmdList["IFrameManager"] = function(msg)
	if (msg == "start") then
		IFrameManager:Enable()
	elseif (msg == "stop") then
		IFrameManager:Disable()
	else
		IFrameManager:Toggle()
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
eventFrame:SetScript("OnEvent", function(self, event, key, value)
	if (key == "LCTRL") then
		if (value == 1) then
			IFrameManager.Source = nil

			for frame, iface in pairs(IFrameManager.List) do
				if (frame.IFrameManager) then
					frame.IFrameManager.label:Hide()
					for anchor, point in pairs(frame.IFrameManager.Anchors) do
						anchor:Show()
					end
				end
			end

			if (UIParent.IFrameManager) then
				for anchor, point in pairs(UIParent.IFrameManager.Anchors) do
					anchor:Show()
				end
			end
		else
			if (IFrameManager.Source) then
				IFrameManager.Source:SetBackdropColor(1.0, 0.82, 0)
			end

			for frame, iface in pairs(IFrameManager.List) do
				if (frame.IFrameManager) then
					frame.IFrameManager.label:Show()
					for anchor in pairs(frame.IFrameManager.Anchors) do
						anchor:Hide()
					end
				end
			end

			if (UIParent.IFrameManager) then
				for anchor, point in pairs(UIParent.IFrameManager.Anchors) do
					anchor:Hide()
				end
			end
		end
	end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event)
	for name, data in pairs(IFrameManagerLayout) do
		local src = getglobal(name)
		if (src) then
			src:ClearAllPoints()
			src:SetPoint(unpack(data))
		end
	end
end)
 
