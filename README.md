# Dasogl
### Plugins contain in this repo are either:
* Created by me
* Created by someone else but I edited to add/change/remove/fix features (credits go to their original creators)
#### Only source files are provided (not to recompile everytime I update the source)
#### The required .inc files and bash compiler for Windows are included.
## Plugin List
### Advertisements
* Fetched from [Advertisements 2.0 in AlliedModders](https://forums.alliedmods.net/showthread.php?p=592536) and merged [pull request by rikka0w0](https://github.com/ErikMinekus/sm-advertisements/pull/3) to support colors in L4D2
* Color tag logic is the same as **colors.inc** {default}, {green}, {lightgreen}, {olive}
* "top" type advertisements are not supported in L4D2
* Grab the [config file](https://github.com/ErikMinekus/sm-advertisements/blob/master/addons/sourcemod/configs/advertisements.txt) from its original repo to use it.
### Confogl's Competitive Core Plugin (confoglcompmod)
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/confoglcompmod.sp)
* Localized common notification chat outputs (such as loading matchmodes, convar changes defined by confogl)
* Enabled debug for ReqMatch module to let server owners follow the moment when match mode is being loaded easily.
### Skeet Database (database_skeet)
* Fethed from [its original repo by Harry Potter](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/top)
* Changed some mutual forwards to L4D2 exclusive ones to better support L4D2.
* Removed sound that plays when a skeet is recorded.
* Localized the TOP 5 Skeeters panel
* Disabled skeet announces since they are already provided by Tabun's l4d2_skill_detect and Sir's l4d2_stats plugins.
* Changed chat commands: **!top5skeet !skeetrank**
### Boss Flow Announce (l4d_boss_percent)
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/l4d_boss_percent.sp)
* Inserted !tankpool command output to !boss, !tank and !witch command outputs.
* Localized command outputs.
* Prevented spawns that doesn't exist from appearing as ReadyUp footer. (Such as _Witch: None_ or _Tank: None_)
### Tank Control Handler/Announce (l4d_tank_control_eq)
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/l4d_tank_control_eq.sp)
* Made !tankpool command output visible for sender client only.
* Localized outputs. (D
### Damage Done To Tank Announce (l4d_tank_damage_announce)
* Fetched from [Sir's Competitive Rework Repo](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d_tank_damage_announce.sp)
* Localized outputs.
### Weapon/Item Carry Limit (l4d_weapon_limits)
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/l4d_weapon_limits.sp)
* Localized "max weapon/item limit reached" output.
### Damage Done To Witch Announce (l4d_witch_damage_announce)
* Fetched from [Sir's Competitive Rework Repo](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d_witch_damage_announce.sp)
* Improved and localized chat outputs.
### Finite Horde Announcer/Tracker (l4d2_horde_equaliser)
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/l4d2_horde_equaliser.sp)
* Decreased the minimum value for audial feedback.
* Localized horde notifiers.
### Mix Manager (l4d2_mix)
* Fetched from [its original repo by LuckyLock](https://github.com/LuckyServ/sourcemod-plugins/blob/master/source/l4d2_mix.sp)
* Localized the captain/player pick menu and chat outputs.
* Prevented spectators to vote for mix
* Increased required vote count to start mix (from 2 to 5)
* Only admins with root access can instantly start mix or stop mix.
### Tank Announce & Random Tank Model Chooser (l4d2_tank_model)
* Chooses randomly available tank models in the server (default one or the one appears in the trailer from The Sacrifice 1st chapter.)
* Notifies and plays sound upon tank spawn. (To help players who turn off/lower music volume for better hearing infected.)
### Toxic Taunting Bots (l4d2_toxic_bots)
* Bots can now taunt, cry via chat.
* Several conditions can trigger every bot in the game. (ex. survivor is incapacitated, saferoom door closed, hit by tank rock, etc.)
* Requires Tabun's l4d2_skill_detect plugin.
### Match Vote
* Fetched [Sir's version](https://github.com/SirPlease/SirCoding/blob/master/PublicSourceSP/Old%20(2014%20and%20Earlier)/match_vote.sp)
* Added outputs that who voted Yes or No during a match or rmatch vote.
* Localized vote outputs.
### Pause
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/pause.sp)
* Added checkboxes to team status panel.
* Localized team status panel and chat outputs.
### playermanagement - Spectate & Swap Players
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/playermanagement.sp)
* Localized spectate line
### Improved ReadyUp
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/readyup.sp)
* Added checkboxes from Sir's ZoneMod version.
* Added date and time to the panel.
* Added playtime to the panel.
* Localized the panel and !speckick command outputs.
### Hyper-V HUD Manager (spechud)
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/spechud.sp)
* Localized the panel.
* Changed the way pass count displayed in tankhud.
### File Consistency Checker a.k.a improvoment for sv_consistency (sv_consistency_fix)
* Fetched fixes from [devilesk's version](https://github.com/devilesk/rl4d2l-plugins/blob/master/sv_consistency_fix.sp)
* Edited console output.
### Speaking List (speaklist)
* Fetched from [its original repo by Harry Potter](https://github.com/fbef0102/L4D1-Competitive-Plugins/tree/master/SpeakingList)
* Spectators can no longer see if someone in survivors or infected is speaking regardless of sv_alltalk value
