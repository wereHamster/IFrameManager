
local FactoryInterface = { }
IFrameFactory("1.0"):Register("IFrameManager", "Overlay", FactoryInterface)

local backdropTable = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\AddOns\\IFrameManager\\Textures\\Border2.tga",
	tile = true, tileSize = 12, edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local function framesOverlap(frameA, frameB)
	local sA, sB = frameA:GetEffectiveScale(), frameB:GetEffectiveScale()
	return ((frameA:GetLeft()*sA) < (frameB:GetRight()*sB))
		and ((frameB:GetLeft()*sB) < (frameA:GetRight()*sA))
		and ((frameA:GetBottom()*sA) < (frameB:GetTop()*sB))
		and ((frameB:GetBottom()*sB) < (frameA:GetTop()*sA))
end

local function snapFrames(frameThis, frameCandidate, lastXDiff, lastYDiff)
	local sT, sC, sP = frameThis:GetEffectiveScale(), frameCandidate:GetEffectiveScale(), frameThis.Parent:GetEffectiveScale() 
	local lT, tT, rT, bT = frameThis:GetLeft() * sT, frameThis:GetTop() * sT, frameThis:GetRight() * sT, frameThis:GetBottom() * sT
	local lC, tC, rC, bC = frameCandidate:GetLeft() * sC, frameCandidate:GetTop() * sC, frameCandidate:GetRight() * sC, frameCandidate:GetBottom() * sC
	local hT, hC = frameThis:GetHeight() / 2 * sT, frameCandidate:GetHeight() / 2 * sC
	local wT, wC = frameThis:GetWidth() / 2 * sT, frameCandidate:GetWidth() / 2 * sC

	local xT, yT = frameThis:GetCenter()
	xT, yT = xT * sT, yT * sT
	local xO, yO = frameThis.Parent:GetCenter()
	xO, yO = xO * sP - xT, yO * sP - yT

	local xC, yC = frameCandidate:GetCenter()
	xC, yC = xC * sC, yC * sC

	local xSet, ySet = lastXDiff, lastYDiff
	local xDiff, yDiff = 0, 0
	
	xDiff = math.abs(rT - lC)
	if (xDiff < xSet) then
		xT = lC - wT --+ 3
		xSet = xDiff
	end
	
	xDiff = math.abs(lT - lC)
	if (xDiff < xSet) then
		xT = lC + wT
		xSet = xDiff
	end
	
	xDiff = math.abs(rT - rC)
	if (xDiff < xSet) then
		xT = rC - wT
		xSet = xDiff
	end
	
	xDiff = math.abs(lT - rC)
	if (xDiff < xSet) then
		xT = rC + wT --- 3
		xSet = xDiff
	end
	
	
	yDiff = math.abs(tT - bC)
	if (yDiff < ySet) then
		yT = bC - hT --+ 3
		ySet = yDiff
	end
	
	yDiff = math.abs(bT - bC)
	if (yDiff < ySet) then
		yT = bC + hT
		ySet = yDiff
	end
	
	yDiff = math.abs(tT - tC)
	if (yDiff < ySet) then
		yT = tC - hT
		ySet = yDiff
	end
	
	yDiff = math.abs(bT - tC)
	if (yDiff < ySet) then
		yT = tC + hT --- 3
		ySet = yDiff
	end

	frameThis.Parent:ClearAllPoints()
	frameThis.Parent:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (xT + xO) / sP, (yT + yO) / sP)
	this.Parent:GetCenter()

	return math.min(xSet, lastXDiff), math.min(ySet, lastYDiff)
end

local function OnMouseDown()
	if (this.Parent:GetName() == nil) then
		return
	end

	local xCur, yCur = GetCursorPosition()
	local xCenter, yCenter = this.Parent:GetCenter()
	local s = this.Parent:GetEffectiveScale()

	this.Offset = { xCenter - xCur / s, yCenter - yCur / s }
end

local function updatePosition(frame)
	IFrameManager:Update(frame)

	for src, data in pairs(IFrameManagerLayout) do
		if (data[2] == frame:GetName()) then
			updatePosition(getglobal(src))
		end
	end
end

local function OnUpdate()
	if (this.Offset == nil) then
		return
	end
	
	local xCur, yCur = GetCursorPosition()
	local s = this.Parent:GetEffectiveScale()

	this.Parent:ClearAllPoints()
	this.Parent:SetPoint("CENTER", UIParent, "BOTTOMLEFT", xCur / s + this.Offset[1], yCur / s + this.Offset[2])

	-- The overlay won't move unless I do this. OnUpdate bug?
	this.Parent:GetCenter()
	
	local xDiff, yDiff = 5, 5
	for frame, iface in pairs(IFrameManager.List) do
		local data = IFrameManagerLayout[frame:GetName()]
		if (frame.IFrameManager ~= this and not (data and data[2] == this.Parent:GetName())) then
			if (framesOverlap(this, frame.IFrameManager)) then
				xDiff, yDiff = snapFrames(this, frame.IFrameManager, xDiff, yDiff)
			end
		end
	end
	
	snapFrames(this, UIParent, xDiff, yDiff)

	-- Update all dependent frames
	for src, data in pairs(IFrameManagerLayout) do
		if (data[2] == this.Parent:GetName()) then
			updatePosition(getglobal(src))
		end
	end
end

local function OnMouseUp()
	if (this.Offset) then
		this.Offset = nil
		IFrameManager:Update(this.Parent)
	end
end


function FactoryInterface:Create()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:EnableMouse(true)
	frame:SetFrameStrata("HIGH")

	frame:SetBackdrop(backdropTable)
	frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
	frame:SetBackdropColor(0, 0, 0, 1)
	
	frame.label = frame:CreateFontString(nil, "Label")
	frame.label:Show()
	frame.label:SetFontObject(GameFontNormal)
	frame.label:SetText("IFrameManager")
	frame.label:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.label:SetJustifyH("CENTER")
	frame.label:SetTextColor(1.0, 0.82, 0)

	frame:SetScript("OnMouseDown", OnMouseDown)
	frame:SetScript("OnUpdate", OnUpdate)
	frame:SetScript("OnMouseUp", OnMouseUp)
	
	return frame
end

function FactoryInterface:Destroy(frame)
	return frame
end

