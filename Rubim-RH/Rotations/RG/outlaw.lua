local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = HL.Spell;
local Item = HL.Item
-- Lua
local pairs = pairs;
local tableconcat = table.concat;
local tostring = tostring;

local S = RubimRH.Spell[260]

S.SinisterStrike.TextureSpellID = { 225096 }
S.Dispatch.TextureSpellID = { 20594 }
S.CrimsonVial.TextureSpellID = { 68992 } --
S.ArcanePulse.TextureSpellID = { 28730 }

local function num(val)
	if val then
		return 1
	else
		return 0
	end
end

-- APL Action Lists (and Variables)
local RtB_BuffsList = {
	S.Broadside,
	S.BuriedTreasure,
	S.GrandMelee,
	S.RuthlessPrecision,
	S.SkullandCrossbones,
	S.TrueBearing
};
local function RtB_List (Type, List)
	if not Cache.APLVar.RtB_List then
		Cache.APLVar.RtB_List = {};
	end
	if not Cache.APLVar.RtB_List[Type] then
		Cache.APLVar.RtB_List[Type] = {};
	end
	local Sequence = table.concat(List);
	-- All
	if Type == "All" then
		if not Cache.APLVar.RtB_List[Type][Sequence] then
			local Count = 0;
			for i = 1, #List do
				if Player:Buff(RtB_BuffsList[List[i]]) then
					Count = Count + 1;
				end
			end
			Cache.APLVar.RtB_List[Type][Sequence] = Count == #List and true or false;
		end
		-- Any
	else
		if not Cache.APLVar.RtB_List[Type][Sequence] then
			Cache.APLVar.RtB_List[Type][Sequence] = false;
			for i = 1, #List do
				if Player:Buff(RtB_BuffsList[List[i]]) then
					Cache.APLVar.RtB_List[Type][Sequence] = true;
					break ;
				end
			end
		end
	end
	return Cache.APLVar.RtB_List[Type][Sequence];
end
local function RtB_BuffRemains ()
	if not Cache.APLVar.RtB_BuffRemains then
		Cache.APLVar.RtB_BuffRemains = 0;
		for i = 1, #RtB_BuffsList do
			if Player:Buff(RtB_BuffsList[i]) then
				Cache.APLVar.RtB_BuffRemains = Player:BuffRemainsP(RtB_BuffsList[i]);
				break ;
			end
		end
	end
	return Cache.APLVar.RtB_BuffRemains;
end
-- Get the number of Roll the Bones buffs currently on
local function RtB_Buffs ()
	if not Cache.APLVar.RtB_Buffs then
		Cache.APLVar.RtB_Buffs = 0;
		for i = 1, #RtB_BuffsList do
			if Player:BuffP(RtB_BuffsList[i]) then
				Cache.APLVar.RtB_Buffs = Cache.APLVar.RtB_Buffs + 1;
			end
		end
	end
	return Cache.APLVar.RtB_Buffs;
end
-- RtB rerolling strategy, return true if we should reroll
local function RtB_Reroll ()
	if not Cache.APLVar.RtB_Reroll then
		-- Defensive Override : Grand Melee if HP < 60
		if RubimRH.db.profile[250].dice == "SoloMode" and Player:HealthPercentage() < 50 then
			Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.GrandMelee)) and true or false;
			-- 1+ Buff
		elseif RubimRH.db.profile[250].dice == "1+ Buff" then
			Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and RtB_Buffs() <= 0) and true or false;
			-- Broadside
		elseif RubimRH.db.profile[250].dice == "Broadside" then
			Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.Broadside)) and true or false;
			-- Buried Treasure
		elseif RubimRH.db.profile[250].dice == "Buried Treasure" then
			Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.BuriedTreasure)) and true or false;
			-- Grand Melee
		elseif RubimRH.db.profile[250].dice == "Grand Melee" then
			Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.GrandMelee)) and true or false;
			-- Jolly Roger
		elseif RubimRH.db.profile[250].dice == "Jolly Roger" then
			Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.JollyRoger)) and true or false;
			-- Shark Infested Waters
		elseif RubimRH.db.profile[250].dice == "Shark Infested Waters" then
			Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.SharkInfestedWaters)) and true or false;
			-- True Bearing
		elseif RubimRH.db.profile[250].dice == "True Bearing" then
			Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.TrueBearing)) and true or false;
			-- SimC Default
			-- # Reroll for 2+ buffs with Loaded Dice up. Otherwise reroll for 2+ or Grand Melee or Ruthless Precision.
			-- actions=variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
		else
			Cache.APLVar.RtB_Reroll = (RtB_Buffs() < 2 and (Player:BuffP(S.LoadedDiceBuff) or
					(not Player:BuffP(S.GrandMelee) and not Player:BuffP(S.RuthlessPrecision)))) and true or false;
		end
	end
	return Cache.APLVar.RtB_Reroll;
