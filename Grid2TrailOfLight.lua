-- Add the Trail of light status, created by Skamer.
-- Thank to grid authors to have this wonderful addon.
local TrailOfLight = Grid2.statusPrototype:new("trail-of-light")

local Grid2 = Grid2

-- Wow APi
local GetSpellInfo = GetSpellInfo
local GetSpellTexture = GetSpellTexture
local GetSpellInfo = GetSpellInfo
local GetSpellDescription = GetSpellDescription
local GetTalentInfo = GetTalentInfo
local GetSpecialization = GetSpecialization
local UnitGUID = UnitGUID

-- data
local FlashHealSpellID = 2061
local TrailOfLightSpellID = 200128 -- it's the talent for the description
local ToLHealSpellID = 234946 -- it's the spell id for the heal

local TrailOfLightName = GetSpellInfo(TrailOfLightSpellID)
local TrailOfLightIcon = GetSpellTexture(TrailOfLightSpellID)

--
local playerGUID = nil
local CurrentTOLPlayer = nil
local TrailOfLightSelected = false
local IsHolySpec = false
local HealData = {}

TrailOfLight.UpdateAllUnits = Grid2.statusLibrary.UpdateAllUnits

function TrailOfLight:OnEnable()
  IsHolySpec = GetSpecialization() == 2
  FirstEvent = true
  playerGUID = UnitGUID("player")

  if IsHolySpec then
    _, _, _, TrailOfLightSelected = GetTalentInfo(1, 1, 1)
  end

  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterEvent("PLAYER_TALENT_UPDATE")
end

function TrailOfLight:OnDisable()
  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:UnregisterEvent("PLAYER_TALENT_UPDATE")
end

function TrailOfLight:PLAYER_TALENT_UPDATE()
  IsHolySpec = GetSpecialization() == 2
  if not IsHolySpec then
    TrailOfLightSelected = false
  else
    _, _, _, TrailOfLightSelected = GetTalentInfo(1, 1, 1)
  end
  TrailOfLight:UpdateAllUnits()
end

function TrailOfLight:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, message, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, destFlags2, ...)
  if message == "SPELL_HEAL" and sourceGUID == playerGUID then
    local spellID, spellName, _, healAmount = ...
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
-- Hook to set the option properties
local PrevLoadOptions = Grid2.LoadOptions
function Grid2:LoadOptions()
  PrevLoadOptions(self)
  Grid2Options:RegisterStatusOptions("trail-of-light", "buff", nil, {title=TrailOfLightName, titleIcon = TrailOfLightIcon, titleDesc=GetSpellDescription(TrailOfLightSpellID)})
end
