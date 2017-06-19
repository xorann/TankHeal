------------------------------
--      Initialization      --
------------------------------

TankHeal = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0")

local isInProgress = false
local spellname = ""
local startTime = nil

-- Called when the addon is loaded
function TankHeal:OnInitialize()
end

-- Called when the addon is enabled
function TankHeal:OnEnable()
	self:RegisterEvent("SPELLCAST_START", "Start")
	self:RegisterEvent("SPELLCAST_STOP", "End")
	self:RegisterEvent("SPELLCAST_FAILED", "End")
	self:RegisterEvent("SPELLCAST_INTERRUPTED", "End")
end

-- Called when the addon is disabled
function TankHeal:OnDisable()
end

----------------------
--  Event Handlers  --
----------------------

function TankHeal:Start(msg)
	if string.find(spellname, msg) then
		isInProgress = true
		startTime = GetTime()
	end
end

function TankHeal:End(msg)
	if msg == nil then
		msg = ""
	end
	
	if isInProgress then
		isInProgress = false
	end
end


-----------------------
-- Utility Functions --
-----------------------

function TankHeal:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function TankHeal:Heal(aSpellname, aCheckTime, aThreshold)	
	local unitId = self:GetUnitId()
	if unitId == nil then
		--self:Print("you do not have a valid target")
		return
	end
	
	if not isInProgress then
		spellname = aSpellname
		
		CastSpellByName(spellname)
		if SpellIsTargeting() then
			isInProgress = true
			startTime = GetTime()
			SpellTargetUnit(unitId)
		end
	else
		local elapsed = GetTime() - startTime
		if elapsed >= aCheckTime then
			local health = UnitHealth(unitId)
			local maxHealth = UnitHealthMax(unitId)
			
			local percentage = 100
			if maxHealth > 0 then
				percentage = health / maxHealth * 100
			end
			
			if percentage >= aThreshold then
				isInProgress = false
				SpellStopCasting()
			end
		end
	end
end

function TankHeal:GetUnitId()
	local target = "target"
	local targettarget = "targettarget"
	local unitId = nil
	
	if UnitIsFriend("player", target) and UnitIsPlayer(target) then
		unitId = target
	elseif UnitIsFriend("player", targettarget) and UnitIsPlayer(targettarget) then
		unitId = targettarget
	end
	
	if unitId == nil then
		return nil
	end
	
	local name = UnitName(unitId)
	
	if GetNumPartyMembers() > 0 then
		for i = 1, GetNumPartyMembers(), 1 do
			if UnitName("Party"..i) == name then
				unitId = "Party"..i
				break
			end
		end
	elseif GetNumRaidMembers() > 0 then
		for i = 1, GetNumRaidMembers(), 1 do
			if UnitName("Raid"..i) == name then
				unitId = UnitName("Raid"..i)
				break
			end
		end
	end
	
	return unitId
end