# Crystal skybox

The six 1024×1024 PNG files are oriented for Roblox `Sky` properties:

- `ft.png` → `SkyboxFt`
- `bk.png` → `SkyboxBk`
- `lf.png` → `SkyboxLf`
- `rt.png` → `SkyboxRt`
- `up.png` → `SkyboxUp`
- `dn.png` → `SkyboxDn`

`up.png` is rotated 90° clockwise and `dn.png` is rotated 90°
counter-clockwise relative to the neutral cubemap projection, as required by
Roblox's cubemap convention.

The Crystal config applies this set to the Shared, Station, and Dimension
skyboxes. Graveyard variants intentionally remain unchanged because each of
them reuses one texture ID for all four side faces; assigning a normal
six-face panorama there would introduce visible repetition seams.

Run `tools/Test-CrystalSkybox.ps1` to validate dimensions, Roblox orientation,
round-trip projection, and config mappings.
