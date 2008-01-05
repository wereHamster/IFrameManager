
local FactoryInterface = { }
IFrameFactory("1.0"):Register("IFrameManager", "Overlay", FactoryInterface)

local function framesOverlap(frameA, frameB)
	local sA, sB = frameA:GetEffectiveScale(), frameB:GetEffectiveScale()
	return ((frameA:GetLeft()*sA) < (frameB:GetRight()*sB))
		and ((frameB:GetLeft()*sB) < (frameA:GetRight()*sA))
		and ((frameA:GetBottom()*sA) < (frameB:GetTop()*sB))
		and ((frameB:GetBottom()*sB) < (frameA:GetTop()*sA))
end

local function snapFrames(frameThis, frameCandidate, lastXDiff, lastYDiff)
	local sT, sC = frameThis:GetEffectiveScale(), frameCandidate:GetEffectiveScale()
	local lT, tT, rT, bT = frameThis:GetLeft(), frameThis:GetTop(), frameThis:GetRight(), frameThis:GetBottom()
	local lC, tC, rC, bC = frameCandidate:GetLeft(), frameCandidate:GetTop(), frameCandidate:GetRight(), frameCandidate:GetBottom()
	
	local xT, yT = frameThis:GetCenter()
	local xC, yC = frameCandidate:GetCenter()
	local hT, hC = frameThis:GetHeight() / 2, ((frameCandidate:GetHeight() * sC) / sT) / 2
	local wT, wC = frameThis:GetWidth() / 2, ((frameCandidate:GetWidth() * sC) / sT) / 2
	
	lC, tC, rC, bC = (lC * sC) / sT, (tC * sC) / sT, (rC * sC) / sT, (bC * sC) / sT
	
	local xSet, ySet = lastXDiff, lastYDiff
	local xDiff, yDiff = 0, 0
	
	xDiff = math.abs(rT - lC)
	if (xDiff < xSet) then
		xT = lC - wT + 3
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
		xT = rC + wT - 3
		xSet = xDiff
	end
	
	
	yDiff = math.abs(tT - bC)
	if (yDiff < ySet) then
		yT = bC - hT + 3
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
		yT = tC + hT - 3
		ySet = yDiff
	end
	
	frameThis:ClearAllPoints()
	frameThis:SetPoint("CENTER", UIParent, "BOTTOMLEFT", xT, yT)
	
	return math.min(xSet, lastXDiff), math.min(ySet, lastYDiff)
end



local function OnShow()
	--DEFAULT_CHAT_FRAME:AddMessage("IFrameManagerCapsule:OnShow()")
end

local function OnMouseDown()
	--DEFAULT_CHAT_FRAME:AddMessage("IFrameManagerCapsule:OnMouseDown()")
	--this:StartMoving()
	this.startMoving = true
	
	local xCur, yCur = GetCursorPosition()
	local xCenter, yCenter = this:GetCenter()
	local s = this:GetEffectiveScale()
	
	xCur, yCur = xCur / s, yCur / s
	this.xOffset, this.yOffset = (xCenter - xCur), (yCenter - yCur)
end

local function OnUpdate()
	if (this.startMoving == nil) then
		return
	end
	--DEFAULT_CHAT_FRAME:AddMessage("IFrameManagerCapsule:OnUpdate()")
	
	local xCur, yCur = GetCursorPosition()
	local s = this:GetEffectiveScale()
		
	xCur, yCur = xCur / s, yCur / s

	this:ClearAllPoints()
	this:SetPoint("CENTER", UIParent, "BOTTOMLEFT", xCur + this.xOffset, yCur + this.yOffset)
	
	local xDiff, yDiff = 10, 10
	for frame, iface in pairs(IFrameManager.frameList) do
		if (frame.IFrameManager ~= this) then
			if (framesOverlap(this, frame.IFrameManager)) then
				xDiff, yDiff = snapFrames(this, frame.IFrameManager, xDiff, yDiff)
			end
		end
	end
	
	snapFrames(this, UIParent, xDiff, yDiff)
end

local function OnMouseUp()
	--DEFAULT_CHAT_FRAME:AddMessage("IFrameManagerCapsule:OnMouseUp()")
	--this:StopMovingOrSizing()
	this.startMoving = nil
end

local function OnHide()
	--DEFAULT_CHAT_FRAME:AddMessage("IFrameManagerCapsule:OnHide()")
end


local backdropTable = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 12,
	edgeSize = 12,
	insets = {
		left = 2,
		right = 2,
		top = 2,
		bottom = 2
	}
}

function FactoryInterface:Create()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetWidth(32)
	frame:SetHeight(32)
	
	frame:SetPoint("CENTER", UIParent)
	
	frame:EnableMouse(true)
	frame:SetMovable(true)
	
	frame:SetFrameStrata("HIGH")

	frame:SetBackdrop(backdropTable)
	frame:SetBackdropBorderColor(0, 0, 0, 1)
	frame:SetBackdropColor(0, 0, 0, 1)
	
	frame.label = frame:CreateFontString(nil, "Label")
	frame.label:Show()
	frame.label:SetFontObject(GameFontNormal)
	frame.label:SetText("IFrameManager")
	frame.label:SetPoint("CENTER", frame, "CENTER", 0, 0)
	frame.label:SetJustifyH("CENTER")
	frame.label:SetTextColor(1.0, 0.82, 0)
	
	
	frame:SetScript("OnShow", OnShow)
	frame:SetScript("OnMouseDown", OnMouseDown)
	frame:SetScript("OnUpdate", OnUpdate)
	frame:SetScript("OnMouseUp", OnMouseUp)
	frame:SetScript("OnHide", OnHide)
	
	return frame
end

function FactoryInterface:Destroy(frame)
	return frame
end
