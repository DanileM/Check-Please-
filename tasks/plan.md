# Current Task: Additive Customer Head Look

## Discovery

- Customer wrapper/controller: `scenes/characters/customer.tscn` / `scripts/customer_controller.gd`.
- Imported animation system: `Visual/CustomerModel/AnimationPlayer`; the real calling clips are `CallWaiter` and `CallWaiterMenu`.
- Imported skeleton: `Visual/CustomerModel/Rig/Skeleton3D`; the real head bone is `Head_2`, parented to `Spine`.
- Player eye target: `Game/Player/Head/Camera3D`.
- Both calling clips already animate `Head_2`; there is no existing procedural bone modifier.
- Godot 4.7.1 exposes `SkeletonModifier3D._process_modification_with_delta(delta)`, which runs in the skeleton modification pass after animation evaluation.

## Architecture Decisions

- Add one reusable `SkeletonModifier3D` solver under the imported skeleton at runtime. It owns target selection, local-space angle solving, limits, cone/distance rejection, and exponential smoothing.
- Read the evaluated `Head_2` pose inside the modifier callback and multiply a yaw/pitch offset onto it for that frame. This preserves the authored head track and never changes roll procedurally.
- Keep player discovery in `game.gd`; pass the actual `Camera3D` to the customer controller, then pass that target to the low-level solver.
- Make calling-state entry/exit authoritative. `CALL_WAITER` and the actual menu variant `CALL_WAITER_MENU` enable tracking; every other state disables it.
- Keep the current gameplay loop on `CallWaiter`; add no new menu gameplay, animation framework, or source-model edits.

## Ordered Slices

1. **Solver (RED/GREEN):** add a failing focused test, then implement local yaw/pitch, ±55° neck clamp, ±85° activation cone, 8 m distance gate, and 7/5 exponential smoothing in a reusable modifier.
2. **Integration:** install the modifier on `Head_2`, pass `Player/Head/Camera3D`, and toggle it from explicit calling states including `CallWaiterMenu`.
3. **Runtime validation:** parse/import, run main, test front/left/right/side/behind/resume/reset cases, and verify both calling clips retain non-head animation tracks and seated placement.

## Result

- All slices are complete. The focused Godot 4.7 test covers direct front, ±30°/50°/75°, rotated-NPC local space, pitch limits, distance, behind/re-entry, both calling clips, smooth exit, authored roll, and a control-character comparison for every non-head bone.
- Editor import, the existing seating regression, a 600-frame main smoke run, and an actual Compatibility-rendered visual check pass. `customer_1.glb` matches its repository hash and no imported source artifact changed.

## Risks

| Risk | Mitigation |
| --- | --- |
| Animation overwrites the procedural pose | Use the Godot 4.7 skeleton modifier pass rather than `_process()` ordering guesses. |
| Rig forward/sign conventions invert tracking | Measure against the imported skeleton/model orientation and assert signed cases in the focused runtime test. |
| Offset accumulates each frame | Always start from the animation-evaluated pose supplied to the modifier pass; never persistently override a global bone transform. |
| Existing dirty work is accidentally bundled | Patch only the controller/game integration and new solver; do not stage, commit, reset, or alter unrelated files. |

# Current Task: Customer Seating Sequence

## Overview

Use the existing `TableStation` and `CustomerController` to stage exactly one imported table, one imported chair, and one customer. The playable sequence is deliberately limited to walk, final alignment, real `SitDown`, seated hold, and repeating real `CallWaiter`.

## Discovery

- Main scene: `scenes/main.tscn`; restaurant: `scenes/restaurant/restaurant.tscn`.
- Customer wrapper: `scenes/characters/customer.tscn`; controller: `scripts/customer_controller.gd`; source GLB: `assets/characters/customer_1.glb`.
- Furniture GLBs: `assets/furniture/table.glb`, `assets/furniture/chair.glb`.
- Actual imported animations: `Walk` (1.042 s), `SitDown` (1.000 s), `CallWaiter` (2.708 s).
- No navigation region, mesh, or agent exists; the existing `CharacterBody3D` movement is the smallest compatible path.
- Git exists but status cannot be queried due ownership protection; no git configuration or destructive git action will be used.

## Architecture Decisions

- Keep `TableStationA` as the reusable owner of imported furniture and Marker3D transforms; add `LookPoint` to make the seating contract explicit.
- Keep the controller as the single NPC system. Replace the active loop entry with an explicit seating state machine and leave unrelated future helpers inactive.
- `SeatPoint` is authoritative after the real sit animation; alignment moves only the short final distance to it.
- No source GLB or generated import artifact is edited.

## Ordered Slices

