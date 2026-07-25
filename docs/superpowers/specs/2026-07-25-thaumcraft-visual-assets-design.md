# Thaumcraft Visual Assets for Magic Redux

## Goal

Create a curated hybrid visual set for the Magic Redux Fleasion texture pack using authorized Thaumcraft assets as source material. Preserve recognizable UI meaning while giving the pack a coherent crystal-and-arcane style.

## Explicit exclusions

- Do not change, regenerate, recolor, overlay, or replace any of the 18 current rank images.
- Do not change any existing rank replacement IDs or rank URLs.
- Do not treat animated portal strips or effect sprites as ready-made skybox faces.
- Do not upload the complete Thaumcraft asset library to GitHub.
- Do not replace map previews with unrelated abstract art that hides the selected map.

## Source inventory

The Thaumcraft 5.2.4 JAR contains:

- 786 PNG textures;
- 37 OBJ models;
- GUI, item, aspect, focus, research, particle, portal, block, and creature textures;
- no complete cubemap or six-face skybox set.

Only selected visual assets required by this design will be extracted into a curated working set.

## Replacement design

### Direct or lightly adapted icons

| Fleasion target | Thaumcraft source |
| --- | --- |
| Back / Next | `misc/architect_arrows.png`, cropped into separate controls |
| Plus | `foci/enlarge.png`, placed in a consistent crystal frame |
| X | `aspects/perditio.png` |
| Lock | `aspects/vinculum.png` |
| Settings | `items/brass_gear.png` |
| Region | `aspects/iter.png` |
| Book | `items/thaumonomicon.png` |
| Scroll | `items/researchnotes.png` |
| Spectate | `items/thaumometer.png` |
| Teammate | `aspects/humanus.png` |
| Level | `aspects/potentia.png` |
| Game mode end | `aspects/exanimis.png` |
| HP | `aspects/victus.png` |
| Damage | `aspects/aversio.png` |
| Arch top | `foci/architect.png` |
| Nem top | `research/r_eldritch.png` |

### Composite icons

| Fleasion target | Composition |
| --- | --- |
| Exit | `perditio.png` inside a generated exit-ring silhouette |
| Save | conventional save glyph combined with `cognitio.png`; meaning must remain immediately recognizable |
| Servers | `machina.png` with a small connected-node motif |
| Task completed | `ordo.png` with a clear check mark |
| Duels | crossed `elemental_sword.png` and `void_sword.png` |
| Main logo | `crystal_essence.png` combined with `praecantatio.png` |
| Logo G | simplified symbol derived from the main logo |
| Streak | `ignis.png` inside a `potentia.png` energy ring |
| Killfeed headshot | `perfodio.png` with a minimal aiming reticle |

### Backgrounds and frames

- Arena background: use `misc/vortex.png` or `research/eldritchajor1.png` as source material, expanded into a clean crystal-arcane background.
- Five item backgrounds: build a shared frame from `aspects/_back.png`, `gui/hex1.png`, `gui/hex2.png`, `misc/frame_corner.png`, and `misc/frame_side.png`.
- The five item backgrounds use gray, cyan, gold, violet, and black-teal treatments while retaining the same geometry.

### Map previews

Map previews must continue to show the actual map. Thaumcraft art may only be used for:

- a consistent border;
- subtle corner details;
- restrained particles;
- color grading.

No map preview is replaced with an unrelated research or portal image.

### Skybox

There is no direct skybox in the JAR. A future six-face, seam-safe skybox may be generated from the visual language of:

- `misc/nodes.png`;
- `misc/vortex.png`;
- `misc/particlefield.png`;
- `misc/eldritch_portal.png`;
- `misc/wispy.png`.

Skybox generation is a separate deliverable. Source sprites must not be stretched directly across cube faces.

## Working-set structure

The curated local set will use:

```text
thaumcraft_visual_extract/
  source_selected/
    aspects/
    foci/
    items/
    gui/
    misc/
    research/
  prepared/
    icons_direct/
    icons_composite/
    item_backgrounds/
    arena_background/
    map_overlay_parts/
    skybox_inspiration/
  manifest.csv
  README.md
```

`manifest.csv` records the original JAR path, dimensions, byte size, SHA-256, intended Fleasion target, and preparation status.

## Processing rules

- Preserve original extracted files unchanged under `source_selected`.
- All crops, scaling, compositing, and recoloring happen under `prepared`.
- Maintain transparency for icons and overlays.
- Use nearest-neighbor scaling only when preserving intentional pixel-art edges.
- Use high-quality resampling for large backgrounds and generated composites.
- Keep conventional control meanings recognizable at Fleasion display size.

## Validation

- Confirm every selected source exists in the JAR.
- Confirm every prepared PNG decodes successfully and has the expected dimensions and alpha channel where required.
- Confirm every Fleasion image ID is unique in the resulting JSON.
- Confirm all resulting CDN URLs point only to `66buncer/magic-redux-66mods`.
- Confirm all 18 rank rules and rank image hashes remain unchanged.
- Visually review controls at their actual UI size before publishing.

## Publication boundary

Only assets actively used by Magic Redux may be committed to the public repository. The complete extracted Thaumcraft library remains local and is not published as a standalone sound or visual asset library.
