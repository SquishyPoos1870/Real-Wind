# Real Wind

**Real Wind** adds living Nauvis-only wind ambience to Factorio.

It keeps the mod stand-alone and UPS-friendly while making forests feel more alive with wind-driven overlays and positional wind gust audio.

## Features

- Nauvis-only wind controller
- Dynamic wind direction and gust strength
- Leaf/debris sweeps near all nearby Nauvis tree prototypes
- Canopy ripple and branch shimmer FX
- Forest gust wisps during stronger wind
- Positional forest wind whoosh sounds during gusts
- No bird ambience
- No dust FX
- No dependency on Real Smoke, Real Steam, Real Rain, or any Dust mod

## Settings

- Wind intensity: Subtle, Balanced, Strong, Cinematic / AAA
- Enable leaf/debris motes
- Enable tree wind FX
- Enable wind gust sounds
- Forest wind sound volume
- Apply real surface wind
- Effect interval

## Commands

- `/real-wind` shows current Real Wind status.
- `/real-wind-gust` triggers a stronger wind gust. Admin only in multiplayer.

## Notes

Factorio tree sprites cannot physically bend, so Real Wind fakes tree movement with wind-driven leaf sweeps, canopy ripple overlays, branch shimmer, and forest gust wisps.

Wind sounds are emitted from actual nearby tree positions, not from the player. As you move toward trees during gusts, the forest whoosh becomes more present. As you move away, new wind sounds fade out because no tree source is nearby.

## Optional Weather Integration

Real Wind can be boosted by Real Rain storms when both mods are installed. During rain/storms, wind speed, gust strength, leaf/debris movement, canopy ripples, and whoosh ambience can all pick up. Real Wind still works normally without Real Rain.

## License

Real Wind is licensed under the GNU General Public License v3.0 only. See `LICENSE` for the full license text.
