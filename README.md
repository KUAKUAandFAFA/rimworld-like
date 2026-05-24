# Rimworld Like

A small Godot prototype exploring RimWorld-like colony simulation systems.

## Early Goals

- Tile-based world simulation
- Pawn movement and jobs
- Construction and hauling
- Needs, mood, and simple AI priorities
- Save/load friendly data model

## Tech

- Godot 4.6
- GDScript

## Prototype Controls

- Left click: move the pawn to a walkable cell
- WASD / arrow keys: pan camera
- Mouse wheel: zoom camera

## Phase 1 Architecture

- `scripts/app`: top-level orchestration and player input routing.
- `scripts/world`: tile grid, terrain definitions, resource placement, and pathfinding.
- `scripts/pawns`: pawn movement and carried-item state.
- `scripts/jobs`: runtime job queue and job drivers.
- `scripts/items`: item definitions and stockpile accounting.
- `scripts/ui`: standalone HUD scene and presentation logic.
