
local IFrameFactory = IFrameFactory("1.0")

IFrameManager = { List = { } }
IFrameManagerLayout = { }


local baseInterface = { }
local interfaceMetatable = { __index = baseInterface }

function baseInterface:getName(frame)
	return frame:GetName()
end

function baseInterface:getBorder(frame)
	return 0, 0, 0, 0
end

function IFrameManager:Interface()
	return setmetatable({ }, interfaceMetatable)
end

function IFrameManager:Register(frame, iface)
	if (getmetatable(iface) == interfaceMetatable) then
		self.List[frame] = iface
	else
		DEFAULT_CHAT_FRAME:AddMessage("wrong metatable for frame: "..frame:GetName())
	end
end

function IFrameManager:Enable()
	if (self.isEnabled) then
		return
	end
	
	for frame, iface in pairs(self.List) do
		frame.IFrameManager = IFrameFactory:Create("IFrameManager", "Overlay")
		frame.IFrameManager.Parent = frame

		local t, r, b, l = iface:getBorder(frame)
		frame.IFrameManager:SetWidth(frame:GetWidth() + l + r)
		frame.IFrameManager:SetHeight(frame:GetHeight() + t + b)
		frame.IFrameManager:SetParent(UIParent)
		frame.IFrameManager:SetScale(frame:GetScale())

		frame.IFrameManager.label:SetWidth(frame.IFrameManager:GetWidth())
		frame.IFrameManager.label:SetText(iface:getName(frame))

		frame.IFrameManager:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -l, -b)

		-- Set up the anchors
		local anchors = { { }, { } }

		local height = frame.IFrameManager:GetHeight()
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

		local width = frame.IFrameManager:GetWidth()
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

		frame.IFrameManager.Anchors = { }
		for _, v in pairs(anchors[1]) do
			for _, h in pairs(anchors[2]) do
				local point = v[1] == "" and h[1] == "" and "CENTER" or v[1]..h[1]
				local anchor = IFrameFactory:Create("IFrameManager", "Anchor")
				frame.IFrameManager.Anchors[anchor] = point

				anchor:SetWidth(math.min(h[2], 40))
				anchor:SetHeight(math.min(v[2], 40))
				anchor:SetParent(frame.IFrameManager)
				anchor:Hide()
				anchor:SetPoint(point, frame.IFrameManager, point)
			end
		end
	end
	
	self.isEnabled = true
end

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
			for frame, iface in pairs(IFrameManager.List) do
				if (frame.IFrameManager) then
					frame.IFrameManager.label:Hide()
					for anchor, point in pairs(frame.IFrameManager.Anchors) do
						anchor:Show()
					end
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
 
