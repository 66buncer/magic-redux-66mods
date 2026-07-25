# Thaumcraft Visual Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a local, validated Magic Redux visual working set from selected Thaumcraft assets without changing any existing rank image, rank rule, or public CDN URL.

**Architecture:** A declarative selection manifest names every permitted JAR asset and its intended Fleasion use. Reproducible PowerShell scripts extract immutable source copies, prepare direct/composite images, generate contact sheets, and validate dimensions, transparency, hashes, and the frozen rank baseline. Public JSON integration and publication happen only in a later plan after visual review.

**Tech Stack:** Windows PowerShell 5.1, .NET `System.IO.Compression`, .NET `System.Drawing`, JSON/CSV manifests, Git.

## Global Constraints

- Do not change, regenerate, recolor, overlay, or replace any of the 18 current rank images.
- Do not change any existing rank replacement IDs or rank URLs.
- Do not upload the complete Thaumcraft asset library to GitHub.
- Do not modify `configs/Crystal_V1.0.json` during this plan.
- Keep extracted originals byte-identical under `source_selected`.
- Keep all generated icons and overlays transparent where the target requires alpha.
- Skybox generation is excluded from this plan.
- Map previews retain real map imagery; this plan creates overlay parts only.

---

## File Structure

- Create `tools/visual-assets/asset-selection.json`: exact allowlist of JAR paths, target names, and processing modes.
- Create `tools/visual-assets/Test-VisualAssets.ps1`: validates selection, outputs, rank freeze, alpha, dimensions, and hashes.
- Create `tools/visual-assets/Export-ThaumcraftVisuals.ps1`: extracts allowlisted files without transforming them.
- Create `tools/visual-assets/Prepare-MagicReduxVisuals.ps1`: produces icons, composites, item backgrounds, arena background, and overlay parts.
- Create `tools/visual-assets/New-ContactSheet.ps1`: produces labeled review sheets.
- Create `tools/visual-assets/rank-baseline.csv`: immutable SHA-256 baseline for all 18 rank PNGs.
- Create `working/thaumcraft_visual_extract/source_selected/`: byte-identical local source files; ignored by Git.
- Create `working/thaumcraft_visual_extract/prepared/`: generated review assets; ignored by Git.
- Create `working/thaumcraft_visual_extract/manifest.csv`: local provenance and output status; ignored by Git.
- Create `working/thaumcraft_visual_extract/contact-sheets/`: review sheets; ignored by Git.
- Modify `.gitignore`: ignore `working/thaumcraft_visual_extract/`.

### Task 1: Freeze ranks and define the asset allowlist

**Files:**
- Create: `.gitignore`
- Create: `tools/visual-assets/rank-baseline.csv`
- Create: `tools/visual-assets/asset-selection.json`
- Create: `tools/visual-assets/Test-VisualAssets.ps1`

**Interfaces:**
- Consumes: committed files under `ranks/` and `Thaumcraft-1.8.9-5.2.4.jar`.
- Produces: `asset-selection.json` entries with `source`, `target`, `mode`, and `group`; `Test-VisualAssets.ps1 -Phase Selection|Prepared`.

- [ ] **Step 1: Record the committed rank baseline**

Run:

```powershell
Get-ChildItem ranks -File -Filter *.png |
  Sort-Object Name |
  ForEach-Object {
    [pscustomobject]@{
      file = $_.Name
      sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
  } |
  Export-Csv tools/visual-assets/rank-baseline.csv -NoTypeInformation -Encoding UTF8
```

Expected: 18 rows, one for each existing rank PNG.

- [ ] **Step 2: Create the selection manifest**

The manifest must include these source groups and targets:

