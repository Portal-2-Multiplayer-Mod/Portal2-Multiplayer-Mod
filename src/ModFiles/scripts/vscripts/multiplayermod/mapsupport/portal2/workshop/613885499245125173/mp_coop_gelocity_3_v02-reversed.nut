// ███╗   ███╗██████╗             █████╗  █████╗  █████╗ ██████╗             ██████╗ ███████╗██╗      █████╗  █████╗ ██╗████████╗██╗   ██╗           ██████╗            ██╗   ██╗ █████╗ ██████╗
// ████╗ ████║██╔══██╗           ██╔══██╗██╔══██╗██╔══██╗██╔══██╗           ██╔════╝ ██╔════╝██║     ██╔══██╗██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝           ╚════██╗           ██║   ██║██╔══██╗╚════██╗
// ██╔████╔██║██████╔╝           ██║  ╚═╝██║  ██║██║  ██║██████╔╝           ██║  ██╗ █████╗  ██║     ██║  ██║██║  ╚═╝██║   ██║    ╚████╔╝             █████╔╝           ╚██╗ ██╔╝██║  ██║  ███╔═╝
// ██║╚██╔╝██║██╔═══╝            ██║  ██╗██║  ██║██║  ██║██╔═══╝            ██║  ╚██╗██╔══╝  ██║     ██║  ██║██║  ██╗██║   ██║     ╚██╔╝              ╚═══██╗            ╚████╔╝ ██║  ██║██╔══╝
// ██║ ╚═╝ ██║██║     ██████████╗╚█████╔╝╚█████╔╝╚█████╔╝██║     ██████████╗╚██████╔╝███████╗███████╗╚█████╔╝╚█████╔╝██║   ██║      ██║   ██████████╗██████╔╝██████████╗  ╚██╔╝  ╚█████╔╝███████╗
// ╚═╝     ╚═╝╚═╝     ╚═════════╝ ╚════╝  ╚════╝  ╚════╝ ╚═╝     ╚═════════╝ ╚═════╝ ╚══════╝╚══════╝ ╚════╝  ╚════╝ ╚═╝   ╚═╝      ╚═╝   ╚═════════╝╚═════╝ ╚═════════╝   ╚═╝    ╚════╝ ╚══════╝

bTournamentMode <- GetConVarInt("p2mm_gelocity_tournament_mode") // Locks down somethings so the host has full control. Default: 0
iGameLaps <- GetConVarInt("p2mm_gelocity_laps_default") // Gelocity race laps. Default: 3
iMusicTrack <- GetConVarInt("p2mm_gelocity_music_default") // Gelocity music track. Default: 0
bFinalLap <- false // Flag signifying the last lap of the race.
lWinnerList <- [] // List of winning players.
bRaceStarted <- false // Flag for checking if the race has started or is in progress.

isRotating <- false // Flag to see if the fan should be spinning or not.
fanofftimer <- 0 // Timer to turn off fan.

MAP_CHECKPOINTS <- [
    "checkpoint_1",
    "checkpoint_2",
    "checkpoint_3",
    "checkpoint_4",
    "checkpoint_5",
    "checkpoint_6",
    "checkpoint_7",
    "checkpoint_8",
    "checkpoint_9",
    "checkpoint_10",
    "checkpoint_11",
    "checkpoint_12",
    "checkpoint_13"
]

MAP_SPAWNPOINTS <- {


    checkpoint_2_blue   = [Vector(-4416, 3452, -424), Vector(0, 270, 0)]
    checkpoint_2_orange = [Vector(-4288, 3452, -424), Vector(0, 270, 0)]

    checkpoint_4_blue   = [Vector(-8896, -672, -296), Vector(0, 90, 0)]
    checkpoint_4_orange = [Vector(-9024, -672, -296), Vector(0, 90, 0)]

    checkpoint_5_blue   = [Vector(-4767, -2752, -424), Vector(0, 180, 0)]
    checkpoint_5_orange = [Vector(-4767, -2880, -424), Vector(0, 180, 0)]

    checkpoint_6_blue   = [Vector(1472, -2752, -424), Vector(0, 180, 0)]
    checkpoint_6_orange = [Vector(1472, -2880, -424), Vector(0, 180, 0)]

    checkpoint_7_blue   = [Vector(5024, -4800, 324), Vector(0, 180, 0)]
    checkpoint_7_orange = [Vector(5024, -4672, 324), Vector(0, 180, 0)]

    checkpoint_8_blue   = [Vector(3008, -1920, 196), Vector(0, 270, 0)]
    checkpoint_8_orange = [Vector(3136, -1920, 196), Vector(0, 270, 0)]

    checkpoint_9_blue   = [Vector(3008, 1184, 88), Vector(0, 270, 0)]
    checkpoint_9_orange = [Vector(3136, 1184, 88), Vector(0, 270, 0)]

    checkpoint_11_blue   = [Vector(1120, 2368, 88), Vector(0, 0, 0)]
    checkpoint_11_orange = [Vector(1120, 2240, 88), Vector(0, 0, 0)]

    checkpoint_13_blue   = [Vector(384, 1280, 0), Vector(0, 90, 0)]
    checkpoint_13_orange = [Vector(256, 1280, 0), Vector(0, 90, 0)]
}

