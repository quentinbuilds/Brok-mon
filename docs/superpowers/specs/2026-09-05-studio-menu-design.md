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
- Existing `GameState.transition_to(OVERWORLD)` route for closing the menu.
- Existing `EventBus.menu_opened` and `menu_closed` signals.

## Visual treatment

Create compact runtime panel and button textures by deterministically extracting shapes and
palette from `assets/studio/battle_menu.png`. Render them with nearest-neighbour filtering at
the project's 200x120 viewport. Use native Labels over the extracted frames so text remains
accurate and can represent live data.

The main menu is a two-by-two grid matching the Studio composition:

1. Party
2. Inventory
3. Save
4. Close

A clearly visible cream-and-navy arrow sits outside the selected panel. It slides to each new
selection and loops through a restrained two-pixel horizontal bob. All panels retain the same
Studio blue treatment; selection is communicated by the animated arrow and a small text pulse,
not a green fill. Text uses the project's existing pixel-readable styling.

## Interaction

The menu has three internal pages; it remains one existing `MENU` game state.

### Main page

- Joystick navigation wraps through the two-by-two grid.
- A opens Party, Inventory, or Save, or closes the menu.
- B or C closes to the overworld.

### Party page

- Shows each current creature as its own Studio-style framed option, up to the party cap of three.
- Each panel contains name, type, and current/max HP; the equipped creature is marked `ACTIVE`.
- Up/down selects a creature; A calls the existing `GameData.set_active(index)` method.
- B returns to the main menu.
- Empty slots are shown but cannot be selected.

### Inventory page

- Shows Capture Orbs and Potions as two selectable Studio-style framed options with live counts.
- Up/down changes selection. A opens a Studio dialogue with a short item description and count.
- It is view-only; items are never consumed and no inventory rules are added.
- B returns to the main menu.

### Save dialogue

- Selecting Save opens a modal using `assets/studio/dialogue_box.png`.
- The exact message is `Save the game from who? You? Huh dumbass`.
- A or B dismisses the modal and returns to the main menu.
- No persistence system is created and no game data is changed.

### Inventory dialogues

- Capture Orb: `Capture Orb: used during encounters. You have xNN.`
- Potion: `Potion: restores health during battle. You have xNN.`
- A or B dismisses the modal back to the Inventory page.

## Feedback and lifecycle

Cursor movement plays the existing menu sound and starts the arrow's slide/bob animation.
Successful selection plays the existing confirm sound; back/close plays the existing cancel
sound. Entering and exiting preserve the current
`menu_opened` / `menu_closed` signals. The overworld remains frozen by the existing core scene
model while the menu is open.

## Error handling

- Party selection clamps to the current party size.
- An empty party renders `No creatures` and ignores equip input.
- Missing inventory keys render as zero through existing GameData accessors.
- Input is handled only by `InputManager`; there are no direct gameplay node references.

## Verification

- Unit tests cover cursor wrapping, visible arrow placement, page transitions, dynamic framed
  party/inventory options, equipping, modal text/dismissal, back/close behavior, and unchanged
  core files.
- Run the full `tests/run.sh` suite.
- Run a hidden Summer playthrough that opens the menu from the overworld, navigates Party and
  Inventory, equips a creature when available, returns, and closes the menu.
- Capture rendered frames to verify the Studio panel styling fits the 200x120 viewport.

## Acceptance criteria

- The placeholder full-screen Label is gone.
- The main menu, Party page, and Inventory page are navigable with the three-button interface.
- Selection uses a visible animated arrow with no green panel highlighting.
- Live party, equipped-creature, HP/type, and inventory counts are visible.
- Save and item selection use the existing Studio dialogue asset; Save does not persist data and
  inventory selection does not consume items.
- Studio-derived menu visuals render crisply and coherently with the existing game.
- No core or gameplay-logic file changes occur.
- Full automated tests and the interactive menu walkthrough pass without runtime errors.
