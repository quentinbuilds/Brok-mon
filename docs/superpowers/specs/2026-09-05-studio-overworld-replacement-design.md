# Studio Overworld Replacement Design

## Goal

Replace the monochrome placeholder overworld art with the original color artwork already
created in Summer Studio. The playable result must feel like a nostalgic handheld creature
collector while remaining visually and legally original.

## Acceptance criteria

- The old `assets/tiles/overworld.png` and `assets/sprites/player.png` are not referenced by
  the runtime overworld scene.
- Every map glyph renders with a color Studio-derived tile: grass, tall grass, path, tree,
  rock, water, flowers, and hedge.
- The trainer uses the Studio trainer artwork and has idle and walking presentation for down,
  up, left, and right directions.
- Left movement mirrors a right-facing frame because the generated sheet contains no clean
  left-facing row.
- Movement remains grid-based, collision remains aligned to the visible map, the camera stays
  within the map, and tall-grass encounters still trigger.
- Rendering remains crisp at the 200×120 internal viewport using nearest-neighbour filtering.

## Asset preparation

The Studio source images are high-resolution presentation sheets, not engine-ready atlases.
A deterministic Summer/Godot asset-preparation script will create two runtime derivatives:

1. `assets/tiles/studio_overworld.png`: eight 16×16 tiles sampled from the Studio overworld
   source and arranged in the existing glyph order.
2. `assets/sprites/studio_trainer.png`: eight consistent 16×20 frames arranged as two frames
   for each direction. Frames are cropped from the Studio trainer sheet, scaled with nearest
   neighbour, and placed on transparent cells.

The checked-in source sheets remain unchanged. Generated runtime derivatives are committed so
the game does not need to regenerate them at startup.

## Runtime architecture

`GrassMap` remains the authoritative map and collision model. Its tile size changes from 8 to
16 pixels so the new artwork remains legible. `overworld_tileset.tres` points to the new color
atlas with 16×16 regions. `OverworldState` continues to paint the same glyph map and publish
the same `EventBus.player_moved` signal, so encounters require no architectural changes.

`Player` keeps the existing stepping API and timing. It points to the Studio trainer atlas,
uses two animation frames per direction, rests on an idle frame, and flips the right-facing
frames for left movement. The sprite is positioned so its feet remain anchored to the occupied
tile.

## Visual direction

- Limited green, teal, navy, cream, amber, and ember palette from the Studio set.
- Hard pixel edges, no smoothing, no gradients introduced during scaling.
- Dense but readable paths, water, grass patches, trees, and hedges.
- Classic handheld pacing and composition without copying protected characters, names, maps,
  logos, or sprites.

## Failure handling

The preparation script fails loudly when a source image cannot load or an output cannot save.
Tests assert that runtime scenes reference the new derivatives and that every direction selects
valid animation frames. Existing map-integrity tests continue to guard collision and reachability.

## Verification

1. Run the preparation script and import the generated PNGs.
2. Run `tests/run.sh`.
3. Use a Summer runtime verification probe to walk in all four directions, check frame changes,
   collide with a blocked tile, enter tall grass, and transition to battle.
4. Capture title, overworld, movement, and battle frames and visually confirm the monochrome
   placeholder map is absent.

## Non-goals

- Changing battle rules, catching rules, menus, state transitions, or input bindings.
- Adding more biomes or procedural maps.
- Recreating copyrighted Pokémon assets or exact maps.
