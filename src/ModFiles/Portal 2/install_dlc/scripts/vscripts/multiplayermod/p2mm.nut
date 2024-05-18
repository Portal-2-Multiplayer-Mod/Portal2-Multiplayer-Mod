//----------------------------------------------------------------------------------//
//                                  COPYRIGHT                                       //
//                      © 2022 Portal 2: Multiplayer Mod                            //
//  https://github.com/Portal-2-Multiplayer-Mod/Portal-2-Multiplayer-Mod/LICENSE    //
//  In the case that this file does not exist at all or in the GitHub repository,   //
//      this project will fall under a GNU LESSER GENERAL PUBLIC LICENSE            //
//----------------------------------------------------------------------------------//

//---------------------------------------------------
//         *****!Do not edit this file!*****
//---------------------------------------------------
// Purpose: The heart of the mod's content. Runs on
// every map transition to bring about features and
//                 fixes for 3+ MP.
//---------------------------------------------------

/*
    TODO:
    - Redo the entire system for LoadMapSupportCode
        - Better to merge everything into one nut file per map, even with gamemode differences
    - Find a proper way to load speedrun mod plugin
        - We could merge it into p2mm dll (need to check with Krzy first)
*/

// In case this is the client VM...
if (!("Entities" in this)) { return }

printl("\n---------------------")
printl("==== calling p2mm.nut")
printl("---------------------\n")

// Make sure all the VScript functions from the plugin are available
IncludeScript("multiplayermod/pluginfunctionscheck.nut")

if (!PluginLoaded) {
    // One-off check for running p2mm on first map load
    try {
        if (HasStartedP2MM) {
            return
        }
    } catch (exception) {} // Should never have an exception, try catch is here for testing...

    if (!("HasStartedP2MM" in this)) {
        HasStartedP2MM <- true
        return
    }
}

iMaxPlayers <- (Entities.FindByClassname(null, "team_manager").entindex() - 1) // Determine what the "maxplayers" cap is

printlP2MM(0, true, "Session info...")
printlP2MM(0, true, "- Current map: " + GetMapName())
printlP2MM(0, true, "- Max players allowed on the server: " + iMaxPlayers)
printlP2MM(0, true, "- Dedicated server: " + IsDedicatedServer())
printlP2MM(0, true, "\n")

IncludeScript("multiplayermod/config.nut")      // Import the user configuration and preferences
IncludeScript("multiplayermod/configcheck.nut") // Make sure nothing was invalid and compensate

// Check if its the first map run so Last Map System stuff can be done
if (IsFirstRun()) {
    EntFire("p2mm_servercommand", "command", "p2mm_firstrun 0")

    // Reset developer level, developer needs to stay enabled for VScript Debugging to work
    if (Config_DevMode || Config_VScriptDebug) {
        EntFire("p2mm_servercommand", "command", "developer 1")
    }
    else {
        EntFire("p2mm_servercommand", "command", "developer 0")
    }
    
    // Check if Last Map System supplied a value and that it's a valid map, then restart on that map
    if (IsMapValid(GetLastMap())) {
        EntFire("p2mm_servercommand", "command", "changelevel " + GetLastMap(), 0.5)
    }
}

//-------------------------------------------------------------------------------------------

// Continue loading the P2:MM fixes, game mode, and features

IncludeScript("multiplayermod/variables.nut")
IncludeScript("multiplayermod/safeguard.nut")
IncludeScript("multiplayermod/functions.nut")
IncludeScript("multiplayermod/hooks.nut")
IncludeScript("multiplayermod/chatcommands.nut")

// Always have global root functions imported for any level
IncludeScript("multiplayermod/mapsupport/#propcreation.nut")
IncludeScript("multiplayermod/mapsupport/#rootfunctions.nut")

//---------------------------------------------------

// Print P2:MM game art in console
ConsoleAscii <- [
"########...#######...##..##.....##.##.....##",
"##.....##.##.....##.####.###...###.###...###",
"##.....##........##..##..####.####.####.####",
"########...#######.......##.###.##.##.###.##",
"##........##.........##..##.....##.##.....##",
"##........##........####.##.....##.##.....##",
"##........#########..##..##.....##.##.....##"
]
foreach (line in ConsoleAscii) { printl(line) }
delete ConsoleAscii

//---------------------------------------------------

// Now, manage everything the player has set in config.nut
// If the gamemode has exceptions of any kind, it will revert to standard mapsupport

// Import map support code
// Map name will be wonky if the client VM attempts to get the map name
function LoadMapSupportCode(gametype) {
    printlP2MM(0, false, "=============================================================")
    printlP2MM(0, false, "Attempting to load " + gametype + " mapsupport code!")
    printlP2MM(0, false, "=============================================================\n")

    if (gametype != "standard") {
        if (gametype == "speedrun") {
            // Quick check for the speedrun mod plugin
            if (!("smsm" in this)) {
                printlP2MM(1, false, "Failed to load the VScript registers in the Speedrun Mod plugin! Reverting to standard mapsupport...")
                return LoadMapSupportCode("standard")
            }
        }
        try {
            // Import the core functions before the actual mapsupport
            IncludeScript("multiplayermod/mapsupport/" + gametype + "/#" + gametype + "functions.nut")
        } catch (exception) {
            printlP2MM(1, false, "Failed to load the " + gametype + " core functions file!")
        }
    }

    try {
        IncludeScript("multiplayermod/mapsupport/" + gametype + "/" + GetMapName() + ".nut")
    } catch (exception) {
        if (gametype == "standard") {
            printlP2MM(1, false, "Failed to load standard mapsupport for " + GetMapName() + "\n")
        }
        else {
            printlP2MM(1, false, "Failed to load " + gametype + " mapsupport code! Reverting to standard mapsupport...")
            return LoadMapSupportCode("standard")
        }
    }
}

// Now, manage everything the player has set in config.nut
// If the gamemode has exceptions of any kind, it will revert to standard mapsupport
switch (Config_GameMode) {
    case 0: LoadMapSupportCode("standard"); break
    case 1: LoadMapSupportCode("speedrun"); break
    default:
        printlP2MM(1, false, "\"Config_GameMode\" value in config.nut is invalid! Be sure it is set to an integer from 0-1. Reverting to standard mapsupport.")
        LoadMapSupportCode("standard")
        break
}

//---------------------------------------------------

// Run InstantRun() shortly AFTER spawn (hooks.nut)
EntFire("p2mm_servercommand", "command", "script InstantRun()", 0.02)