end
-- # Condition to use Stealth cooldowns for Ambush
local function Ambush_Condition ()
	-- actions+=/variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
	return Player:ComboPointsDeficit() >= 2 + 2 * ((S.GhostlyStrike:IsAvailable() and S.GhostlyStrike:CooldownRemainsP() < 1) and 1 or 0)
			+ (Player:Buff(S.Broadside) and 1 or 0) and Player:EnergyPredicted() > 60 and not Player:Buff(S.SkullandCrossbones);
end
-- # With multiple targets, this variable is checked to decide whether some CDs should be synced with Blade Flurry
-- actions+=/variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
local function Blade_Flurry_Sync ()
	return not RubimRH.AoEON() or Cache.EnemiesCount[tostring(S.Dispatch:ID())] < 2 or Player:BuffP(S.BladeFlurry)
end

local function EnergyTimeToMaxRounded ()
	-- Round to the nearesth 10th to reduce prediction instability on very high regen rates
	return math.floor(Player:EnergyTimeToMaxPredicted() * 10 + 0.5) / 10;
end

local function CPMaxSpend ()
	-- Should work for all 3 specs since they have same Deeper Stratagem Spell ID.
	return RubimRH.Spell[261].DeeperStratagem:IsAvailable() and 6 or 5;
end