1. Furniture slice: expose one `TableStationA`, hide legacy duplicate meshes, set table/chair/marker transforms and simple collisions; import/run check.
2. Behavior slice: add `WALK_TO_CHAIR → ALIGN_TO_CHAIR → SIT_DOWN → SEATED → CALL_WAITER`, use actual animation names and animation completion; runtime check.
3. Validation slice: run a deterministic seating test, capture a real camera view, verify player remains functional and inspect alignment.

## Result

- All three slices are complete. The focused runtime test confirms all seating states, `SeatPoint` stability, a repeating call cycle, visible imported furniture, hidden legacy duplicates, and an enabled player.

## Risks

| Risk | Mitigation |
| --- | --- |
| Imported sit root does not align | Use the existing marker contract, then correct only at `SitDown` completion. |
| Chair collision blocks final seat position | Keep the approach point outside the collider; make only the short controlled alignment ignore character collision. |
| Call animation resets pose | Preserve the authoritative seat transform and restart the actual non-looping imported animation only after it finishes. |

# Implementation Plan: Production Restaurant Environment Pass

## Overview

Rework the existing Godot 4.7 restaurant scene in place. The pass keeps the first-person and customer systems intact, removes visible dining furniture, replaces the neon placeholder treatment with a controlled illustrated palette, adds architectural depth and practical lighting, and completes the visible street block around the restaurant.

## Architecture Decisions

- Keep the current 18 m by 24 m gameplay footprint and existing root scene names so NodePaths remain stable.
- Build all architecture as editable Godot scenes using primitive meshes, simple box collisions, shared materials, and small reusable shaders.
- Preserve customer and table scenes/scripts. Any temporary gameplay instances remain disabled and out of view instead of deleting their systems.
- Split new exterior frontage into a separate reusable street-neighbor scene rather than growing the restaurant scene into one monolithic file.
- Retain GL Compatibility. Use few shadow-casting lights and subtle material response instead of enabling expensive GI blindly.

## Dependency Order

1. Audit and baseline verification.
2. Gameplay preservation and shared material foundation.
3. Interior shell and floor.
4. Ceiling and practical lighting.
5. Restaurant entrance and facade.
6. Neighbor frontage, street, greenery, and limited props.
7. Cohesion pass and technical validation.

## Task List

### Phase 1: Foundation

- [x] Task 1: Audit scenes, renderer, gameplay paths, materials, lights, and collisions.
- [x] Task 2: Preserve dormant gameplay placeholders and create shared controlled materials.

### Checkpoint: Foundation

- [x] Godot imports all resources without errors.
- [x] Main scene runs with player controls intact and no visible furniture.

### Phase 2: Interior

- [x] Task 3: Replace floor and flat wall treatment with correctly scaled tile, paneling, seams, baseboards, and cornice.
- [x] Task 4: Rebuild ceiling into repeated bays with cove detail, pendants, spots, and limited wall sconces.

### Checkpoint: Interior

- [x] Empty room reads as a finished restaurant shell.
- [x] Palette is warm and controlled; no arcade grid or neon slabs remain.

### Phase 3: Facade and Street

- [x] Task 5: Refine entrance, glazing, facade framing, sign area, handles, and threshold.
- [x] Task 6: Add two varied neighboring facades on each side using a separate Godot scene.
- [x] Task 7: Refine sidewalk, curb, asphalt, markings, greenery, and limited street props.

### Checkpoint: Exterior

- [x] Restaurant remains centered and visually dominant.
- [x] Exterior reads as a complete small street block from the interior and sidewalk.

### Phase 4: Polish and Validation

- [ ] Task 8: Tune outlines, lighting, roughness, saturation, collision, and runtime behavior; capture final evidence.

### Checkpoint: Complete

- [ ] Godot 4.7 imports and runs cleanly.
- [ ] Player can cross the doorway; glazing and architecture block correctly.
- [ ] Customer/table architecture remains intact but dormant for the furniture-free pass.
- [ ] No visible restaurant furniture was added.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Scene paths break gameplay | High | Preserve root names and validate all NodePaths after every structural slice. |
| Large exterior scene becomes hard to edit | Medium | Put neighboring frontage in a focused scene and reuse shared materials. |
| Too many lights hurt GL Compatibility performance | Medium | Keep most fixtures non-shadowed; use only one sun and a few shadowed practical lights. |
| Stylization becomes neon or flat | High | Use muted source colors, moderate roughness, low emission, and selective outlines only. |
| Furniture-free room still feels empty | Medium | Add rhythm at walls, ceiling, facade, and perimeter while preserving the central gameplay area. |

## Open Questions Resolved by Assumption

- The existing Korean restaurant identity is retained because the current project and earlier user direction already establish it; no new reference branding is copied.
- Earlier screenshots in this task are treated as the available visual references. The written specification controls where it is more specific.
- No git commits are possible because the workspace is not a git repository.