function HostStartGame(player) {
    if (!bRaceStarted) {
        if (player.entindex() == 1) {
            StartGelocityRace()
            return
        } else {
            HudPrint(player.entindex(), "Only the host can start the game!", Vector(-1, 0.2, 3), 0, 0.0, Vector(255, 255, 255), 255, Vector(0, 0, 0), 0, Vector(0.5, 3, 0.5))
        }
    }
}

function DevFillPassedPoints(index) {
    local playerClass = FindPlayerClass(PlayerByIndex(index))
    if (!playerClass) return
    playerClass.l_PassedCheckpoints.clear()
    playerClass.l_PassedCheckpoints.extend(MAP_CHECKPOINTS)
}

function WonRace(playerClass) {
    // A player won! Trigger their teams win relay!
    if (playerClass.player.GetTeam() == TEAM_BLUE) {
        EntFire("blue_wins", "Trigger")
        EntFire("orange_wins", "Kill")
        playerClass.v_SpawnVector = null
    } else {
        EntFire("orange_wins", "Trigger")
        EntFire("blue_wins", "Kill")
        playerClass.v_SpawnVector = null
    }

    // Check to make sure if anyone triggers WonRace and they are already on the winner list to return.
    foreach (index, winner in lWinnerList) {
        // Only add someone to the list when they aren't already on and its not already containing a certain amount.
        if (winner == playerClass.player.GetName() || index >= (bTournamentMode ? 9 : 2)) return
    }
    lWinnerList.append(playerClass.username) // Add winner to the list.

    // Setup the place postfix and color that will be sent in HudPrint.
    local placeString = "th"
    local placeColor = Vector(255, 255, 255)
    switch (lWinnerList.len()) {
        case (1):
            placeString = "st"
            placeColor = Vector(255, 255, 0)
            break
        case (2):
            placeString = "nd"
            placeColor = Vector(140, 150, 140)
            break
        case (3):
            placeString = "rd"
            placeColor = Vector(150, 75, 0)
            break
        default:
            break
    }
    HudPrint(playerClass.player.entindex(), "FINISHED " + lWinnerList.len() + placeString + "!", Vector(-1, 0.2, 3), 0, 0.0, placeColor, 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 1.5))
    SendToChat(0, "\x04" + playerClass.username + " Has Passed The Finish Line For " + lWinnerList.len() + placeString + " Place!")
}

function KillLosers(player) {
    local playerClass = FindPlayerClass(player)
    if (lWinnerList[0] != playerClass.username) {
        printlP2MM(0, true, playerClass.username + " landed on pedestal, but isnt #1. Killing.")
        player.SetVelocity(Vector(player.GetVelocity().x, player.GetVelocity().y, 500))
        EntFireByHandle(player, "sethealth", "-99999999999", 0.75, null, null)
    } else {
        printlP2MM(0, true, "" + playerClass.username + " landed on pedestal, and is the winner. Not killing.")
        EntFire("glados_6_p2mmoverride", "Start")
    }
}

function CheckCompletedLaps(player, checkpoint) {
    local playerClass = FindPlayerClass(player)
    if (GetDeveloperLevelP2MM()) {
        foreach (checkpoint in playerClass.l_PassedCheckpoints) {
            printlP2MM(0, true, "" + checkpoint)
        }
    }

    // Only check for completed laps if the passed checkpoints is less to the MAP_CHECKPOINTS length and if the player hasn't finished the race.
    if (playerClass.l_PassedCheckpoints.len() < MAP_CHECKPOINTS.len() || playerClass.b_FinishedRace) return

    // Check if the player has all the required MAP_CHECKPOINTS required to complete a lap.
    for (local i = 0; i < MAP_CHECKPOINTS.len(); i++) {
        if (playerClass.l_PassedCheckpoints[i] != MAP_CHECKPOINTS[i]) return
    }

    // Player has completed the lap.
    playerClass.i_CompletedLaps++
    printlP2MM(0, true, "LAP COMPLETE")
    // The first player has reached the final lap.
    if (playerClass.i_CompletedLaps == (iGameLaps - 1) && !bFinalLap) {
        EntFire("last_lap", "PlaySound")
        HudPrint(playerClass.player.entindex(), "FINAL LAP!", Vector(-1, 0.2, 3), 2, 0, Vector(255, 0, 0), 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 1))
        SendToChat(0, "\x04" + playerClass.username + " HAS REACHED THE FINAL LAP!")
        bFinalLap = true
    }
    // Other player have reached the final lap.
    else if (playerClass.i_CompletedLaps == (iGameLaps - 1) && bFinalLap) {
        HudPrint(playerClass.player.entindex(), "FINAL LAP!", Vector(-1, 0.2, 3), 2, 0, Vector(255, 0, 0), 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 1))
    }
    // Player has completed a lap.
    else if (playerClass.i_CompletedLaps < iGameLaps) {
        HudPrint(playerClass.player.entindex(), "COMPLETED LAP " + playerClass.i_CompletedLaps + "!", Vector(-1, 0.2, 3), 2, 1, Vector(255, 255, 255), 255, Vector(0, 0, 0), 0, Vector(0.2, 0.5, 1))
    }

    // Check if the player has completed all the laps, if so, they won!
    if (playerClass.i_CompletedLaps >= iGameLaps) {
        playerClass.b_FinishedRace = true
        WonRace(playerClass)
        return
    }
    // Clear the passed checkpoint list for the next lap.
    printlP2MM(0, true, "CLEAR")
    playerClass.l_PassedCheckpoints.clear()
}

