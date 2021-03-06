--- Localize Vars
local RubimRH = LibStub("AceAddon-3.0"):GetAddon("RubimRH")

-- Addon
local addonName, addonTable = ...;

-- HeroLib
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = HL.Spell;
local Item = HL.Item;

local S = RubimRH.Spell[71]

S.Warbreaker.TextureSpellID = { 20594 }
S.SkullSplinter.TextureSpellID = { 58984 }

-- Items
if not Item.Warrior then
    Item.Warrior = {}
end
Item.Warrior.Arms = {
    -- Legendaries
    TheGreatStormsEye = Item(151823, { 1 }),
    -- Misc
    PoPP = Item(142117),
};
local I = Item.Warrior.Arms;


-- APL Variables
local function battle_cry_deadly_calm()
    if Player:Buff(S.BattleCryBuff) and S.DeadlyCalm:IsAvailable() then
        return true
    else
        return false
    end
end

local T202PC, T204PC = HL.HasTier("T20");
local T212PC, T214PC = HL.HasTier("T21");

local function Cleave()
    --	actions.cleave=bladestorm,if=buff.battle_cry.up&!talent.ravager.enabled
    if S.Bladestorm:IsReady() and Player:Buff(S.BattleCry) and not S.Ravager:IsAvailable() then
        return S.Bladestorm:Cast()
    end

    --	actions.cleave+=/ravager,if=talent.ravager.enabled&cooldown.battle_cry.remains<=gcd&debuff.colossus_smash.remains>6
    if RubimRH.config.Spells[2].isActive and S.Ravager:IsReady() and (S.BattleCry:CooldownRemainsP() <= Player:GCD() and Target:DebuffRemainsP(S.ColossusSmashDebuff) > 6) then
        return S.Ravager:Cast()
    end

    --	actions.cleave+=/colossus_smash,cycle_targets=1,if=debuff.colossus_smash.down
    if S.ColossusSmash:IsReady("Melee") and not Target:Debuff(S.ColossusSmashDebuff) then
        return S.ColossusSmash:Cast()
    end

    --	actions.cleave+=/warbreaker,if=raid_event.adds.in>90&buff.shattered_defenses.down
    if Cache.EnemiesCount[8] >= 1 and RubimRH.config.Spells[1].isActive and S.Warbreaker:IsAvailable() and S.Warbreaker:IsReady() and (not Player:Buff(S.ShatteredDefensesBuff)) then
        return S.Warbreaker:Cast()
    end

    --	actions.cleave+=/focused_rage,if=rage.deficit<35&buff.focused_rage.stack<3
    if S.FocusedRage:IsReady() and Player:BuffStack(S.FocusedRageBuff) < 3 and Player:RageDeficit() < 35 then
        return S.FocusedRage:Cast()
    end

    --	actions.cleave+=/rend,cycle_targets=1,if=remains<=duration*0.3
    if S.Rend:IsReady("Melee") and (Target:DebuffRemainsP(S.RendDebuff) <= Target:DebuffDuration(S.RendDebuff) * 0.3) then
        return S.Rend:Cast()
    end

    --	actions.cleave+=/mortal_strike
    if S.MortalStrike:IsReady("Melee") then
        return S.MortalStrike:Cast()
    end

    --	actions.cleave+=/execute
    if S.Execute:IsReady("Melee") then
        return S.Execute:Cast()
    end

    --	actions.cleave+=/cleave
    if S.Cleave:IsReady("Melee") then
        return S.Cleave:Cast()
    end

    --	actions.cleave+=/Whirlwind
    if S.Whirlwind:IsReady("Melee") then
        return S.Whirlwind:Cast()
    end
end

