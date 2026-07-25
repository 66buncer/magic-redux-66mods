# Thaumcraft Visual Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the approved Magic Redux visual set, connect 32 image rules to Fleasion IDs, and install the updated Crystal configuration without changing rank assets.

**Architecture:** Copy only the curated and prepared outputs into public project folders. Record the supplied image permission and attribution, append validated CDN rules to the existing JSON, then verify the immutable rank baseline, every local asset, every published RAW file, and the installed Fleasion config.

**Tech Stack:** PNG, JSON, PowerShell 5.1, Git, GitHub RAW.

## Global Constraints

- All 18 rank PNG hashes must remain identical to `tools/visual-assets/rank-baseline.csv`.
- Existing 42 sound/rank rules remain enabled and unchanged.
- Publish only the 34 approved prepared PNGs, never the full extracted library.
- Map overlay PNGs are published for future composition but receive no replacement IDs.
- Include the supplied image permission and attribution.

---

### Task 1: Record permission and stage approved images

- [ ] Add `docs/permissions/THAUMCRAFT_IMAGE_PERMISSION.md` with the user-supplied permission.
- [ ] Add the attribution `Thaumcraft image assets — used with permission.` to `THIRD_PARTY_NOTICES.md`.
- [ ] Copy 26 icons to `visuals/icons/`.
- [ ] Copy five item backgrounds to `visuals/item-backgrounds/`.
- [ ] Copy the arena background to `visuals/backgrounds/arena.png`.
- [ ] Copy two map overlay parts to `visuals/overlays/`.
- [ ] Verify 34 PNG files decode, have expected dimensions, and ranks still match baseline.

### Task 2: Append Fleasion replacement rules

- [ ] Add 26 icon rules using the approved ID mapping.
- [ ] Add five item background rules.
- [ ] Add the arena background rule.
- [ ] Verify 74 total rules and 77 unique replacement IDs.
- [ ] Verify all CDN URLs use `66buncer/magic-redux-66mods`.
- [ ] Verify every CDN URL resolves to a local repository asset.
- [ ] Verify the 18 rank rules and image hashes are unchanged.

### Task 3: Publish and install

- [ ] Commit only permission, attribution, approved PNGs, and the updated JSON.
- [ ] Push `main` to GitHub.
- [ ] Download all 34 visual RAW files by immutable commit SHA and compare SHA-256.
- [ ] Download and semantically compare the published JSON.
- [ ] Copy the verified JSON to `C:/Users/b/AppData/Local/FleasionNT/configs/Crystal_V1.0.json`.
- [ ] Confirm the installed config has 74 rules and 77 unique IDs.