function CheckpointHit(player, checkpoint) {
    local playerClass = FindPlayerClass(player)
    // Dev debug
    printlP2MM(0, true, player.tostring())
    printlP2MM(0, true, playerClass.username)
    printlP2MM(0, true, checkpoint)
    printlP2MM(0, true, "checkpoint hit")

    if (playerClass.b_FinishedRace) return // Only register a checkpoint as hit when the player hasn't finished the race.

    // Check to make sure the player is no going the wrong direction.
    if (playerClass.l_PassedCheckpoints.len() < MAP_CHECKPOINTS.len() - 1 && checkpoint == MAP_CHECKPOINTS[MAP_CHECKPOINTS.len() - 1]) {
        if (player.GetTeam() == TEAM_BLUE) {
            playerClass.v_SpawnVector = null
        } else {
            playerClass.v_SpawnVector = null
        }

        // Delayed because instant respawn makes the game_text disappear.
        EntFireByHandle(player, "RunScriptCode", "HudPrint(" + player.entindex() + ", \"WRONG WAY!\", Vector(-1, 0.6, 3) 0, 0, Vector(255, 0, 0), 255, Vector(0, 0, 0), 0, Vector(0, 2, 1))", 0.1, null, null)
        RespawnPlayer(player.entindex())
        return
    }

    // Dev debug
    if (GetDeveloperLevelP2MM()) {
        HudPrint(player.entindex(), "CHECKPOINT: " + checkpoint, Vector(-1, 0.8, 2), 0, 0, Vector(0, 150, 255), 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 1))
    }

    // Check if the player hasn't already passed the point.
    foreach (passedpoint in playerClass.l_PassedCheckpoints) {
        printlP2MM(0, true, passedpoint)
        if (checkpoint == passedpoint) return
    }

    playerClass.s_LastCheckPoint = checkpoint
    // Make sure no duplicate checkpoints are added to the player's passed checkpoints list.
    foreach (index, point in playerClass.l_PassedCheckpoints) {
        if (checkpoint == playerClass.l_PassedCheckpoints[index]) return
    }
    playerClass.l_PassedCheckpoints.append(checkpoint)
    printlP2MM(0, true, "checkpoint passed")
}

function StartGelocityRace() {
    bRaceStarted = true;
    EntFire("painter", "Paint")
    EntFire("painter", "Kill", "", 5)
    EntFire("gel_relay", "Trigger")

    // Move everyone into their respective start positions.
    for (local p = null; p = Entities.FindByClassname(p, "player");) {
        p.SetAngles(0, 0, 0)
        if (p.GetTeam() == TEAM_RED) {
            p.SetOrigin(Vector(-5184, 848, -64))
        } else {
            p.SetOrigin(Vector(-5184, 688, -64))
        }
    }

    // Move start locations incase someone dies without hitting a checkpoint
    Entities.FindByName(null, "red_dropper-initial_spawn").SetOrigin(Vector(-4904, 848, -64))
    Entities.FindByName(null, "blue_dropper-initial_spawn").SetOrigin(Vector(-4904, 688, -64))
    Entities.FindByName(null, "red_dropper-initial_spawn").SetAngles(0, 0, 0)
    Entities.FindByName(null, "blue_dropper-initial_spawn").SetAngles(0, 0, 0)

    // Lock the buttons so no one can change the laps once the game started.
    EntFire("rounds_button_1", "Lock")
    EntFire("button_1", "Skin", "1")
    EntFire("rounds_button_2", "Lock")
    EntFire("button_2", "Skin", "1")

    // Close the doors so no one can escape.
    EntFire("door_start_1_1", "Close")
    EntFire("door_start_1_2", "Close")
    EntFire("door_start_2_1", "Close")
    EntFire("door_start_2_2", "Close")
    EntFire("door_start", "SetAnimation" "close")

    // Start the countdown... and the RACE!
    EntFire("relay_start_p2mmoverride", "Trigger")
}

