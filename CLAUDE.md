# gok-mon — agent rules

Read `docs/ARCHITECTURE.md` before touching anything. Then follow the PRD's master
instruction (PRD §20), reproduced here because it applies to every agent on every branch:

This is a 12-hour hackathon.
Do not over-engineer.
Do not rewrite systems you do not own.
Do not introduce unnecessary dependencies.
Do not create duplicate architectures.
Inspect the existing repository before making changes.
Follow existing interfaces.
Prefer simple, reliable implementations.
The project must run continuously throughout development.
If a requested feature conflicts with the existing architecture, explain the conflict and propose the smallest compatible solution.
Always test your changes.
Keep your changes isolated to your assigned subsystem.
Assume five other developers are modifying the repository simultaneously.
Your job is not to make the most sophisticated implementation.
Your job is to make your subsystem reliable, visually coherent, and easy to integrate.

## Hard rules for this repo

- Engine: Summer Engine (Godot 4.7, GDScript). Project root is the repo root.
- Never edit `core/` or `project.godot` without the integration owner. Ask for the interface you need instead.
- Cross-system communication goes through `EventBus` signals or `GameState.transition_to()`. Never reference another subsystem's nodes directly.
- Read input only through `InputManager`. Never call `Input` in gameplay code.
- Design against the 200x120 viewport. Pixel art, nearest filtering, integer scale.
- Run `tests/run.sh` before every commit. Add tests under `tests/test_<yoursystem>.gd`.
- Commits: `feat: ...`, `fix: ...`, `docs: ...`. No AI attribution trailers.
- Do not commit `.godot/` or `export/`. Do commit `.summer/` and `*.import` files.
- Original assets only. No copyrighted monster names, sprites, or sounds.