local function AoE()
    -- actions.aoe=warbreaker,if=(cooldown.bladestorm.up|cooldown.bladestorm.remains<=gcd)&(cooldown.battle_cry.up|cooldown.battle_cry.remains<=gcd)
    if Cache.EnemiesCount[8] >= 1 and RubimRH.config.Spells[1].isActive and S.Warbreaker:IsAvailable() and S.Warbreaker:IsReady() and ((S.Bladestorm:CooldownRemainsP() == 0 or S.Bladestorm:CooldownRemainsP() <= Player:GCD()) and (S.BattleCry:CooldownRemainsP() == 0 or S.BattleCry:CooldownRemainsP() <= Player:GCD())) then
        return S.Warbreaker:Cast()
    end

    --actions.aoe+=/bladestorm,if=buff.battle_cry.up&!talent.ravager.enabled
    if Cache.EnemiesCount[8] >= 1 and S.Bladestorm:IsReady() and Player:Buff(S.BattleCryBuff) and not S.Ravager:IsAvailable() then
        return S.Bladestorm:Cast()
    end

    --actions.aoe+=/ravager,if=talent.ravager.enabled&cooldown.battle_cry.remains<=gcd&debuff.colossus_smash.remains>6
    if RubimRH.config.Spells[2].isActive and S.Ravager:IsReady() and (S.BattleCry:CooldownRemainsP() <= Player:GCD() and Target:DebuffRemainsP(S.ColossusSmashDebuff) > 6) then
        return S.Ravager:Cast()
    end

    -- actions.aoe+=/colossus_smash,if=buff.in_for_the_kill.down&talent.in_for_the_kill.enabled
    if S.ColossusSmash:IsReady("Melee") and (not Player:Buff(S.InForTheKillBuff) and S.InForTheKill:IsAvailable()) then
        return S.ColossusSmash:Cast()
    end

    -- actions.aoe+=/colossus_smash,cycle_targets=1,if=debuff.colossus_smash.down&spell_targets.Whirlwind<=10
    if S.ColossusSmash:IsReady("Melee") and (not Target:Debuff(S.ColossusSmashDebuff) and Cache.EnemiesCount[8] <= 10) then
        return S.ColossusSmash:Cast()
    end

    -- actions.aoe+=/cleave,if=spell_targets.Whirlwind>=5
    if S.Cleave:IsReady("Melee") and (Cache.EnemiesCount[8] >= 5) then
        return S.Cleave:Cast()
    end

    -- actions.aoe+=/Whirlwind,if=spell_targets.Whirlwind>=5&buff.cleave.up
    if S.Whirlwind:IsReady() and (Cache.EnemiesCount[8] >= 5 and Player:Buff(S.CleaveBuff)) then
        return S.Whirlwind:Cast()
    end

    -- actions.aoe+=/Whirlwind,if=spell_targets.Whirlwind>=7
    if S.Whirlwind:IsReady() and (Cache.EnemiesCount[8] >= 7) then
        return S.Whirlwind:Cast()
    end

    -- actions.aoe+=/colossus_smash,if=buff.shattered_defenses.down
    if S.ColossusSmash:IsReady("Melee") and (not Player:Buff(S.ShatteredDefensesBuff)) then
        return S.ColossusSmash:Cast()
    end

    -- actions.aoe+=/execute,if=buff.stone_heart.react
    if S.Execute:IsReady("Melee") and (Player:Buff(S.StoneHeartBuff)) then
        return S.Execute:Cast()
    end

    -- actions.aoe+=/mortal_strike,if=buff.shattered_defenses.up|buff.executioners_precision.down
    if S.MortalStrike:IsReady("Melee") and (Player:Buff(S.ShatteredDefensesBuff) or not Target:Debuff(S.ExecutionersPrecisionDebuff)) then
        return S.MortalStrike:Cast()
    end

    -- actions.aoe+=/rend,cycle_targets=1,if=remains<=duration*0.3&spell_targets.Whirlwind<=3
    if S.Rend:IsReady("Melee") and (Target:DebuffRemainsP(S.RendDebuff) <= Target:DebuffDuration(S.RendDebuff) * 0.3) and Cache.EnemiesCount[8] <= 3 then
        return S.Rend:Cast()
    end

    -- actions.aoe+=/cleave
    if S.Cleave:IsReady("Melee") then
        return S.Cleave:Cast()
    end

    -- actions.aoe+=/Whirlwind
    if S.Whirlwind:IsReady("Melee") then
        return S.Whirlwind:Cast()
    end
