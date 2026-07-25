# Crystal skybox

The six 1024×1024 PNG files are oriented for Roblox `Sky` properties:

- `ft_v2.png` → `SkyboxFt` (-Z)
- `bk_v2.png` → `SkyboxBk` (+Z)
- `lf_v2.png` → `SkyboxLf` (-X)
- `rt_v2.png` → `SkyboxRt` (+X)
- `up_v4.png` → `SkyboxUp` (+Y, with the v3 correction turned another 90° clockwise)
- `dn_v2.png` → `SkyboxDn` (-Y, rotated 90° counter-clockwise)

The v2 names prevent clients from reusing the cached, incorrectly mapped
first export. The axis mapping and pole rotations follow Roblox's cubemap
convention.


The Crystal config applies this set to the Shared, Station, and Dimension
skyboxes. Graveyard variants intentionally remain unchanged because each of
them reuses one texture ID for all four side faces; assigning a normal
six-face panorama there would introduce visible repetition seams.

Run `tools/Test-CrystalSkybox.ps1` to validate dimensions, Roblox orientation,
round-trip projection, and config mappings.