// When a player respawns, send them back to the last spawning checkpoint they've passed as indicated by v_SpawnVector.
function GEPlayerRespawn(player) {
    local playerClass = FindPlayerClass(player)

    if (playerClass.v_SpawnVector == null) return

    player.SetOrigin(playerClass.v_SpawnVector[0])
    player.SetAngles(playerClass.v_SpawnVector[1].x, playerClass.v_SpawnVector[1].y, playerClass.v_SpawnVector[1].z)
}

// If a player dies, set spawn vector to be at the last applicable spawn point.
function GEPlayerDeath(userid, attacker, entindex) {
    printlP2MM(0, false, "tejasdfhasjdf")
    local player = PlayerByIndex(entindex) 
    local playerClass = FindPlayerClass(player)

    if (playerClass.s_LastCheckPoint == "start") { return }

    foreach (spawn_name, spawn_vector in MAP_SPAWNPOINTS) {
        printlP2MM(0, false, spawn_name.tostring())
        if (playerClass.s_LastCheckPoint + (player.GetTeam() == TEAM_BLUE ? "_blue" : "_orange") == spawn_name) {
            playerClass.v_SpawnVector = spawn_vector
            return
        }
    }
    printlP2MM(1, false, "Player last checkpoint does not match any on the list!")
}

function GameLapsAdd() {
    if (iGameLaps >= 300) return

    iGameLaps++
    HudPrint(0, "Race Laps: " + iGameLaps, Vector(-1, 0.2, 3), 0, 0.0, Vector(255, 255, 255), 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 0.5))

    if (iGameLaps >= 300) {
        EntFire("rounds_button_1", "Unlock", "", 0, null)
        EntFire("rounds_button_2", "Lock", "", 0, null)
        EntFire("button_1", "Skin", "0", 0, null)
        EntFire("button_2", "Skin", "1", 0, null)
        return
    }

    if (iGameLaps < 300 && iGameLaps > 1) {
        EntFire("rounds_button_1", "Unlock", "", 0, null)
        EntFire("rounds_button_2", "Unlock", "", 0, null)
        EntFire("button_1", "Skin", "0", 0, null)
        return
    }
}

// Subtract a lap to iGameLaps.
function GameLapsSub() {
    if (iGameLaps <= 1) return

    iGameLaps--
    HudPrint(0, "Race Laps: " + iGameLaps, Vector(-1, 0.2, 3), 0, 0.0, Vector(255, 255, 255), 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 0.5))
    
    if (iGameLaps <= 1) {
        EntFire("rounds_button_1", "Lock", "", 1, null)
        EntFire("rounds_button_2", "Unlock", "", 1, null)
        EntFire("button_2", "Skin", "0", 0, null)
        EntFire("button_1", "Skin", "1", 0, null)
        return
    }

    if (iGameLaps < 300 && iGameLaps > 1) {      
        EntFire("rounds_button_1", "Unlock", "", 0, null)
        EntFire("rounds_button_2", "Unlock", "", 0, null)
        EntFire("button_2", "Skin", "0", 0, null)
        return
    }
}

// Progress music track up one.
function GameMusicNext() {
    if (iMusicTrack >= 5) return

    iMusicTrack++
    HudPrint(0, "Music Track: " + iMusicTrack, Vector(-1, 0.2, 3), 0, 0.0, Vector(255, 255, 255), 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 0.5))
    EntFire("counter_music", "SetValue", iMusicTrack)
}

// Progress music track down one.
function GameMusicBack() {
    if (iMusicTrack <= 0) return

    iMusicTrack--
    if (iMusicTrack == 0) {
        HudPrint(0, "No Music", Vector(-1, 0.2, 3), 0, 0.0, Vector(255, 255, 255), 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 0.5))
    }
    else {
        HudPrint(0, "Music Track: " + iMusicTrack, Vector(-1, 0.2, 3), 0, 0.0, Vector(255, 255, 255), 255, Vector(0, 0, 0), 0, Vector(0.5, 0.5, 0.5))
    }
    EntFire("counter_music", "SetValue", iMusicTrack)
}