end

local function Execute()
    -- actions.execute=bladestorm,if=buff.battle_cry.up&(set_bonus.tier20_4pc|equipped.the_great_storms_eye)
    if Cache.EnemiesCount[8] >= 1 and S.Bladestorm:IsReady() and (Player:Buff(S.BattleCryBuff) and (HL.Tier20_4Pc or I.TheGreatStormsEye:IsEquipped())) then
        return S.Bladestorm:Cast()
    end

    -- actions.execute+=/colossus_smash,if=buff.shattered_defenses.down&(buff.battle_cry.down|buff.battle_cry.remains>gcd.max)
    if S.ColossusSmash:IsReady() and (not Player:Buff(S.ShatteredDefensesBuff) and (not Player:Buff(S.BattleCryBuff) or Player:BuffRemainsP(S.BattleCryBuff) > Player:GCD())) then
        return S.ColossusSmash:Cast()
    end

    -- actions.execute+=/warbreaker,if=(raid_event.adds.in>90|!raid_event.adds.exists)&cooldown.mortal_strike.remains<=gcd.remains&buff.shattered_defenses.down&buff.executioners_precision.stack=2
    if Cache.EnemiesCount[8] >= 1 and RubimRH.config.Spells[1].isActive and S.Warbreaker:IsAvailable() and S.Warbreaker:IsReady() and (S.MortalStrike:CooldownRemainsP() <= Player:GCDRemains() and not Player:Buff(S.ShatteredDefensesBuff) and Target:DebuffStack(S.ExecutionersPrecisionDebuff) == 2) then
        return S.Warbreaker:Cast()
    end

    -- actions.execute+=/focused_rage,if=rage.deficit<35
    if S.FocusedRage:IsReady() and (Player:RageDeficit() < 35) then
        return S.FocusedRage:Cast()
    end

    -- actions.execute+=/rend,if=remains<5&cooldown.battle_cry.remains<2&(cooldown.bladestorm.remains<2|!set_bonus.tier20_4pc)
    if S.Rend:IsReady("Melee") and (Target:DebuffRemainsP(S.RendDebuff) < 5 and S.BattleCry:CooldownRemainsP() < 2 and (S.Bladestorm:CooldownRemainsP() < 2 or not HL.Tier20_4Pc)) then
        return S.Rend:Cast()
    end

    -- actions.execute+=/ravager,if=cooldown.battle_cry.remains<=gcd&debuff.colossus_smash.remains>6
    if RubimRH.config.Spells[2].isActive and S.Ravager:IsReady() and (S.BattleCry:CooldownRemainsP() <= Player:GCD() and Target:DebuffRemainsP(S.ColossusSmashDebuff) > 6) then
        return S.Ravager:Cast()
    end

    -- actions.execute+=/mortal_strike,if=buff.executioners_precision.stack=2&buff.shattered_defenses.up
    if S.MortalStrike:IsReady("Melee") and (Target:DebuffStack(S.ExecutionersPrecisionDebuff) == 2 and Player:Buff(S.ShatteredDefensesBuff)) then
        return S.MortalStrike:Cast()
    end

    -- actions.execute+=/Whirlwind,if=talent.fervor_of_battle.enabled&buff.weighted_blade.stack=3&debuff.colossus_smash.up&buff.battle_cry.down
    if S.Whirlwind:IsReady() and S.FervorOfBattle:IsAvailable() and Player:BuffStack(S.FocusedRageBuff) == 3 and Target:Debuff(S.ColossusSmashDebuff) and not Player:Buff(S.BattleCryBuff) then
        return S.Whirlwind:Cast()
    end

    -- actions.execute+=/overpower,if=rage<40
    if S.Overpower:IsReady("Melee") and (Player:Rage() < 40) then
        return S.Overpower:Cast()
    end

    -- actions.execute+=/execute,if=buff.shattered_defenses.down|rage>=40|talent.dauntless.enabled&rage>=36
    if S.Execute:IsReady("Melee") and (not Player:Buff(S.ShatteredDefensesBuff) or Player:Rage() >= 40 or S.Dauntless:IsAvailable() and Player:Rage() >= 36) then
        return S.Execute:Cast()
    end

    -- actions.execute+=/bladestorm,interrupt=1,if=(raid_event.adds.in>90|!raid_event.adds.exists|spell_targets.bladestorm_mh>desired_targets)&!set_bonus.tier20_4pc
    if S.Bladestorm:IsReady() and (Cache.EnemiesCount[8] > 1 and not HL.Tier20_4Pc) then
        return S.Bladestorm:Cast()
    end
