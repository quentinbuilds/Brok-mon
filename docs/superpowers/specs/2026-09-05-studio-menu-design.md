# Studio Menu Design

## Goal

Replace the placeholder pause-menu text with a complete, navigable menu using the visual
language of `assets/studio/battle_menu.png`. The menu must expose existing party and inventory
data without changing core state transitions or gameplay rules.

## Scope and ownership

Implementation is restricted to `menu/`, menu-specific generated assets under `assets/ui/`,
documentation, and menu tests. Files under `core/`, `world/`, `battle/`, `catching/`, and
`project.godot` are out of scope.

The implementation consumes only established interfaces:

- `InputManager.direction_just_pressed()` for cursor movement.
- `InputManager.button_a_just_pressed()` for selection.
- `InputManager.button_b_just_pressed()` and `button_menu_just_pressed()` for back/close.
- `GameData.get_party()`, `get_inventory()`, `active_index`, and `set_active()` for display and
  equipping.
- Existing `GameState.transition_to()` routes for `SOUND_TEST` and `OVERWORLD`.
- Existing `EventBus.menu_opened` and `menu_closed` signals.

## Visual treatment

Create compact runtime panel and button textures by deterministically extracting shapes and
palette from `assets/studio/battle_menu.png`. Render them with nearest-neighbour filtering at
the project's 200x120 viewport. Use native Labels over the extracted frames so text remains
accurate and can represent live data.

The main menu is a two-by-two grid matching the Studio composition:

1. Party
2. Inventory
3. Sound Test
4. Close

A clear left-side cursor and selected-button tint provide navigation feedback. Text uses the
project's existing pixel-readable styling; no copyrighted names or imagery are introduced.

## Interaction

The menu has three internal pages; it remains one existing `MENU` game state.

### Main page

- Joystick navigation wraps through the two-by-two grid.
- A opens Party, Inventory, or Sound Test, or closes the menu.
- B or C closes to the overworld.

### Party page

- Shows up to three current creatures with name, type, and current/max HP.
- The equipped creature is marked clearly.
- Up/down selects a creature; A calls the existing `GameData.set_active(index)` method.
- B returns to the main menu.
- Empty slots are shown but cannot be selected.

### Inventory page

- Shows the existing capture-orb and potion counts using readable display names.
- It is view-only; items are not consumed and no inventory rules are added.
- B returns to the main menu.

## Feedback and lifecycle

Cursor movement plays the existing menu sound. Successful selection plays the existing confirm
sound; back/close plays the existing cancel sound. Entering and exiting preserve the current
`menu_opened` / `menu_closed` signals. The overworld remains frozen by the existing core scene
model while the menu is open.

## Error handling

- Party selection clamps to the current party size.
- An empty party renders `No creatures` and ignores equip input.
- Missing inventory keys render as zero through existing GameData accessors.
- Input is handled only by `InputManager`; there are no direct gameplay node references.

## Verification

- Unit tests cover cursor wrapping, page transitions, dynamic party/inventory display, equipping,
  back/close behavior, and unchanged core files.
- Run the full `tests/run.sh` suite.
- Run a hidden Summer playthrough that opens the menu from the overworld, navigates Party and
  Inventory, equips a creature when available, returns, and closes the menu.
- Capture rendered frames to verify the Studio panel styling fits the 200x120 viewport.

## Acceptance criteria

- The placeholder full-screen Label is gone.
- The main menu, Party page, and Inventory page are navigable with the three-button interface.
- Live party, equipped-creature, HP/type, and inventory counts are visible.
- Studio-derived menu visuals render crisply and coherently with the existing game.
- No core or gameplay-logic file changes occur.
- Full automated tests and the interactive menu walkthrough pass without runtime errors.