function MapSupport(MSInstantRun, MSLoop, MSPostPlayerSpawn, MSPostMapSpawn, MSOnPlayerJoin, MSOnDeath, MSOnRespawn) {
    if (MSInstantRun) {
        // change some blobs to make the map possible backwards.
        Entities.FindByNameNearest("s_sphere_13", Vector(-8960, -384, -512), 32).__KeyValueFromString("paint_type", "0")
        Entities.FindByNameNearest("s_sphere_9", Vector(-2964, -2824, -512), 32).__KeyValueFromString("paint_type", "0")
        Entities.FindByNameNearest("j_sphere_3", Vector(-3607, -2760, -512), 32).__KeyValueFromString("paint_type", "2")
        Entities.FindByNameNearest("j_sphere_3", Vector(-3607, -2888, -512), 32).__KeyValueFromString("paint_type", "2")
        Entities.FindByNameNearest("s_sphere_9", Vector(-1116, -2824, -512), 32).__KeyValueFromString("paint_type", "0")
        Entities.FindByNameNearest("j_sphere_3", Vector(-1759, -2760, -512), 32).__KeyValueFromString("paint_type", "2")
        Entities.FindByNameNearest("j_sphere_3", Vector(-1759, -2888, -512), 32).__KeyValueFromString("paint_type", "2")
        //                                                                                                                                                                       what the hell is null here??!
        // EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(-8680, -968, -192), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:activator.SetVelocity(Vector(null 0 -600 -100))", 0, null, null)
        for (local gel = null; gel = Entities.FindByName(gel, "s_sphere_12");) {
            gel.__KeyValueFromString("paint_type", "0")
        }

        Entities.FindByName(null, "ml_jump_1").__KeyValueFromString("targetname", "ml_jump_1_p2mmoverride")
        Entities.FindByName(null, "ml_jump_2").__KeyValueFromString("targetname", "ml_jump_2_p2mmoverride")
        EntFire("gel_relay", "AddOutput", "OnTrigger ml_jump_1_p2mmoverride:Open::17")
        EntFire("gel_relay", "AddOutput", "OnTrigger ml_jump_2_p2mmoverride:Open::17")
        EntFire("ml_jump_1_p2mmoverride", "AddOutput", "OnFullyOpen ml_jump_1_p2mmoverride:Close")
        EntFire("ml_jump_1_p2mmoverride", "AddOutput", "OnFullyClosed ml_jump_1_p2mmoverride:Open")
        EntFire("ml_jump_2_p2mmoverride", "AddOutput", "OnFullyOpen ml_jump_2_p2mmoverride:Close")
        EntFire("ml_jump_2_p2mmoverride", "AddOutput", "OnFullyClosed ml_jump_2_p2mmoverride:Open")
        EntFire("relay_moveplat_r", "AddOutput", "OnTrigger ml_jump_2_p2mmoverride:Open")
        EntFire("relay_moveplat_l", "AddOutput", "OnTrigger ml_jump_2_p2mmoverride:Close")
        Entities.FindByNameNearest("s_sphere_10", Vector(-4736, -2824, -512), 32).__KeyValueFromString("paint_type", "0")
        Entities.FindByName(null, "launch_arm16").SetOrigin(Vector(1560, -4988, -328))
        Entities.FindByName(null, "launch_arm16").SetAngles(-90, 180, 90)
        Entities.FindByName(null, "launch_arm16").__KeyValueFromString("skin", "0")
        Entities.FindByName(null, "launch_sound16").SetOrigin(Vector(1560, -4988, -328))

        Entities.FindByName(null, "launch_arm14").SetOrigin(Vector(3712, -2492, -176))
        Entities.FindByName(null, "launch_arm14").SetAngles(-90 270 0)
        Entities.FindByName(null, "launch_sound14").SetOrigin(Vector(3712, -2492, -176))

        Entities.FindByNameNearest("s_sphere_8", Vector(1472, -4352, -704), 32).__KeyValueFromString("paint_type", "0")
        Entities.FindByNameNearest("s_sphere_8", Vector(1456, -4096, -656), 32).__KeyValueFromString("paint_type", "0")

        for (local paint = null; paint = Entities.FindByName(paint, "j_sphere_2");) {
            paint.__KeyValueFromString("paint_type", "2")
        }
        local floor = Entities.CreateByClassname("prop_dynamic")
        floor.SetOrigin(Vector(3712, 256, 0))
        floor.SetAngles(90, 90, 0)
        floor.__KeyValueFromString("model", "models/props_underground/wood_panel_64x128_01.mdl")
        floor.__KeyValueFromString("solid", "6")
        floor.__KeyValueFromString("physicsmode", "1")
        InitializeEntity(floor)

        local fan = Entities.CreateByClassname("prop_dynamic")
        fan.SetOrigin(Vector(-9127, -1588, -36))
        fan.__KeyValueFromString("model", "models/props_bts/fan01.mdl")
        fan.__KeyValueFromString("targetname", "stupidfan")
        fan.__KeyValueFromString("solid", "6")
        fan.__KeyValueFromString("physicsmode", "1")
        InitializeEntity(fan)

        local stand = Entities.CreateByClassname("prop_dynamic")
        stand.SetOrigin(Vector(-9152, -1589, -496))
        stand.__KeyValueFromString("model", "models/props_bts/huge_fan_support.mdl")
        stand.__KeyValueFromString("solid", "6")
        stand.__KeyValueFromString("physicsmode", "1")
        InitializeEntity(stand)

        areablock <- Entities.CreateByClassname("prop_dynamic")
        areablock.SetOrigin(Vector(-8380, -1535, -30))
        areablock.SetAngles(0, 30, 0)
        areablock.__KeyValueFromString("model", "models/props_bts/gantry_hoist_a.mdl")
        areablock.__KeyValueFromString("solid", "6")
        areablock.__KeyValueFromString("physicsmode", "1")
        InitializeEntity(areablock)

        Entities.FindByName(null, "launch_arm12").Destroy()
        Entities.FindByName(null, "catapult12").Destroy()

        Entities.FindByNameNearest("j_sphere_3", Vector(128, -2816, -512), 32).SetOrigin(Vector(3792, 176, 0))
        Entities.FindByNameNearest("j_sphere_1", Vector(-3328, 2720, -224), 32).__KeyValueFromString("paint_type", "3")
        Entities.FindByNameNearest("j_sphere_1", Vector(-3328, 2720, -224), 32).SetOrigin(Vector(3776, 502, 224))
        Entities.FindByNameNearest("j_sphere_1_1", Vector(-3328, 2528, -224), 32).__KeyValueFromString("paint_type", "2")
        Entities.FindByNameNearest("j_sphere_1_1", Vector(-3328, 2528, -224), 32).__KeyValueFromString("radius", "200")
        Entities.FindByNameNearest("j_sphere_1_1", Vector(-3328, 2528, -224), 32).SetOrigin(Vector(3460, 380, 136))
        Entities.FindByNameNearest("j_sphere_1_1", Vector(-3328, 2912, -224), 32).SetOrigin(Vector(3453, 699, 136))

        Entities.FindByName(null, "catapult3.1").Destroy()
        Entities.FindByName(null, "catapult3.2").Destroy()
        Entities.FindByName(null, "launch_arm3").SetOrigin(Vector(880, 2304, 5))
        Entities.FindByName(null, "launch_arm3").SetAngles(0, 180, 0)
        Entities.FindByName(null, "launch_sound3").SetOrigin(Vector(880, 2304, 5))

        Entities.FindByNameNearest("j_sphere_3", Vector(128, -2688, -512), 32).__KeyValueFromString("paint_type", "3")
        Entities.FindByNameNearest("j_sphere_3", Vector(128, -2688, -512), 32).__KeyValueFromString("radius", "230")
        Entities.FindByNameNearest("j_sphere_3", Vector(128, -2688, -512), 32).SetOrigin(Vector(760, 780, 232))
        EntFire("door_finish_2", "Close", "", 1)
        EntFire("door_finish_1", "Close", "", 1)

        Entities.FindByClassnameNearest("trigger_portal_cleanser", Vector(320, 1791.5, -128), 32).Destroy()
        Entities.FindByClassnameNearest("trigger_portal_cleanser", Vector(320, 1792, 0), 32).Destroy()
        Entities.FindByClassnameNearest("info_placement_helper", Vector(3072, -1416, 64), 32).Destroy()
        Entities.FindByClassnameNearest("info_placement_helper", Vector(3072, -1416, 192), 32).Destroy()

        //* this can still be used if needed
        Entities.FindByNameNearest("j_sphere_3", Vector(128, -2944, -512), 32).Destroy()

        // So nobody spawns here.
        Entities.FindByClassname(null, "info_player_start").Destroy()

        // Remove test chamber VGUI screen as it doesn't work.
        EntFire("info_sign-info_panel", "Kill")
        EntFire("info_sign-info_panel", "Kill", "", 0.1)

        // Remove the lap counters, VScript will keep track instead.
        Entities.FindByName(null, "rounds").Destroy()
        for (local ent = null; ent = Entities.FindByName(null, "round_counter_orange");) {
            ent.Destroy()
        }
        for (local ent = null; ent = Entities.FindByName(null, "round_counter_blue");) {
            ent.Destroy()
        }

        // Remove all the original spawn locations.
        for (local trigger = null; trigger = Entities.FindByClassname(trigger, "info_coop_spawn");) {
            if ((trigger.GetName().find("blue_spawner") != null) || (trigger.GetName().find("red_spawner") != null)) {
                trigger.Destroy()
            }
        }

        // Add new checkpoint system to triggers.
        Entities.FindByName(null, "checkpoint_blue_1").__KeyValueFromString("target_team", "0")
        Entities.FindByName(null, "checkpoint_blue_2").__KeyValueFromString("target_team", "0")
        Entities.FindByName(null, "checkpoint_blue_3").__KeyValueFromString("target_team", "0")
        Entities.FindByName(null, "checkpoint_blue_1").__KeyValueFromString("targetname", "checkpoint_blue_1_p2mmoverride")
        Entities.FindByName(null, "checkpoint_blue_2").__KeyValueFromString("targetname", "checkpoint_blue_2_p2mmoverride")
        Entities.FindByName(null, "checkpoint_blue_3").__KeyValueFromString("targetname", "checkpoint_blue_3_p2mmoverride")
        EntFire("checkpoint_blue_1_p2mmoverride", "AddOutput", "OnEndTouch !activator:RunScriptCode:CheckCompletedLaps(activator MAP_CHECKPOINTS[12])")
        EntFire("checkpoint_blue_1_p2mmoverride", "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[12])")
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(320, 1696, -128), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[11])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(-2272, 2388, 128), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[10])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(800, 2304, 448), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[9])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(3072, 1440, 128), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[8])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(3072, -2592, 128), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[7])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(5408, -4352, 256), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[6])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(480, -2816, 64), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[5])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(-4512, -2816, -384), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[4])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(-6752, -1536, -384), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[3])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(-9260, -1088, -232.77), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[2])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(-7168, 1952, -384), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[1])", 0, null, null)
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_playerteam", Vector(-4352, 4128, -384), 32), "AddOutput", "OnStartTouch !activator:RunScriptCode:CheckpointHit(activator MAP_CHECKPOINTS[0])", 0, null, null)

        // We have our own respawning system for all players. Delete all but the initial ones.
        for (local ent; ent = Entities.FindByClassname(ent, "info_coop_spawn");) {
            if (ent.GetName().find("initial_spawn") == null) {
                ent.Destroy()
            }
        }
        
        // remove +remoteview logic as it is buggy in 3+ MP
        // TODO: maybe add custom logic for this instead?
        Entities.FindByName(null, "counter_view_blue").Destroy()
        Entities.FindByName(null, "counter_view_orange").Destroy()

        // Make buttons increase the VScript lap counter.
        EntFire("rounds_button_1", "AddOutput", "OnPressed !self:RunScriptCode:GameLapsSub():0:-1")
        EntFire("rounds_button_2", "AddOutput", "OnPressed !self:RunScriptCode:GameLapsAdd():0:-1")

        // Make buttons run a music track function instead of the usual relay.
        EntFire("music_button_1", "AddOutput", "OnPressed !self:RunScriptCode:GameMusicBack():0:-1")
        EntFire("music_button_2", "AddOutput", "OnPressed !self:RunScriptCode:GameMusicNext():0:-1")

        // Remove the old game_text entities for the lap and music selection.
        for (local gt = null; gt = Entities.FindByClassname(gt, "game_text");) {
            if (gt.GetName().find("music_") != null && gt.GetName().find("_text") != null) {
                gt.Destroy()
            }
        }
        Entities.FindByName(null, "change_rounds_text").Destroy()

        if (!GetConVarInt("p2mm_gelocity_lockbuttons")) {
            EntFire("rounds_button_1", "Unlock")
            EntFire("rounds_button_2", "Unlock")
            EntFire("music_button_1", "Unlock")
            EntFire("music_button_2", "Unlock")
        } else {
            EntFire("rounds_button_1", "Lock")
            EntFire("rounds_button_2", "Lock")
            EntFire("music_button_1", "Lock")
            EntFire("music_button_2", "Lock")
        }

        // Only the winner can go onto the #1 pedestal and trigger the voiceline.
        Entities.FindByName(null, "glados_6").__KeyValueFromString("targetname", "glados_6_p2mmoverride")
        Entities.FindByName(null, "trigger_blue_wins").Destroy()
        Entities.FindByName(null, "trigger_orange_wins").__KeyValueFromString("target_team", "0")
        Entities.FindByName(null, "trigger_orange_wins").__KeyValueFromString("trigger_once", "0")
        EntFire("trigger_orange_wins", "AddOutput", "OnStartTouch !activator:RunScriptCode:KillLosers(activator)")
        EntFire("glados_7", "AddOutput", "OnCompletion glados_6_p2mmoverride:Kill")
        EntFire("trigger_orange_wins", "Enable")

        // Turn off death icons and turn on instant respawn
        SetConVarInt("p2mm_deathicons", 0)
        SetConVarInt("p2mm_instantrespawn", 1)

        // Tournament mode stuff
        if (bTournamentMode) {
            Config_HostOnlyChatCommands <- true // Make sure no other chat commands can be used.

            // Disabled round and music buttons so only host can remotely control their values.
            EntFire("button_music_1", "Skin", "1")
            EntFire("button_music_2", "Skin", "1")
            EntFire("music_button_1", "Kill")
            EntFire("music_button_2", "Kill")
            EntFire("rounds_button_1", "Kill")
            EntFire("rounds_button_2", "Kill")
            EntFire("button_1", "Skin", "1")
            EntFire("button_2", "Skin", "1")

            // Remove hint triggers.
            Entities.FindByClassnameNearest("trigger_multiple", Vector(-5568.01, -416, -64), 10).Destroy()
            Entities.FindByClassnameNearest("trigger_multiple", Vector(-5312.01, -416, -64), 10).Destroy()
            Entities.FindByClassnameNearest("trigger_playerteam", Vector(-1056, -768, 60.25), 10).Destroy()
            Entities.FindByName(null, "restart_hint_orange").Destroy()
            Entities.FindByName(null, "restart_hint_blue").Destroy()
            Entities.FindByName(null, "restart_hint_orange_2").Destroy()
            Entities.FindByName(null, "restart_hint_blue_2").Destroy()
            Entities.FindByName(null, "pd_01_trigger").Destroy()
            Entities.FindByName(null, "pd_01_trigger").Destroy()
            
            // Prevent exit door from opening.
            Entities.FindByName(null, "@relay_exit_door_open").Destroy()
        }
        // Stop gel spawning so it can be done once the race actually starts.
        Entities.FindByName(null, "coop_man_gel").Destroy()

        // Delete elements that change the level.
        Entities.FindByName(null, "reset_button_1").Destroy()
        Entities.FindByName(null, "team_trigger_door").Destroy()
        Entities.FindByName(null, "team_door-trigger_glados_exit_door").Destroy()
        
        // Rename the relay that starts the race so it can be controlled.
        Entities.FindByName(null, "startdoor_2_manager_2").Destroy()
        Entities.FindByName(null, "relay_start").__KeyValueFromString("targetname", "relay_start_p2mmoverride")
        
        // Make a prop_button for the host to start the game.
        if (!bTournamentMode) {
            local button = Entities.FindByClassname(null, "prop_under_button")
            button.SetOrigin(Vector(-5280, 768, -127))
            EntFireByHandle(button, "AddOutput", "OnPressed !activator:RunScriptCode:HostStartGame(activator)", 0, null, null)
        }
            
        // Delete starting race levers.
        Entities.FindByName(null, "lever_2_red").Destroy()
        Entities.FindByName(null, "lever_1_red").Destroy()
        Entities.FindByName(null, "lever_2_knob").Destroy()
        Entities.FindByName(null, "lever_1_knob").Destroy()
        Entities.FindByClassnameNearest("trigger_playerteam", Vector(-4904, 848, -64), 32).Destroy()
        Entities.FindByClassnameNearest("trigger_playerteam", Vector(-4904, 688, -64), 32).Destroy()

    }
    if (MSLoop) {
        // Prevent players jumping through window before the game starts.
        if (!bRaceStarted) {
            for (local p; p = Entities.FindByClassname(p, "player");) {
                if (p.GetOrigin().z < -170 && p.GetOrigin().y > 16.03) {
                    p.SetOrigin(Vector(-5406.540527, 803.267151, -127.968750))
                    p.SetAngles(0, -45, 0)
                }
            }
        }
        foreach (p in CreateTrigger("player", 1468, -4988, -476, 1652, -4893, -180)) {
            EntFire("launch_sound16", "PlaySound")
            EntFire("launch_arm16", "SetAnimation", "angled")
            p.SetVelocity(Vector(300, 150, 1000))
        }
        foreach (p in CreateTrigger("player", 3752, -2496, -268, 3672, -2408, -120)) {
            EntFire("launch_sound14", "PlaySound")
            EntFire("launch_arm14", "SetAnimation", "angled")
            p.SetVelocity(Vector(0, 600, 1100))
        }
        foreach (p in CreateTrigger("player", 4036, 252, 252, 3948, 388, 100)) {
            if (p.GetVelocity().x < -175)
            p.SetVelocity(Vector(-500, 0, 200))
        }
        foreach (p in CreateTrigger("player", 818, 2242, 0, 950, 2374, 16)) {
            EntFire("launch_sound3", "PlaySound")
            EntFire("launch_arm3", "SetAnimation", "angled")
            p.SetVelocity(Vector(-330, 0, 800))
        }
        foreach (p in CreateTrigger("player", 3330, 641, 130, 3538, 782, 300)) {
            if (p.GetVelocity().z > 1 && p.GetVelocity().y > 300) {
                p.SetVelocity(Vector(-200, 400, 400))
            }
        }

        foreach (p in CreateTrigger("player", 3330, 641, 130, 3538, 782, 300)) {
            if (p.GetVelocity().z > 1 && p.GetVelocity().y > 300) {
                p.SetVelocity(Vector(-200, 400, 400))
            }
        }

        if (isRotating == false && Entities.FindByClassnameWithin(null, "player", Vector(-8960, -4028, -192), 512)) {
            printlP2MM(0, true, "Fan rotation triggered")
            isRotating = true
            fanofftimer = Time() + 60
        }

        if (fanofftimer < Time()) {
            isRotating = false
            fanofftimer = 0
        }

        if (isRotating == true) {
            local angles = Entities.FindByName(null, "stupidfan").GetAngles()
            if (angles.z == 360) {
                Entities.FindByName(null, "stupidfan").SetAngles(angles.x, angles.y, 1)
            } else {
                Entities.FindByName(null, "stupidfan").SetAngles(angles.x, angles.y, angles.z + 2)
            }
            for (local p; p = Entities.FindByClassnameWithin(p, "player", Vector(-8924, -1608, -31), 128);) {
                p.SetVelocity(Vector(1300, 0, 0))
            }
        }
    }
}