end

local function Single()

    if S.SkullSplinter:IsAvailable() and S.SkullSplinter:IsReady("Melee") and Player:RageDeficit() >= 35 then
        return S.SkullSplinter:Cast()
    end

    -- actions.single=bladestorm,if=buff.battle_cry.up&(set_bonus.tier20_4pc|equipped.the_great_storms_eye)
    if Cache.EnemiesCount[8] >= 1 and S.Bladestorm:IsReady() and (Player:Buff(S.BattleCryBuff) and (HL.Tier20_4Pc or I.TheGreatStormsEye:IsEquipped())) then
        return S.Bladestorm:Cast()
    end

    -- actions.single+=/colossus_smash,if=buff.shattered_defenses.down
    if S.ColossusSmash:IsReady("Melee") and (not Player:Buff(S.ShatteredDefensesBuff)) then
        return S.ColossusSmash:Cast()
    end

    -- actions.single+=/warbreaker,if=(raid_event.adds.in>90|!raid_event.adds.exists)&((talent.fervor_of_battle.enabled&debuff.colossus_smash.remains<gcd)|!talent.fervor_of_battle.enabled&((buff.stone_heart.up|cooldown.mortal_strike.remains<=gcd.remains)&buff.shattered_defenses.down))
    if Cache.EnemiesCount[8] >= 1 and RubimRH.config.Spells[1].isActive and S.Warbreaker:IsAvailable() and S.Warbreaker:IsReady() and ((S.FervorOfBattle:IsAvailable() and Target:DebuffRemainsP(S.ColossusSmashDebuff) < Player:GCD()) or not S.FervorOfBattle:IsAvailable() and ((Player:Buff(S.StoneHeartBuff) or S.MortalStrike:CooldownRemainsP() <= Player:GCDRemains()) and not Player:Buff(S.ShatteredDefensesBuff))) then
        return S.Warbreaker:Cast()
    end

    -- actions.single+=/focused_rage,if=!buff.battle_cry_deadly_calm.up&buff.focused_rage.stack<3&!cooldown.colossus_smash.up&(rage>=130|debuff.colossus_smash.down|talent.anger_management.enabled&cooldown.battle_cry.remains<=8)
    if S.FocusedRage:IsReady() and (not battle_cry_deadly_calm() and Player:BuffStack(S.FocusedRageBuff) < 3 and S.ColossusSmash:CooldownRemainsP() > 0 and (Player:Rage() >= 130 or Target:Debuff(S.ColossusSmashDebuff) or (S.AngerManagement:IsAvailable() and S.BattleCry:CooldownRemainsP() <= 8))) then
        return S.FocusedRage:Cast()
    end

    -- actions.single+=/rend,if=remains<=gcd.max|remains<5&cooldown.battle_cry.remains<2&(cooldown.bladestorm.remains<2|!set_bonus.tier20_4pc)
    if S.Rend:IsReady("Melee") and (Target:DebuffRemainsP(S.RendDebuff) < 5 and S.BattleCry:CooldownRemainsP() < 2 and (S.Bladestorm:CooldownRemainsP() < 2 or not HL.Tier20_4Pc)) then
        return S.Rend:Cast()
    end

    -- actions.single+=/ravager,if=cooldown.battle_cry.remains<=gcd&debuff.colossus_smash.remains>6
    if RubimRH.config.Spells[2].isActive and S.Ravager:IsReady() and (S.BattleCry:CooldownRemainsP() <= Player:GCD() and Target:DebuffRemainsP(S.ColossusSmashDebuff) > 6) then
        return S.Ravager:Cast()
    end

    -- actions.single+=/execute,if=buff.stone_heart.react
    if S.Execute:IsReady("Melee") and (Player:Buff(S.StoneHeartBuff)) then
        return S.Execute:Cast()
    end

    -- actions.single+=/overpower,if=buff.battle_cry.down
    if S.Overpower:IsReady("Melee") and (not Player:Buff(S.BattleCryBuff)) then
        return S.Overpower:Cast()
    end

    -- actions.single+=/mortal_strike,if=buff.shattered_defenses.up|buff.executioners_precision.down
    if S.MortalStrike:IsReady("Melee") and (Player:Buff(S.ShatteredDefensesBuff) or not Target:Debuff(S.ExecutionersPrecisionDebuff)) then
        return S.MortalStrike:Cast()
    end

    -- actions.single+=/rend,if=remains<=duration*0.3
    if S.Rend:IsReady("Melee") and (Target:DebuffRemainsP(S.RendDebuff) <= Target:DebuffDuration(S.RendDebuff) * 0.3) then
        return S.Rend:Cast()
    end

    -- actions.single+=/Whirlwind,if=spell_targets.Whirlwind>1|talent.fervor_of_battle.enabled
    if S.Whirlwind:IsReady("Melee") and (Cache.EnemiesCount[8] > 1 or S.FervorOfBattle:IsAvailable()) then
        return S.Whirlwind:Cast()
    end

    -- actions.single+=/slam,if=spell_targets.Whirlwind=1&!talent.fervor_of_battle.enabled&(rage>=52|!talent.rend.enabled|!talent.ravager.enabled)
    if S.Slam:IsReady("Melee") and (Cache.EnemiesCount[8] <= 1 and not S.FervorOfBattle:IsAvailable() and (Player:Rage() >= 52 or not S.Rend:IsAvailable() or not S.Ravager:IsAvailable())) then
        return S.Slam:Cast()
    end

    -- actions.single+=/overpower
    if S.Overpower:IsReady("Melee") then
        return S.Overpower:Cast()
    end

    -- actions.single+=/bladestorm,if=(raid_event.adds.in>90|!raid_event.adds.exists)&!set_bonus.tier20_4pc
    if Cache.EnemiesCount[8] >= 1 and S.Bladestorm:IsReady() and (not HL.Tier20_4Pc) then
        return S.Bladestorm:Cast()
    end
