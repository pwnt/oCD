--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2007, Trond A Ekseth
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of oCD nor the names of its contributors may
        be used to endorse or promote products derived from this
        software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]

local onEvent = function(self, event, ...)
	self[event](self, event, ...)
end

-- addon related...
local addon = CreateFrame"Frame"
addon:Hide()
local print = function(...) ChatFrame1:AddMessage(...) end
local printf = function(...) ChatFrame1:AddMessage(string.format(...)) end
local start, stop, register

-- locals
local GetSpellCooldown = GetSpellCooldown
local pairs = pairs

-- we run 1.5 across the board, it's possible to have 1.5 seconds global cooldown on a rogue.
local gc = 1.5

-- tooltip madness
tip = CreateFrame"GameTooltip"
tip:SetOwner(WorldFrame, "ANCHOR_NONE")
tip.r, tip.l = {}, {}

for i=1,8 do
	tip.l[i], tip.r[i] = tip:CreateFontString(nil, nil, "GameFontNormal"), tip:CreateFontString(nil, nil, "GameFontNormal")
	tip:AddFontStrings(tip.l[i], tip.r[i])
end

local SetSpell = function(id, type)
	tip:ClearLines()
	tip:SetSpell(id, type)
end

-- We have them here for now
local SPELL_RECAST_TIME_MIN = SPELL_RECAST_TIME_MIN:gsub("%%%.3g", "%(%%d+%%.?%%d*%)")
local SPELL_RECAST_TIME_SEC = SPELL_RECAST_TIME_SEC:gsub("%%%.3g", "%(%%d+%%.?%%d*%)")

-- locals we need:
local spells = {}

-- remove these later
addon.spells = spells

local time, duration, enable
local updateCooldown = function(self)
	for name, vars in pairs(spells) do
		time, duration, enable = GetSpellCooldown(vars.id, vars.type)

		if(time > 0 and duration > gc and enable > 0) then
			start(name, time, duration)
		elseif(time == 0 and duration == 0 and enable == 1) then
			stop(name)
		end
	end
end
local show = function() addon:Show() end

addon.PLAYER_ENTERING_WORLD = updateCooldown
addon.UNIT_SPELLCAST_SUCCEEDED = show
addon.UNIT_SPELLCAST_STOP = show
addon.UPDATE_STEALTH = show

-- enable
function addon:PLAYER_LOGIN()
	start = self.bars.start
	stop = self.bars.stop
	register = self.bars.register

	self:parseSpellBook(BOOKTYPE_SPELL)
end

function addon:parseSpellBook(type)
	local i, n, n2, r, cd = 1
	while true do
		n, r = GetSpellName(i, type)
		n2 = GetSpellName(i+1, type)
		if not n then break end
		
		if(n ~= n2) then
			SetSpell(i, type)

			cd = tip.r[3]:GetText() or tip.r[2]:GetText()
			if(cd and cd:match(SPELL_RECAST_TIME_MIN)) then
				spells[n] = {id = i, type = type}
				register(n, cd:match(SPELL_RECAST_TIME_MIN)*60, GetSpellTexture(i, type))
			elseif(cd and cd:match(SPELL_RECAST_TIME_SEC)) then
				spells[n] = {id = i, type = type}
				register(n, cd:match(SPELL_RECAST_TIME_SEC), GetSpellTexture(i, type))
			end
		end

		i = i + 1
	end
end

addon:SetScript("OnEvent", onEvent)

local update = 0
addon:SetScript("OnUpdate", function(self, elapsed)
	update = update + elapsed
	if(update > .5) then
		updateCooldown()

		update = 0
		self:Hide()
	end
end)
addon:RegisterEvent"PLAYER_LOGIN"
addon:RegisterEvent"PLAYER_ENTERING_WORLD"
addon:RegisterEvent"UNIT_SPELLCAST_SUCCEEDED"
addon:RegisterEvent"UNIT_SPELLCAST_STOP"
addon:RegisterEvent"UPDATE_STEALTH"

_G['oCD'] = addon