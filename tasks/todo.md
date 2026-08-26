# Customer Head Look Task List

## Task 12: Implement the Reusable Solver

**Acceptance criteria:**

- [x] Uses the imported `Head_2` bone and Godot 4.7 post-animation modifier pass.
- [x] Applies only local yaw/pitch additively to the current animated head pose.
- [x] Clamps yaw to ±55°, pitch to +25°/-30°, rejects outside ±85° or 8 m, and smooths at 7/5.

**Verification:** focused RED/GREEN Godot runtime test of solver output and limits.

## Task 13: Integrate Calling States and Camera Target

**Acceptance criteria:**

- [x] `Player/Head/Camera3D` is supplied as the look target.
- [x] `CALL_WAITER` and `CALL_WAITER_MENU` enable look; all other seating states disable it.
- [x] Current seating loop, body animation, props, controller, and source GLB remain unchanged outside this behavior.

**Verification:** controller state/animation integration test using both actual clip names.

## Task 14: Validate Visual Behavior and Regressions

**Acceptance criteria:**

- [x] Front, ±30°, ±50°, ±75°, behind, re-entry, and smooth reset cases pass.
- [x] Both calling clips continue animating body/arms while only the head receives the procedural offset.
- [x] Main scene runs cleanly; customer remains seated; no `.glb` or generated import file changed.

**Verification:** Godot 4.7 import/parse, focused runtime harness, main-scene smoke run, and change audit.

# Current Task: Customer Seating Sequence

## Task 9: Place One Reusable Seating Setup

**Acceptance criteria:**

- [x] Exactly one imported table and one imported chair are visible.
- [x] Table, chair, `ApproachPoint`, `SeatPoint`, and `LookPoint` are floor-aligned and reusable.
- [x] Legacy duplicate furniture is not visible.

**Verification:** Godot import plus visual scene check.

## Task 10: Run the Seating State Machine

**Acceptance criteria:**

- [x] Customer starts away from the chair and uses `Walk` to reach `ApproachPoint`.
- [x] Customer performs short alignment, actual `SitDown`, then remains at `SeatPoint`.
- [x] Actual `CallWaiter` repeats while seated.

**Verification:** Focused Godot runtime check of state transitions and animation names.

## Task 11: Validate the Playable View

**Acceptance criteria:**

- [x] Main scene starts without parse/resource errors.
- [x] Player controls remain enabled.
- [x] Seating alignment and repeating call are visually inspected.

**Verification:** Main-scene runtime and captured camera view.

# Restaurant Environment Task List

## Task 1: Audit Current Project

**Description:** Inspect the renderer, scenes, scripts, resources, materials, lights, collision, and current runtime before further edits.

**Acceptance criteria:**

- [x] Existing scene hierarchy and gameplay NodePaths are mapped.
- [x] Renderer and environment configuration are identified.
- [x] Current visual and collision defects are documented in the implementation plan.

**Verification:**

- [x] `project.godot`, main scene, restaurant scenes, player, and customer files inspected.
- [x] Git status attempted; workspace confirmed not to be a git repository.

**Dependencies:** None

**Estimated scope:** Small

## Task 2: Preserve Gameplay and Establish Shared Materials

**Description:** Keep dormant player/customer/table architecture available while hiding furniture for this pass, then introduce a small shared material palette for interior and exterior architecture.

**Acceptance criteria:**

- [x] Player controller and input mapping remain unchanged.
- [x] Customer and table systems remain available but do not render furniture or run service loops.
- [x] Core coral, teal, cream, charcoal, tile, concrete, asphalt, glass, and plant materials are reusable resources.

**Verification:**

- [x] Godot resource import succeeds.
- [x] Main scene runs for at least 60 frames without errors.

**Dependencies:** Task 1

**Estimated scope:** Medium

## Task 3: Rebuild Floor and Wall Architecture

**Description:** Replace the arcade floor and giant flat wall planes with 0.55–0.75 m terracotta tiles, subtle variation, layered wall panels, seams, baseboards, picture rails, and cornice.

**Acceptance criteria:**

- [x] Floor tile scale and grout are believable and non-glowing.
- [x] Both side walls and rear wall show physical architectural depth.
- [x] Central floor remains clear for future tables and NPC navigation.

**Verification:**

- [x] Interior preview inspected at gameplay eye height.
- [x] Floor and wall collisions remain unchanged and valid.

**Dependencies:** Task 2

**Estimated scope:** Medium

## Task 4: Rebuild Ceiling and Practical Lighting

**Description:** Create repeated shallow ceiling bays, perimeter cove trim, small center globes, side spots, limited wall sconces, and warm neutral lighting.

**Acceptance criteria:**

- [x] Ceiling has three readable depth layers and repeated rhythm.
- [x] Practical lights are warm but do not wash the scene orange.
- [x] Shadow-casting lights remain limited.

**Verification:**

- [x] Interior preview shows readable ceiling structure and floor illumination.
- [x] Runtime has no light or shader errors.

**Dependencies:** Task 3

**Estimated scope:** Medium

## Task 5: Refine Restaurant Facade and Entrance

**Description:** Convert the bright prototype frontage into a controlled coral entrance with dark glazing frames, readable glass, entrance hardware, threshold, sign area, and layered trim.

**Acceptance criteria:**

- [x] Large left window, centered door, and large right window remain clear.
- [x] Player corridor is at least 0.68 m wide and unobstructed.
- [x] Glass is visible and blocks the player while the doorway remains open.

**Verification:**

- [x] Automated doorway and glass collision check passes.
- [x] Facade preview inspected from inside and outside.

**Dependencies:** Tasks 2 and 4

**Estimated scope:** Medium

## Task 6: Build Neighboring Frontage

**Description:** Add two distinct facade buildings left and two right of the restaurant, with varied heights, windows, doors, cornices, awnings, and dark interior cards.

**Acceptance criteria:**

- [x] Five-part frontage reads as L2, L1, restaurant, R1, R2.
- [x] Neighbor buildings are varied but share the controlled palette.
- [x] No detailed unused interiors are built.

**Verification:**

- [x] Street preview inspected from the doorway and across the road.
- [x] Static building collision uses simple boxes.

**Dependencies:** Task 5

**Estimated scope:** Medium

## Task 7: Refine Street and Greenery

**Description:** Add segmented light concrete sidewalk, believable curb, cool gray asphalt, restrained markings, 3–5 rounded trees, planters, and limited structural props.

**Acceptance criteria:**

- [x] Sidewalk, curb, and road have distinct scale and materials.
- [x] Exterior no longer ends in empty space.
- [x] Greenery and props support composition without clutter.

**Verification:**

- [ ] Player cannot fall through walkable exterior surfaces.
- [ ] Exterior preview remains readable through restaurant glazing.

**Dependencies:** Task 6

**Estimated scope:** Medium

## Task 8: Cohesion and Technical Validation

**Description:** Tune saturation, roughness, outline width, exposure, z-fighting, and collision, then run full validation and capture final visual evidence.

**Acceptance criteria:**

- [ ] No neon placeholder surfaces, missing resources, or visible furniture remain.
- [ ] Main scene, player, and dormant customer architecture remain valid.
- [ ] Final interior and exterior views match the written acceptance criteria.

**Verification:**

- [ ] Godot editor import exits successfully.
- [ ] Main scene runs at least 600 frames without errors.
- [ ] Door/glass collision test passes.
- [ ] Final interior, facade, and street captures inspected.

**Dependencies:** Tasks 3–7

**Estimated scope:** Medium
