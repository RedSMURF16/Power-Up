<h1 align="center">Power Up</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=EE_IodMXQN0"><img src="https://img.youtube.com/vi/EE_IodMXQN0/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
This plugin adds a fully dynamic, multi-class power-up system to Counter-Strike 1.6.
Power-ups can be placed, managed and configured during gameplay with full runtime control over team access, respawn timing, animation, and per-class effects.
Custom setups are saved per map and automatically loaded on every map start.
- Create and remove power-ups during gameplay via an in-game menu
- 18 distinct power-up classes, each with its own model and dedicated effect: Ammo, Ammo2, Bomb, Clock, Health, Health2, Lightning, Lightning2, Mask, Mask2, Rocket, Shield, Skull, Stun, Stun2, Up, Up2, and Wings
- Configurable per power-up: flags (Sparkle, Sound, Message), team access, animation (Idle, Spin, Float, Spin-Float), starting frame, respawn mode (Never, Delay, Round Start), respawn delay range, and spawn chance
- Ammo and Ammo2 power-ups resupply current or all weapons' clip and backpack ammo in relative or absolute amounts with optional overflow
- Bomb power-ups supply HE, Flashbang, and Smoke grenades with individual per-type limits and optional overflow
- Clock power-ups boost weapon reload speed for a configurable duration with optional stacking
- Health and Health2 power-ups restore health instantly or over time with configurable limits, screen fade, overflow, and stacking
- Lightning and Lightning2 power-ups boost player movement speed or apply a delayed forward speed surge with a colored trail
- Mask and Mask2 power-ups control player transparency and footstep noise, or swap player models via model flags
- Rocket power-ups launch players into the air with smoke trails, configurable flight speed, and explosive gibbing
- Shield power-ups grant Kevlar or Vesthelm armor plus damage absorption and reflection with a visual shield effect
- Skull power-ups multiply player damage output and grant life-steal on hit
- Stun and Stun2 power-ups disorient targets with screen shake, fade, and FOV distortion, or inflict timed slaps that can optionally kill
- Up and Up2 power-ups launch players upward with a colored trail, or grant extra mid-air jumps and reduced gravity
- Wings power-ups revive fallen players at spawn or death origin with configurable health, lightning strike effect, and optional weapon/ammo restoration
- Noclip and intuitive ghost preview tracking for natural alignment with grounds and walls

## 💬 Commands
- `say /pu` - Opens the Power Ups menu.
- `say_team /pu` - Opens the Power Ups menu.
- `say /power` - Opens the Power Ups menu.
- `say_team /power` - Opens the Power Ups menu.
- `pu_reload` - Reloads the configuration file.
- `power_reload` - Reloads the configuration file.

## ⚙️ Configuration
```ini
# [Main Settings]
# SETTING_DEFAULT_MODEL       = Default power-up model path
# SETTING_MINS                = Minimum bounding box vector
# SETTING_MAXS                = Maximum bounding box vector
# SETTING_POWER_LOAD          = Whether to load saved power-up data of the current map (0 - Disabled, 1 - Enabled)
# SETTING_POWER_TASK          = Time interval in seconds to check for power-ups and apply their effects
# SETTING_POWER_NOCLIP        = Whether to grant temporary noclip for players placing power-ups (0 - Disabled, 1 - Enabled)
# SETTING_POWER_ACTION        = Whether spawned power-ups can be placed (0 - Disabled, 1 - Enabled)
# Per-class settings (defined under each [Power Name] section, depending on POWER_CLASS):
# AMMO_*       = Current weapon clip/backpack ammo refill amount, mode and overflow
# AMMO2_*      = All weapons clip/backpack ammo refill amount, mode and overflow
# BOMB_*       = HE/Flashbang/Smoke grenade supply amounts, limits and overflow
# CLOCK_*      = Weapon reload speed multiplier, duration range and stacking toggle
# HEALTH_*     = Instant health restore range, limit, screen fade and overflow
# HEALTH2_*    = Health regeneration rate, tick frequency, duration range, limit, screen fade, overflow and stacking
# LIGHTNING_*  = Movement speed range, duration range, mode (0 - Relative, 1 - Absolute) and stacking
# LIGHTNING2_* = Delayed forward launch speed range, delay range, pre-launch speed, trail RGBA color and stacking
# MASK_*       = Player alpha transparency range, duration range, footstep silencing and stacking
# MASK2_*      = Enemy model duration range, model flag (a/b/c/d) and override toggle
# ROCKET_*     = Explosion damage, upward push force, push/smoke intervals, flight duration, speed and gib toggle
# SHIELD_*     = Armor range, limit, overflow, armor type (1 - Kevlar, 2 - Vesthelm), absorb/reflect factors, duration, size, RGBA color and stacking
# SKULL_*      = Damage multiplier, life-steal fraction, duration range and stacking
# STUN_*       = Screen shake amplitude/frequency, duration range, FOV/fade/shake toggles and stacking
# STUN2_*      = Slap frequency range, slap damage range, duration range, direction (0 - Forward, 1 - Random), kill toggle and stacking
# UP_*         = Upward push velocity range and trail RGBA color
# UP2_*        = Extra jump count range, duration range, gravity multiplier and stacking
# WINGS_*      = Revival origin (0 - Spawn, 1 - Self), revival health, weapon/ammo restoration and lightning effect
# POWER_MODEL      = Path of power-up's model
# POWER_FLAGS      = a - Sparkle, b - Sound, c - Message
# POWER_TEAM       = 0 - Disabled, 1 - Terrorist Only, 2 - CT Only, 3 - Both Teams
# POWER_SPAWN_MODE = 0 - Never, 1 - Delay, 2 - Round Start
# POWER_ANIMATION  = 0 - Idle, 1 - Spin, 2 - Float, 3 - Spin-Float
# POWER_CLASS      = 0 - Ammo, 1 - Ammo2, 2 - Bomb, 3 - Clock, 4 - Health, 5 - Health2, 6 - Lightning, 7 - Lightning2, 8 - Mask, 9 - Mask2, 10 - Rocket, 11 - Shield, 12 - Skull, 13 - Stun, 14 - Stun2, 15 - Up, 16 - Up2, 17 - Wings
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20video-FF0000?logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=EE_IodMXQN0)