```json
{
  "jar": "C:/Users/b/Downloads/Thaumcraft-1.8.9-5.2.4.jar",
  "entries": [
    {"source":"assets/thaumcraft/textures/misc/architect_arrows.png","target":"back_next","mode":"crop","group":"icons"},
    {"source":"assets/thaumcraft/textures/foci/enlarge.png","target":"plus","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/perditio.png","target":"x_exit","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/vinculum.png","target":"lock","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/items/brass_gear.png","target":"settings","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/iter.png","target":"region","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/cognitio.png","target":"save","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/machina.png","target":"servers","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/ordo.png","target":"task_completed","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/items/thaumonomicon.png","target":"book","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/items/researchnotes.png","target":"scroll","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/items/elemental_sword.png","target":"duels","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/items/void_sword.png","target":"duels","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/items/thaumometer.png","target":"spectate","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/humanus.png","target":"teammate","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/items/crystal_essence.png","target":"logo","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/praecantatio.png","target":"logo","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/potentia.png","target":"level_streak","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/exanimis.png","target":"gamemode_end","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/victus.png","target":"hp","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/aversio.png","target":"damage","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/ignis.png","target":"streak","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/perfodio.png","target":"headshot","mode":"composite","group":"icons"},
    {"source":"assets/thaumcraft/textures/foci/architect.png","target":"arch_top","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/research/r_eldritch.png","target":"nem_top","mode":"direct","group":"icons"},
    {"source":"assets/thaumcraft/textures/aspects/_back.png","target":"item_backgrounds","mode":"composite","group":"frames"},
    {"source":"assets/thaumcraft/textures/gui/hex1.png","target":"item_backgrounds","mode":"composite","group":"frames"},
    {"source":"assets/thaumcraft/textures/gui/hex2.png","target":"item_backgrounds","mode":"composite","group":"frames"},
    {"source":"assets/thaumcraft/textures/misc/frame_corner.png","target":"frames","mode":"composite","group":"frames"},
    {"source":"assets/thaumcraft/textures/misc/frame_side.png","target":"frames","mode":"composite","group":"frames"},
    {"source":"assets/thaumcraft/textures/misc/vortex.png","target":"arena_background","mode":"background","group":"backgrounds"},
    {"source":"assets/thaumcraft/textures/research/eldritchajor1.png","target":"arena_background","mode":"background","group":"backgrounds"},
    {"source":"assets/thaumcraft/textures/misc/nodes.png","target":"skybox_inspiration","mode":"source_only","group":"inspiration"},
    {"source":"assets/thaumcraft/textures/misc/particlefield.png","target":"map_overlay","mode":"overlay","group":"overlays"},
    {"source":"assets/thaumcraft/textures/misc/eldritch_portal.png","target":"skybox_inspiration","mode":"source_only","group":"inspiration"},
    {"source":"assets/thaumcraft/textures/misc/wispy.png","target":"map_overlay","mode":"overlay","group":"overlays"}
  ]
}
```

- [ ] **Step 3: Write the selection-phase validation**

`Test-VisualAssets.ps1 -Phase Selection` must:

```powershell
param([ValidateSet('Selection','Prepared')] [string]$Phase = 'Selection')

$selection = Get-Content -Raw tools/visual-assets/asset-selection.json | ConvertFrom-Json
$baseline = @(Import-Csv tools/visual-assets/rank-baseline.csv)
if ($baseline.Count -ne 18) { throw "Expected 18 frozen ranks" }
foreach ($rank in $baseline) {
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath "ranks/$($rank.file)").Hash
  if ($actual -ne $rank.sha256) { throw "Rank changed: $($rank.file)" }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($selection.jar)
try {
  $names = @($zip.Entries.FullName)
  foreach ($entry in $selection.entries) {
    if ($names -notcontains $entry.source) { throw "Missing JAR entry: $($entry.source)" }
  }
} finally {
  $zip.Dispose()
}
```

