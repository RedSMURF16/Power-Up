/*
*
*	Power-Up by RedSMURF
*
*
*	Description:
*       This plugin adds 18 unique power-ups to CS 1.6,
*       giving players temporary abilities, boosts, and special effects while tracking weapons, ammo, and player states.
*       All power-ups are fully dynamic and configurable, allowing their effects, duration, and behavior to be changed during gameplay.
*       Power-ups are stackable, so using multiple instances combines their effects.
*       All power-up settings are stored in the configuration file "configs/PowerUp.ini".
*
*       Ammo:           Adds ammo to the clip and backpack of the current weapon.
*       Ammo2:          Adds ammo to the clip and backpack of all weapons.
*       Bomb:           Adds any combination of bombs to the player’s inventory.
*       Clock:          Increases reload speed temporarily.
*       Health:         Restores player health.
*       Health2:        Regenerates health temporarily.
*       Lightning:      Boosts player speed temporarily.
*       Lightning2:     Gives an instant forward speed boost.
*       Mask:           Reduces player visibility temporarily.
*       Mask2:          Swaps the player’s model to the enemy team temporarily.
*       Rocket:         Rockets the player sky-high with explosive impact.
*       Shield:         Grants a shield that absorbs and reflects damage temporarily, adds armor too.
*       Skull:          Increases damage, steals life, and turns the player into a skeleton temporarily.
*       Stun:           Makes the player see wobbly, colorful, and dizzy temporarily.
*       Stun2:          Grants the player a shower of constant slaps temporarily.
*       Up:             Launches the player upward instantly, like a trampoline.
*       Up2:            Grants extra jumps and modifies gravity temporarily.
*       Wings:          Brings spectators back to life.
*
*
*	Cvars:
*		None
*
*	Commands:
*       say /pu                         "Opens the Power Ups menu."
*       say_team /pu                    "Opens the Power Ups menu."
*       say /power                      "Opens the Power Ups menu."
*       say_team /power                 "Opens the Power Ups menu."
*       pu_reload                       "Reloads the configuration file."
*       power_reload                    "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_AUTHID_LENGTH
    #define MAX_AUTHID_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT             48
#define FLOAT_MAX           1.0e10
#define POWER_DISTANCE      20.0

#define MEMBER_OWNER        41
#define MEMBER_NEXT_IDLE    48
#define MEMBER_AMMO_TYPE    49
#define MEMBER_WEAPON_CLIP  51
#define MEMBER_IN_RELOAD    54
#define MEMBER_NEXT_ATTACK  83

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const ERROR_FILE[]              = "powerUp_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_POWER,
    SECTION_POWER_AMMO,
    SECTION_POWER_AMMO2,
    SECTION_POWER_BOMB,
    SECTION_POWER_CLOCK,
    SECTION_POWER_HEALTH,
    SECTION_POWER_HEALTH2,
    SECTION_POWER_LIGHTNING,
    SECTION_POWER_LIGHTNING2,
    SECTION_POWER_MASK,
    SECTION_POWER_MASK2,
    SECTION_POWER_ROCKET,
    SECTION_POWER_SHIELD,
    SECTION_POWER_SKULL,
    SECTION_POWER_STUN,
    SECTION_POWER_STUN2,
    SECTION_POWER_UP,
    SECTION_POWER_UP2,
    SECTION_POWER_WINGS
}

enum
{
    CLASS_AMMO,
    CLASS_AMMO2,
    CLASS_BOMB,
    CLASS_CLOCK,
    CLASS_HEALTH,
    CLASS_HEALTH2,
    CLASS_LIGHTNING,
    CLASS_LIGHTNING2,
    CLASS_MASK,
    CLASS_MASK2,
    CLASS_ROCKET,
    CLASS_SHIELD,
    CLASS_SKULL,
    CLASS_STUN,
    CLASS_STUN2,
    CLASS_UP,
    CLASS_UP2,
    CLASS_WINGS
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT,
    SOUND_BLIP1,
    SOUND_BLIP2,
    SOUND_SWALLOW,
    SOUND_CLIP1,
    SOUND_BELL,
    SOUND_MEDCHARGE,
    SOUND_SUITCHARGE,
    SOUND_BEEP_BEEP,
    SOUND_FAST_WHOOSH,
    SOUND_ROCKET1,
    SOUND_ROCKETFIRE1,
    SOUND_FIRE_WHOOSH,
    SOUND_AMMO_PICKUP,
    SOUND_SCREAM,
    SOUND_HYPNO,
    SOUND_BOUNCING,
    SOUND_LIGHTNING
}

enum
{
    FLAG_SPARKLE    = (1 << 0),
    FLAG_SOUND      = (1 << 1),
    FLAG_MESSAGE    = (1 << 2),

    FLAG_SHOW       = (1 << 3),
    FLAG_SELECT     = (1 << 4)
}

enum
{
    SHOW_DEFAULT,
    SHOW_FORCE_SHOW,
    SHOW_FORCE_HIDE
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    ANIMATION_IDLE,
    ANIMATION_SPIN,
    ANIMATION_FLOAT,
    ANIMATION_SPIN_FLOAT
}

enum
{
    SPAWN_NEVER,
    SPAWN_DELAY,
    SPAWN_ROUND_START
}

enum
{
    AMMO_MODE_RELATIVE,
    AMMO_MODE_ABSOLUTE
}

enum
{
    SPEED_MODE_RELATIVE,
    SPEED_MODE_ABSOLUTE
}

enum
{
    SHIELD_SIZE_SMALL,
    SHIELD_SIZE_MEDIUM,
    SHIELD_SIZE_LARGE
}

enum
{
    STUN2_DIRECTION_FORWARD,
    STUN2_DIRECTION_RANDOM
}

enum
{
    WINGS_ORIGIN_SPAWN,
    WINGS_ORIGIN_SELF
}

enum
{
    SPARKLE_MODE_SINGLE,
    SPARKLE_MODE_RANDOM
}

enum
{
    CLASSNAME_PLAYER,
    CLASSNAME_SPECTATOR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_MINS[3],
    Float:SETTING_MAXS[3],

    bool:SETTING_POWER_LOAD,
    bool:SETTING_POWER_NOCLIP,
    bool:SETTING_POWER_ACTION,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET_MIN,
    Float:SETTING_OFFSET_MAX,
    Float:SETTING_OFFSET_STEP,
    Float:SETTING_OFFSET_FREQ,
    Float:SETTING_EFFECT_FREQ,
    Float:SETTING_TASK_FREQ,
    Float:SETTING_SPECTATOR_FREQ,
    SETTING_GHOST_ALPHA,

    SETTING_SPRITE_BLUEFLARE2,
    SETTING_SPRITE_GREENFLARE2,
    SETTING_SPRITE_YELLOWFLARE2,
    SETTING_SPRITE_REDFLARE2,
    SETTING_SPRITE_PINKFLARE2,
    SETTING_SPRITE_PURPLEFLARE2,
    SETTING_SPRITE_BALLSMOKE,
    SETTING_SPRITE_STEAM1,
    SETTING_SPRITE_WHITE,

    SETTING_MODEL_SNOWBALL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_SNOWBALL2[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_SNOWBALL3[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_SKELETON_T[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_SKELETON_CT[MAX_RESOURCE_PATH_LENGTH],

    SETTING_SOUND_MENU_NAV[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_MENU_REMOVE[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_MENU_ALERT[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_BLIP1[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_BLIP2[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_SWALLOW[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_CLIP1[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_BELL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_MEDCHARGE[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_SUITCHARGE[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_BEEP_BEEP[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_FAST_WHOOSH[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_ROCKET1[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_ROCKETFIRE1[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_FIRE_WHOOSH[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_AMMO_PICKUP[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_SCREAM[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_HYPNO[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_BOUNCING[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_LIGHTNING[MAX_RESOURCE_PATH_LENGTH],

    SETTING_COLOR_SELECT[3]
}

enum _:POWER
{
    POWER_ID,
    POWER_ITEM,
    POWER_SHOW,
    POWER_FLAGS,
    POWER_TEAM,
    POWER_NAME[MAX_VALUE_LENGTH],
    POWER_MODEL[MAX_RESOURCE_PATH_LENGTH],
    Float:POWER_ORIGIN[3],
    Float:POWER_ANGLES[3],
    Float:POWER_MINS[3],
    Float:POWER_MAXS[3],

    POWER_SPAWN_MODE,
    Float:POWER_SPAWN_MIN,
    Float:POWER_SPAWN_MAX,
    Float:POWER_SPAWN_CHANCE,
    Float:POWER_NEXT_SPAWN,

    POWER_ANIMATION,
    Float:POWER_FRAME,
    Float:POWER_FRAMERATE,

    POWER_CLASS,
    Array:POWER_DATA
}

enum _:POWER_AMMO
{
    Float:AMMO_CLIP,
    Float:AMMO_AMMO,
    AMMO_MODE,
    bool:AMMO_OVERFLOW
}

enum _:POWER_AMMO2
{
    Float:AMMO2_CLIP,
    Float:AMMO2_AMMO,
    AMMO2_MODE,
    bool:AMMO2_OVERFLOW
}

enum _:POWER_BOMB
{
    BOMB_HE_SUPPLY,
    BOMB_FB_SUPPLY,
    BOMB_SMOKE_SUPPLY,
    BOMB_HE_LIMIT,
    BOMB_FB_LIMIT,
    BOMB_SMOKE_LIMIT,
    bool:BOMB_OVERFLOW
}

enum _:POWER_CLOCK
{
    Float:CLOCK_SPEED,
    Float:CLOCK_DURATION_MIN,
    Float:CLOCK_DURATION_MAX,
    bool:CLOCK_STACK
}

enum _:POWER_HEALTH
{
    Float:HEALTH_MIN,
    Float:HEALTH_MAX,
    Float:HEALTH_LIMIT,
    bool:HEALTH_SCREEN_FADE,
    bool:HEALTH_OVERFLOW
}

enum _:POWER_HEALTH2
{
    Float:HEALTH2_MIN,
    Float:HEALTH2_MAX,
    Float:HEALTH2_FREQ,
    Float:HEALTH2_DURATION_MIN,
    Float:HEALTH2_DURATION_MAX,
    Float:HEALTH2_LIMIT,
    bool:HEALTH2_SCREEN_FADE,
    bool:HEALTH2_OVERFLOW,
    bool:HEALTH2_STACK
}

enum _:POWER_LIGHTNING
{
    Float:LIGHTNING_MIN,
    Float:LIGHTNING_MAX,
    Float:LIGHTNING_DURATION_MIN,
    Float:LIGHTNING_DURATION_MAX,
    LIGHTNING_MODE,
    bool:LIGHTNING_STACK
}

enum _:POWER_LIGHTNING2
{
    Float:LIGHTNING2_MIN,
    Float:LIGHTNING2_MAX,
    Float:LIGHTNING2_DELAY_MIN,
    Float:LIGHTNING2_DELAY_MAX,
    Float:LIGHTNING2_DELAY_SPEED,
    LIGHTNING2_TRAIL_COLOR[4],
    bool:LIGHTNING2_STACK
}

enum _:POWER_MASK
{
    Float:MASK_ALPHA_MIN,
    Float:MASK_ALPHA_MAX,
    Float:MASK_DURATION_MIN,
    Float:MASK_DURATION_MAX,
    bool:MASK_FOOTSTEP,
    bool:MASK_STACK
}

enum _:POWER_MASK2
{
    Float:MASK2_DURATION_MIN,
    Float:MASK2_DURATION_MAX,
    MASK2_MODEL_FLAG,
    bool:MASK2_OVERRIDE
}

enum _:POWER_ROCKET
{
    Float:ROCKET_DAMAGE,
    Float:ROCKET_PUSH,
    Float:ROCKET_GAP_PUSH,
    Float:ROCKET_GAP_SMOKE,
    Float:ROCKET_DURATION_MIN,
    Float:ROCKET_DURATION_MAX,
    Float:ROCKET_SPEED,
    bool:ROCKET_GIB
}

enum _:POWER_SHIELD
{
    SHIELD_ARMOR_MIN,
    SHIELD_ARMOR_MAX,
    SHIELD_ARMOR_LIMIT,
    bool:SHIELD_ARMOR_OVERFLOW,
    CsArmorType:SHIELD_ARMOR_TYPE,
    Float:SHIELD_FACTOR_ABSORB,
    Float:SHIELD_FACTOR_REFLECT,
    Float:SHIELD_DURATION_MIN,
    Float:SHIELD_DURATION_MAX,
    SHIELD_SIZE,
    SHIELD_COLOR[4],
    bool:SHIELD_STACK
}

enum _:POWER_SKULL
{
    Float:SKULL_FACTOR_DAMAGE,
    Float:SKULL_FACTOR_BLOOD,
    Float:SKULL_DURATION_MIN,
    Float:SKULL_DURATION_MAX,
    bool:SKULL_STACK
}

enum _:POWER_STUN
{
    STUN_AMPLITUDE,
    STUN_FREQUENCY,
    Float:STUN_DURATION_MIN,
    Float:STUN_DURATION_MAX,
    bool:STUN_FOV,
    bool:STUN_FADE,
    bool:STUN_SHAKE,
    bool:STUN_STACK
}

enum _:POWER_STUN2
{
    Float:STUN2_FREQ_MIN,
    Float:STUN2_FREQ_MAX,
    Float:STUN2_DAMAGE_MIN,
    Float:STUN2_DAMAGE_MAX,
    Float:STUN2_DURATION_MIN,
    Float:STUN2_DURATION_MAX,
    STUN2_DIRECTION,
    bool:STUN2_KILL,
    bool:STUN2_STACK
}

enum _:POWER_UP
{
    Float:UP_MIN,
    Float:UP_MAX,
    UP_TRAIL_COLOR[4]
}

enum _:POWER_UP2
{
    UP2_JUMP_MIN,
    UP2_JUMP_MAX,
    Float:UP2_DURATION_MIN,
    Float:UP2_DURATION_MAX,
    Float:UP2_GRAVITY,
    bool:UP2_STACK
}

enum _:POWER_WINGS
{
    WINGS_ORIGIN,
    Float:WINGS_HEALTH,
    bool:WINGS_SAVE_WEAPONS,
    bool:WINGS_SAVE_AMMO,
    bool:WINGS_LIGHTNING
}

enum _:PLAYER_DATA
{
    PDATA_NAME[MAX_VALUE_LENGTH],
    PDATA_AUTHID[MAX_AUTHID_LENGTH],
    PDATA_ADMIN_FLAGS,
    PDATA_POWER_GHOST,
    PDATA_POWER_MENU,
    bool:PDATA_POWER_SWALLOW,
    bool:PDATA_POWER_ACTION,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,
    Float:PDATA_POWER_BEAM_NEXT_KILL,
    Float:PDATA_BASE_SPEED,
    Float:PDATA_BASE_GRAVITY,
    bool:PDATA_BASE_FOOTSTEP,
    PDATA_BASE_FOV,

    PDATA_POWER_CLOCK_COUNT,
    Float:PDATA_POWER_CLOCK_END[MAX_ENT],
    Float:PDATA_POWER_CLOCK_SPEED[MAX_ENT],

    PDATA_POWER_HEALTH2[MAX_ENT],
    PDATA_POWER_HEALTH2_COUNT,
    Float:PDATA_POWER_HEALTH2_NEXT[MAX_ENT],
    Float:PDATA_POWER_HEALTH2_END[MAX_ENT],

    PDATA_POWER_LIGHTNING[MAX_ENT],
    PDATA_POWER_LIGHTNING_COUNT,
    Float:PDATA_POWER_LIGHTNING_END[MAX_ENT],

    PDATA_POWER_LIGHTNING2[MAX_ENT],
    PDATA_POWER_LIGHTNING2_COUNT,
    Float:PDATA_POWER_LIGHTNING2_NEXT[MAX_ENT],

    Float:PDATA_POWER_MASK,
    PDATA_POWER_MASK_COUNT,
    Float:PDATA_POWER_MASK_ALPHA[MAX_ENT],
    Float:PDATA_POWER_MASK_END[MAX_ENT],

    Float:PDATA_POWER_MASK2_END,

    PDATA_POWER_ROCKET,
    Float:PDATA_POWER_ROCKET_END,
    Float:PDATA_POWER_ROCKET_NEXT_PUSH,
    Float:PDATA_POWER_ROCKET_NEXT_SMOKE,
    bool:PDATA_POWER_ROCKET_FIRE,

    PDATA_POWER_SHIELD[MAX_ENT],
    PDATA_POWER_SHIELD_COUNT,
    PDATA_POWER_SHIELD_BUBBLE[MAX_ENT],
    Float:PDATA_POWER_SHIELD_END[MAX_ENT],
    bool:PDATA_POWER_SHIELD_IS_REFLECTED,

    PDATA_POWER_SKULL[MAX_ENT],
    PDATA_POWER_SKULL_COUNT,
    Float:PDATA_POWER_SKULL_END[MAX_ENT],

    PDATA_POWER_STUN[MAX_ENT],
    PDATA_POWER_STUN_COUNT,
    Float:PDATA_POWER_STUN_NEXT_SHAKE[MAX_ENT],
    Float:PDATA_POWER_STUN_END[MAX_ENT],

    PDATA_POWER_STUN2[MAX_ENT],
    PDATA_POWER_STUN2_COUNT,
    Float:PDATA_POWER_STUN2_END[MAX_ENT],
    Float:PDATA_POWER_STUN2_NEXT_SLAP[MAX_ENT],

    PDATA_POWER_UP2[MAX_ENT],
    PDATA_POWER_UP2_COUNT,
    Float:PDATA_POWER_UP2_END[MAX_ENT],
    PDATA_POWER_UP2_JUMP[MAX_ENT],
    bool:PDATA_POWER_UP2_GROUNDED,
    Float:PDATA_POWER_UP2_GRAVITY[MAX_ENT],

    Float:PDATA_POWER_WINGS_ORIGIN[3],
    bool:PDATA_POWER_WINGS_WEAPONS[32],
    PDATA_POWER_WINGS_AMMO[32]
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_TEAM,
    MENU_ANIM,
    MENU_SPAWN,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_SHOW = 4,
    ROOT_TEAM,
    ROOT_ANIM,
    ROOT_SPAWN
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE,
    SHOW_ALL_DEFAULT
}

enum
{
    TEAM_NEXT,
    TEAM_BACK,

    TEAM_CURRENT = 3,
    TEAM_ALL_NONE,
    TEAM_ALL_T,
    TEAM_ALL_CT,
    TEAM_ALL_BOTH
}

enum
{
    ANIM_NEXT,
    ANIM_BACK,

    ANIM_CURRENT = 3,
    ANIM_ALL_IDLE,
    ANIM_ALL_SPIN,
    ANIM_ALL_FLOAT,
    ANIM_ALL_SPIN_FLOAT
}

enum
{
    SPAWN_NEXT,
    SPAWN_BACK,

    SPAWN_CURRENT = 3,
    SPAWN_ALL_NEVER,
    SPAWN_ALL_DELAY,
    SPAWN_ALL_ROUND_START
}


enum
{
    ROTATE_RIGHT,
    ROTATE_LEFT,
    ROTATE_PLACE
}

new const g_iWeaponMaxBp[] =
{
    0,      52,     0,    90,     0,    32,     0,   100,    90,     1,
    120,   100,   100,    90,    90,    90,   100,   120,    30,   120,
    200,    32,    90,   120,    90,     0,    35,    90,    90,     0,
    100
}

new const g_iWeaponMaxClip[] =
{
    0,      13,     0,    10,     1,     7,     1,    30,    30,     1,
    30,     20,    25,     5,    35,    25,    12,    20,    10,    30,
    100,     8,    30,    30,     5,     1,     7,    30,    30,     0,
    50
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerTeam",
    "menuHandlerAnim",
    "menuHandlerSpawn",
    "menuHandlerRotate"
}

new g_szShow[][] = {"POWER_DEFAULT", "POWER_SHOWN", "POWER_HIDDEN"}
new g_szShowChat[][] = {"POWER_CHAT_DEFAULT", "POWER_CHAT_SHOWN", "POWER_CHAT_HIDDEN"}
new g_szShowColor[][] = {"\d", "\y", "\r"}
new g_szTeam[][] = {"POWER_NONE", "POWER_T", "POWER_CT", "POWER_BOTH"}
new g_szTeamChat[][] = {"POWER_CHAT_NONE", "POWER_CHAT_T", "POWER_CHAT_CT", "POWER_CHAT_BOTH"}
new g_szAnim[][] = {"POWER_IDLE", "POWER_SPIN", "POWER_FLOAT", "POWER_SPIN_FLOAT"}
new g_szAnimChat[][] = {"POWER_CHAT_IDLE", "POWER_CHAT_SPIN", "POWER_CHAT_FLOAT", "POWER_CHAT_SPIN_FLOAT"}
new g_szSpawn[][] = {"POWER_NEVER", "POWER_DELAY", "POWER_ROUND_START"}
new g_szSpawnChat[][] = {"POWER_CHAT_NEVER", "POWER_CHAT_DELAY", "POWER_CHAT_ROUND_START"}

new g_szTModels[][] = {"terror", "leet", "arctic", "guerilla"}
new g_szCTModels[][] = {"urban", "gsg9", "sas", "gign"}

new g_szCN[][] = {"powerup_player", "powerup_spectator"}

new Array:g_aPower,
    Array:g_aPowerConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    g_szFileName[MAX_RESOURCE_PATH_LENGTH],
    bool:g_bFileWasRead = false,
    g_iPower, g_iPowerConfig,
    g_iDamage, g_iAmmoPickup, g_iWeapPickup, g_iScreenFade, g_iScreenShake, g_iSetFov,
    g_szWeapon[32]

public plugin_init()
{
    register_plugin("POWER Spawn", PLUGIN_VERSION, "RedSMURF")

    register_clcmd("say /pu",           "cmdMenu", ADMIN_RCON)
    register_clcmd("say_team /pu",      "cmdMenu", ADMIN_RCON)
    register_clcmd("say /power",        "cmdMenu", ADMIN_RCON)
    register_clcmd("say_team /power",   "cmdMenu", ADMIN_RCON)
    register_concmd("pu_reload",        "cmdReload", ADMIN_RCON, "-- Reloads the configuration file")
    register_concmd("power_reload",     "cmdReload", ADMIN_RCON, "-- Reloads the configuration file")

    register_dictionary("PowerUp.txt")

    register_forward(FM_UpdateClientData, "fwdUpdateClientData", 1)
    register_forward(FM_AddToFullPack, "fwdAddToFullPack", 1)
    RegisterHam(Ham_Spawn, "info_target", "fwdSpawn", 1)
    RegisterHam(Ham_Touch, "info_target", "fwdTouch", 0)
    RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink", 0)
    RegisterHam(Ham_TakeDamage, "player", "fwdTakeDamage", 0)
    RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "fwdResetMaxSpeedPlayer", 1)
    for ( new i = CSW_P228; i <= CSW_P90; i ++ )
    {
        if ( get_weaponname(i, g_szWeapon, charsmax(g_szWeapon)) )
            RegisterHam(Ham_Weapon_Reload, g_szWeapon, "fwdWeaponReload", 1)
    }

    register_event("HLTV", "eventHLTV", "a", "1=0", "2=0")
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    g_iDamage = get_user_msgid("Damage")
    g_iAmmoPickup = get_user_msgid("AmmoPickup")
    g_iWeapPickup = get_user_msgid("WeapPickup")
    g_iScreenFade = get_user_msgid("ScreenFade")
    g_iScreenShake = get_user_msgid("ScreenShake")
    g_iSetFov = get_user_msgid("SetFOV")

    set_task(g_eSettings[SETTING_TASK_FREQ], "powerTask", .flags = "b")
    set_task(g_eSettings[SETTING_SPECTATOR_FREQ], "powerWings", .flags = "b")
    powerInit()
}

public plugin_precache()
{
    g_aPower       = ArrayCreate(POWER)
    g_aPowerConfig = ArrayCreate(POWER)

    ReadFile()
}

public plugin_end()
{
    new ePower[POWER]

    for ( new i = 0; i < g_iPower; i ++ )
    {
        ArrayGetArray(g_aPower, i, ePower)
        ArrayDestroy(ePower[POWER_DATA])
    }

    for ( new i = 0; i < g_iPowerConfig; i ++ )
    {
        ArrayGetArray(g_aPowerConfig, i, ePower)
        ArrayDestroy(ePower[POWER_DATA])
    }

    ArrayDestroy(g_aPower)
    ArrayDestroy(g_aPowerConfig)
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    if ( !g_eSettings[SETTING_POWER_ACTION] )
    {
        client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_NO_ACTION")
        return PLUGIN_HANDLED
    }

    powerSound(id, SOUND_MENU_NAV)
    powerMenu(id, MENU_ROOT)

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public client_command(id)
{
    if ( !g_ePlayerData[id][PDATA_POWER_GHOST] )
        return PLUGIN_CONTINUE

    new szCmd[16]
    read_argv(0, szCmd, charsmax(szCmd))

    if ( contain(szCmd, "weapon_") != -1
    || equal(szCmd, "invnext")
    || equal(szCmd, "invprev")
    || equal(szCmd, "lastinv") )
        return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public eventHLTV()
{
    new iPlayers[MAX_PLAYERS], iNum, id
    get_players(iPlayers, iNum, "a")

    for ( new i = 0; i < iNum; i ++ )
    {
        id = iPlayers[i]
        powerReset(id)
    }
}

public eventRoundStart()
{
    if ( !g_iPower )
        return PLUGIN_HANDLED

    new ePower[POWER]

    for ( new i = 0; i < g_iPower; i ++ )
    {
        ArrayGetArray(g_aPower, i, ePower)

        if ( ePower[POWER_SHOW] != SHOW_DEFAULT
        || ePower[POWER_SPAWN_MODE] != SPAWN_ROUND_START )
            continue

        if ( ePower[POWER_SPAWN_CHANCE] >= random_float(0.0, 1.0) )
        {
            ePower[POWER_FLAGS] |= FLAG_SHOW
            set_pev(ePower[POWER_ID], pev_solid, SOLID_TRIGGER)
        }
        else
        {
            ePower[POWER_FLAGS] &= ~FLAG_SHOW
            set_pev(ePower[POWER_ID], pev_solid, SOLID_NOT)
        }

        ArraySetArray(g_aPower, i, ePower)
    }

    return PLUGIN_HANDLED
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        new iPlayers[MAX_PLAYERS], iNum
        get_players(iPlayers, iNum, "ch")

        for ( new i = 0; i < iNum; i ++ )
            UpdateData(iPlayers[i])

        ArrayClear(g_aPowerConfig)
        g_iPowerConfig = 0
    }

    get_configsdir(g_szFileName, charsmax(g_szFileName))
    add(g_szFileName, charsmax(g_szFileName), "/PowerUp.ini")

    new iFile
    iFile = fopen(g_szFileName, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH],
        szValue[MAX_RESOURCE_PATH_LENGTH],
        ePower[POWER], iSection = SECTION_NONE, iLine,
        ePowerAmmo[POWER_AMMO], ePowerAmmo2[POWER_AMMO2], ePowerBomb[POWER_BOMB], ePowerClock[POWER_CLOCK],
        ePowerHealth[POWER_HEALTH], ePowerHealth2[POWER_HEALTH2], ePowerLightning[POWER_LIGHTNING], ePowerLightning2[POWER_LIGHTNING2],
        ePowerMask[POWER_MASK], ePowerMask2[POWER_MASK2], ePowerRocket[POWER_ROCKET], ePowerShield[POWER_SHIELD], ePowerSkull[POWER_SKULL],
        ePowerStun[POWER_STUN], ePowerStun2[POWER_STUN2], ePowerUp[POWER_UP], ePowerUp2[POWER_UP2], ePowerWings[POWER_WINGS]

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iPowerConfig )
                            ArrayPushArray(g_aPowerConfig, ePower)

                        copy(ePower[POWER_NAME], charsmax(ePower[POWER_NAME]), szData)
                        copy(ePower[POWER_MODEL], charsmax(ePower[POWER_MODEL]), g_eSettings[SETTING_DEFAULT_MODEL])
                        ePower[POWER_FLAGS]                         = FLAG_SPARKLE | FLAG_SOUND | FLAG_MESSAGE
                        ePower[POWER_TEAM]                          = TEAM_BOTH
                        ePower[POWER_SPAWN_MODE]                    = SPAWN_DELAY
                        ePower[POWER_SPAWN_MIN]                     = 10.0
                        ePower[POWER_SPAWN_MAX]                     = 25.0
                        ePower[POWER_SPAWN_CHANCE]                  = 1.0
                        ePower[POWER_ANIMATION]                     = ANIMATION_SPIN_FLOAT
                        ePower[POWER_FRAME]                         = 0.0
                        ePower[POWER_FRAMERATE]                     = 1.0
                        ePower[POWER_CLASS]                         = CLASS_AMMO

                        ePowerAmmo[AMMO_CLIP]                       = 1.0
                        ePowerAmmo[AMMO_AMMO]                       = 0.5
                        ePowerAmmo[AMMO_MODE]                       = AMMO_MODE_RELATIVE
                        ePowerAmmo[AMMO_OVERFLOW]                   = false

                        ePowerAmmo2[AMMO2_CLIP]                     = 1.0
                        ePowerAmmo2[AMMO2_AMMO]                     = 0.5
                        ePowerAmmo2[AMMO2_MODE]                     = AMMO_MODE_RELATIVE
                        ePowerAmmo2[AMMO2_OVERFLOW]                 = false

                        ePowerBomb[BOMB_HE_SUPPLY]                  = 1
                        ePowerBomb[BOMB_FB_SUPPLY]                  = 1
                        ePowerBomb[BOMB_SMOKE_SUPPLY]               = 1
                        ePowerBomb[BOMB_HE_LIMIT]                   = 5
                        ePowerBomb[BOMB_FB_LIMIT]                   = 5
                        ePowerBomb[BOMB_SMOKE_LIMIT]                = 5
                        ePowerBomb[BOMB_OVERFLOW]                   = false

                        ePowerClock[CLOCK_SPEED]                    = 0.0
                        ePowerClock[CLOCK_DURATION_MIN]             = 7.0
                        ePowerClock[CLOCK_DURATION_MAX]             = 12.0
                        ePowerClock[CLOCK_STACK]                    = true

                        ePowerHealth[HEALTH_MIN]                    = 15.0
                        ePowerHealth[HEALTH_MAX]                    = 25.0
                        ePowerHealth[HEALTH_LIMIT]                  = 150.0
                        ePowerHealth[HEALTH_SCREEN_FADE]            = true
                        ePowerHealth[HEALTH_OVERFLOW]               = true

                        ePowerHealth2[HEALTH2_MIN]                  = 1.0
                        ePowerHealth2[HEALTH2_MAX]                  = 1.0
                        ePowerHealth2[HEALTH2_FREQ]                 = 1.0
                        ePowerHealth2[HEALTH2_DURATION_MIN]         = 7.0
                        ePowerHealth2[HEALTH2_DURATION_MAX]         = 12.0
                        ePowerHealth2[HEALTH2_LIMIT]                = 150.0
                        ePowerHealth2[HEALTH2_SCREEN_FADE]          = true
                        ePowerHealth2[HEALTH2_OVERFLOW]             = true
                        ePowerHealth2[HEALTH2_STACK]                = true

                        ePowerLightning[LIGHTNING_MIN]              = 1.28
                        ePowerLightning[LIGHTNING_MAX]              = 1.28
                        ePowerLightning[LIGHTNING_DURATION_MIN]     = 7.0
                        ePowerLightning[LIGHTNING_DURATION_MAX]     = 12.0
                        ePowerLightning[LIGHTNING_MODE]             = SPEED_MODE_RELATIVE
                        ePowerLightning[LIGHTNING_STACK]            = true

                        ePowerLightning2[LIGHTNING2_MIN]            = 900.0
                        ePowerLightning2[LIGHTNING2_MAX]            = 1200.0
                        ePowerLightning2[LIGHTNING2_DELAY_MIN]      = 0.25
                        ePowerLightning2[LIGHTNING2_DELAY_MAX]      = 0.25
                        ePowerLightning2[LIGHTNING2_DELAY_SPEED]    = 0.1
                        ePowerLightning2[LIGHTNING2_TRAIL_COLOR][0] = 128
                        ePowerLightning2[LIGHTNING2_TRAIL_COLOR][1] = 128
                        ePowerLightning2[LIGHTNING2_TRAIL_COLOR][2] = 0
                        ePowerLightning2[LIGHTNING2_TRAIL_COLOR][3] = 105
                        ePowerLightning2[LIGHTNING2_STACK]          = true

                        ePowerMask[MASK_ALPHA_MIN]                  = 0.32
                        ePowerMask[MASK_ALPHA_MAX]                  = 0.45
                        ePowerMask[MASK_DURATION_MIN]               = 7.0
                        ePowerMask[MASK_DURATION_MAX]               = 12.0
                        ePowerMask[MASK_FOOTSTEP]                   = true
                        ePowerMask[MASK_STACK]                      = true

                        ePowerMask2[MASK2_DURATION_MIN]             = 7.0
                        ePowerMask2[MASK2_DURATION_MAX]             = 12.0
                        ePowerMask2[MASK2_MODEL_FLAG]               = 15
                        ePowerMask2[MASK2_OVERRIDE]                 = true

                        ePowerRocket[ROCKET_DAMAGE]                 = 5000.0
                        ePowerRocket[ROCKET_PUSH]                   = 450.0
                        ePowerRocket[ROCKET_GAP_PUSH]               = 0.1
                        ePowerRocket[ROCKET_GAP_SMOKE]              = 0.2
                        ePowerRocket[ROCKET_DURATION_MIN]           = 1.3
                        ePowerRocket[ROCKET_DURATION_MAX]           = 1.7
                        ePowerRocket[ROCKET_SPEED]                  = 0.01
                        ePowerRocket[ROCKET_GIB]                    = true

                        ePowerShield[SHIELD_ARMOR_MIN]              = 50
                        ePowerShield[SHIELD_ARMOR_MAX]              = 75
                        ePowerShield[SHIELD_ARMOR_LIMIT]            = 200
                        ePowerShield[SHIELD_ARMOR_OVERFLOW]         = true
                        ePowerShield[SHIELD_ARMOR_TYPE]             = CS_ARMOR_VESTHELM
                        ePowerShield[SHIELD_FACTOR_ABSORB]          = 0.5
                        ePowerShield[SHIELD_FACTOR_REFLECT]         = 0.1
                        ePowerShield[SHIELD_DURATION_MIN]           = 7.0
                        ePowerShield[SHIELD_DURATION_MAX]           = 12.0
                        ePowerShield[SHIELD_SIZE]                   = SHIELD_SIZE_MEDIUM
                        ePowerShield[SHIELD_COLOR][0]               = 128
                        ePowerShield[SHIELD_COLOR][1]               = 0
                        ePowerShield[SHIELD_COLOR][2]               = 128
                        ePowerShield[SHIELD_COLOR][3]               = 16
                        ePowerShield[SHIELD_STACK]                  = true

                        ePowerSkull[SKULL_FACTOR_DAMAGE]            = 0.25
                        ePowerSkull[SKULL_FACTOR_BLOOD]             = 0.25
                        ePowerSkull[SKULL_DURATION_MIN]             = 7.0
                        ePowerSkull[SKULL_DURATION_MAX]             = 12.0
                        ePowerSkull[SKULL_STACK]                    = true

                        ePowerStun[STUN_AMPLITUDE]                  = 8
                        ePowerStun[STUN_FREQUENCY]                  = 4
                        ePowerStun[STUN_DURATION_MIN]               = 7.0
                        ePowerStun[STUN_DURATION_MAX]               = 12.0
                        ePowerStun[STUN_FOV]                        = true
                        ePowerStun[STUN_FADE]                       = true
                        ePowerStun[STUN_SHAKE]                      = true
                        ePowerStun[STUN_STACK]                      = true

                        ePowerStun2[STUN2_FREQ_MIN]                 = 0.2
                        ePowerStun2[STUN2_FREQ_MAX]                 = 0.25
                        ePowerStun2[STUN2_DAMAGE_MIN]               = 0.1
                        ePowerStun2[STUN2_DAMAGE_MAX]               = 1.0
                        ePowerStun2[STUN2_DURATION_MIN]             = 7.0
                        ePowerStun2[STUN2_DURATION_MAX]             = 12.0
                        ePowerStun2[STUN2_DIRECTION]                = STUN2_DIRECTION_RANDOM
                        ePowerStun2[STUN2_KILL]                     = false
                        ePowerStun2[STUN2_STACK]                    = true

                        ePowerUp[UP_MIN]                            = 900.0
                        ePowerUp[UP_MAX]                            = 1200.0
                        ePowerUp[UP_TRAIL_COLOR][0]                 = 0
                        ePowerUp[UP_TRAIL_COLOR][1]                 = 128
                        ePowerUp[UP_TRAIL_COLOR][2]                 = 0
                        ePowerUp[UP_TRAIL_COLOR][3]                 = 105

                        ePowerUp2[UP2_JUMP_MIN]                     = 2
                        ePowerUp2[UP2_JUMP_MAX]                     = 2
                        ePowerUp2[UP2_DURATION_MIN]                 = 7.0
                        ePowerUp2[UP2_DURATION_MAX]                 = 12.0
                        ePowerUp2[UP2_GRAVITY]                      = 1.0
                        ePowerUp2[UP2_STACK]                        = true

                        ePowerWings[WINGS_ORIGIN]                   = WINGS_ORIGIN_SELF
                        ePowerWings[WINGS_HEALTH]                   = 50.0
                        ePowerWings[WINGS_SAVE_WEAPONS]             = false
                        ePowerWings[WINGS_SAVE_AMMO]                = false
                        ePowerWings[WINGS_LIGHTNING]                = true

                        iSection = SECTION_POWER
                        g_iPowerConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                        {
                            copy(g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]), szValue)
                            if ( !g_bFileWasRead ) precache_model(g_eSettings[SETTING_DEFAULT_MODEL])
                        }
                        else if ( equali(szKey, "SETTING_MINS") )
                        {
                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            g_eSettings[SETTING_MINS][0] = str_to_float(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            g_eSettings[SETTING_MINS][1] = str_to_float(szKey)
                            g_eSettings[SETTING_MINS][2] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_MAXS") )
                        {
                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            g_eSettings[SETTING_MAXS][0] = str_to_float(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            g_eSettings[SETTING_MAXS][1] = str_to_float(szKey)
                            g_eSettings[SETTING_MAXS][2] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_POWER_LOAD") )
                        {
                            g_eSettings[SETTING_POWER_LOAD] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "SETTING_POWER_NOCLIP") )
                        {
                            g_eSettings[SETTING_POWER_NOCLIP] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "SETTING_POWER_ACTION") )
                        {
                            g_eSettings[SETTING_POWER_ACTION] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                        {
                            g_eSettings[SETTING_OFFSET_BASE] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_OFFSET_MIN") )
                        {
                            g_eSettings[SETTING_OFFSET_MIN] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_OFFSET_MAX") )
                        {
                            g_eSettings[SETTING_OFFSET_MAX] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                        {
                            g_eSettings[SETTING_OFFSET_STEP] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_OFFSET_FREQ") )
                        {
                            g_eSettings[SETTING_OFFSET_FREQ] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_EFFECT_FREQ") )
                        {
                            g_eSettings[SETTING_EFFECT_FREQ] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_TASK_FREQ") )
                        {
                            g_eSettings[SETTING_TASK_FREQ] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPECTATOR_FREQ") )
                        {
                            g_eSettings[SETTING_SPECTATOR_FREQ] = str_to_float(szValue)
                        }
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                        {
                            g_eSettings[SETTING_GHOST_ALPHA] = str_to_num(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_BLUEFLARE2") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_BLUEFLARE2] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_GREENFLARE2") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_GREENFLARE2] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_YELLOWFLARE2") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_YELLOWFLARE2] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_REDFLARE2") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_REDFLARE2] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_PINKFLARE2") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_PINKFLARE2] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_PURPLEFLARE2") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_PURPLEFLARE2] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_BALLSMOKE") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_BALLSMOKE] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_STEAM1") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_STEAM1] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SPRITE_WHITE") )
                        {
                            if ( !g_bFileWasRead )
                                g_eSettings[SETTING_SPRITE_WHITE] = precache_model(szValue)
                        }
                        else if ( equali(szKey, "SETTING_MODEL_SNOWBALL") )
                        {
                            copy(g_eSettings[SETTING_MODEL_SNOWBALL], charsmax(g_eSettings[SETTING_MODEL_SNOWBALL]), szValue)
                            if ( !g_bFileWasRead ) precache_model(g_eSettings[SETTING_MODEL_SNOWBALL])
                        }
                        else if ( equali(szKey, "SETTING_MODEL_SNOWBALL2") )
                        {
                            copy(g_eSettings[SETTING_MODEL_SNOWBALL2], charsmax(g_eSettings[SETTING_MODEL_SNOWBALL2]), szValue)
                            if ( !g_bFileWasRead ) precache_model(g_eSettings[SETTING_MODEL_SNOWBALL2])
                        }
                        else if ( equali(szKey, "SETTING_MODEL_SNOWBALL3") )
                        {
                            copy(g_eSettings[SETTING_MODEL_SNOWBALL3], charsmax(g_eSettings[SETTING_MODEL_SNOWBALL3]), szValue)
                            if ( !g_bFileWasRead ) precache_model(g_eSettings[SETTING_MODEL_SNOWBALL3])
                        }
                        else if ( equali(szKey, "SETTING_MODEL_SKELETON_T") )
                        {
                            copy(g_eSettings[SETTING_MODEL_SKELETON_T], charsmax(g_eSettings[SETTING_MODEL_SKELETON_T]), szValue)
                            if ( !g_bFileWasRead ) precache_model(g_eSettings[SETTING_MODEL_SKELETON_T])
                        }
                        else if ( equali(szKey, "SETTING_MODEL_SKELETON_CT") )
                        {
                            copy(g_eSettings[SETTING_MODEL_SKELETON_CT], charsmax(g_eSettings[SETTING_MODEL_SKELETON_CT]), szValue)
                            if ( !g_bFileWasRead ) precache_model(g_eSettings[SETTING_MODEL_SKELETON_CT])
                        }
                        else if ( equali(szKey, "SETTING_SOUND_MENU_NAV") )
                        {
                            copy(g_eSettings[SETTING_SOUND_MENU_NAV], charsmax(g_eSettings[SETTING_SOUND_MENU_NAV]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_MENU_REMOVE") )
                        {
                            copy(g_eSettings[SETTING_SOUND_MENU_REMOVE], charsmax(g_eSettings[SETTING_SOUND_MENU_REMOVE]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_MENU_ALERT") )
                        {
                            copy(g_eSettings[SETTING_SOUND_MENU_ALERT], charsmax(g_eSettings[SETTING_SOUND_MENU_ALERT]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_BLIP1") )
                        {
                            copy(g_eSettings[SETTING_SOUND_BLIP1], charsmax(g_eSettings[SETTING_SOUND_BLIP1]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_BLIP2") )
                        {
                            copy(g_eSettings[SETTING_SOUND_BLIP2], charsmax(g_eSettings[SETTING_SOUND_BLIP2]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_SWALLOW") )
                        {
                            copy(g_eSettings[SETTING_SOUND_SWALLOW], charsmax(g_eSettings[SETTING_SOUND_SWALLOW]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_CLIP1") )
                        {
                            copy(g_eSettings[SETTING_SOUND_CLIP1], charsmax(g_eSettings[SETTING_SOUND_CLIP1]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_BELL") )
                        {
                            copy(g_eSettings[SETTING_SOUND_BELL], charsmax(g_eSettings[SETTING_SOUND_BELL]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_MEDCHARGE") )
                        {
                            copy(g_eSettings[SETTING_SOUND_MEDCHARGE], charsmax(g_eSettings[SETTING_SOUND_MEDCHARGE]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_SUITCHARGE") )
                        {
                            copy(g_eSettings[SETTING_SOUND_SUITCHARGE], charsmax(g_eSettings[SETTING_SOUND_SUITCHARGE]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_BEEP_BEEP") )
                        {
                            copy(g_eSettings[SETTING_SOUND_BEEP_BEEP], charsmax(g_eSettings[SETTING_SOUND_BEEP_BEEP]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_FAST_WHOOSH") )
                        {
                            copy(g_eSettings[SETTING_SOUND_FAST_WHOOSH], charsmax(g_eSettings[SETTING_SOUND_FAST_WHOOSH]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_ROCKET1") )
                        {
                            copy(g_eSettings[SETTING_SOUND_ROCKET1], charsmax(g_eSettings[SETTING_SOUND_ROCKET1]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_ROCKETFIRE1") )
                        {
                            copy(g_eSettings[SETTING_SOUND_ROCKETFIRE1], charsmax(g_eSettings[SETTING_SOUND_ROCKETFIRE1]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_FIRE_WHOOSH") )
                        {
                            copy(g_eSettings[SETTING_SOUND_FIRE_WHOOSH], charsmax(g_eSettings[SETTING_SOUND_FIRE_WHOOSH]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_AMMO_PICKUP") )
                        {
                            copy(g_eSettings[SETTING_SOUND_AMMO_PICKUP], charsmax(g_eSettings[SETTING_SOUND_AMMO_PICKUP]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_SCREAM") )
                        {
                            copy(g_eSettings[SETTING_SOUND_SCREAM], charsmax(g_eSettings[SETTING_SOUND_SCREAM]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_HYPNO") )
                        {
                            copy(g_eSettings[SETTING_SOUND_HYPNO], charsmax(g_eSettings[SETTING_SOUND_HYPNO]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_BOUNCING") )
                        {
                            copy(g_eSettings[SETTING_SOUND_BOUNCING], charsmax(g_eSettings[SETTING_SOUND_BOUNCING]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_SOUND_LIGHTNING") )
                        {
                            copy(g_eSettings[SETTING_SOUND_LIGHTNING], charsmax(g_eSettings[SETTING_SOUND_LIGHTNING]), szValue)
                            if ( !g_bFileWasRead ) precache_sound(szValue)
                        }
                        else if ( equali(szKey, "SETTING_COLOR_SELECT") )
                        {
                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            g_eSettings[SETTING_COLOR_SELECT][0] = str_to_num(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            g_eSettings[SETTING_COLOR_SELECT][1] = str_to_num(szKey)
                            g_eSettings[SETTING_COLOR_SELECT][2] = str_to_num(szValue)
                        }
                    }
                    case SECTION_POWER:
                    {
                        if ( equali(szKey, "POWER_MODEL") )
                        {
                            copy( ePower[POWER_MODEL], charsmax(ePower[POWER_MODEL]), szValue)
                            if ( !g_bFileWasRead )
                                precache_model(szValue)
                        }
                        else if ( equali(szKey, "POWER_FLAGS") )
                        {
                            ePower[POWER_FLAGS] = read_flags(szValue)
                            ePower[POWER_FLAGS] &= 7
                        }
                        else if ( equali(szKey, "POWER_TEAM") )
                        {
                            ePower[POWER_TEAM] = str_to_num(szValue)
                            ePower[POWER_TEAM] = clamp(ePower[POWER_TEAM], TEAM_NONE, TEAM_BOTH)
                        }
                        else if ( equali(szKey, "POWER_SPAWN_MODE") )
                        {
                            ePower[POWER_SPAWN_MODE] = str_to_num(szValue)
                            ePower[POWER_SPAWN_MODE] = clamp(ePower[POWER_SPAWN_MODE], SPAWN_NEVER, SPAWN_DELAY)
                        }
                        else if ( equali(szKey, "POWER_SPAWN_MIN") )
                        {
                            ePower[POWER_SPAWN_MIN] = str_to_float(szValue)
                            if ( ePower[POWER_SPAWN_MIN] < 0.0 ) ePower[POWER_SPAWN_MIN] = 0.0
                        }
                        else if ( equali(szKey, "POWER_SPAWN_MAX") )
                        {
                            ePower[POWER_SPAWN_MAX] = str_to_float(szValue)
                            if ( ePower[POWER_SPAWN_MAX] < ePower[POWER_SPAWN_MIN] ) ePower[POWER_SPAWN_MIN] = 0.0
                        }
                        else if ( equali(szKey, "POWER_SPAWN_CHANCE") )
                        {
                            ePower[POWER_SPAWN_CHANCE] = str_to_float(szValue)
                            ePower[POWER_SPAWN_CHANCE] = floatclamp(ePower[POWER_SPAWN_CHANCE], 0.0, 1.0)
                        }
                        else if ( equali(szKey, "POWER_ANIMATION") )
                        {
                            ePower[POWER_ANIMATION] = str_to_num(szValue)
                            if ( ePower[POWER_ANIMATION] < 0 ) ePower[POWER_ANIMATION] = 0
                        }
                        else if ( equali(szKey, "POWER_FRAME") )
                        {
                            ePower[POWER_FRAME] = str_to_float(szValue)
                            if ( ePower[POWER_FRAME] < 0.0 ) ePower[POWER_FRAME] = 0.0
                        }
                        else if ( equali(szKey, "POWER_FRAMERATE") )
                        {
                            ePower[POWER_FRAMERATE] = str_to_float(szValue)
                            if ( ePower[POWER_FRAMERATE] < 0.0 ) ePower[POWER_FRAMERATE] = 0.0
                        }
                        else if ( equali(szKey, "POWER_CLASS") )
                        {
                            ePower[POWER_CLASS] = str_to_num(szValue)
                            ePower[POWER_CLASS] = clamp(ePower[POWER_CLASS], CLASS_AMMO, CLASS_WINGS)

                            switch( ePower[POWER_CLASS] )
                            {
                                case CLASS_AMMO:        { ePower[POWER_DATA] = ArrayCreate(POWER_AMMO);         ArrayPushArray(ePower[POWER_DATA], ePowerAmmo);         iSection = SECTION_POWER_AMMO; }
                                case CLASS_AMMO2:       { ePower[POWER_DATA] = ArrayCreate(POWER_AMMO2);        ArrayPushArray(ePower[POWER_DATA], ePowerAmmo2);        iSection = SECTION_POWER_AMMO2; }
                                case CLASS_BOMB:        { ePower[POWER_DATA] = ArrayCreate(POWER_BOMB);         ArrayPushArray(ePower[POWER_DATA], ePowerBomb);         iSection = SECTION_POWER_BOMB; }
                                case CLASS_CLOCK:       { ePower[POWER_DATA] = ArrayCreate(POWER_CLOCK);        ArrayPushArray(ePower[POWER_DATA], ePowerClock);        iSection = SECTION_POWER_CLOCK; }
                                case CLASS_HEALTH:      { ePower[POWER_DATA] = ArrayCreate(POWER_HEALTH);       ArrayPushArray(ePower[POWER_DATA], ePowerHealth);       iSection = SECTION_POWER_HEALTH; }
                                case CLASS_HEALTH2:     { ePower[POWER_DATA] = ArrayCreate(POWER_HEALTH2);      ArrayPushArray(ePower[POWER_DATA], ePowerHealth2);      iSection = SECTION_POWER_HEALTH2; }
                                case CLASS_LIGHTNING:   { ePower[POWER_DATA] = ArrayCreate(POWER_LIGHTNING);    ArrayPushArray(ePower[POWER_DATA], ePowerLightning);    iSection = SECTION_POWER_LIGHTNING; }
                                case CLASS_LIGHTNING2:  { ePower[POWER_DATA] = ArrayCreate(POWER_LIGHTNING2);   ArrayPushArray(ePower[POWER_DATA], ePowerLightning2);   iSection = SECTION_POWER_LIGHTNING2; }
                                case CLASS_MASK:        { ePower[POWER_DATA] = ArrayCreate(POWER_MASK);         ArrayPushArray(ePower[POWER_DATA], ePowerMask);         iSection = SECTION_POWER_MASK; }
                                case CLASS_MASK2:       { ePower[POWER_DATA] = ArrayCreate(POWER_MASK2);        ArrayPushArray(ePower[POWER_DATA], ePowerMask2);        iSection = SECTION_POWER_MASK2; }
                                case CLASS_ROCKET:      { ePower[POWER_DATA] = ArrayCreate(POWER_ROCKET);       ArrayPushArray(ePower[POWER_DATA], ePowerRocket);       iSection = SECTION_POWER_ROCKET; }
                                case CLASS_SHIELD:      { ePower[POWER_DATA] = ArrayCreate(POWER_SHIELD);       ArrayPushArray(ePower[POWER_DATA], ePowerShield);       iSection = SECTION_POWER_SHIELD; }
                                case CLASS_SKULL:       { ePower[POWER_DATA] = ArrayCreate(POWER_SKULL);        ArrayPushArray(ePower[POWER_DATA], ePowerSkull);        iSection = SECTION_POWER_SKULL; }
                                case CLASS_STUN:        { ePower[POWER_DATA] = ArrayCreate(POWER_STUN);         ArrayPushArray(ePower[POWER_DATA], ePowerStun);         iSection = SECTION_POWER_STUN; }
                                case CLASS_STUN2:       { ePower[POWER_DATA] = ArrayCreate(POWER_STUN2);        ArrayPushArray(ePower[POWER_DATA], ePowerStun2);        iSection = SECTION_POWER_STUN2; }
                                case CLASS_UP:          { ePower[POWER_DATA] = ArrayCreate(POWER_UP);           ArrayPushArray(ePower[POWER_DATA], ePowerUp);           iSection = SECTION_POWER_UP; }
                                case CLASS_UP2:         { ePower[POWER_DATA] = ArrayCreate(POWER_UP2);          ArrayPushArray(ePower[POWER_DATA], ePowerUp2);          iSection = SECTION_POWER_UP2; }
                                case CLASS_WINGS:       { ePower[POWER_DATA] = ArrayCreate(POWER_WINGS);        ArrayPushArray(ePower[POWER_DATA], ePowerWings);        iSection = SECTION_POWER_WINGS; }
                            }
                        }
                    }
                    case SECTION_POWER_AMMO:
                    {
                        if ( equali(szKey, "AMMO_CLIP") )
                        {
                            ePowerAmmo[AMMO_CLIP] = str_to_float(szValue)
                            if ( ePowerAmmo[AMMO_CLIP] < 0.0 ) ePowerAmmo[AMMO_CLIP] = 1.0
                        }
                        else if ( equali(szKey, "AMMO_AMMO") )
                        {
                            ePowerAmmo[AMMO_AMMO] = str_to_float(szValue)
                            if ( ePowerAmmo[AMMO_AMMO] < 0.0 ) ePowerAmmo[AMMO_AMMO] = 0.5
                        }
                        else if ( equali(szKey, "AMMO_MODE") )
                        {
                            ePowerAmmo[AMMO_MODE] = str_to_num(szValue)
                            clamp(ePowerAmmo[AMMO_MODE], AMMO_MODE_RELATIVE, AMMO_MODE_ABSOLUTE)
                        }
                        else if ( equali(szKey, "AMMO_OVERFLOW") )
                        {
                            ePowerAmmo[AMMO_OVERFLOW] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerAmmo)
                    }
                    case SECTION_POWER_AMMO2:
                    {
                        if ( equali(szKey, "AMMO2_CLIP") )
                        {
                            ePowerAmmo2[AMMO2_CLIP] = str_to_float(szValue)
                            if ( ePowerAmmo2[AMMO2_CLIP] < 0.0 ) ePowerAmmo2[AMMO2_CLIP] = 1.0
                        }
                        else if ( equali(szKey, "AMMO2_AMMO") )
                        {
                            ePowerAmmo2[AMMO2_AMMO] = str_to_float(szValue)
                            if ( ePowerAmmo2[AMMO2_AMMO] < 0.0 ) ePowerAmmo2[AMMO2_AMMO] = 0.5
                        }
                        else if ( equali(szKey, "AMMO2_MODE") )
                        {
                            ePowerAmmo2[AMMO2_MODE] = str_to_num(szValue)
                            clamp(ePowerAmmo2[AMMO2_MODE], AMMO_MODE_RELATIVE, AMMO_MODE_ABSOLUTE)
                        }
                        else if ( equali(szKey, "AMMO2_OVERFLOW") )
                        {
                            ePowerAmmo2[AMMO2_OVERFLOW] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerAmmo2)
                    }
                    case SECTION_POWER_BOMB:
                    {
                        if ( equali(szKey, "BOMB_HE_SUPPLY") )
                        {
                            ePowerBomb[BOMB_HE_SUPPLY] = str_to_num(szValue)
                            if ( ePowerBomb[BOMB_HE_SUPPLY] < 0 ) ePowerBomb[BOMB_HE_SUPPLY] = 1
                        }
                        else if ( equali(szKey, "BOMB_FB_SUPPLY") )
                        {
                            ePowerBomb[BOMB_FB_SUPPLY] = str_to_num(szValue)
                            if ( ePowerBomb[BOMB_FB_SUPPLY] < 0 ) ePowerBomb[BOMB_FB_SUPPLY] = 1
                        }
                        else if ( equali(szKey, "BOMB_SMOKE_SUPPLY") )
                        {
                            ePowerBomb[BOMB_SMOKE_SUPPLY] = str_to_num(szValue)
                            if ( ePowerBomb[BOMB_SMOKE_SUPPLY] < 0 ) ePowerBomb[BOMB_SMOKE_SUPPLY] = 1
                        }
                        else if ( equali(szKey, "BOMB_HE_LIMIT") )
                        {
                            ePowerBomb[BOMB_HE_LIMIT] = str_to_num(szValue)
                            if ( ePowerBomb[BOMB_HE_LIMIT] < 0 ) ePowerBomb[BOMB_HE_LIMIT] = 5
                        }
                        else if ( equali(szKey, "BOMB_FB_LIMIT") )
                        {
                            ePowerBomb[BOMB_FB_LIMIT] = str_to_num(szValue)
                            if ( ePowerBomb[BOMB_FB_LIMIT] < 0 ) ePowerBomb[BOMB_FB_LIMIT] = 5
                        }
                        else if ( equali(szKey, "BOMB_SMOKE_LIMIT") )
                        {
                            ePowerBomb[BOMB_SMOKE_LIMIT] = str_to_num(szValue)
                            if ( ePowerBomb[BOMB_SMOKE_LIMIT] < 0 ) ePowerBomb[BOMB_SMOKE_LIMIT] = 5
                        }
                        else if ( equali(szKey, "BOMB_OVERFLOW") )
                        {
                            ePowerBomb[BOMB_OVERFLOW] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerBomb)
                    }
                    case SECTION_POWER_CLOCK:
                    {
                        if ( equali(szKey, "CLOCK_SPEED") )
                        {
                            ePowerClock[CLOCK_SPEED] = str_to_float(szValue)
                            if ( ePowerClock[CLOCK_SPEED] < 0.0 ) ePowerClock[CLOCK_SPEED] = 0.0
                        }
                        else if ( equali(szKey, "CLOCK_DURATION_MIN") )
                        {
                            ePowerClock[CLOCK_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerClock[CLOCK_DURATION_MIN] < 0.0 ) ePowerClock[CLOCK_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "CLOCK_DURATION_MAX") )
                        {
                            ePowerClock[CLOCK_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerClock[CLOCK_DURATION_MAX] < 0.0 ) ePowerClock[CLOCK_DURATION_MAX] = 12.0
                        }
                        else if ( equali(szKey, "CLOCK_STACk") )
                        {
                            ePowerClock[CLOCK_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerClock)
                    }
                    case SECTION_POWER_HEALTH:
                    {
                        if ( equali(szKey, "HEALTH_MIN") )
                        {
                            ePowerHealth[HEALTH_MIN] = str_to_float(szValue)
                            if ( ePowerHealth[HEALTH_MIN] < 0.0 ) ePowerHealth[HEALTH_MIN] = 15.0
                        }
                        else if ( equali(szKey, "HEALTH_MAX") )
                        {
                            ePowerHealth[HEALTH_MAX] = str_to_float(szValue)
                            if ( ePowerHealth[HEALTH_MAX] < ePowerHealth[HEALTH_MIN] ) ePowerHealth[HEALTH_MAX] = ePowerHealth[HEALTH_MIN]
                        }
                        else if ( equali(szKey, "HEALTH_LIMIT") )
                        {
                            ePowerHealth[HEALTH_LIMIT] = str_to_float(szValue)
                            if ( ePowerHealth[HEALTH_LIMIT] < 0.0 ) ePowerHealth[HEALTH_LIMIT] = 150.0
                        }
                        else if ( equali(szKey, "HEALTH_SCREEN_FADE") )
                        {
                            ePowerHealth[HEALTH_SCREEN_FADE] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "HEALTH_OVERFLOW") )
                        {
                            ePowerHealth[HEALTH_OVERFLOW] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerHealth)
                    }
                    case SECTION_POWER_HEALTH2:
                    {
                        if ( equali(szKey, "HEALTH2_MIN") )
                        {
                            ePowerHealth2[HEALTH2_MIN] = str_to_float(szValue)
                            if ( ePowerHealth2[HEALTH2_MIN] < 0.0 ) ePowerHealth2[HEALTH2_MIN] = 1.0
                        }
                        else if ( equali(szKey, "HEALTH2_MAX") )
                        {
                            ePowerHealth2[HEALTH2_MAX] = str_to_float(szValue)
                            if ( ePowerHealth2[HEALTH2_MAX] < ePowerHealth2[HEALTH2_MIN] ) ePowerHealth2[HEALTH2_MAX] = ePowerHealth2[HEALTH2_MIN]
                        }
                        else if ( equali(szKey, "HEALTH2_FREQ") )
                        {
                            ePowerHealth2[HEALTH2_FREQ] = str_to_float(szValue)
                            if ( ePowerHealth2[HEALTH2_FREQ] < 0.0 ) ePowerHealth2[HEALTH2_FREQ] = 1.0
                        }
                        else if ( equali(szKey, "HEALTH2_DURATION_MIN") )
                        {
                            ePowerHealth2[HEALTH2_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerHealth2[HEALTH2_DURATION_MIN] < 0.0 ) ePowerHealth2[HEALTH2_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "HEALTH2_DURATION_MAX") )
                        {
                            ePowerHealth2[HEALTH2_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerHealth2[HEALTH2_DURATION_MAX] < ePowerHealth2[HEALTH2_DURATION_MIN] ) ePowerHealth2[HEALTH2_DURATION_MAX] = ePowerHealth2[HEALTH2_DURATION_MIN]
                        }
                        else if ( equali(szKey, "HEALTH2_LIMIT") )
                        {
                            ePowerHealth2[HEALTH2_LIMIT] = str_to_float(szValue)
                            if ( ePowerHealth2[HEALTH2_LIMIT] < 0.0 ) ePowerHealth2[HEALTH2_LIMIT] = 150.0
                        }
                        else if ( equali(szKey, "HEALTH2_SCREEN_FADE") )
                        {
                            ePowerHealth2[HEALTH2_SCREEN_FADE] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "HEALTH2_OVERFLOW") )
                        {
                            ePowerHealth2[HEALTH2_OVERFLOW] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "HEALTH2_STACK") )
                        {
                            ePowerHealth2[HEALTH2_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerHealth2)
                    }
                    case SECTION_POWER_LIGHTNING:
                    {
                        if ( equali(szKey, "LIGHTNING_MIN") )
                        {
                            ePowerLightning[LIGHTNING_MIN] = str_to_float(szValue)
                            if ( ePowerLightning[LIGHTNING_MIN] < 0.0 ) ePowerLightning[LIGHTNING_MIN] = 1.28
                        }
                        else if ( equali(szKey, "LIGHTNING_MAX") )
                        {
                            ePowerLightning[LIGHTNING_MAX] = str_to_float(szValue)
                            if ( ePowerLightning[LIGHTNING_MAX] < ePowerLightning[LIGHTNING_MIN] ) ePowerLightning[LIGHTNING_MAX] = ePowerLightning[LIGHTNING_MIN]
                        }
                        else if ( equali(szKey, "LIGHTNING_DURATION_MIN") )
                        {
                            ePowerLightning[LIGHTNING_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerLightning[LIGHTNING_DURATION_MIN] < 0.0 ) ePowerLightning[LIGHTNING_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "LIGHTNING_DURATION_MAX") )
                        {
                            ePowerLightning[LIGHTNING_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerLightning[LIGHTNING_DURATION_MAX] < ePowerLightning[LIGHTNING_DURATION_MIN] ) ePowerLightning[LIGHTNING_DURATION_MAX] = ePowerLightning[LIGHTNING_DURATION_MIN]
                        }
                        else if ( equali(szKey, "LIGHTNING_MODE") )
                        {
                            ePowerLightning[LIGHTNING_MODE] = str_to_num(szValue)
                            clamp(ePowerLightning[LIGHTNING_MODE], SPEED_MODE_RELATIVE, SPEED_MODE_ABSOLUTE)
                        }
                        else if ( equali(szKey, "LIGHTNING_STACK") )
                        {
                            ePowerLightning[LIGHTNING_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerLightning)
                    }
                    case SECTION_POWER_LIGHTNING2:
                    {
                        if ( equali(szKey, "LIGHTNING2_MIN") )
                        {
                            ePowerLightning2[LIGHTNING2_MIN] = str_to_float(szValue)
                            if ( ePowerLightning2[LIGHTNING2_MIN] < 0.0 ) ePowerLightning2[LIGHTNING2_MIN] = 1.28
                        }
                        else if ( equali(szKey, "LIGHTNING2_MAX") )
                        {
                            ePowerLightning2[LIGHTNING2_MAX] = str_to_float(szValue)
                            if ( ePowerLightning2[LIGHTNING2_MAX] < ePowerLightning2[LIGHTNING2_MIN] ) ePowerLightning2[LIGHTNING2_MAX] = ePowerLightning2[LIGHTNING2_MIN]
                        }
                        else if ( equali(szKey, "LIGHTNING2_DELAY_MIN") )
                        {
                            ePowerLightning2[LIGHTNING2_DELAY_MIN] = str_to_float(szValue)
                            if ( ePowerLightning2[LIGHTNING2_DELAY_MIN] < 0.0 ) ePowerLightning2[LIGHTNING2_DELAY_MIN] = 1.0
                        }
                        else if ( equali(szKey, "LIGHTNING2_DELAY_MAX") )
                        {
                            ePowerLightning2[LIGHTNING2_DELAY_MAX] = str_to_float(szValue)
                            if ( ePowerLightning2[LIGHTNING2_DELAY_MAX] < ePowerLightning2[LIGHTNING2_DELAY_MIN] ) ePowerLightning2[LIGHTNING2_DELAY_MAX] = ePowerLightning2[LIGHTNING2_DELAY_MIN]
                        }
                        else if ( equali(szKey, "LIGHTNING2_DELAY_SPEED") )
                        {
                            ePowerLightning2[LIGHTNING2_DELAY_SPEED] = str_to_float(szValue)
                            if ( ePowerLightning2[LIGHTNING2_DELAY_SPEED] < 0.0 ) ePowerLightning2[LIGHTNING2_DELAY_SPEED] = 0.1
                        }
                        else if ( equali(szKey, "LIGHTNING2_TRAIL_COLOR") )
                        {
                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerLightning2[LIGHTNING2_TRAIL_COLOR][0] = str_to_num(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerLightning2[LIGHTNING2_TRAIL_COLOR][1] = str_to_num(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerLightning2[LIGHTNING2_TRAIL_COLOR][2] = str_to_num(szKey)
                            ePowerLightning2[LIGHTNING2_TRAIL_COLOR][3] = str_to_num(szValue)
                        }
                        else if ( equali(szKey, "LIGHTNING2_STACK") )
                        {
                            ePowerLightning2[LIGHTNING2_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerLightning2)
                    }
                    case SECTION_POWER_MASK:
                    {
                        if ( equali(szKey, "MASK_ALPHA_MIN") )
                        {
                            ePowerMask[MASK_ALPHA_MIN] = str_to_float(szValue)
                            if ( ePowerMask[MASK_ALPHA_MIN] < 0.0 ) ePowerMask[MASK_ALPHA_MIN] = 90.0
                        }
                        else if ( equali(szKey, "MASK_ALPHA_MAX") )
                        {
                            ePowerMask[MASK_ALPHA_MAX] = str_to_float(szValue)
                            if ( ePowerMask[MASK_ALPHA_MAX] < ePowerMask[MASK_ALPHA_MIN] ) ePowerMask[MASK_ALPHA_MAX] = ePowerMask[MASK_ALPHA_MIN]
                        }
                        else if ( equali(szKey, "MASK_DURATION_MIN") )
                        {
                            ePowerMask[MASK_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerMask[MASK_DURATION_MIN] < 0.0 ) ePowerMask[MASK_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "MASK_DURATION_MAX") )
                        {
                            ePowerMask[MASK_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerMask[MASK_DURATION_MAX] < ePowerMask[MASK_DURATION_MIN] ) ePowerMask[MASK_DURATION_MAX] = ePowerMask[MASK_DURATION_MIN]
                        }
                        else if ( equali(szKey, "MASK_FOOTSTEP") )
                        {
                            ePowerMask[MASK_FOOTSTEP] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "MASK_STACK") )
                        {
                            ePowerMask[MASK_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerMask)
                    }
                    case SECTION_POWER_MASK2:
                    {
                        if ( equali(szKey, "MASK2_DURATION_MIN") )
                        {
                            ePowerMask2[MASK2_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerMask2[MASK2_DURATION_MIN] < 0.0 ) ePowerMask2[MASK2_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "MASK2_DURATION_MAX") )
                        {
                            ePowerMask2[MASK2_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerMask2[MASK2_DURATION_MAX] < ePowerMask2[MASK2_DURATION_MIN] ) ePowerMask2[MASK2_DURATION_MAX] = ePowerMask2[MASK2_DURATION_MIN]
                        }
                        else if ( equali(szKey, "MASK2_MODEL_FLAG") )
                        {
                            ePowerMask2[MASK2_MODEL_FLAG] = read_flags(szValue)
                            ePowerMask2[MASK2_MODEL_FLAG] &= 15
                        }
                        else if ( equali(szKey, "MASK2_OVERRIDE") )
                        {
                            ePowerMask2[MASK2_OVERRIDE] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerMask2)
                    }
                    case SECTION_POWER_ROCKET:
                    {
                        if ( equali(szKey, "ROCKET_DAMAGE") )
                        {
                            ePowerRocket[ROCKET_DAMAGE] = str_to_float(szValue)
                            if ( ePowerRocket[ROCKET_DAMAGE] < 0.0 ) ePowerRocket[ROCKET_DAMAGE] = 5000.0
                        }
                        else if ( equali(szKey, "ROCKET_PUSH") )
                        {
                            ePowerRocket[ROCKET_PUSH] = str_to_float(szValue)
                            if ( ePowerRocket[ROCKET_PUSH] < 0.0 ) ePowerRocket[ROCKET_PUSH] = 450.0
                        }
                        else if ( equali(szKey, "ROCKET_GAP_PUSH") )
                        {
                            ePowerRocket[ROCKET_GAP_PUSH] = str_to_float(szValue)
                            if ( ePowerRocket[ROCKET_GAP_PUSH] < 0.0 ) ePowerRocket[ROCKET_GAP_PUSH] = 0.1
                        }
                        else if ( equali(szKey, "ROCKET_GAP_SMOKE") )
                        {
                            ePowerRocket[ROCKET_GAP_SMOKE] = str_to_float(szValue)
                            if ( ePowerRocket[ROCKET_GAP_SMOKE] < 0.0 ) ePowerRocket[ROCKET_GAP_SMOKE] = 0.2
                        }
                        else if ( equali(szKey, "ROCKET_DURATION_MIN") )
                        {
                            ePowerRocket[ROCKET_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerRocket[ROCKET_DURATION_MIN] < 0.0 ) ePowerRocket[ROCKET_DURATION_MIN] = 1.3
                        }
                        else if ( equali(szKey, "ROCKET_DURATION_MAX") )
                        {
                            ePowerRocket[ROCKET_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerRocket[ROCKET_DURATION_MAX] < 0.0 ) ePowerRocket[ROCKET_DURATION_MAX] = 1.7
                        }
                        else if ( equali(szKey, "ROCKET_SPEED") )
                        {
                            ePowerRocket[ROCKET_SPEED] = str_to_float(szValue)
                            if ( ePowerRocket[ROCKET_SPEED] < 0.0 ) ePowerRocket[ROCKET_SPEED] = 0.01
                        }
                        else if ( equali(szKey, "ROCKET_GIB") )
                        {
                            ePowerRocket[ROCKET_GIB] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerRocket)
                    }
                    case SECTION_POWER_SHIELD:
                    {
                        if ( equali(szKey, "SHIELD_ARMOR_MIN") )
                        {
                            ePowerShield[SHIELD_ARMOR_MIN] = str_to_num(szValue)
                            if ( ePowerShield[SHIELD_ARMOR_MIN] < 0 ) ePowerShield[SHIELD_ARMOR_MIN] = 50
                        }
                        else if ( equali(szKey, "SHIELD_ARMOR_MAX") )
                        {
                            ePowerShield[SHIELD_ARMOR_MAX] = str_to_num(szValue)
                            if ( ePowerShield[SHIELD_ARMOR_MAX] < ePowerShield[SHIELD_ARMOR_MIN] ) ePowerShield[SHIELD_ARMOR_MAX] = ePowerShield[SHIELD_ARMOR_MIN]
                        }
                        else if ( equali(szKey, "SHIELD_ARMOR_LIMIT") )
                        {
                            ePowerShield[SHIELD_ARMOR_LIMIT] = str_to_num(szValue)
                            if ( ePowerShield[SHIELD_ARMOR_LIMIT] < 0 ) ePowerShield[SHIELD_ARMOR_LIMIT] = 200
                        }
                        else if ( equali(szKey, "SHIELD_ARMOR_OVERFLOW") )
                        {
                            ePowerShield[SHIELD_ARMOR_OVERFLOW] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "SHIELD_ARMOR_TYPE") )
                        {
                            ePowerShield[SHIELD_ARMOR_TYPE] = CsArmorType:str_to_num(szValue)

                            if ( ePowerShield[SHIELD_ARMOR_TYPE] < CS_ARMOR_KEVLAR || ePowerShield[SHIELD_ARMOR_TYPE] > CS_ARMOR_VESTHELM )
                                ePowerShield[SHIELD_ARMOR_TYPE] = CS_ARMOR_VESTHELM
                        }
                        if ( equali(szKey, "SHIELD_FACTOR_ABSORB") )
                        {
                            ePowerShield[SHIELD_FACTOR_ABSORB] = str_to_float(szValue)
                            if ( ePowerShield[SHIELD_FACTOR_ABSORB] < 0.0 ) ePowerShield[SHIELD_FACTOR_ABSORB] = 0.5
                        }
                        else if ( equali(szKey, "SHIELD_FACTOR_REFLECT") )
                        {
                            ePowerShield[SHIELD_FACTOR_REFLECT] = str_to_float(szValue)
                            if ( ePowerShield[SHIELD_FACTOR_REFLECT] < 0.0 ) ePowerShield[SHIELD_FACTOR_REFLECT] = 0.1
                        }
                        else if ( equali(szKey, "SHIELD_DURATION_MIN") )
                        {
                            ePowerShield[SHIELD_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerShield[SHIELD_DURATION_MIN] < 0.0 ) ePowerShield[SHIELD_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "SHIELD_DURATION_MAX") )
                        {
                            ePowerShield[SHIELD_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerShield[SHIELD_DURATION_MAX] < ePowerShield[SHIELD_DURATION_MIN] ) ePowerShield[SHIELD_DURATION_MAX] = ePowerShield[SHIELD_DURATION_MIN]
                        }
                        else if ( equali(szKey, "SHIELD_SIZE") )
                        {
                            ePowerShield[SHIELD_SIZE] = str_to_num(szValue)
                            ePowerShield[SHIELD_SIZE] = clamp(ePowerShield[SHIELD_SIZE], SHIELD_SIZE_SMALL, SHIELD_SIZE_LARGE)
                        }
                        else if ( equali(szKey, "SHIELD_COLOR") )
                        {
                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerShield[SHIELD_COLOR][0] = str_to_num(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerShield[SHIELD_COLOR][1] = str_to_num(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerShield[SHIELD_COLOR][2] = str_to_num(szKey)
                            ePowerShield[SHIELD_COLOR][3] = str_to_num(szValue)
                        }
                        else if ( equali(szKey, "SHIELD_STACK") )
                        {
                            ePowerShield[SHIELD_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerShield)
                    }
                    case SECTION_POWER_SKULL:
                    {
                        if ( equali(szKey, "SKULL_FACTOR_DAMAGE") )
                        {
                            ePowerSkull[SKULL_FACTOR_DAMAGE] = str_to_float(szValue)
                            if ( ePowerSkull[SKULL_FACTOR_DAMAGE] < 0.0 ) ePowerSkull[SKULL_FACTOR_DAMAGE] = 0.25
                        }
                        else if ( equali(szKey, "SKULL_FACTOR_BLOOD") )
                        {
                            ePowerSkull[SKULL_FACTOR_BLOOD] = str_to_float(szValue)
                            if ( ePowerSkull[SKULL_FACTOR_BLOOD] < 0.0 ) ePowerSkull[SKULL_FACTOR_BLOOD] = 0.25
                        }
                        else if ( equali(szKey, "SKULL_DURATION_MIN") )
                        {
                            ePowerSkull[SKULL_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerSkull[SKULL_DURATION_MIN] < 0.0 ) ePowerSkull[SKULL_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "SKULL_DURATION_MAX") )
                        {
                            ePowerSkull[SKULL_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerSkull[SKULL_DURATION_MAX] < ePowerSkull[SKULL_DURATION_MIN] ) ePowerSkull[SKULL_DURATION_MAX] = ePowerSkull[SKULL_DURATION_MIN]
                        }
                        else if ( equali(szKey, "SKULL_STACK") )
                        {
                            ePowerSkull[SKULL_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerSkull)
                    }
                    case SECTION_POWER_STUN:
                    {
                        if ( equali(szKey, "STUN_AMPLITUDE") )
                        {
                            ePowerStun[STUN_AMPLITUDE] = str_to_num(szValue)
                            ePowerStun[STUN_AMPLITUDE] = clamp(ePowerStun[STUN_AMPLITUDE], 0, 8)
                        }
                        else if ( equali(szKey, "STUN_FREQUENCY") )
                        {
                            ePowerStun[STUN_FREQUENCY] = str_to_num(szValue)
                            ePowerStun[STUN_FREQUENCY] = clamp(ePowerStun[STUN_FREQUENCY], 0, 8)
                        }
                        else if ( equali(szKey, "STUN_DURATION_MIN") )
                        {
                            ePowerStun[STUN_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerStun[STUN_DURATION_MIN] < 0.0 ) ePowerStun[STUN_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "STUN_DURATION_MAX") )
                        {
                            ePowerStun[STUN_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerStun[STUN_DURATION_MAX] < ePowerStun[STUN_DURATION_MIN] ) ePowerStun[STUN_DURATION_MAX] = ePowerStun[STUN_DURATION_MIN]
                        }
                        else if ( equali(szKey, "STUN_FOV") )
                        {
                            ePowerStun[STUN_FOV] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "STUN_FADE") )
                        {
                            ePowerStun[STUN_FADE] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "STUN_SHAKE") )
                        {
                            ePowerStun[STUN_SHAKE] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "STUN_STACK") )
                        {
                            ePowerStun[STUN_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerStun)
                    }
                    case SECTION_POWER_STUN2:
                    {
                        if ( equali(szKey, "STUN2_FREQ_MIN") )
                        {
                            ePowerStun2[STUN2_FREQ_MIN] = str_to_float(szValue)
                            if ( ePowerStun2[STUN2_FREQ_MIN] < 0.0 ) ePowerStun2[STUN2_FREQ_MIN] = 0.0
                        }
                        else if ( equali(szKey, "STUN2_FREQ_MAX") )
                        {
                            ePowerStun2[STUN2_FREQ_MAX] = str_to_float(szValue)
                            if ( ePowerStun2[STUN2_FREQ_MAX] < ePowerStun2[STUN2_FREQ_MIN] ) ePowerStun2[STUN2_FREQ_MAX] = ePowerStun2[STUN2_FREQ_MIN]
                        }
                        else if ( equali(szKey, "STUN2_DAMAGE_MIN") )
                        {
                            ePowerStun2[STUN2_DAMAGE_MIN] = str_to_float(szValue)
                            if ( ePowerStun2[STUN2_DAMAGE_MIN] < 0.0 ) ePowerStun2[STUN2_DAMAGE_MIN] = 0.0
                        }
                        else if ( equali(szKey, "STUN2_DAMAGE_MAX") )
                        {
                            ePowerStun2[STUN2_DAMAGE_MAX] = str_to_float(szValue)
                            if ( ePowerStun2[STUN2_DAMAGE_MAX] < ePowerStun2[STUN2_DAMAGE_MIN] ) ePowerStun2[STUN2_DAMAGE_MAX] = ePowerStun2[STUN2_DAMAGE_MIN]
                        }
                        else if ( equali(szKey, "STUN2_DURATION_MIN") )
                        {
                            ePowerStun2[STUN2_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerStun2[STUN2_DURATION_MIN] < 0.0 ) ePowerStun2[STUN2_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "STUN2_DURATION_MAX") )
                        {
                            ePowerStun2[STUN2_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerStun2[STUN2_DURATION_MAX] < ePowerStun2[STUN2_DURATION_MIN] ) ePowerStun2[STUN2_DURATION_MAX] = ePowerStun2[STUN2_DURATION_MIN]
                        }
                        else if ( equali(szKey, "STUN2_DIRECTION") )
                        {
                            ePowerStun2[STUN2_DIRECTION] = str_to_num(szValue)
                            ePowerStun2[STUN2_DIRECTION] = clamp(ePowerStun2[STUN2_DIRECTION], STUN2_DIRECTION_FORWARD, STUN2_DIRECTION_RANDOM)
                        }
                        else if ( equali(szKey, "STUN2_KILL") )
                        {
                            ePowerStun2[STUN2_KILL] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "STUN2_STACK") )
                        {
                            ePowerStun2[STUN2_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerStun2)
                    }
                    case SECTION_POWER_UP:
                    {
                        if ( equali(szKey, "UP_MIN") )
                        {
                            ePowerUp[UP_MIN] = str_to_float(szValue)
                            if ( ePowerUp[UP_MIN] < 0.0 ) ePowerUp[UP_MIN] = 900.0
                        }
                        else if ( equali(szKey, "UP_MAX") )
                        {
                            ePowerUp[UP_MAX] = str_to_float(szValue)
                            if ( ePowerUp[UP_MAX] < ePowerUp[UP_MIN] ) ePowerUp[UP_MAX] = ePowerUp[UP_MIN]
                        }
                        else if ( equali(szKey, "UP_TRAIL_COLOR") )
                        {
                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerUp[UP_TRAIL_COLOR][0] = str_to_num(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerUp[UP_TRAIL_COLOR][1] = str_to_num(szKey)

                            strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                            ePowerUp[UP_TRAIL_COLOR][2] = str_to_num(szKey)
                            ePowerUp[UP_TRAIL_COLOR][3] = str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerUp)
                    }
                    case SECTION_POWER_UP2:
                    {
                        if ( equali(szKey, "UP2_JUMP_MIN") )
                        {
                            ePowerUp2[UP2_JUMP_MIN] = str_to_num(szValue)
                            if ( ePowerUp2[UP2_JUMP_MIN] < 0 ) ePowerUp2[UP2_JUMP_MIN] = 3
                        }
                        else if ( equali(szKey, "UP2_JUMP_MAX") )
                        {
                            ePowerUp2[UP2_JUMP_MAX] = str_to_num(szValue)
                            if ( ePowerUp2[UP2_JUMP_MAX] < ePowerUp2[UP2_JUMP_MIN] ) ePowerUp2[UP2_JUMP_MAX] = ePowerUp2[UP2_JUMP_MIN]
                        }
                        else if ( equali(szKey, "UP2_DURATION_MIN") )
                        {
                            ePowerUp2[UP2_DURATION_MIN] = str_to_float(szValue)
                            if ( ePowerUp2[UP2_DURATION_MIN] < 0.0 ) ePowerUp2[UP2_DURATION_MIN] = 7.0
                        }
                        else if ( equali(szKey, "UP2_DURATION_MAX") )
                        {
                            ePowerUp2[UP2_DURATION_MAX] = str_to_float(szValue)
                            if ( ePowerUp2[UP2_DURATION_MAX] < ePowerUp2[UP2_DURATION_MIN] ) ePowerUp2[UP2_DURATION_MAX] = ePowerUp2[UP2_DURATION_MIN]
                        }
                        else if ( equali(szKey, "UP2_GRAVITY") )
                        {
                            ePowerUp2[UP2_GRAVITY] = str_to_float(szValue)
                            if ( ePowerUp2[UP2_GRAVITY] < 0.0 ) ePowerUp2[UP2_GRAVITY] = 0.5
                        }
                        else if ( equali(szKey, "UP2_STACK") )
                        {
                            ePowerUp2[UP2_STACK] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerUp2)
                    }
                    case SECTION_POWER_WINGS:
                    {
                        if ( equali(szKey, "WINGS_ORIGIN") )
                        {
                            ePowerWings[WINGS_ORIGIN] = str_to_num(szValue)
                            ePowerWings[WINGS_ORIGIN] = clamp(ePowerWings[WINGS_ORIGIN], WINGS_ORIGIN_SPAWN, WINGS_ORIGIN_SELF)
                        }
                        else if ( equali(szKey, "WINGS_HEALTH") )
                        {
                            ePowerWings[WINGS_HEALTH] = str_to_float(szValue)
                            if ( ePowerWings[WINGS_HEALTH] < 0.0 ) ePowerWings[WINGS_HEALTH] = 50.0
                        }
                        else if ( equali(szKey, "WINGS_SAVE_WEAPONS") )
                        {
                            ePowerWings[WINGS_SAVE_WEAPONS] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "WINGS_SAVE_AMMO") )
                        {
                            ePowerWings[WINGS_SAVE_AMMO] = bool:str_to_num(szValue)
                        }
                        else if ( equali(szKey, "WINGS_LIGHTNING") )
                        {
                            ePowerWings[WINGS_LIGHTNING] = bool:str_to_num(szValue)
                        }

                        ArraySetArray(ePower[POWER_DATA], 0, ePowerWings)
                    }
                }
            }
        }
    }

    if ( g_iPowerConfig )
        ArrayPushArray(g_aPowerConfig, ePower)
    else
        set_fail_state("No power-ups were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    get_user_name(id, g_ePlayerData[id][PDATA_NAME], charsmax(g_ePlayerData[][PDATA_NAME]))
    get_user_authid(id, g_ePlayerData[id][PDATA_AUTHID], charsmax(g_ePlayerData[][PDATA_AUTHID]))

    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public UpdateData(id)
{
    get_user_name(id, g_ePlayerData[id][PDATA_NAME], charsmax(g_ePlayerData[][PDATA_NAME]))
    g_ePlayerData[id][PDATA_ADMIN_FLAGS]    = get_user_flags(id)
    g_ePlayerData[id][PDATA_OFFSET]         = g_eSettings[SETTING_OFFSET_BASE]
}

public powerInit()
{
    if ( g_eSettings[SETTING_POWER_LOAD] )
        loadData()
}

public powerMenu(id, iType)
{
    new szTitle[64],
        iMenu

    formatex(szTitle, charsmax(szTitle), "%L", id, "POWER_MENU_TITLE")
    iMenu = menu_create(szTitle, g_szMenuHandler[iType])

    switch( iType )
    {
        case MENU_ROOT:     { menuRoot(id, iMenu); }
        case MENU_CREATE:   { menuCreate(iMenu);        format(szTitle, charsmax(szTitle), "%s^n%L", szTitle, id, "POWER_ROOT_CREATE"); }
        case MENU_REMOVE:   { menuRemove(id, iMenu);    format(szTitle, charsmax(szTitle), "%s^n%L", szTitle, id, "POWER_ROOT_REMOVE"); }
        case MENU_SHOW:     { menuShow(id, iMenu);      format(szTitle, charsmax(szTitle), "%s^n%L", szTitle, id, "POWER_ROOT_SHOW"); }
        case MENU_TEAM:     { menuTeam(id, iMenu);      format(szTitle, charsmax(szTitle), "%s^n%L", szTitle, id, "POWER_ROOT_TEAM"); }
        case MENU_ANIM:     { menuAnim(id, iMenu);      format(szTitle, charsmax(szTitle), "%s^n%L", szTitle, id, "POWER_ROOT_ANIM"); }
        case MENU_SPAWN:    { menuSpawn(id, iMenu);     format(szTitle, charsmax(szTitle), "%s^n%L", szTitle, id, "POWER_ROOT_SPAWN"); }
        case MENU_ROTATE:   { menuRotate(id, iMenu);    format(szTitle, charsmax(szTitle), "%s^n%L", szTitle, id, "POWER_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szTitle, charsmax(szTitle), "%s^n%L", szTitle, id, "POWER_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szTitle)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROOT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROOT_TEAM")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROOT_ANIM")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROOT_SPAWN")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iPower >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_LIMIT", MAX_ENT)
            }
            else
            {
                powerSound(id, SOUND_MENU_NAV)
                powerMenu(id, MENU_CREATE)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iPower )
            {
                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_NO_POWER")
            }
            else
            {
                powerSound(id, SOUND_MENU_REMOVE)
                powerMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_SHOW:
        {
            if ( !g_iPower )
            {
                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_NO_POWER")
            }
            else
            {
                powerSound(id, SOUND_MENU_NAV)
                powerMenu(id, MENU_SHOW)
            }
        }
        case ROOT_TEAM :
        {
            if ( !g_iPower )
            {
                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_NO_POWER")
            }
            else
            {
                powerSound(id, SOUND_MENU_NAV)
                powerMenu(id, MENU_TEAM)
            }
        }
        case ROOT_ANIM:
        {
            if ( !g_iPower )
            {
                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_NO_POWER")
            }
            else
            {
                powerSound(id, SOUND_MENU_NAV)
                powerMenu(id, MENU_ANIM)
            }
        }
        case ROOT_SPAWN:
        {
            if ( !g_iPower )
            {
                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_NO_POWER")
            }
            else
            {
                powerSound(id, SOUND_MENU_NAV)
                powerMenu(id, MENU_SPAWN)
            }
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new ePower[POWER],
        szItem[64]

    for ( new i = 0; i < g_iPowerConfig; i ++ )
    {
        ArrayGetArray(g_aPowerConfig, i, ePower)

        copy(szItem, charsmax(szItem), ePower[POWER_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( item == MENU_EXIT
    || !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    powerCreate(id, item)
    powerSound(id, SOUND_MENU_NAV)
    powerMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64],
        ePower[POWER]

    menuNav(id, iMenu)
    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_REMOVE_CURRENT", ePower[POWER_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    g_ePlayerData[id][PDATA_POWER_ACTION] = true
    ePower[POWER_FLAGS] |= FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
}

public menuHandlerRemove(id, menu, item)
{
    new ePower[POWER]

    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
    ePower[POWER_FLAGS] &= ~FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] >= g_iPower - 1 )
                g_ePlayerData[id][PDATA_POWER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_POWER_MENU] ++

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_POWER_MENU] = g_iPower - 1
            else
                g_ePlayerData[id][PDATA_POWER_MENU] --

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            powerKill(ePower[POWER_ID])
            powerRemove(g_ePlayerData[id][PDATA_POWER_MENU])

            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_REMOVE_CURRENT", ePower[POWER_NAME])
            g_ePlayerData[id][PDATA_POWER_MENU] = 0

            powerSound(id, g_iPower > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            powerMenu(id, g_iPower > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iPower )
            {
                ArrayGetArray(g_aPower, 0, ePower)

                powerKill(ePower[POWER_ID])
                powerRemove(0)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_POWER_MENU] = 0

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_ROOT)
        }
        default:
        {
            g_ePlayerData[id][PDATA_POWER_MENU] = 0
            g_ePlayerData[id][PDATA_POWER_ACTION] = false
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

stock saveData(id)
{
    new ePower[POWER],
        szFile[64], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_PowerUp.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iPower; i ++ )
    {
        ArrayGetArray(g_aPower, i, ePower)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        ePower[POWER_ORIGIN][0], ePower[POWER_ORIGIN][1], ePower[POWER_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n^n",
        ePower[POWER_ANGLES][0], ePower[POWER_ANGLES][1], ePower[POWER_ANGLES][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", ePower[POWER_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", ePower[POWER_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "show = %d^n", ePower[POWER_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "team = %d^n", ePower[POWER_TEAM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "anim = %d^n", ePower[POWER_ANIMATION])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "spawn = %d^n", ePower[POWER_SPAWN_MODE])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_SAVE", szFile)
    fclose(iFile)

    return PLUGIN_HANDLED
}

stock loadData()
{
    new szFile[64], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem,
        iFlags, iShow, iTeam, iAnim, iSpawn,
        ePower[POWER], iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_PowerUp.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
    {
        console_print(0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_NO_DATA")
        return PLUGIN_HANDLED
    }

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
            {
                powerCreate(0, iItem)
                ArrayGetArray(g_aPower, iCount, ePower)

                xs_vec_copy(fOrigin, ePower[POWER_ORIGIN])
                xs_vec_copy(fAngles, ePower[POWER_ANGLES])
                set_pev(ePower[POWER_ID], pev_origin, fOrigin)
                set_pev(ePower[POWER_ID], pev_angles, fAngles)
                ePower[POWER_FLAGS] = iFlags
                ePower[POWER_SHOW] = iShow
                ePower[POWER_TEAM] = iTeam
                ePower[POWER_ANIMATION] = iAnim
                ePower[POWER_SPAWN_MODE] = iSpawn

                powerSetBox(ePower)
                powerSetAnim(ePower)
                powerSetSolid(ePower)
                ArraySetArray(g_aPower, iCount, ePower)
            }

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "team") )
            {
                iTeam = str_to_num(szValue)
            }
            else if ( equal(szKey, "anim") )
            {
                iAnim = str_to_num(szValue)
            }
            else if ( equal(szKey, "spawn") )
            {
                iSpawn = str_to_num(szValue)
            }
        }
    }

    if ( iCount != -1 )
    {
        powerCreate(0, iItem)
        ArrayGetArray(g_aPower, iCount, ePower)

        xs_vec_copy(fOrigin, ePower[POWER_ORIGIN])
        xs_vec_copy(fAngles, ePower[POWER_ANGLES])
        set_pev(ePower[POWER_ID], pev_origin, fOrigin)
        set_pev(ePower[POWER_ID], pev_angles, fAngles)
        ePower[POWER_FLAGS] = iFlags
        ePower[POWER_SHOW] = iShow
        ePower[POWER_TEAM] = iTeam
        ePower[POWER_ANIMATION] = iAnim
        ePower[POWER_SPAWN_MODE] = iSpawn

        powerSetBox(ePower)
        powerSetAnim(ePower)
        powerSetSolid(ePower)
        ArraySetArray(g_aPower, iCount, ePower)
    }

    fclose(iFile)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64],
        ePower[POWER]

    menuNav(id, iMenu)
    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_SHOW_CURRENT",
    g_szShowColor[ePower[POWER_SHOW]], ePower[POWER_NAME], id, g_szShow[ePower[POWER_SHOW]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_SHOW_ALL_DEFAULT")
    menu_additem(iMenu, szItem)

    g_ePlayerData[id][PDATA_POWER_ACTION] = true
    ePower[POWER_FLAGS] |= FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
}

public menuHandlerShow(id, menu, item)
{
    new ePower[POWER]

    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
    ePower[POWER_FLAGS] &= ~FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] >= g_iPower - 1 )
                g_ePlayerData[id][PDATA_POWER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_POWER_MENU] ++

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_POWER_MENU] = g_iPower - 1
            else
                g_ePlayerData[id][PDATA_POWER_MENU] --

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            if ( ++ ePower[POWER_SHOW] > SHOW_FORCE_HIDE )
                ePower[POWER_SHOW] = SHOW_DEFAULT

            if ( ePower[POWER_SHOW] == SHOW_FORCE_SHOW )
                ePower[POWER_FLAGS] |= FLAG_SHOW
            else if ( ePower[POWER_SHOW] == SHOW_FORCE_HIDE )
                ePower[POWER_FLAGS] &= ~FLAG_SHOW

            if ( ePower[POWER_SHOW] == SHOW_DEFAULT
            && ePower[POWER_SPAWN_MODE] == SPAWN_DELAY
            && !(ePower[POWER_FLAGS] & FLAG_SHOW) )
                ePower[POWER_NEXT_SPAWN] = get_gametime() + random_float(ePower[POWER_SPAWN_MIN], ePower[POWER_SPAWN_MAX])

            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_SHOW_CURRENT",
            ePower[POWER_NAME], id, g_szShowChat[ePower[POWER_SHOW]])
            ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
            set_pev(ePower[POWER_ID], pev_solid, ePower[POWER_FLAGS] & FLAG_SHOW ? SOLID_TRIGGER : SOLID_NOT)

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_SHOW] = SHOW_FORCE_SHOW
                ePower[POWER_FLAGS] |= FLAG_SHOW
                set_pev(ePower[POWER_ID], pev_solid, SOLID_TRIGGER)

                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_SHOW_ALL_SHOWN")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_SHOW] = SHOW_FORCE_HIDE
                ePower[POWER_FLAGS] &= ~FLAG_SHOW
                set_pev(ePower[POWER_ID], pev_solid, SOLID_NOT)

                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_SHOW_ALL_HIDDEN")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_DEFAULT:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)

                ePower[POWER_SHOW] = SHOW_DEFAULT
                if ( ePower[POWER_SPAWN_MODE] == SPAWN_DELAY
                && !(ePower[POWER_FLAGS] & FLAG_SHOW) )
                    ePower[POWER_NEXT_SPAWN] = get_gametime() + random_float(ePower[POWER_SPAWN_MIN], ePower[POWER_SPAWN_MAX])

                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_SHOW_ALL_DEFAULT")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_SHOW)
        }
        default:
        {
            g_ePlayerData[id][PDATA_POWER_MENU] = 0
            g_ePlayerData[id][PDATA_POWER_ACTION] = false
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuTeam(id, iMenu)
{
    new szItem[64],
        ePower[POWER]

    menuNav(id, iMenu)
    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_TEAM_CURRENT",
    ePower[POWER_NAME], id, g_szTeam[ePower[POWER_TEAM]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_TEAM_ALL_NONE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_TEAM_ALL_T")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_TEAM_ALL_CT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_TEAM_ALL_BOTH")
    menu_additem(iMenu, szItem)

    g_ePlayerData[id][PDATA_POWER_ACTION] = true
    ePower[POWER_FLAGS] |= FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
}

public menuHandlerTeam(id, menu, item)
{
    new ePower[POWER]

    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
    ePower[POWER_FLAGS] &= ~FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    switch( item )
    {
        case TEAM_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] >= g_iPower - 1 )
                g_ePlayerData[id][PDATA_POWER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_POWER_MENU] ++

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_TEAM)
        }
        case TEAM_BACK:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_POWER_MENU] = g_iPower - 1
            else
                g_ePlayerData[id][PDATA_POWER_MENU] --

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_TEAM)
        }
        case TEAM_CURRENT:
        {
            if ( ++ ePower[POWER_TEAM] > TEAM_BOTH )
                ePower[POWER_TEAM] = TEAM_NONE

            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_TEAM_CURRENT",
            ePower[POWER_NAME], id, g_szTeamChat[ePower[POWER_TEAM]])
            ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_TEAM)
        }
        case TEAM_ALL_NONE:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_TEAM] = TEAM_NONE
                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_TEAM_ALL_NONE")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_TEAM)
        }
        case TEAM_ALL_T:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_TEAM] = TEAM_T
                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_TEAM_ALL_T")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_TEAM)
        }
        case TEAM_ALL_CT:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_TEAM] = TEAM_CT
                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_TEAM_ALL_CT")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_TEAM)
        }
        case TEAM_ALL_BOTH:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_TEAM] = TEAM_BOTH
                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_TEAM_ALL_BOTH")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_TEAM)
        }
        default:
        {
            g_ePlayerData[id][PDATA_POWER_MENU] = 0
            g_ePlayerData[id][PDATA_POWER_ACTION] = false
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuAnim(id, iMenu)
{
    new szItem[64],
        ePower[POWER]

    menuNav(id, iMenu)
    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ANIM_CURRENT",
    ePower[POWER_NAME], id, g_szAnim[ePower[POWER_ANIMATION]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ANIM_ALL_IDLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ANIM_ALL_SPIN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ANIM_ALL_FLOAT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ANIM_ALL_SPIN_FLOAT")
    menu_additem(iMenu, szItem)

    g_ePlayerData[id][PDATA_POWER_ACTION] = true
    ePower[POWER_FLAGS] |= FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
}

public menuHandlerAnim(id, menu, item)
{
    new ePower[POWER]

    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
    ePower[POWER_FLAGS] &= ~FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    switch( item )
    {
        case ANIM_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] >= g_iPower - 1 )
                g_ePlayerData[id][PDATA_POWER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_POWER_MENU] ++

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_ANIM)
        }
        case ANIM_BACK:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_POWER_MENU] = g_iPower - 1
            else
                g_ePlayerData[id][PDATA_POWER_MENU] --

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_ANIM)
        }
        case ANIM_CURRENT:
        {
            if ( ++ ePower[POWER_ANIMATION] > ANIMATION_SPIN_FLOAT )
                ePower[POWER_ANIMATION] = ANIMATION_IDLE

            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_ANIM_CURRENT",
            ePower[POWER_NAME], id, g_szAnimChat[ePower[POWER_ANIMATION]])

            ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
            powerSetAnim(ePower)

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_ANIM)
        }
        case ANIM_ALL_IDLE:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_ANIMATION] = ANIMATION_IDLE

                ArraySetArray(g_aPower, i, ePower)
                powerSetAnim(ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_ANIM_ALL_IDLE")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_ANIM)
        }
        case ANIM_ALL_SPIN:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_ANIMATION] = ANIMATION_SPIN

                ArraySetArray(g_aPower, i, ePower)
                powerSetAnim(ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_ANIM_ALL_SPIN")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_ANIM)
        }
        case ANIM_ALL_FLOAT:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_ANIMATION] = ANIMATION_FLOAT

                ArraySetArray(g_aPower, i, ePower)
                powerSetAnim(ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_ANIM_ALL_FLOAT")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_ANIM)
        }
        case ANIM_ALL_SPIN_FLOAT:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_ANIMATION] = ANIMATION_SPIN_FLOAT

                ArraySetArray(g_aPower, i, ePower)
                powerSetAnim(ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_ANIM_ALL_SPIN_FLOAT")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_ANIM)
        }
        default:
        {
            g_ePlayerData[id][PDATA_POWER_MENU] = 0
            g_ePlayerData[id][PDATA_POWER_ACTION] = false
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuSpawn(id, iMenu)
{
    new szItem[64],
        ePower[POWER]

    menuNav(id, iMenu)
    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_SPAWN_CURRENT",
    ePower[POWER_NAME], id, g_szSpawn[ePower[POWER_SPAWN_MODE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_SPAWN_ALL_NEVER")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_SPAWN_ALL_DELAY")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_SPAWN_ALL_ROUND_START")
    menu_additem(iMenu, szItem)

    g_ePlayerData[id][PDATA_POWER_ACTION] = true
    ePower[POWER_FLAGS] |= FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
}

public menuHandlerSpawn(id, menu, item)
{
    new ePower[POWER]

    ArrayGetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)
    ePower[POWER_FLAGS] &= ~FLAG_SELECT
    ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

    switch( item )
    {
        case SPAWN_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] >= g_iPower - 1 )
                g_ePlayerData[id][PDATA_POWER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_POWER_MENU] ++

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_SPAWN)
        }
        case SPAWN_BACK:
        {
            if ( g_ePlayerData[id][PDATA_POWER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_POWER_MENU] = g_iPower - 1
            else
                g_ePlayerData[id][PDATA_POWER_MENU] --

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_SPAWN)
        }
        case SPAWN_CURRENT:
        {
            if ( ++ ePower[POWER_SPAWN_MODE] > SPAWN_ROUND_START )
                ePower[POWER_SPAWN_MODE] = SPAWN_NEVER

            if ( ePower[POWER_SHOW] == SHOW_DEFAULT
            && ePower[POWER_SPAWN_MODE] == SPAWN_DELAY
            && !(ePower[POWER_FLAGS] & FLAG_SHOW) )
                ePower[POWER_NEXT_SPAWN] = get_gametime() + random_float(ePower[POWER_SPAWN_MIN], ePower[POWER_SPAWN_MAX])

            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_SPAWN_CURRENT",
            ePower[POWER_NAME], id, g_szSpawnChat[ePower[POWER_SPAWN_MODE]])
            ArraySetArray(g_aPower, g_ePlayerData[id][PDATA_POWER_MENU], ePower)

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_SPAWN)
        }
        case SPAWN_ALL_NEVER:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_SPAWN_MODE] = SPAWN_NEVER
                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_SPAWN_ALL_NEVER")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_SPAWN)
        }
        case SPAWN_ALL_DELAY:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)

                ePower[POWER_SPAWN_MODE] = SPAWN_DELAY
                if ( ePower[POWER_SHOW] == SHOW_DEFAULT
                && !(ePower[POWER_FLAGS] & FLAG_SHOW) )
                    ePower[POWER_NEXT_SPAWN] = get_gametime() + random_float(ePower[POWER_SPAWN_MIN], ePower[POWER_SPAWN_MAX])

                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_SPAWN_ALL_DELAY")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_SPAWN)
        }
        case SPAWN_ALL_ROUND_START:
        {
            for ( new i = 0; i < g_iPower; i ++ )
            {
                ArrayGetArray(g_aPower, i, ePower)
                ePower[POWER_SPAWN_MODE] = SPAWN_ROUND_START
                ArraySetArray(g_aPower, i, ePower)
            }

            client_print_color(0, 0, "%L %L", 0, "POWER_CHAT_TAG", 0, "POWER_CHAT_SPAWN_ALL_ROUND_START")

            powerSound(0, SOUND_MENU_ALERT)
            powerMenu(id, MENU_SPAWN)
        }
        default:
        {
            g_ePlayerData[id][PDATA_POWER_MENU] = 0
            g_ePlayerData[id][PDATA_POWER_ACTION] = false
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64],
        ePower[POWER]

    powerFind(g_ePlayerData[id][PDATA_POWER_GHOST], ePower)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROTATE_RIGHT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROTATE_LEFT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "POWER_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new ePower[POWER],
        iItem

    iItem = powerFind(g_ePlayerData[id][PDATA_POWER_GHOST], ePower)

    switch( item )
    {
        case ROTATE_RIGHT:
        {
            pev(ePower[POWER_ID], pev_angles, ePower[POWER_ANGLES])
            ePower[POWER_ANGLES][1] -= 22.5
            if ( ePower[POWER_ANGLES][1] < -180.0 ) ePower[POWER_ANGLES][1] += 360.0

            set_pev(ePower[POWER_ID], pev_angles, ePower[POWER_ANGLES])
            ArraySetArray(g_aPower, iItem, ePower)

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_ROTATE)
        }
        case ROTATE_LEFT:
        {
            pev(ePower[POWER_ID], pev_angles, ePower[POWER_ANGLES])
            ePower[POWER_ANGLES][1] += 22.5
            if ( ePower[POWER_ANGLES][1] > 180.0 ) ePower[POWER_ANGLES][1] -= 360.0

            set_pev(ePower[POWER_ID], pev_angles, ePower[POWER_ANGLES])
            ArraySetArray(g_aPower, iItem, ePower)

            powerSound(id, SOUND_MENU_NAV)
            powerMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            if ( iItem != -1 )
            {
                powerTrace(ePower, id)

                g_ePlayerData[id][PDATA_POWER_GHOST] = 0
                g_ePlayerData[id][PDATA_POWER_ACTION] = false

                pev(ePower[POWER_ID], pev_origin, ePower[POWER_ORIGIN])
                pev(ePower[POWER_ID], pev_angles, ePower[POWER_ANGLES])
                ePower[POWER_FLAGS] |= FLAG_SHOW

                powerNoClip(id, false)
                powerSetAnim(ePower)
                powerSetSolid(ePower)
                ArraySetArray(g_aPower, iItem, ePower)

                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CHAT_CREATE_NEW", ePower[POWER_NAME])
                powerSound(id, SOUND_MENU_NAV)
                powerMenu(id, MENU_ROOT)
            }
        }
        default:
        {
            powerNoClip(id, false)
            powerKill(ePower[POWER_ID])
            powerRemove(iItem)
            g_ePlayerData[id][PDATA_POWER_GHOST] = 0
            g_ePlayerData[id][PDATA_POWER_ACTION] = false
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public powerTask()
{
    new iPlayers[MAX_PLAYERS], iNum, id,
        ePower[POWER], iEnt

    get_players(iPlayers, iNum, "ach")
    for ( new i = 0; i < iNum; i ++ )
    {
        id = iPlayers[i]
        iEnt = g_ePlayerData[id][PDATA_POWER_GHOST]
        if ( !iEnt || powerFind(iEnt, ePower) == -1 )
            continue

        powerTrace(ePower, id)
    }

    for ( new i = 0; i < g_iPower; i ++ )
    {
        ArrayGetArray(g_aPower, i, ePower)

        if ( ePower[POWER_NEXT_SPAWN]
        && get_gametime() >= ePower[POWER_NEXT_SPAWN] )
        {
            ePower[POWER_FLAGS] |= FLAG_SHOW
            ePower[POWER_NEXT_SPAWN] = 0.0

            set_pev(ePower[POWER_ID], pev_solid, SOLID_TRIGGER)
            powerSound(ePower[POWER_ID], SOUND_SUITCHARGE, false, .iPitch = 150)
        }

        ArraySetArray(g_aPower, i, ePower)
    }
}

stock powerCreate(id, iItem)
{
    new iEnt
    iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))

    if ( !pev_valid(iEnt) )
        return

    new ePower[POWER]
    ArrayGetArray(g_aPowerConfig, iItem, ePower)

    ePower[POWER_ID] = iEnt
    ePower[POWER_ITEM] = iItem
    ePower[POWER_DATA] = ArrayClone(ePower[POWER_DATA])
    if ( id )
    {
        g_ePlayerData[id][PDATA_POWER_GHOST] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_ACTION] = true
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        powerNoClip(id, true)
    }

    set_pev(iEnt, pev_classname, g_szCN[ePower[POWER_CLASS] != CLASS_WINGS ? CLASSNAME_PLAYER : CLASSNAME_SPECTATOR])
    engfunc(EngFunc_SetModel, iEnt, ePower[POWER_MODEL])

    ArrayPushArray(g_aPower, ePower)
    g_iPower ++

    dllfunc(DLLFunc_Spawn, iEnt)
}

stock powerRemove(iItem)
{
    ArrayDeleteItem(g_aPower, iItem)
    g_iPower --
}

public fwdUpdateClientData(id, iSendWeapons, iHandle)
{
    if ( g_ePlayerData[id][PDATA_POWER_GHOST] )
    {
        set_cd(iHandle, CD_WeaponAnim, 0)
        set_cd(iHandle, CD_flNextAttack, get_gametime() + 0.1)
    }

    return FMRES_IGNORED
}

public fwdAddToFullPack(es, e, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
    if ( !pev_valid(iEnt)
    || (!isPowerPlayer(iEnt) && !isPowerSpectator(iEnt))
    || !get_orig_retval() )
        return FMRES_IGNORED

    new ePower[POWER],
        bool:bHidden

    powerFind(iEnt, ePower)
    bHidden = !(ePower[POWER_FLAGS] & FLAG_SHOW)

    if ( !g_ePlayerData[iHost][PDATA_POWER_ACTION] )
    {
        if ( bHidden || isPowerSpectator(iEnt) && is_user_alive(iHost) )
            set_es(es, ES_Effects, EF_NODRAW)
    }
    else if ( ePower[POWER_FLAGS] & FLAG_SELECT )
    {
        set_es(es, ES_RenderColor, g_eSettings[SETTING_COLOR_SELECT])
        set_es(es, ES_RenderAmt, 12)
        set_es(es, ES_RenderFx, kRenderFxGlowShell)

        if ( bHidden )
            set_es(es, ES_RenderMode, kRenderTransAlpha)
    }
    else if ( bHidden )
    {
        set_es(es, ES_RenderMode, kRenderTransAlpha)
        set_es(es, ES_RenderAmt, g_eSettings[SETTING_GHOST_ALPHA])
    }

    return FMRES_IGNORED
}

public fwdSpawn(iEnt)
{
    if ( !isPowerPlayer(iEnt) )
        return HAM_IGNORED

    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    return HAM_IGNORED
}

public fwdTouch(iEnt, iOther)
{
    if ( !isPowerPlayer(iEnt)
    || !is_user_alive(iOther)
    || pev(iOther, pev_solid) < SOLID_BBOX )
        return HAM_IGNORED

    new ePower[POWER], iItem
    iItem = powerFind(iEnt, ePower)

    if ( iItem == -1
    || !(CsTeams:ePower[POWER_TEAM] & cs_get_user_team(iOther)) )
        return HAM_IGNORED

    switch( ePower[POWER_CLASS] )
    {
        case CLASS_AMMO:        powerAmmo(iOther,       ePower)
        case CLASS_AMMO2:       powerAmmo2(iOther,      ePower)
        case CLASS_BOMB:        powerBomb(iOther,       ePower)
        case CLASS_CLOCK:       powerClock(iOther,      ePower)
        case CLASS_HEALTH:      powerHealth(iOther,     ePower)
        case CLASS_HEALTH2:     powerHealth2(iOther,    ePower)
        case CLASS_LIGHTNING:   powerLightning(iOther,  ePower)
        case CLASS_LIGHTNING2:  powerLightning2(iOther, ePower)
        case CLASS_MASK:        powerMask(iOther,       ePower)
        case CLASS_MASK2:       powerMask2(iOther,      ePower)
        case CLASS_ROCKET:      powerRocket(iOther,     ePower)
        case CLASS_SHIELD:      powerShield(iOther,     ePower)
        case CLASS_SKULL:       powerSkull(iOther,      ePower)
        case CLASS_STUN:        powerStun(iOther,       ePower)
        case CLASS_STUN2:       powerStun2(iOther,      ePower)
        case CLASS_UP:          powerUp(iOther,         ePower)
        case CLASS_UP2:         powerUp2(iOther,        ePower)
    }

    if ( g_ePlayerData[iOther][PDATA_POWER_SWALLOW] )
    {
        powerHide(ePower)
        g_ePlayerData[iOther][PDATA_POWER_SWALLOW] = false
    }

    ArraySetArray(g_aPower, iItem, ePower)
    return HAM_IGNORED
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static ePower[POWER], iButton, iOldButton, Float:fCurrentTime, iLast
    iButton = pev(id, pev_button)
    iOldButton = pev(id, pev_oldbuttons)
    fCurrentTime = get_gametime()

    if ( g_ePlayerData[id][PDATA_POWER_GHOST] )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
        {
            if ( iButton & IN_ATTACK )
            {
                g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET_MIN], g_eSettings[SETTING_OFFSET_MAX])
                g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + g_eSettings[SETTING_OFFSET_FREQ]
            }
            else if ( iButton & IN_ATTACK2 )
            {
                g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET_MIN], g_eSettings[SETTING_OFFSET_MAX])
                g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + g_eSettings[SETTING_OFFSET_FREQ]
            }
        }

        iButton &= ~(IN_ATTACK | IN_ATTACK2)
        set_pev(id, pev_button, iButton)
    }

    if ( g_ePlayerData[id][PDATA_POWER_BEAM_NEXT_KILL]
    && fCurrentTime > g_ePlayerData[id][PDATA_POWER_BEAM_NEXT_KILL] )
    {
        powerTrailKill(id)
        g_ePlayerData[id][PDATA_POWER_BEAM_NEXT_KILL] = 0.0
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT]; i ++ )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_CLOCK_END][i] )
        {
            iLast = g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_CLOCK_END][i]   = g_ePlayerData[id][PDATA_POWER_CLOCK_END][iLast]
            g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT] --
            i --

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CLOCK_EXPIRE")
        }
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT]; i ++ )
    {
        if ( g_ePlayerData[id][PDATA_POWER_HEALTH2_END][i]
        && g_ePlayerData[id][PDATA_POWER_HEALTH2_END][i] > fCurrentTime )
        {
            if ( g_ePlayerData[id][PDATA_POWER_HEALTH2_NEXT][i]
            && fCurrentTime > g_ePlayerData[id][PDATA_POWER_HEALTH2_NEXT][i] )
            {
                new ePowerHealth2[POWER_HEALTH2],
                    Float:fHealth

                powerFind(g_ePlayerData[id][PDATA_POWER_HEALTH2][i], ePower)
                ArrayGetArray(ePower[POWER_DATA], 0, ePowerHealth2)

                pev(id, pev_health, fHealth)
                fHealth += random_float(ePowerHealth2[HEALTH2_MIN], ePowerHealth2[HEALTH2_MAX])
                set_pev(id, pev_health, fHealth)

                g_ePlayerData[id][PDATA_POWER_HEALTH2_NEXT][i] += ePowerHealth2[HEALTH2_FREQ]
            }
        }
        else if ( g_ePlayerData[id][PDATA_POWER_HEALTH2_END][i] )
        {
            iLast = g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_HEALTH2][i]       = g_ePlayerData[id][PDATA_POWER_HEALTH2][iLast]
            g_ePlayerData[id][PDATA_POWER_HEALTH2_NEXT][i]  = g_ePlayerData[id][PDATA_POWER_HEALTH2_NEXT][iLast]
            g_ePlayerData[id][PDATA_POWER_HEALTH2_END][i]   = g_ePlayerData[id][PDATA_POWER_HEALTH2_END][iLast]
            g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT] --
            i --

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_HEALTH2_EXPIRE")
        }
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT]; i ++ )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_LIGHTNING_END][i] )
        {
            iLast = g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_LIGHTNING][i]       = g_ePlayerData[id][PDATA_POWER_LIGHTNING][iLast]
            g_ePlayerData[id][PDATA_POWER_LIGHTNING_END][i]   = g_ePlayerData[id][PDATA_POWER_LIGHTNING_END][iLast]
            g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT] --
            i --

            ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id)

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_LIGHTNING_EXPIRE")
        }
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT]; i ++ )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_LIGHTNING2_NEXT][i] )
        {
            new ePowerLightning2[POWER_LIGHTNING2]

            powerFind(g_ePlayerData[id][PDATA_POWER_LIGHTNING2][i], ePower)
            ArrayGetArray(ePower[POWER_DATA], 0, ePowerLightning2)
            powerTrail(id, ePowerLightning2[LIGHTNING2_TRAIL_COLOR][0], ePowerLightning2[LIGHTNING2_TRAIL_COLOR][1], ePowerLightning2[LIGHTNING2_TRAIL_COLOR][2], ePowerLightning2[LIGHTNING2_TRAIL_COLOR][3] + random_num(-15, 15))
            lightningPush(id, random_float(ePowerLightning2[LIGHTNING2_MIN], ePowerLightning2[LIGHTNING2_MAX]))
            g_ePlayerData[id][PDATA_POWER_BEAM_NEXT_KILL] = get_gametime() + 1.0

            iLast = g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_LIGHTNING2][i]       = g_ePlayerData[id][PDATA_POWER_LIGHTNING2][iLast]
            g_ePlayerData[id][PDATA_POWER_LIGHTNING2_NEXT][i]  = g_ePlayerData[id][PDATA_POWER_LIGHTNING2_NEXT][iLast]
            g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT] --
            i --

            if ( ePower[POWER_FLAGS] & FLAG_SOUND )
                powerSound(ePower[POWER_ID], SOUND_FAST_WHOOSH, false)
        }
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_MASK_COUNT]; i ++ )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_MASK_END][i] )
        {
            g_ePlayerData[id][PDATA_POWER_MASK] += g_ePlayerData[id][PDATA_POWER_MASK_ALPHA][i]
            set_pev(id, pev_renderamt, g_ePlayerData[id][PDATA_POWER_MASK])

            iLast = g_ePlayerData[id][PDATA_POWER_MASK_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_MASK_ALPHA][i] = g_ePlayerData[id][PDATA_POWER_MASK_ALPHA][iLast]
            g_ePlayerData[id][PDATA_POWER_MASK_END][i]   = g_ePlayerData[id][PDATA_POWER_MASK_END][iLast]
            g_ePlayerData[id][PDATA_POWER_MASK_COUNT] --
            i --

            if ( g_ePlayerData[id][PDATA_POWER_MASK_COUNT] == 0 )
            {
                set_pev(id, pev_rendermode, kRenderNormal)
                set_user_footsteps(id, g_ePlayerData[id][PDATA_BASE_FOOTSTEP] ? 1 : 0)
            }

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_MASK_EXPIRE")
        }
    }

    if ( g_ePlayerData[id][PDATA_POWER_MASK2_END]
    && fCurrentTime > g_ePlayerData[id][PDATA_POWER_MASK2_END] )
    {
        cs_reset_user_model(id)
        g_ePlayerData[id][PDATA_POWER_MASK2_END] = 0.0

        powerSound(id, SOUND_BLIP2)
        client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_MASK2_EXPIRE")
    }

    if ( g_ePlayerData[id][PDATA_POWER_ROCKET_END]
    && fCurrentTime < g_ePlayerData[id][PDATA_POWER_ROCKET_END] )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_PUSH] )
        {
            new ePowerRocket[POWER_ROCKET]
            powerFind(g_ePlayerData[id][PDATA_POWER_ROCKET], ePower)
            ArrayGetArray(ePower[POWER_DATA], 0, ePowerRocket)

            rocketPush(id, ePowerRocket[ROCKET_PUSH])
            g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_PUSH] += ePowerRocket[ROCKET_GAP_PUSH]

            if ( !g_ePlayerData[id][PDATA_POWER_ROCKET_FIRE] )
            {
                g_ePlayerData[id][PDATA_POWER_ROCKET_FIRE] = true
                powerIcon(id, DMG_BURN)

                if ( ePower[POWER_FLAGS] & FLAG_SOUND )
                    powerSound(id, SOUND_ROCKET1, false)
            }
        }

        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_SMOKE] )
        {
            new ePowerRocket[POWER_ROCKET]
            powerFind(g_ePlayerData[id][PDATA_POWER_ROCKET], ePower)
            ArrayGetArray(ePower[POWER_DATA], 0, ePowerRocket)

            rocketSmoke(id)
            g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_SMOKE] += ePowerRocket[ROCKET_GAP_SMOKE]
        }
    }
    else if ( g_ePlayerData[id][PDATA_POWER_ROCKET_END] )
    {
        new ePowerRocket[POWER_ROCKET],
            Float:fOrigin[3], iSprites[1]

        pev(id, pev_origin, fOrigin)
        powerFind(g_ePlayerData[id][PDATA_POWER_ROCKET], ePower)
        ArrayGetArray(ePower[POWER_DATA], 0, ePowerRocket)
        iSprites[0] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]

        rocketExplode(fOrigin)
        rocketCylinder(fOrigin)
        rocketSteam(fOrigin)
        powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        powerSound(id, SOUND_ROCKET1, false, .iFlags = SND_STOP)
        ExecuteHam(Ham_TakeDamage, id, 0, id, ePowerRocket[ROCKET_DAMAGE], ePowerRocket[ROCKET_GIB] ? DMG_ALWAYSGIB : DMG_GENERIC)

        g_ePlayerData[id][PDATA_POWER_ROCKET] = 0
        g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_PUSH] = 0.0
        g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_SMOKE] = 0.0
        g_ePlayerData[id][PDATA_POWER_ROCKET_END] = 0.0
        g_ePlayerData[id][PDATA_POWER_ROCKET_FIRE] = false
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT]; i ++ )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_SHIELD_END][i] )
        {
            powerKill(g_ePlayerData[id][PDATA_POWER_SHIELD_BUBBLE][i])
            iLast = g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_SHIELD_BUBBLE][i] = g_ePlayerData[id][PDATA_POWER_SHIELD_BUBBLE][iLast]
            g_ePlayerData[id][PDATA_POWER_SHIELD_END][i]    = g_ePlayerData[id][PDATA_POWER_SHIELD_END][iLast]
            g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT] --
            i --

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_SHIELD_EXPIRE")
        }
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_SKULL_COUNT]; i ++ )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_SKULL_END][i] )
        {
            iLast = g_ePlayerData[id][PDATA_POWER_SKULL_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_SKULL_END][i] = g_ePlayerData[id][PDATA_POWER_SKULL_END][iLast]
            g_ePlayerData[id][PDATA_POWER_SKULL_COUNT] --
            i --

            if ( g_ePlayerData[id][PDATA_POWER_SKULL_COUNT] == 0 )
                cs_reset_user_model(id)

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_SKULL_EXPIRE")
        }
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_STUN_COUNT]; i ++ )
    {
        if ( g_ePlayerData[id][PDATA_POWER_STUN_END][i]
        && g_ePlayerData[id][PDATA_POWER_STUN_END][i] > fCurrentTime )
        {
            if ( g_ePlayerData[id][PDATA_POWER_STUN_NEXT_SHAKE][i]
            && fCurrentTime > g_ePlayerData[id][PDATA_POWER_STUN_NEXT_SHAKE][i] )
            {
                new ePowerStun[POWER_STUN], Float:fDuration
                powerFind(g_ePlayerData[id][PDATA_POWER_STUN][i], ePower)
                ArrayGetArray(ePower[POWER_DATA], 0, ePowerStun)

                fDuration = g_ePlayerData[id][PDATA_POWER_STUN_END][i] - g_ePlayerData[id][PDATA_POWER_STUN_NEXT_SHAKE][i]
                if ( fDuration > 8.0 )
                    fDuration = 8.0

                if ( ePowerStun[STUN_FADE] )
                    powerFade(id, 13, 0x0002, 128 + random_num(-20, 20), 0, 128 + random_num(-20, 20), 150 + random_num(-30, 30))

                if ( ePowerStun[STUN_SHAKE] )
                    stunShake(id, ePowerStun[STUN_AMPLITUDE], fDuration, ePowerStun[STUN_FREQUENCY])

                g_ePlayerData[id][PDATA_POWER_STUN_NEXT_SHAKE][i] += 1.0
            }
        }
        else if ( g_ePlayerData[id][PDATA_POWER_STUN_END][i] )
        {
            iLast = g_ePlayerData[id][PDATA_POWER_STUN_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_STUN][i]              = g_ePlayerData[id][PDATA_POWER_STUN][iLast]
            g_ePlayerData[id][PDATA_POWER_STUN_NEXT_SHAKE][i]   = g_ePlayerData[id][PDATA_POWER_STUN_NEXT_SHAKE][iLast]
            g_ePlayerData[id][PDATA_POWER_STUN_END][i]          = g_ePlayerData[id][PDATA_POWER_STUN_END][iLast]
            g_ePlayerData[id][PDATA_POWER_STUN_COUNT] --
            i --

            if ( g_ePlayerData[id][PDATA_BASE_FOV] )
                powerFov(id, g_ePlayerData[id][PDATA_BASE_FOV])

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_STUN_EXPIRE")
        }
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_STUN2_COUNT]; i ++ )
    {
        if ( g_ePlayerData[id][PDATA_POWER_STUN2_END][i]
        && g_ePlayerData[id][PDATA_POWER_STUN2_END][i] > fCurrentTime )
        {
            if ( g_ePlayerData[id][PDATA_POWER_STUN2_NEXT_SLAP][i]
            && fCurrentTime > g_ePlayerData[id][PDATA_POWER_STUN2_NEXT_SLAP][i] )
            {
                new ePowerStun2[POWER_STUN2], iDamage
                powerFind(g_ePlayerData[id][PDATA_POWER_STUN2][i], ePower)
                ArrayGetArray(ePower[POWER_DATA], 0, ePowerStun2)

                iDamage = floatround(random_float(ePowerStun2[STUN2_DAMAGE_MIN], ePowerStun2[STUN2_DAMAGE_MAX]))

                if ( iDamage >= pev(id, pev_health) && !ePowerStun2[STUN2_KILL] )
                    user_slap(id, 0, ePowerStun2[STUN2_DIRECTION])
                else
                    user_slap(id, iDamage, ePowerStun2[STUN2_DIRECTION])

                g_ePlayerData[id][PDATA_POWER_STUN2_NEXT_SLAP][i] += random_float(ePowerStun2[STUN2_FREQ_MIN], ePowerStun2[STUN2_FREQ_MAX])
            }
        }
        else if ( g_ePlayerData[id][PDATA_POWER_STUN2_END][i] )
        {
            iLast = g_ePlayerData[id][PDATA_POWER_STUN2_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_STUN2][i]             = g_ePlayerData[id][PDATA_POWER_STUN2][iLast]
            g_ePlayerData[id][PDATA_POWER_STUN2_NEXT_SLAP][i]   = g_ePlayerData[id][PDATA_POWER_STUN2_NEXT_SLAP][iLast]
            g_ePlayerData[id][PDATA_POWER_STUN2_END][i]         = g_ePlayerData[id][PDATA_POWER_STUN2_END][iLast]
            g_ePlayerData[id][PDATA_POWER_STUN2_COUNT] --
            i --

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_STUN2_EXPIRE")
        }
    }

    if ( g_ePlayerData[id][PDATA_POWER_UP2_COUNT]
    && !g_ePlayerData[id][PDATA_POWER_UP2_GROUNDED]
    && pev(id, pev_flags) & FL_ONGROUND )
    {
        new ePowerUp2[POWER_UP2]
        g_ePlayerData[id][PDATA_POWER_UP2_GROUNDED] = true
        set_pev(id, pev_gravity, g_ePlayerData[id][PDATA_BASE_GRAVITY])

        for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_UP2_COUNT]; i ++ )
        {
            powerFind(g_ePlayerData[id][PDATA_POWER_UP2][i], ePower)
            ArrayGetArray(ePower[POWER_DATA], 0, ePowerUp2)

            g_ePlayerData[id][PDATA_POWER_UP2_JUMP][i] = random_num(ePowerUp2[UP2_JUMP_MIN], ePowerUp2[UP2_JUMP_MAX])
        }
    }
    else if ( !(pev(id, pev_flags) & FL_ONGROUND) )
        g_ePlayerData[id][PDATA_POWER_UP2_GROUNDED] = false

    if ( g_ePlayerData[id][PDATA_POWER_UP2_COUNT]
    && iButton & IN_JUMP && !(iOldButton & IN_JUMP)
    && !g_ePlayerData[id][PDATA_POWER_UP2_GROUNDED] )
    {
        new ePowerUp2[POWER_UP2]

        for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_UP2_COUNT]; i ++ )
        {
            if ( !g_ePlayerData[id][PDATA_POWER_UP2_JUMP][i] )
                continue

            powerFind(g_ePlayerData[id][PDATA_POWER_UP2][i], ePower)
            ArrayGetArray(ePower[POWER_DATA], 0, ePowerUp2)

            set_pev(id, pev_gravity, ePowerUp2[UP2_GRAVITY])
            upPush(id, random_float(290.0, 320.0))
            g_ePlayerData[id][PDATA_POWER_UP2_JUMP][i] --

            break
        }
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_UP2_COUNT]; i ++ )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_POWER_UP2_END][i] )
        {
            iLast = g_ePlayerData[id][PDATA_POWER_UP2_COUNT] - 1
            g_ePlayerData[id][PDATA_POWER_UP2_END][i] = g_ePlayerData[id][PDATA_POWER_UP2_END][iLast]
            g_ePlayerData[id][PDATA_POWER_UP2_COUNT] --
            i --

            if ( g_ePlayerData[id][PDATA_POWER_UP2_COUNT] == 0 )
                set_pev(id, pev_gravity, g_ePlayerData[id][PDATA_BASE_GRAVITY])

            powerSound(id, SOUND_BLIP2)
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_UP2_EXPIRE")
        }
    }

    return HAM_IGNORED
}

public fwdTakeDamage(id, iInflictor, iAttacker, Float:fDamage, iDamageBits)
{
    if (!is_user_alive(id)
    || (!g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT] && !g_ePlayerData[iAttacker][PDATA_POWER_SKULL] ) )
        return HAM_IGNORED

    new ePower[POWER], ePowerShield[POWER_SHIELD], ePowerSkull[POWER_SKULL],
        Float:fAmplify, Float:fAbsorb, Float:fReflect, Float:fBlood, Float:fHealth, iWeaponActive

    iWeaponActive = cs_get_user_weapon_entity(iAttacker)

    for ( new i = 0; i < g_ePlayerData[iAttacker][PDATA_POWER_SKULL_COUNT]; i ++ )
    {
        powerFind(g_ePlayerData[iAttacker][PDATA_POWER_SKULL][i], ePower)
        ArrayGetArray(ePower[POWER_DATA], 0, ePowerSkull)

        fAmplify += ePowerSkull[SKULL_FACTOR_DAMAGE]
        fBlood += ePowerSkull[SKULL_FACTOR_BLOOD]
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT]; i ++ )
    {
        powerFind(g_ePlayerData[id][PDATA_POWER_SHIELD][i], ePower)
        ArrayGetArray(ePower[POWER_DATA], 0, ePowerShield)

        fAbsorb += ePowerShield[SHIELD_FACTOR_ABSORB]
        fReflect += ePowerShield[SHIELD_FACTOR_REFLECT]
    }

    fDamage += (fAmplify * fDamage)
    fDamage -= (fAbsorb * fDamage)
    fBlood *= fDamage
    fReflect *= fDamage
    SetHamParamFloat(4, fDamage)

    if ( g_ePlayerData[iAttacker][PDATA_POWER_SKULL_COUNT] > 0 )
    {
        pev(iAttacker, pev_health, fHealth)
        set_pev(iAttacker, pev_health, fHealth + fBlood)
    }

    if ( g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT]
    && !g_ePlayerData[id][PDATA_POWER_SHIELD_IS_REFLECTED] )
    {
        g_ePlayerData[iAttacker][PDATA_POWER_SHIELD_IS_REFLECTED] = true
        ExecuteHam(Ham_TakeDamage, iAttacker, iWeaponActive, id, fReflect, DMG_GENERIC)
        g_ePlayerData[iAttacker][PDATA_POWER_SHIELD_IS_REFLECTED] = false
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    if ( g_ePlayerData[id][PDATA_POWER_GHOST] )
    {
        new ePower[POWER], iItem

        if ( (iItem = powerFind(g_ePlayerData[id][PDATA_POWER_GHOST], ePower)) != -1 )
        {
            powerKill(g_ePlayerData[id][PDATA_POWER_GHOST])
            powerRemove(iItem)
            g_ePlayerData[id][PDATA_POWER_GHOST] = 0
        }

        powerNoClip(id, false)
    }

    new iWeapons[32], iNum
    get_user_weapons(id, iWeapons, iNum)

    for ( new i = CSW_P228; i <= CSW_P90; i ++ )
        g_ePlayerData[id][PDATA_POWER_WINGS_WEAPONS][i] = false

    for ( new i = 0; i < iNum; i ++ )
    {
        if ( !((1 << iWeapons[i]) & CSW_ALL_GUNS)
        && !((1 << iWeapons[i]) & CSW_ALL_GRENADES) )
            continue

        g_ePlayerData[id][PDATA_POWER_WINGS_WEAPONS][iWeapons[i]] = true
        g_ePlayerData[id][PDATA_POWER_WINGS_AMMO][iWeapons[i]] = cs_get_user_bpammo(id, iWeapons[i])
    }

    pev(id, pev_origin, g_ePlayerData[id][PDATA_POWER_WINGS_ORIGIN])
    powerReset(id)

    return HAM_IGNORED
}

public fwdResetMaxSpeedPlayer(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    new ePower[POWER], Float:fSpeed
    fSpeed = g_ePlayerData[id][PDATA_BASE_SPEED]

    if ( g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT] )
    {
        new ePowerLightning2[POWER_LIGHTNING2]

        for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT]; i ++ )
        {
            powerFind(g_ePlayerData[id][PDATA_POWER_LIGHTNING2][i], ePower)
            ArrayGetArray(ePower[POWER_DATA], 0, ePowerLightning2)

            fSpeed *= ePowerLightning2[LIGHTNING2_DELAY_SPEED]
        }

        set_pev(id, pev_maxspeed, fSpeed)
        return HAM_IGNORED
    }
    else if ( g_ePlayerData[id][PDATA_POWER_ROCKET] )
    {
        new ePowerRocket[POWER_ROCKET]
        powerFind(g_ePlayerData[id][PDATA_POWER_ROCKET], ePower)
        ArrayGetArray(ePower[POWER_DATA], 0, ePowerRocket)

        set_pev(id, pev_maxspeed, ePowerRocket[ROCKET_SPEED])
        return HAM_IGNORED
    }

    if ( g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT] )
    {
        new ePowerLightning[POWER_LIGHTNING]

        for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT]; i ++ )
        {
            powerFind(g_ePlayerData[id][PDATA_POWER_LIGHTNING][i], ePower)
            ArrayGetArray(ePower[POWER_DATA], 0, ePowerLightning)

            if ( ePowerLightning[LIGHTNING_MODE] == SPEED_MODE_RELATIVE )
                fSpeed *= random_float(ePowerLightning[LIGHTNING_MIN], ePowerLightning[LIGHTNING_MAX])
            else if ( ePowerLightning[LIGHTNING_MODE] == SPEED_MODE_ABSOLUTE )
                fSpeed += random_float(ePowerLightning[LIGHTNING_MIN], ePowerLightning[LIGHTNING_MAX])
        }

        set_pev(id, pev_maxspeed, fSpeed)
    }

    return HAM_IGNORED
}

public fwdWeaponReload(iEnt)
{
    if ( get_pdata_int(iEnt, MEMBER_IN_RELOAD) )
    {
        new id
        id = get_pdata_cbase(iEnt, MEMBER_OWNER)

        if ( g_ePlayerData[id][PDATA_POWER_CLOCK_END]
        && get_gametime() <= g_ePlayerData[id][PDATA_POWER_CLOCK_END] )
        {
            new Float:fSpeed

            for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT]; i ++ )
                fSpeed *= g_ePlayerData[id][PDATA_POWER_CLOCK_SPEED][i]

            set_pdata_float(id, MEMBER_NEXT_ATTACK, fSpeed)
            set_pdata_float(iEnt, MEMBER_NEXT_IDLE, floatclamp(fSpeed - 0.1, 0.0, fSpeed))
        }
    }

    return HAM_IGNORED
}

stock bool:powerTrace(ePower[POWER], id)
{
    new Float:fVec1[3]

    pev(id, pev_origin, ePower[POWER_ORIGIN])
    pev(id, pev_view_ofs, fVec1)
    xs_vec_add(fVec1, ePower[POWER_ORIGIN], ePower[POWER_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, ePower[POWER_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, ePower[POWER_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, ePower[POWER_ORIGIN])

    powerSetBox(ePower)
    powerSetOffset(ePower)
    set_pev(ePower[POWER_ID], pev_origin, ePower[POWER_ORIGIN])
}

stock powerSetBox(ePower[POWER])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    engfunc(EngFunc_AngleVectors, ePower[POWER_ANGLES], fForward, fRight, fUp)
    xs_vec_copy(g_eSettings[SETTING_MINS], fMins)
    xs_vec_copy(g_eSettings[SETTING_MAXS], fMaxs)

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, ePower[POWER_MINS])
    xs_vec_copy(fMaxs, ePower[POWER_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] + fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] + fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] + fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock powerSetOffset(ePower[POWER])
{
    new Float:fGaps[6], Float:fVec1[3],
        Float:fCurrentGap

    fGaps[0] = -ePower[POWER_MINS][0]
    fGaps[1] = ePower[POWER_MAXS][0]
    fGaps[2] = -ePower[POWER_MINS][1]
    fGaps[3] = ePower[POWER_MAXS][1]
    fGaps[4] = -ePower[POWER_MINS][2]
    fGaps[5] = ePower[POWER_MAXS][2]

    for ( new i = 0; i < 6; i ++ )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, ePower[POWER_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, ePower[POWER_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, ePower[POWER_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(ePower[POWER_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(ePower[POWER_ORIGIN], fVec1, ePower[POWER_ORIGIN])
        }
    }
}

stock powerSetSolid(ePower[POWER])
{
    new Float:fMins[3],
        Float:fMaxs[3]

    set_pev(ePower[POWER_ID], pev_solid, SOLID_TRIGGER)
    set_pev(ePower[POWER_ID], pev_movetype, MOVETYPE_NONE)

    xs_vec_copy(ePower[POWER_MINS], fMins)
    xs_vec_copy(ePower[POWER_MAXS], fMaxs)
    engfunc(EngFunc_SetSize, ePower[POWER_ID], fMins, fMaxs)
    set_rendering(ePower[POWER_ID], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
}

stock powerSetAnim(ePower[POWER])
{
    set_pev(ePower[POWER_ID], pev_sequence, ePower[POWER_ANIMATION])
    set_pev(ePower[POWER_ID], pev_frame, ePower[POWER_FRAME])
    set_pev(ePower[POWER_ID], pev_framerate, ePower[POWER_FRAMERATE])
    set_pev(ePower[POWER_ID], pev_animtime, get_gametime())
}

stock powerNoClip(id, bool:bSet)
{
    if ( g_eSettings[SETTING_POWER_NOCLIP] )
        set_pev(id, pev_movetype, bSet ? MOVETYPE_NOCLIP : MOVETYPE_WALK)
}

stock powerAmmo(id, ePower[POWER])
{
    new ePowerAmmo[POWER_AMMO],
        iWeaponActive, iWeapon, iClip, iAmmo

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerAmmo)
    iWeaponActive = cs_get_user_weapon_entity(id)
    iWeapon = cs_get_user_weapon(id, iClip, iAmmo)

    if ( !((1 << iWeapon) & CSW_ALL_GUNS) )
        return;

    if ( ePowerAmmo[AMMO_CLIP] > 0.0 )
    {
        new iNew = iClip

        if ( ePowerAmmo[AMMO_MODE] == AMMO_MODE_RELATIVE )
            iNew += floatround(ePowerAmmo[AMMO_CLIP] * g_iWeaponMaxClip[iWeapon])
        else if ( ePowerAmmo[AMMO_MODE] == AMMO_MODE_ABSOLUTE )
            iNew += floatround(ePowerAmmo[AMMO_CLIP])

        if ( !ePowerAmmo[AMMO_OVERFLOW]
        && iNew > g_iWeaponMaxClip[iWeapon] )
            iNew = g_iWeaponMaxClip[iWeapon]

        if ( iNew != iClip )
        {
            cs_set_weapon_ammo(iWeaponActive, iNew)
            g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
            ammoPickup(id, iWeaponActive, iNew - iClip)
        }
    }

    if ( ePowerAmmo[AMMO_AMMO] > 0.0 )
    {
        new iNew = iAmmo

        if ( ePowerAmmo[AMMO_MODE] == AMMO_MODE_RELATIVE )
            iNew += floatround(ePowerAmmo[AMMO_AMMO] * g_iWeaponMaxBp[iWeapon])
        else if ( ePowerAmmo[AMMO_MODE] == AMMO_MODE_ABSOLUTE )
            iNew += floatround(ePowerAmmo[AMMO_AMMO])

        if ( !ePowerAmmo[AMMO_OVERFLOW]
        && iNew > g_iWeaponMaxBp[iWeapon] )
            iNew = g_iWeaponMaxBp[iWeapon]

        if ( iNew != iAmmo )
        {
            cs_set_user_bpammo(id, iWeapon, iNew)
            g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
            ammoPickup(id, iWeaponActive, iNew - iAmmo)
        }
    }

    if ( g_ePlayerData[id][PDATA_POWER_SWALLOW] )
    {
        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[2]

            iSprites[0] = g_eSettings[SETTING_SPRITE_BLUEFLARE2]
            iSprites[1] = g_eSettings[SETTING_SPRITE_REDFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 2, SPARKLE_MODE_RANDOM)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_CLIP1, false)
    }
}

stock powerAmmo2(id, ePower[POWER])
{
    new ePowerAmmo2[POWER_AMMO2],
        szWeapon[32], iWeaponActive, iClip, iAmmo

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerAmmo2)

    for ( new iWeapon = CSW_P228; iWeapon <= CSW_P90; iWeapon ++ )
    {
        if ( !((1 << iWeapon) & CSW_ALL_GUNS) )
            continue

        get_weaponname(iWeapon, szWeapon, charsmax(szWeapon))
        iWeaponActive = cs_find_ent_by_owner(-1, szWeapon, id)

        if ( !pev_valid(iWeaponActive) )
            continue

        iAmmo = cs_get_user_bpammo(id, iWeapon)
        iClip = get_pdata_int(iWeaponActive, MEMBER_WEAPON_CLIP)

        if ( ePowerAmmo2[AMMO2_CLIP] > 0.0 )
        {
            new iNew = iClip

            if ( ePowerAmmo2[AMMO2_MODE] == AMMO_MODE_RELATIVE )
                iNew += floatround(ePowerAmmo2[AMMO2_CLIP] * g_iWeaponMaxClip[iWeapon])
            else if ( ePowerAmmo2[AMMO2_MODE] == AMMO_MODE_ABSOLUTE )
                iNew += floatround(ePowerAmmo2[AMMO2_CLIP])

            if ( !ePowerAmmo2[AMMO2_OVERFLOW]
            && iNew > g_iWeaponMaxClip[iWeapon] )
                iNew = g_iWeaponMaxClip[iWeapon]

            if ( iNew != iClip )
            {
                cs_set_weapon_ammo(iWeaponActive, iNew)
                g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
                ammoPickup(id, iWeaponActive, iNew - iClip)
            }
        }

        if ( ePowerAmmo2[AMMO2_AMMO] > 0.0 )
        {
            new iNew = iAmmo

            if ( ePowerAmmo2[AMMO2_MODE] == AMMO_MODE_RELATIVE )
                iNew += floatround(ePowerAmmo2[AMMO2_AMMO] * g_iWeaponMaxBp[iWeapon])
            else if ( ePowerAmmo2[AMMO2_MODE] == AMMO_MODE_ABSOLUTE )
                iNew += floatround(ePowerAmmo2[AMMO2_AMMO])

            if ( !ePowerAmmo2[AMMO2_OVERFLOW]
            && iNew > g_iWeaponMaxBp[iWeapon] )
                iNew = g_iWeaponMaxBp[iWeapon]

            if ( iNew != iAmmo )
            {
                cs_set_user_bpammo(id, iWeapon, iNew)
                g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
                ammoPickup(id, iWeaponActive, iNew - iAmmo)
            }
        }
    }

    if ( g_ePlayerData[id][PDATA_POWER_SWALLOW] )
    {
        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[2]

            iSprites[0] = g_eSettings[SETTING_SPRITE_BLUEFLARE2]
            iSprites[1] = g_eSettings[SETTING_SPRITE_REDFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 2, SPARKLE_MODE_RANDOM)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_CLIP1, false)
    }
}

stock powerBomb(id, ePower[POWER])
{
    new ePowerBomb[POWER_BOMB],
        iHe, iFb, iSmoke

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerBomb)
    iHe = cs_get_user_bpammo(id, CSW_HEGRENADE)
    iFb = cs_get_user_bpammo(id, CSW_FLASHBANG)
    iSmoke = cs_get_user_bpammo(id, CSW_SMOKEGRENADE)

    if ( ePowerBomb[BOMB_HE_SUPPLY] > 0 )
    {
        new iNew
        iNew = iHe + ePowerBomb[BOMB_HE_SUPPLY]

        if ( !ePowerBomb[BOMB_OVERFLOW]
        && iNew > ePowerBomb[BOMB_HE_LIMIT] )
            iNew = ePowerBomb[BOMB_HE_LIMIT]

        if ( iNew != iHe )
        {
            if ( !iHe )
                give_item(id, "weapon_hegrenade")
            else
                bombPickup(id, CSW_HEGRENADE)

            cs_set_user_bpammo(id, CSW_HEGRENADE, iNew)
            g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
        }
    }

    if ( ePowerBomb[BOMB_FB_SUPPLY] > 0 )
    {
        new iNew
        iNew = iFb + ePowerBomb[BOMB_FB_SUPPLY]

        if ( !ePowerBomb[BOMB_OVERFLOW]
        && iNew > ePowerBomb[BOMB_FB_LIMIT] )
            iNew = ePowerBomb[BOMB_FB_LIMIT]

        if ( iNew != iFb )
        {
            if ( !iFb )
                give_item(id, "weapon_flashbang")
            else
                bombPickup(id, CSW_FLASHBANG)

            cs_set_user_bpammo(id, CSW_FLASHBANG, iNew)
            g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
        }
    }

    if ( ePowerBomb[BOMB_SMOKE_SUPPLY] > 0 )
    {
        new iNew
        iNew = iSmoke + ePowerBomb[BOMB_SMOKE_SUPPLY]

        if ( !ePowerBomb[BOMB_OVERFLOW]
        && iNew > ePowerBomb[BOMB_SMOKE_LIMIT] )
            iNew = ePowerBomb[BOMB_SMOKE_LIMIT]

        if ( iNew != iSmoke )
        {
            if ( !iSmoke )
                give_item(id, "weapon_smokegrenade")
            else
                bombPickup(id, CSW_SMOKEGRENADE)

            cs_set_user_bpammo(id, CSW_SMOKEGRENADE, iNew)
            g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
        }
    }

    if ( g_ePlayerData[id][PDATA_POWER_SWALLOW] )
    {
        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[3]

            iSprites[0] = g_eSettings[SETTING_SPRITE_BLUEFLARE2]
            iSprites[1] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]
            iSprites[2] = g_eSettings[SETTING_SPRITE_REDFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 3, SPARKLE_MODE_RANDOM)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_CLIP1, false)
    }
}

stock powerClock(id, ePower[POWER])
{
    new ePowerClock[POWER_CLOCK], Float:fDuration
    ArrayGetArray(ePower[POWER_DATA], 0, ePowerClock)

    if ( !g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT]
    || ePowerClock[CLOCK_STACK] )
    {
        fDuration = random_float(ePowerClock[CLOCK_DURATION_MIN], ePowerClock[CLOCK_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_CLOCK_END][g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT]] = get_gametime() + fDuration
        g_ePlayerData[id][PDATA_POWER_CLOCK_SPEED][g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT]] = ePowerClock[CLOCK_SPEED]
        g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[2]

            iSprites[0] = g_eSettings[SETTING_SPRITE_BLUEFLARE2]
            iSprites[1] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 2, SPARKLE_MODE_RANDOM)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_BELL, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_CLOCK_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerHealth(id, ePower[POWER])
{
    new ePowerHealth[POWER_HEALTH],
        Float:fHealth, Float:fNew, Float:fBoost

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerHealth)
    pev(id, pev_health, fHealth)
    fBoost = random_float(ePowerHealth[HEALTH_MIN], ePowerHealth[HEALTH_MAX])
    fNew = fHealth + fBoost

    if ( fNew > ePowerHealth[HEALTH_LIMIT]
    && !ePowerHealth[HEALTH_OVERFLOW] )
        fNew = ePowerHealth[HEALTH_LIMIT]

    if ( fNew != fHealth )
    {
        set_pev(id, pev_health, fNew)
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

        if ( ePowerHealth[HEALTH_SCREEN_FADE] )
            powerFade(id, random_num(9, 12), 0, 0, 255, 0, random_num(90, 120))

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[1]

            iSprites[0] = g_eSettings[SETTING_SPRITE_GREENFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_MEDCHARGE, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_HEALTH_PICKUP", fBoost)
    }
}

stock powerHealth2(id, ePower[POWER])
{
    new ePowerHealth2[POWER_HEALTH2],
        Float:fHealth, Float:fDuration

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerHealth2)
    pev(id, pev_health, fHealth)

    if ( (fHealth < ePowerHealth2[HEALTH2_LIMIT] || ePowerHealth2[HEALTH2_OVERFLOW])
    && (!g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT] || ePowerHealth2[HEALTH2_STACK]) )
    {
        fDuration = random_float(ePowerHealth2[HEALTH2_DURATION_MIN], ePowerHealth2[HEALTH2_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_HEALTH2][g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT]] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_HEALTH2_NEXT][g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT]] = get_gametime()
        g_ePlayerData[id][PDATA_POWER_HEALTH2_END][g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT]] = get_gametime() + fDuration
        g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

        if ( ePowerHealth2[HEALTH2_SCREEN_FADE] )
            powerFade(id, random_num(9, 12), 0, 0, 255, 0, random_num(90, 120))

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[1]

            iSprites[0] = g_eSettings[SETTING_SPRITE_GREENFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_SUITCHARGE, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_HEALTH2_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerLightning(id, ePower[POWER])
{
    new ePowerLightning[POWER_LIGHTNING],
        Float:fDuration

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerLightning)

    if ( !g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT]
    || ePowerLightning[LIGHTNING_STACK] )
    {
        if ( !g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT] )
            pev(id, pev_maxspeed, g_ePlayerData[id][PDATA_BASE_SPEED])

        fDuration = random_float(ePowerLightning[LIGHTNING_DURATION_MIN], ePowerLightning[LIGHTNING_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_LIGHTNING][g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT]] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_LIGHTNING_END][g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT]] = get_gametime() + fDuration
        g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
        ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id)

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[1]

            iSprites[0] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_BEEP_BEEP, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_LIGHTNING_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerLightning2(id, ePower[POWER])
{
    new ePowerLightning2[POWER_LIGHTNING2]
    ArrayGetArray(ePower[POWER_DATA], 0, ePowerLightning2)

    if ( !g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT]
    || ePowerLightning2[LIGHTNING2_STACK] )
    {
        if ( !g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT] )
            pev(id, pev_maxspeed, g_ePlayerData[id][PDATA_BASE_SPEED])

        g_ePlayerData[id][PDATA_POWER_LIGHTNING2][g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT]] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_LIGHTNING2_NEXT][g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT]] = get_gametime() +
        random_float(ePowerLightning2[LIGHTNING2_DELAY_MIN], ePowerLightning2[LIGHTNING2_DELAY_MAX])
        g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
        ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id)

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[1]

            iSprites[0] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        }
    }
}

stock powerMask(id, ePower[POWER])
{
    new ePowerMask[POWER_MASK],
        Float:fRenderAmount, Float:fDuration

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerMask)

    if ( !g_ePlayerData[id][PDATA_POWER_MASK_COUNT]
    || ePowerMask[MASK_STACK] )
    {
        if ( !g_ePlayerData[id][PDATA_POWER_MASK_COUNT] )
        {
            g_ePlayerData[id][PDATA_POWER_MASK] = 255.0
            g_ePlayerData[id][PDATA_BASE_FOOTSTEP] = bool:get_user_footsteps(id)
        }

        fDuration = random_float(ePowerMask[MASK_DURATION_MIN], ePowerMask[MASK_DURATION_MAX])
        fRenderAmount = g_ePlayerData[id][PDATA_POWER_MASK] * random_float(ePowerMask[MASK_ALPHA_MIN], ePowerMask[MASK_ALPHA_MAX])
        g_ePlayerData[id][PDATA_POWER_MASK] -= fRenderAmount
        set_pev(id, pev_rendermode, kRenderTransAlpha)
        set_pev(id, pev_renderamt, g_ePlayerData[id][PDATA_POWER_MASK])

        g_ePlayerData[id][PDATA_POWER_MASK_ALPHA][g_ePlayerData[id][PDATA_POWER_MASK_COUNT]] = fRenderAmount
        g_ePlayerData[id][PDATA_POWER_MASK_END][g_ePlayerData[id][PDATA_POWER_MASK_COUNT]] = fDuration + get_gametime()
        g_ePlayerData[id][PDATA_POWER_MASK_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

        if ( ePowerMask[MASK_FOOTSTEP] )
            set_user_footsteps(id, 1)

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[2]

            iSprites[0] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]
            iSprites[1] = g_eSettings[SETTING_SPRITE_REDFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 2, SPARKLE_MODE_RANDOM)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_FIRE_WHOOSH, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_MASK_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerMask2(id, ePower[POWER])
{
    new ePowerMask2[POWER_MASK2],
        Float:fDuration, iTemp[4], iCount

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerMask2)

    if ( !g_ePlayerData[id][PDATA_POWER_MASK2_END]
    || ePowerMask2[MASK2_OVERRIDE] )
    {
        fDuration = random_float(ePowerMask2[MASK2_DURATION_MIN], ePowerMask2[MASK2_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_MASK2_END] = fDuration + get_gametime()
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
        g_ePlayerData[id][PDATA_POWER_SKULL_END] = 0.0

        for ( new i = 0; i < 4; i ++ )
        {
            if ( ePowerMask2[MASK2_MODEL_FLAG] & (1 << i) )
                iTemp[iCount ++] = i
        }

        if ( cs_get_user_team(id) == CS_TEAM_T )
            cs_set_user_model(id, g_szCTModels[iTemp[random(iCount)]])
        else if ( cs_get_user_team(id) == CS_TEAM_CT )
            cs_set_user_model(id, g_szTModels[iTemp[random(iCount)]])

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[2]

            iSprites[0] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]
            iSprites[1] = g_eSettings[SETTING_SPRITE_REDFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 2, SPARKLE_MODE_RANDOM)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_FIRE_WHOOSH, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_MASK2_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerRocket(id, ePower[POWER])
{
    new ePowerRocket[POWER_ROCKET]
    ArrayGetArray(ePower[POWER_DATA], 0, ePowerRocket)

    if ( !g_ePlayerData[id][PDATA_BASE_SPEED] )
        pev(id, pev_maxspeed, g_ePlayerData[id][PDATA_BASE_SPEED])

    g_ePlayerData[id][PDATA_POWER_ROCKET] = ePower[POWER_ID]
    g_ePlayerData[id][PDATA_POWER_ROCKET_END] = get_gametime() + random_float(ePowerRocket[ROCKET_DURATION_MIN], ePowerRocket[ROCKET_DURATION_MAX]) + 1.0
    g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_PUSH] = get_gametime() + 1.0
    g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_SMOKE] = g_ePlayerData[id][PDATA_POWER_ROCKET_NEXT_PUSH]
    g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
    ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id)

    if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
    {
        new Float:fOrigin[3],
            iSprites[1]

        iSprites[0] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]
        xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
        powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
    }

    if ( ePower[POWER_FLAGS] & FLAG_SOUND )
        powerSound(ePower[POWER_ID], SOUND_ROCKETFIRE1, false)
}

stock powerShield(id, ePower[POWER])
{
    new ePowerShield[POWER_SHIELD],
        Float:fDuration, iArmor, iBoost, iNew

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerShield)

    if ( !g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT]
    || ePowerShield[SHIELD_STACK] )
    {
        fDuration = random_float(ePowerShield[SHIELD_DURATION_MIN], ePowerShield[SHIELD_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_SHIELD][g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT]] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_SHIELD_END][g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT]] = get_gametime() + fDuration
        shieldCreate(id, ePowerShield[SHIELD_SIZE], ePowerShield[SHIELD_COLOR][0], ePowerShield[SHIELD_COLOR][1], ePowerShield[SHIELD_COLOR][2], ePowerShield[SHIELD_COLOR][3])
        g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

        iArmor = cs_get_user_armor(id)
        iBoost = random_num(ePowerShield[SHIELD_ARMOR_MIN], ePowerShield[SHIELD_ARMOR_MAX])
        iNew = iArmor + iBoost

        if ( iNew > ePowerShield[SHIELD_ARMOR_LIMIT]
        && !ePowerShield[SHIELD_ARMOR_OVERFLOW] )
            iNew = ePowerShield[SHIELD_ARMOR_LIMIT]

        if ( iNew != iArmor )
        {
            cs_set_user_armor(id, iNew, ePowerShield[SHIELD_ARMOR_TYPE])

            if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_SHIELD_ARMOR_PICKUP", iBoost)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[1]

            iSprites[0] = g_eSettings[SETTING_SPRITE_PURPLEFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_AMMO_PICKUP, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_SHIELD_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerSkull(id, ePower[POWER])
{
    new ePowerSkull[POWER_SKULL],
        Float:fDuration

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerSkull)

    if ( !g_ePlayerData[id][PDATA_POWER_SKULL_COUNT]
    || ePowerSkull[SKULL_STACK] )
    {
        fDuration = random_float(ePowerSkull[SKULL_DURATION_MIN], ePowerSkull[SKULL_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_SKULL][g_ePlayerData[id][PDATA_POWER_SKULL_COUNT]] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_SKULL_END][g_ePlayerData[id][PDATA_POWER_SKULL_COUNT]] = fDuration + get_gametime()
        g_ePlayerData[id][PDATA_POWER_SKULL_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true
        g_ePlayerData[id][PDATA_POWER_MASK2_END] = 0.0

        if ( g_ePlayerData[id][PDATA_POWER_SKULL_COUNT] == 1 )
        {
            if ( cs_get_user_team(id) == CS_TEAM_T )
                cs_set_user_model(id, "arctic_skeleton")
            else if ( cs_get_user_team(id) == CS_TEAM_CT )
                cs_set_user_model(id, "guerilla_skeleton")
        }

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[2]

            iSprites[0] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]
            iSprites[1] = g_eSettings[SETTING_SPRITE_REDFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 2, SPARKLE_MODE_RANDOM)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_SCREAM, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_SKULL_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerStun(id, ePower[POWER])
{
    new ePowerStun[POWER_STUN],
        Float:fDuration

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerStun)

    if ( !g_ePlayerData[id][PDATA_POWER_STUN_COUNT]
    || ePowerStun[STUN_STACK] )
    {
        if ( !g_ePlayerData[id][PDATA_POWER_STUN_COUNT] && ePowerStun[STUN_FOV] )
        {
            g_ePlayerData[id][PDATA_BASE_FOV] = pev(id, pev_fov)
            powerFov(id, 140)
        }

        fDuration = random_float(ePowerStun[STUN_DURATION_MIN], ePowerStun[STUN_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_STUN][g_ePlayerData[id][PDATA_POWER_STUN_COUNT]] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_STUN_END][g_ePlayerData[id][PDATA_POWER_STUN_COUNT]] = fDuration + get_gametime()
        g_ePlayerData[id][PDATA_POWER_STUN_NEXT_SHAKE][g_ePlayerData[id][PDATA_POWER_STUN_COUNT]] = get_gametime()
        g_ePlayerData[id][PDATA_POWER_STUN_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[1]

            iSprites[0] = g_eSettings[SETTING_SPRITE_PURPLEFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_HYPNO, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_STUN_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerStun2(id, ePower[POWER])
{
    new ePowerStun2[POWER_STUN2],
        Float:fDuration

    ArrayGetArray(ePower[POWER_DATA], 0, ePowerStun2)

    if ( !g_ePlayerData[id][PDATA_POWER_STUN2_COUNT]
    || ePowerStun2[STUN2_STACK] )
    {
        fDuration = random_float(ePowerStun2[STUN2_DURATION_MIN], ePowerStun2[STUN2_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_STUN2][g_ePlayerData[id][PDATA_POWER_STUN2_COUNT]] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_STUN2_END][g_ePlayerData[id][PDATA_POWER_STUN2_COUNT]] = fDuration + get_gametime()
        g_ePlayerData[id][PDATA_POWER_STUN2_NEXT_SLAP][g_ePlayerData[id][PDATA_POWER_STUN2_COUNT]] = random_float(ePowerStun2[STUN2_FREQ_MIN], ePowerStun2[STUN2_FREQ_MAX]) + get_gametime()
        g_ePlayerData[id][PDATA_POWER_STUN2_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[1]

            iSprites[0] = g_eSettings[SETTING_SPRITE_PURPLEFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_HYPNO, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_STUN2_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

stock powerUp(id, ePower[POWER])
{
    new ePowerUp[POWER_UP]
    ArrayGetArray(ePower[POWER_DATA], 0, ePowerUp)

    upPush(id, random_float(ePowerUp[UP_MIN], ePowerUp[UP_MAX]))
    powerTrail(id, ePowerUp[UP_TRAIL_COLOR][0], ePowerUp[UP_TRAIL_COLOR][1], ePowerUp[UP_TRAIL_COLOR][2], ePowerUp[UP_TRAIL_COLOR][3] + random_num(-15, 15))
    g_ePlayerData[id][PDATA_POWER_BEAM_NEXT_KILL] = get_gametime() + 2.5
    g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

    if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
    {
        new Float:fOrigin[3],
            iSprites[1]

        iSprites[0] = g_eSettings[SETTING_SPRITE_GREENFLARE2]
        xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
        powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
    }

    if ( ePower[POWER_FLAGS] & FLAG_SOUND )
        powerSound(ePower[POWER_ID], SOUND_BOUNCING, false)
}

stock powerUp2(id, ePower[POWER])
{
    new ePowerUp2[POWER_UP2], Float:fDuration
    ArrayGetArray(ePower[POWER_DATA], 0, ePowerUp2)

    if ( !g_ePlayerData[id][PDATA_POWER_UP2_COUNT]
    || ePowerUp2[UP2_STACK] )
    {
        if ( !g_ePlayerData[id][PDATA_POWER_UP2_COUNT] )
            pev(id, pev_gravity, g_ePlayerData[id][PDATA_BASE_GRAVITY])

        fDuration = random_float(ePowerUp2[UP2_DURATION_MIN], ePowerUp2[UP2_DURATION_MAX])
        g_ePlayerData[id][PDATA_POWER_UP2][g_ePlayerData[id][PDATA_POWER_UP2_COUNT]] = ePower[POWER_ID]
        g_ePlayerData[id][PDATA_POWER_UP2_END][g_ePlayerData[id][PDATA_POWER_UP2_COUNT]] = fDuration + get_gametime()
        g_ePlayerData[id][PDATA_POWER_UP2_GRAVITY][g_ePlayerData[id][PDATA_POWER_UP2_COUNT]] = ePowerUp2[UP2_GRAVITY]
        g_ePlayerData[id][PDATA_POWER_UP2_COUNT] ++
        g_ePlayerData[id][PDATA_POWER_SWALLOW] = true

        if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
        {
            new Float:fOrigin[3],
                iSprites[1]

            iSprites[0] = g_eSettings[SETTING_SPRITE_GREENFLARE2]
            xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
            powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
        }

        if ( ePower[POWER_FLAGS] & FLAG_SOUND )
            powerSound(ePower[POWER_ID], SOUND_FIRE_WHOOSH, false)

        if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
            client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_UP2_PICKUP",
            fDuration, fDuration == 1.0 ? ' ' : 's')
    }
}

public powerWings()
{
    new ePower[POWER], iItem, Float:fOrigin[3],
        iPlayers[MAX_PLAYERS], iNum, id, iEnt = -1

    get_players(iPlayers, iNum, "bch")
    for ( new i = 0; i < iNum; i ++ )
    {
        id = iPlayers[i]
        pev(id, pev_origin, fOrigin)

        while ( (iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, fOrigin, POWER_DISTANCE)) )
        {
            if ( !isPowerSpectator(iEnt)
            || (iItem = powerFind(iEnt, ePower)) == -1 )
                continue

            new ePowerWings[POWER_WINGS]
            ArrayGetArray(ePower[POWER_DATA], 0, ePowerWings)

            ExecuteHam(Ham_CS_RoundRespawn, id)
            set_pev(id, pev_health, ePowerWings[WINGS_HEALTH])

            if ( ePowerWings[WINGS_ORIGIN] == WINGS_ORIGIN_SELF )
                set_pev(id, pev_origin, fOrigin)

            if ( ePowerWings[WINGS_SAVE_WEAPONS] )
                wingsWeapons(id, ePowerWings[WINGS_SAVE_AMMO])

            if ( ePowerWings[WINGS_LIGHTNING] )
                wingsLightning(id, fOrigin)

            if ( ePower[POWER_FLAGS] & FLAG_SPARKLE )
            {
                new iSprites[1]
                iSprites[0] = g_eSettings[SETTING_SPRITE_YELLOWFLARE2]

                xs_vec_copy(ePower[POWER_ORIGIN], fOrigin)
                powerSparkle(fOrigin, iSprites, 1, SPARKLE_MODE_SINGLE)
            }

            if ( ePower[POWER_FLAGS] & FLAG_SOUND )
                powerSound(id, SOUND_LIGHTNING, false)

            if ( ePower[POWER_FLAGS] & FLAG_MESSAGE )
                client_print_color(id, id, "%L %L", id, "POWER_CHAT_TAG", id, "POWER_WINGS_PICKUP")

            powerHide(ePower)
            ArraySetArray(g_aPower, iItem, ePower)
            break
        }
    }
}

// Extra-Helpers

stock powerHide(ePower[POWER])
{
    ePower[POWER_FLAGS] &= ~FLAG_SHOW
    set_pev(ePower[POWER_ID], pev_solid, SOLID_NOT)

    if ( ePower[POWER_SHOW] == SHOW_DEFAULT
    && ePower[POWER_SPAWN_MODE] == SPAWN_DELAY )
        ePower[POWER_NEXT_SPAWN] = get_gametime() + random_float(ePower[POWER_SPAWN_MIN], ePower[POWER_SPAWN_MAX])
}

stock powerReset(id)
{
    g_ePlayerData[id][PDATA_POWER_CLOCK_COUNT] = 0
    g_ePlayerData[id][PDATA_POWER_HEALTH2_COUNT] = 0
    g_ePlayerData[id][PDATA_POWER_LIGHTNING_COUNT] = 0
    g_ePlayerData[id][PDATA_POWER_LIGHTNING2_COUNT] = 0

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_MASK_COUNT]; i ++ )
    {
        g_ePlayerData[id][PDATA_POWER_MASK] += g_ePlayerData[id][PDATA_POWER_MASK_ALPHA][i]
        set_pev(id, pev_renderamt, g_ePlayerData[id][PDATA_POWER_MASK])
    }

    g_ePlayerData[id][PDATA_POWER_MASK_COUNT] = 0
    g_ePlayerData[id][PDATA_POWER_MASK2_END] = 0.0

    if ( g_ePlayerData[id][PDATA_POWER_ROCKET_END] )
    {
        g_ePlayerData[id][PDATA_POWER_ROCKET_END] = 0.0
        powerSound(id, SOUND_ROCKET1, false, .iFlags = SND_STOP)
    }

    for ( new i = 0; i < g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT]; i ++ )
        powerKill(g_ePlayerData[id][PDATA_POWER_SHIELD_BUBBLE][i])

    g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT] = 0
    g_ePlayerData[id][PDATA_POWER_SKULL_COUNT] = 0
    g_ePlayerData[id][PDATA_POWER_STUN_COUNT] = 0

    if ( g_ePlayerData[id][PDATA_BASE_FOV] )
        powerFov(id, g_ePlayerData[id][PDATA_BASE_FOV])

    g_ePlayerData[id][PDATA_POWER_STUN2_COUNT] = 0
    g_ePlayerData[id][PDATA_POWER_UP2_COUNT] = 0

    if ( !g_ePlayerData[id][PDATA_POWER_UP2_GROUNDED] && g_ePlayerData[id][PDATA_BASE_GRAVITY] )
        set_pev(id, pev_gravity, g_ePlayerData[id][PDATA_BASE_GRAVITY])

    cs_reset_user_model(id)
}

stock ammoPickup(id, iWeaponActive, iAmount)
{
    new iAmmoType
    iAmmoType = get_pdata_int(iWeaponActive, MEMBER_AMMO_TYPE)

    message_begin(MSG_ONE_UNRELIABLE, g_iAmmoPickup, .player = id)
    write_byte(iAmmoType)
    write_byte(iAmount)
    message_end()
}

stock bombPickup(id, iGrenade)
{
    message_begin(MSG_ONE_UNRELIABLE, g_iWeapPickup, .player = id)
    write_byte(iGrenade)
    message_end()
}

stock lightningPush(id, Float:fFactor)
{
    new Float:fVelocity[3],
        Float:fForward[3]

    pev(id, pev_v_angle, fForward)
    pev(id, pev_velocity, fVelocity)
    engfunc(EngFunc_MakeVectors, fForward)
    global_get(glb_v_forward, fForward)

    xs_vec_mul_scalar(fForward, fFactor, fForward)
    xs_vec_add(fVelocity, fForward, fForward)
    fForward[2] += 250.0
    set_pev(id, pev_velocity, fForward)
}

stock rocketPush(id, Float:fPush)
{
    new Float:fVelocity[3]

    pev(id, pev_velocity, fVelocity)
    fVelocity[2] = fPush
    set_pev(id, pev_velocity, fVelocity)
}

stock rocketSmoke(id)
{
    new Float:fOrigin[3]
    pev(id, pev_origin, fOrigin)

    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
    write_byte(TE_SPRITE)
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2])
    write_short(g_eSettings[SETTING_SPRITE_BALLSMOKE])
    write_byte(10)
    write_byte(255)
    message_end()
}

stock rocketExplode(Float:fOrigin[3])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
    write_byte(TE_EXPLOSION2)
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2])
    write_byte(0)
    write_byte(10)
    message_end()
}

stock rocketCylinder(Float:fOrigin[3])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
    write_byte(TE_BEAMCYLINDER)
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2])
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2] + 450.0)
    write_short(g_eSettings[SETTING_SPRITE_WHITE])
    write_byte(0)
    write_byte(0)
    write_byte(3)
    write_byte(18)
    write_byte(0)
    write_byte(255)
    write_byte(255)
    write_byte(255)
    write_byte(255)
    write_byte(0)
    message_end()
}

stock rocketSteam(Float:fOrigin[3])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
    write_byte(TE_SMOKE)
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2])
    write_short(g_eSettings[SETTING_SPRITE_STEAM1])
    write_byte(10)
    write_byte(10)
    message_end()
}

stock shieldCreate(id, iSize, iRed, iGreen, iBlue, iAlpha)
{
    new iEnt
    iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    g_ePlayerData[id][PDATA_POWER_SHIELD_BUBBLE][g_ePlayerData[id][PDATA_POWER_SHIELD_COUNT]] = iEnt
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
    set_pev(iEnt, pev_aiment, id)

    if ( iSize == SHIELD_SIZE_SMALL )       engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_SNOWBALL])
    else if ( iSize == SHIELD_SIZE_MEDIUM ) engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_SNOWBALL2])
    else if ( iSize == SHIELD_SIZE_LARGE )  engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_SNOWBALL3])
    set_rendering(iEnt, kRenderFxGlowShell, iRed, iGreen, iBlue, kRenderTransAlpha, iAlpha)

    dllfunc(DLLFunc_Spawn, iEnt)
}

stock stunShake(id, iAmplitude, Float:fDuration, iFrequency)
{
    message_begin(MSG_ONE_UNRELIABLE, g_iScreenShake, .player = id)
    write_short(iAmplitude * 4096)
    write_short(floatround(fDuration * 4096))
    write_short(iFrequency * 4096)
    message_end()
}

stock upPush(id, Float:fFactor)
{
    new Float:fVelocity[3],
        Float:fUp[3]

    pev(id, pev_v_angle, fUp)
    pev(id, pev_velocity, fVelocity)
    engfunc(EngFunc_MakeVectors, fUp)
    global_get(glb_v_up, fUp)

    xs_vec_mul_scalar(fUp, fFactor, fUp)

    fVelocity[2] = 0.0
    xs_vec_add(fVelocity, fUp, fUp)
    set_pev(id, pev_velocity, fUp)
}

stock wingsWeapons(id, bool:bAmmo)
{
    new szWeapon[32]

    strip_user_weapons(id)
    give_item(id, "weapon_knife")

    for ( new iWeapon = CSW_P228; iWeapon <= CSW_P90; iWeapon ++ )
    {
        if ( !g_ePlayerData[id][PDATA_POWER_WINGS_WEAPONS][iWeapon] )
            continue

        get_weaponname(iWeapon, szWeapon, charsmax(szWeapon))
        give_item(id, szWeapon)

        if ( bAmmo )
            cs_set_user_bpammo(id, iWeapon, g_ePlayerData[id][PDATA_POWER_WINGS_AMMO][iWeapon])
    }
}

stock wingsLightning(id, Float:fOrigin[3])
{
    new Float:fStart[3]

    xs_vec_add(fOrigin, Float:{0.0, 0.0, 9999.9}, fStart)
    engfunc(EngFunc_TraceLine, fOrigin, fStart, IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, fStart)

    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
    write_byte(TE_BEAMENTPOINT)
    write_short(id)
    write_coord_f(fStart[0])
    write_coord_f(fStart[1])
    write_coord_f(fStart[2])
    write_short(g_eSettings[SETTING_SPRITE_WHITE])
    write_byte(0)
    write_byte(0)
    write_byte(random_num(4, 7))
    write_byte(random_num(17, 23))
    write_byte(random_num(35, 65))
    write_byte(255)
    write_byte(255)
    write_byte(255)
    write_byte(255)
    write_byte(0)
    message_end()
}

stock powerTrail(id, iRed, iGreen, iBlue, iAlpha)
{
    message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW)
    write_short(id)
    write_short(g_eSettings[SETTING_SPRITE_WHITE])
    write_byte(5)
    write_byte(random_num(5, 10))
    write_byte(iRed)
    write_byte(iGreen)
    write_byte(iBlue)
    write_byte(iAlpha)
    message_end()
}

stock powerTrailKill(id)
{
    message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_KILLBEAM)
    write_short(id)
    message_end()
}

stock powerFade(id, iDuration, iFlags, iRed, iGreen, iBlue, iAlpha)
{
    message_begin(MSG_ONE_UNRELIABLE, g_iScreenFade, .player = id)
    write_short(1 << iDuration)
    write_short(0)
    write_short(iFlags)
    write_byte(iRed)
    write_byte(iGreen)
    write_byte(iBlue)
    write_byte(iAlpha)
    message_end()
}

stock powerFov(id, iDegree)
{
    message_begin(MSG_ONE_UNRELIABLE, g_iSetFov, .player = id)
    write_byte(iDegree)
    message_end()
}

stock powerIcon(id, iType)
{
    message_begin(MSG_ONE, g_iDamage, .player = id)
    write_byte(0)
    write_byte(0)
    write_long(iType)
    write_coord(0)
    write_coord(0)
    write_coord(0)
    message_end()
}

stock powerSparkle(Float:fOrigin[3], iSprites[], iSize, iMode)
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
    write_byte(TE_SPRITETRAIL)
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2])
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2] + 30.0)
    write_short(iMode == SPARKLE_MODE_SINGLE ? iSprites[0] : iSprites[random_num(0, iSize - 1)])
    write_byte(random_num(4, 7))
    write_byte(1)
    write_byte(1)
    write_byte(random_num(12, 15))
    write_byte(5)
    message_end()
}

stock powerSound(iEnt, iSound, bool:bPlayer = true, Float:fVol = VOL_NORM, Float:fAttn = ATTN_NORM, iFlags = 0, iPitch = PITCH_NORM)
{
    new szSample[64]

    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_MENU_NAV])
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_MENU_REMOVE])
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_MENU_ALERT])
        case SOUND_BLIP1:       copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_BLIP1])
        case SOUND_BLIP2:       copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_BLIP2])
        case SOUND_SWALLOW:     copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_SWALLOW])
        case SOUND_CLIP1:       copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_CLIP1])
        case SOUND_BELL:        copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_BELL])
        case SOUND_MEDCHARGE:   copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_MEDCHARGE])
        case SOUND_SUITCHARGE:  copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_SUITCHARGE])
        case SOUND_BEEP_BEEP:   copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_BEEP_BEEP])
        case SOUND_FAST_WHOOSH: copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_FAST_WHOOSH])
        case SOUND_ROCKET1:     copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_ROCKET1])
        case SOUND_ROCKETFIRE1: copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_ROCKETFIRE1])
        case SOUND_FIRE_WHOOSH: copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_FIRE_WHOOSH])
        case SOUND_AMMO_PICKUP: copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_AMMO_PICKUP])
        case SOUND_SCREAM:      copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_SCREAM])
        case SOUND_HYPNO:       copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_HYPNO])
        case SOUND_BOUNCING:    copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_BOUNCING])
        case SOUND_LIGHTNING:   copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_LIGHTNING])
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, fVol, fAttn, iFlags, iPitch)
}

stock bool:isPowerPlayer(iEnt)
{
    new szEnt[32]
    pev(iEnt, pev_classname, szEnt, charsmax(szEnt))

    return bool:equal(g_szCN[CLASSNAME_PLAYER], szEnt)
}

stock bool:isPowerSpectator(iEnt)
{
    new szEnt[32]
    pev(iEnt, pev_classname, szEnt, charsmax(szEnt))

    return bool:equal(g_szCN[CLASSNAME_SPECTATOR], szEnt)
}

stock powerKill(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock powerFind(iEnt, ePower[POWER])
{
    for ( new i = 0; i < g_iPower; i ++ )
    {
        ArrayGetArray(g_aPower, i, ePower)
        if ( ePower[POWER_ID] == iEnt )
            return i
    }

    return -1
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}


