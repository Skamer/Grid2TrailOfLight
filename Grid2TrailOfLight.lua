-- Add the Trail of light status, created by Skamer.
-- Thank to grid authors to have this wonderful addon.
-- Edited by Finarf for TWW
local TrailOfLight = Grid2.statusPrototype:new("trail-of-light")

local Grid2 = Grid2

-- Wow APi
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellDescription = C_Spell.GetSpellDescription
local GetTalentInfo = GetTalentInfo
local GetSpecialization = GetSpecialization
local UnitGUID = UnitGUID

-- data
local FlashHealSpellID = 2061
local TrailOfLightSpellID = 200128 -- it's the talent for the description
local ToLHealSpellID = 234946 -- it's the spell id for the heal
local ToLNodeID = 82634 -- talent node id

local TrailOfLightName = GetSpellInfo(TrailOfLightSpellID).name
local TrailOfLightIcon,_ = C_Spell.GetSpellTexture(TrailOfLightSpellID)

--
local playerGUID = nil
local CurrentTOLPlayer = nil
local TrailOfLightSelected = false
local HealData = {}

TrailOfLight.UpdateAllUnits = Grid2.statusLibrary.UpdateAllUnits

-- Utility to check if ToL is talented
local function IsToLTalented()
    local configID = C_ClassTalents.GetActiveConfigID()
    if configID == nil then return end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if configInfo == nil then return end
	
	-- Check holy is current spec
	if configInfo.name ~= "Holy" then return end	

	-- Check the ToL talent tree node and if it is active
	local nodeInfo = C_Traits.GetNodeInfo(configID, ToLNodeID)
	for _, entryID in ipairs(nodeInfo.entryIDsWithCommittedRanks) do -- there should be 1 or 0
		local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
		if entryInfo and entryInfo.definitionID then
			local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
			if definitionInfo.spellID == TrailOfLightSpellID then
				return true
			end
		end
	end
    return false
end

function TrailOfLight:OnEnable()
  playerGUID = UnitGUID("player")
  TrailOfLightSelected = IsToLTalented()

  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterEvent("PLAYER_TALENT_UPDATE")
end

function TrailOfLight:OnDisable()
  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:UnregisterEvent("PLAYER_TALENT_UPDATE")
end

function TrailOfLight:PLAYER_TALENT_UPDATE()
  TrailOfLightSelected = IsToLTalented()
  
  TrailOfLight:UpdateAllUnits()
end

function TrailOfLight:COMBAT_LOG_EVENT_UNFILTERED()
  local timestamp, message, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, destFlags2, spellID, spellName, _, healAmount = CombatLogGetCurrentEventInfo()
  if message == "SPELL_HEAL" and sourceGUID == playerGUID then
    if spellID == ToLHealSpellID then
      CurrentTOLPlayer = destGUID
      TrailOfLight:UpdateAllUnits()
    end
  end
end

function TrailOfLight:IsActive(unit)
  return TrailOfLightSelected and CurrentTOLPlayer == UnitGUID(unit)
end


function TrailOfLight:GetIcon()
  return TrailOfLightIcon
end

function TrailOfLight:GetColor()
  local color = self.dbx.color1
  return color.r, color.g, color.b, color.a
end

local function CreateStatusTrailOfLight(baseKey, dbx)
	Grid2:RegisterStatus(TrailOfLight, {"color", "icon"}, baseKey, dbx)
	return TrailOfLight
end

Grid2.setupFunc["trail-of-light"] = CreateStatusTrailOfLight

Grid2:DbSetStatusDefaultValue("trail-of-light", {type = "trail-of-light",  color1= {r=0,g=1,b=0,a=1} } )
-- Hook to set the option properties done at the end

-------------------------------------------------------------------------------------------
-- Add the last Heal/Flash Heal target status
local LastTarget = Grid2.statusPrototype:new("last-target")

-- data
local HealSpellID = 2060

local LastTargetName = "Last Heal Target"
local LastTargetIcon,_ = C_Spell.GetSpellTexture(HealSpellID)

--
local CurrentLastTargetPlayer = nil
local LastTargetSelected = false

LastTarget.UpdateAllUnits = Grid2.statusLibrary.UpdateAllUnits

function LastTarget:OnEnable()
  playerGUID = UnitGUID("player")
  LastTargetSelected = IsToLTalented()

  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterEvent("PLAYER_TALENT_UPDATE")
end

function LastTarget:OnDisable()
  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:UnregisterEvent("PLAYER_TALENT_UPDATE")
end

function LastTarget:PLAYER_TALENT_UPDATE()
  LastTargetSelected = IsToLTalented()
  
  LastTarget:UpdateAllUnits()
end

function LastTarget:COMBAT_LOG_EVENT_UNFILTERED()
  local timestamp, message, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, destFlags2, spellID, spellName, _, healAmount = CombatLogGetCurrentEventInfo()
  if message == "SPELL_HEAL" and sourceGUID == playerGUID then
    if spellID == HealSpellID or spellID == FlashHealSpellID then
      CurrentLastTargetPlayer = destGUID
      LastTarget:UpdateAllUnits()
    end
  end
end

function LastTarget:IsActive(unit)
  return LastTargetSelected and CurrentLastTargetPlayer == UnitGUID(unit)
end

function LastTarget:GetIcon()
  return LastTargetIcon
end

function LastTarget:GetColor()
  local color = self.dbx.color1
  return color.r, color.g, color.b, color.a
end

local function CreateStatusLastTarget(baseKey, dbx)
	Grid2:RegisterStatus(LastTarget, {"color", "icon"}, baseKey, dbx)
	return LastTarget
end

Grid2.setupFunc["last-target"] = CreateStatusLastTarget

Grid2:DbSetStatusDefaultValue("last-target", {type = "last-target",  color1= {r=0,g=0,b=1,a=1} } )

-- Hook to set the option properties
local PrevLoadOptions = Grid2.LoadOptions
function Grid2:LoadOptions()
  PrevLoadOptions(self)
  Grid2Options:RegisterStatusOptions("last-target", "buff", nil, {title=LastTargetName, titleIcon = LastTargetIcon, titleDesc="The last target of Heal or Flash Heal."})
  Grid2Options:RegisterStatusOptions("trail-of-light", "buff", nil, {title=TrailOfLightName, titleIcon = TrailOfLightIcon, titleDesc=GetSpellDescription(TrailOfLightSpellID)})
end