end

local function APL()
    -- Unit Update
    HL.GetEnemies(8); -- Whirlwind
    -- Out of Combat

    if not Player:AffectingCombat() then
        return 0, 462338
    end

    -- In Combat
    if RubimRH.TargetIsValid() then
        if RubimRH.config.Spells[3].isActive and S.Charge:IsReady() and Target:IsInRange(S.Charge) then
            return S.Charge:Cast()
        end

        if Player:Buff(S.Victorious) and S.VictoryRush:IsReady() and Player:HealthPercentage() <= RubimRH.db.profile[71].victoryrush then
            return S.VictoryRush:Cast()
        end

        if Player:Buff(S.Victorious) and Player:BuffRemains(S.Victorious) <= 2 and S.VictoryRush:IsReady() then
            return S.VictoryRush:Cast()
        end
        -- Racial
        -- actions+=/blood_fury,if=buff.battle_cry.up|target.time_to_die<=16
        if S.BloodFury:IsReady() and RubimRH.CDsON() and (Player:Buff(S.BattleCryBuff) or Target:TimeToDie() <= 16) then
            return S.BloodFury:Cast()
        end

        -- Racial
        -- actions+=/berserking,if=buff.battle_cry.up|target.time_to_die<=11
        if S.Berserking:IsReady() and RubimRH.CDsON() and (Player:Buff(S.BattleCryBuff) or Target:TimeToDie() <= 11) then
            return S.Berserking:Cast()
        end

        -- Racial
        -- actions+=/arcane_torrent,if=buff.battle_cry_deadly_calm.down&rage.deficit>40&cooldown.battle_cry.remains
        if S.ArcaneTorrent:IsReady() and RubimRH.CDsON() and (not battle_cry_deadly_calm() and Player:RageDeficit() > 40 and S.BattleCry:CooldownRemainsP() > 0) then
            return S.ArcaneTorrent:Cast()
        end

        -- Omit gcd.remains on this offGCD because we can't react quickly enough otherwise (the intention is to cast this before the next GCD ability, but is a OffGCD abiltiy).
        -- actions+=/avatar,if=gcd.remains<0.25&(buff.battle_cry.up|cooldown.battle_cry.remains<15)|target.time_to_die<=20
        if S.Avatar:IsReady("Melee") and RubimRH.CDsON() and ((Player:Buff(S.BattleCryBuff) or S.BattleCry:CooldownRemainsP() < 15) or Target:TimeToDie() <= 20) then
            return S.Avatar:Cast()
        end

        -- Omit gcd.remains on this offGCD because we can't react quickly enough otherwise (the intention is to cast this before the next GCD ability, but is a OffGCD abiltiy).
        -- actions+=/battle_cry,if=target.time_to_die<=6|(gcd.remains<=0.5&prev_gcd.1.ravager)|!talent.ravager.enabled&!gcd.remains&target.debuff.colossus_smash.remains>=5&(!cooldown.bladestorm.remains|!set_bonus.tier20_4pc)&(!talent.rend.enabled|dot.rend.remains>4)
        if S.BattleCry:IsReady("Melee") and RubimRH.CDsON() and (Target:TimeToDie() <= 6 or (Player:PrevGCD(1, S.Ravager)) or not S.Ravager:IsAvailable() and Target:DebuffRemainsP(S.ColossusSmashDebuff) >= 5 and (S.Bladestorm:CooldownRemainsP() == 0 or not HL.Tier20_4Pc) and (not S.Rend:IsAvailable() or Target:DebuffRemainsP(S.RendDebuff) > 4)) then
            return S.BattleCry:Cast()
        end

        -- actions+=/run_action_list,name=cleave,if=spell_targets.Whirlwind>=2&talent.sweeping_strikes.enabled
        if Cache.EnemiesCount[8] >= 2 and S.SweepingStrikes:IsAvailable() and Cleave() ~= nil then
            return Cleave()
        end

        -- actions+=/run_action_list,name=execute,target_if=target.health.pct<=20&spell_targets.Whirlwind<5
        if Target:Exists() and Target:HealthPercentage() <= 20 and Cache.EnemiesCount[8] < 5 and Execute() ~= nil then
            return Execute()
        end

        -- actions+=/run_action_list,name=aoe,if=spell_targets.Whirlwind>=4
        if Cache.EnemiesCount[8] >= 2 and AoE() ~= nil then
            return AoE()
        end

        -- actions+=/run_action_list,name=cleave,if=spell_targets.Whirlwind>=2
        if Cache.EnemiesCount[8] >= 2 and Cleave() ~= nil then
            return Cleave()
        end

        -- actions+=/run_action_list,name=single,if=target.health.pct>20
        if ((Target:Exists() and Target:HealthPercentage() > 20) or true) and Single() ~= nil then
            return Single()
        end

    end
    return 0, 135328
end
RubimRH.Rotation.SetAPL(71, APL);

local function PASSIVE()
    return RubimRH.Shared()
end

RubimRH.Rotation.SetPASSIVE(71, PASSIVE);