- [ ] **Step 4: Run selection validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/visual-assets/Test-VisualAssets.ps1 -Phase Selection
```

Expected: PASS with 18 unchanged ranks and every allowlisted JAR entry present.

- [ ] **Step 5: Commit**

```powershell
git add .gitignore tools/visual-assets
git commit -m "build: define Thaumcraft visual asset selection"
```

### Task 2: Extract immutable selected sources

**Files:**
- Create: `tools/visual-assets/Export-ThaumcraftVisuals.ps1`
- Create locally: `working/thaumcraft_visual_extract/source_selected/**`
- Create locally: `working/thaumcraft_visual_extract/manifest.csv`

**Interfaces:**
- Consumes: `asset-selection.json`.
- Produces: byte-identical extracted files and manifest columns `source`, `target`, `mode`, `group`, `relative_path`, `width`, `height`, `bytes`, `sha256`.

- [ ] **Step 1: Extend validation so it fails before extraction**

Add checks that every selection entry has exactly one `source_selected` file and matching SHA-256. Run Prepared validation and expect failure because outputs do not exist.

- [ ] **Step 2: Implement exact extraction**

Use `ZipArchiveEntry.Open()` and `Stream.CopyTo()`; never re-encode source PNGs. Preserve group directories and source filenames. Reject duplicate destination paths.

- [ ] **Step 3: Generate provenance**

Read PNG dimensions with `System.Drawing.Image.FromStream`, calculate SHA-256 after extraction, and export `manifest.csv`.

- [ ] **Step 4: Run validation**

Run Selection and Prepared phases. Expected: every allowlisted source exists, has nonzero bytes, and matches the extracted SHA-256.

- [ ] **Step 5: Commit the scripts only**

```powershell
git add tools/visual-assets/Export-ThaumcraftVisuals.ps1 tools/visual-assets/Test-VisualAssets.ps1
git commit -m "build: extract selected Thaumcraft visuals"
```

### Task 3: Prepare direct and composite icons

**Files:**
- Create: `tools/visual-assets/Prepare-MagicReduxVisuals.ps1`
- Create locally: `working/thaumcraft_visual_extract/prepared/icons_direct/*.png`
- Create locally: `working/thaumcraft_visual_extract/prepared/icons_composite/*.png`

**Interfaces:**
- Consumes: extracted source files and manifest rows.
- Produces: named 256×256 RGBA review icons with 24 px safe padding.

- [ ] **Step 1: Add failing prepared-icon assertions**

Require the exact planned icon filenames, 256×256 dimensions, alpha channel, nonempty alpha bounds, and no pixels touching the outer 8 px border.

- [ ] **Step 2: Implement shared image primitives**

Implement focused functions:

```powershell
function New-TransparentCanvas([int]$Width, [int]$Height)
function Draw-SourceCentered([Drawing.Graphics]$Graphics, [Drawing.Image]$Image, [Drawing.Rectangle]$Bounds)
function Save-Png([Drawing.Bitmap]$Bitmap, [string]$Path)
function Draw-CrystalFrame([Drawing.Graphics]$Graphics, [Drawing.Rectangle]$Bounds, [Drawing.Color]$Accent)
```

Use nearest-neighbor for 16/32 px icons and high-quality bicubic only for larger art.

- [ ] **Step 3: Produce direct icons**

Generate `lock`, `settings`, `region`, `book`, `scroll`, `spectate`, `teammate`, `gamemode_end`, `hp`, `damage`, `arch_top`, and `nem_top`.

- [ ] **Step 4: Produce composite icons**

Generate `back`, `next`, `plus`, `x`, `exit`, `save`, `servers`, `task_completed`, `duels`, `logo`, `logo_g`, `level`, `streak`, and `headshot`. Preserve conventional UI meaning for exit, save, and completion controls.

- [ ] **Step 5: Run prepared validation and commit**

Expected: all required icons pass alpha, size, safe-border, and rank-freeze checks.

```powershell
git add tools/visual-assets/Prepare-MagicReduxVisuals.ps1 tools/visual-assets/Test-VisualAssets.ps1
git commit -m "build: prepare Magic Redux interface icons"
```

### Task 4: Prepare backgrounds, frames, and overlay parts

**Files:**
- Modify: `tools/visual-assets/Prepare-MagicReduxVisuals.ps1`
- Create locally: `working/thaumcraft_visual_extract/prepared/item_backgrounds/itembg1.png` through `itembg5.png`
- Create locally: `working/thaumcraft_visual_extract/prepared/arena_background/arena.png`
- Create locally: `working/thaumcraft_visual_extract/prepared/map_overlay_parts/*.png`

**Interfaces:**
- Consumes: `_back`, `hex1`, `hex2`, `frame_corner`, `frame_side`, `vortex`, `eldritchajor1`, `particlefield`, and `wispy`.
- Produces: five same-geometry rarity backgrounds, one arena background, and transparent reusable map-overlay components.

- [ ] **Step 1: Add failing background assertions**

Require five distinct item background hashes, consistent dimensions, one arena background with no alpha holes, and transparent overlay parts.

- [ ] **Step 2: Generate five item backgrounds**

Use identical geometry with accent colors:

```text
itembg1 #88939E
itembg2 #31CDE8
itembg3 #F1C84B
itembg4 #9A62E8
itembg5 #11282C with #45F1D0 highlights
```

- [ ] **Step 3: Generate arena background**

Create a 1536×1024 nontransparent background using `vortex` as central structure and restrained `eldritchajor1` detail. Do not use rank images.

- [ ] **Step 4: Generate map overlay parts**

Create transparent corner/frame and particle overlays only. Do not generate or replace actual map preview images.

- [ ] **Step 5: Run validation and commit**

```powershell
git add tools/visual-assets/Prepare-MagicReduxVisuals.ps1 tools/visual-assets/Test-VisualAssets.ps1
git commit -m "build: prepare Magic Redux visual frames"
```

### Task 5: Generate review sheets and stop before integration

**Files:**
- Create: `tools/visual-assets/New-ContactSheet.ps1`
- Create locally: `working/thaumcraft_visual_extract/contact-sheets/icons.png`
- Create locally: `working/thaumcraft_visual_extract/contact-sheets/backgrounds.png`
- Create locally: `working/thaumcraft_visual_extract/README.md`

**Interfaces:**
- Consumes: every prepared output.
- Produces: labeled PNG contact sheets and a review index.

- [ ] **Step 1: Implement deterministic contact sheets**

Sort by output filename; show the filename under every tile; render transparent icons over both dark and checkerboard backgrounds.

- [ ] **Step 2: Generate the review README**

List target name, source asset(s), output path, dimensions, and validation result. State explicitly that ranks and `configs/Crystal_V1.0.json` were not changed.

- [ ] **Step 3: Run the complete validation suite**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/visual-assets/Test-VisualAssets.ps1 -Phase Selection
powershell -ExecutionPolicy Bypass -File tools/visual-assets/Test-VisualAssets.ps1 -Phase Prepared
git diff --exit-code -- ranks configs/Crystal_V1.0.json
```

Expected: both phases PASS and Git reports no changes to ranks or Crystal JSON.

- [ ] **Step 4: Commit the contact-sheet tooling**

```powershell
git add tools/visual-assets/New-ContactSheet.ps1
git commit -m "build: add visual asset review sheets"
```

- [ ] **Step 5: Present outputs for user review**

Stop before copying prepared images into public asset folders or modifying JSON. Publication and replacement-ID integration require explicit visual approval and a separate implementation plan.