local function CDs ()
	-- actions.cds=potion,if=buff.bloodlust.react|target.time_to_die<=60|buff.adrenaline_rush.up
	-- TODO: Add Potion
	-- actions.cds+=/use_item,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
	-- TODO: Add Items
	if Target:IsInRange(S.SinisterStrike) then
		if RubimRH.CDsON() then
			-- actions.cds+=/blood_fury
			if S.BloodFury:IsReady() then
				return S.BloodFury:Cast()
			end
			-- actions.cds+=/berserking
			if S.Berserking:IsReady() then
				return S.Berserking:Cast()
			end
			-- actions.cds+=/adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1
			if S.AdrenalineRush:IsReady() and not Player:BuffP(S.AdrenalineRush) and EnergyTimeToMaxRounded() > 1 then
				return S.AdrenalineRush:Cast()
			end
		end
		-- actions.cds+=/marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit|((raid_event.adds.in>40|buff.true_bearing.remains>15-buff.adrenaline_rush.up*5)&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
		if S.MarkedforDeath:IsReady() then
			-- Note: Increased the SimC condition by 50% since we are slower.
			if Target:FilteredTimeToDie("<", Player:ComboPointsDeficit() * 1.5) or (Target:FilteredTimeToDie("<", 2) and Player:ComboPointsDeficit() > 0)
					or (((Cache.EnemiesCount[30] == 1 and Player:BuffRemainsP(S.TrueBearing) > 15 - (Player:BuffP(S.AdrenalineRush) and 5 or 0))
					or Target:IsDummy()) and not Player:IsStealthed(true, true) and Player:ComboPointsDeficit() >= CPMaxSpend() - 1) then
				return S.MarkedforDeath:Cast()
			elseif not Player:IsStealthed(true, true) and Player:ComboPointsDeficit() >= CPMaxSpend() - 1 then
				return S.MarkedforDeath:Cast()
			end
		end
		if RubimRH.CDsON() then
			-- actions.cds+=/blade_flurry,if=spell_targets.blade_flurry>=2&!buff.blade_flurry.up
			if RubimRH.AoEON() and S.BladeFlurry:IsReady() and Cache.EnemiesCount[tostring(S.Dispatch:ID())] >= 2 and not Player:BuffP(S.BladeFlurry) then
				return S.BladeFlurry:Cast()
			end
			-- actions.cds+=/ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up
			if S.GhostlyStrike:IsReady(S.SinisterStrike) and Blade_Flurry_Sync() and Player:ComboPointsDeficit() >= (1 + (Player:BuffP(S.Broadside) and 1 or 0)) then
				return S.GhostlyStrike:Cast()
			end
			-- actions.cds+=/killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
			if S.KillingSpree:IsReady(10) and Blade_Flurry_Sync() and (EnergyTimeToMaxRounded() > 5 or Player:EnergyPredicted() < 15) then
				return S.KillingSpree:Cast()
			end
			-- actions.cds+=/blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1
			if S.BladeRush:IsReady(S.SinisterStrike) and Blade_Flurry_Sync() and EnergyTimeToMaxRounded() > 1 then
				return S.BladeRush:Cast()
			end
			if not Player:IsStealthed(true, true) then
				-- # Using Vanish/Ambush is only a very tiny increase, so in reality, you're absolutely fine to use it as a utility spell.
				-- actions.cds+=/vanish,if=!stealthed.all&variable.ambush_condition
				if S.Vanish:IsReady() and Ambush_Condition() then
					return S.Vanish:Cast()
				end
				-- actions.cds+=/shadowmeld,if=!stealthed.all&variable.ambush_condition
				if S.Shadowmeld:IsReady() and Ambush_Condition() then
					return S.Shadowmeld:Cast()
				end
			end
		end
	end
end

local function Stealth ()
	if Target:IsInRange(S.SinisterStrike) then
		-- actions.stealth=ambush
		if S.Ambush:IsReady() then
			return S.Ambush:Cast()
		end
	end
end

local function Finish ()
	-- actions.finish=slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
	-- Note: Added Player:BuffRemainsP(S.SliceandDice) == 0 to maintain the buff while TTD is invalid (it's mainly for Solo, not an issue in raids)
	if S.SliceandDice:IsAvailable() and S.SliceandDice:IsReady()
			and (Target:FilteredTimeToDie(">", Player:BuffRemainsP(S.SliceandDice)) or Player:BuffRemainsP(S.SliceandDice) == 0)
			and Player:BuffRemainsP(S.SliceandDice) < (1 + Player:ComboPoints()) * 1.8 then
		return S.SliceandDice:Cast()
	end
	-- actions.finish+=/roll_the_bones,if=(buff.roll_the_bones.remains<=3|variable.rtb_reroll)&(target.time_to_die>20|buff.roll_the_bones.remains<target.time_to_die)
	-- Note: Added RtB_BuffRemains() == 0 to maintain the buff while TTD is invalid (it's mainly for Solo, not an issue in raids)
	if S.RolltheBones:IsReady() and (RtB_BuffRemains() <= 3 or RtB_Reroll())
			and (Target:FilteredTimeToDie(">", 20)
			or Target:FilteredTimeToDie(">", RtB_BuffRemains()) or RtB_BuffRemains() == 0) then
		return S.RolltheBones:Cast()
	end
	-- # BTE worth being used with the boosted crit chance from Ruthless Precision
	-- actions.finish+=/between_the_eyes,if=buff.ruthless_precision.up
	if S.BetweentheEyes:IsReady(20) and Player:BuffP(S.RuthlessPrecision) then
		return S.BetweentheEyes:Cast()
	end
	-- actions.finish+=/dispatch
	if S.Dispatch:IsReady(S.Dispatch) then
		return S.Dispatch:Cast()
	end
	-- OutofRange BtE
	if S.BetweentheEyes:IsReady(20) and not Target:IsInRange(10) then
		return S.BetweentheEyes:Cast()
	end
end

local function Build ()
	-- actions.build=pistol_shot,if=combo_points.deficit>=1+buff.broadside.up+talent.quick_draw.enabled&buff.opportunity.up
	if S.PistolShot:IsReady(20)
			and Player:ComboPointsDeficit() >= (1 + (Player:BuffP(S.Broadside) and 1 or 0) + (S.QuickDraw:IsAvailable() and 1 or 0))
			and Player:BuffP(S.Opportunity) then
		return S.PistolShot:Cast()
	end
	-- actions.build+=/sinister_strike
	if S.SinisterStrike:IsReady(S.SinisterStrike) then
		return S.SinisterStrike:Cast()
	end
end

-- APL Main
local function APL ()
	-- Unit Update
	HL.GetEnemies(8); -- Cannonball Barrage
	HL.GetEnemies(S.Dispatch); -- Blade Flurry
	HL.GetEnemies(S.SinisterStrike); -- Melee

	if S.CrimsonVial:IsReady() and Player:HealthPercentage() <= 70 then
		return S.CrimsonVial:Cast()
	end    

	-- Out of Combat
	if not Player:AffectingCombat() then
		-- Stealth
		if IsStealthed() == false then
			return S.Stealth:Cast()
		end
		-- Flask
		-- Food
		-- Rune
		-- PrePot w/ Bossmod Countdown
		-- Opener
		if RubimRH.TargetIsValid() and Target:IsInRange(S.SinisterStrike) then
			if Player:ComboPoints() >= 5 then
				if S.Dispatch:IsReady() then
					return S.Dispatch:Cast()
				end
			else
				if Player:IsStealthed(true, true) and S.Ambush:IsReady() then
					return S.Ambush:Cast()
				elseif S.SinisterStrike:IsReady() then
					return S.SinisterStrike:Cast()
				end
			end
		end
		return 0, 462338
	end

	-- In Combat
	if RubimRH.TargetIsValid() then
		-- actions+=/call_action_list,name=stealth,if=stealthed.all
		if Player:IsStealthed(true, true) then
			if Stealth() ~= nil then
				return Stealth()
			end
		end

		-- actions+=/call_action_list,name=cds
		if CDs() ~= nil then
			return CDs()
		end
		-- actions+=/call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
		if Player:ComboPoints() >= CPMaxSpend() - (num(Player:BuffP(S.Broadside)) + num(Player:BuffP(S.Opportunity))) * num(S.QuickDraw:IsAvailable() and (not S.MarkedforDeath:IsAvailable() or S.MarkedforDeath:CooldownRemainsP() > 1)) then
			if Finish() ~= nil then
				return Finish()
			end
		end
		-- actions+=/call_action_list,name=build
		if Build() ~= nil then
			return Build()
		end
		-- actions+=/arcane_torrent,if=energy.deficit>=15+energy.regen
		if S.ArcaneTorrent:IsReady(S.SinisterStrike) and Player:EnergyDeficitPredicted() > 15 + Player:EnergyRegen() then
			return S.ArcaneTorrent:Cast()
		end
		-- actions+=/arcane_pulse
		if S.ArcanePulse:IsReady(S.SinisterStrike) then
			return S.ArcanePulse:Cast()
		end
		-- actions+=/lights_judgment
		if S.LightsJudgment:IsReady(S.SinisterStrike) then
			return S.LightsJudgment:Cast()
		end
		-- OutofRange Pistol Shot
		if not Target:IsInRange(10) and S.PistolShot:IsReady(20) and not Player:IsStealthed(true, true)
				and Player:EnergyDeficitPredicted() < 25 and (Player:ComboPointsDeficit() >= 1 or EnergyTimeToMaxRounded() <= 1.2) then
			return S.PistolShot:Cast()
		end
	end
	return 0, 135328
end

RubimRH.Rotation.SetAPL(260, APL)

local function PASSIVE()
	return RubimRH.Shared()
end

RubimRH.Rotation.SetPASSIVE(260, PASSIVE)