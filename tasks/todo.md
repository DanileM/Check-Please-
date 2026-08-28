# Interaction Presentation, Carry, and New Terminal Task List

## Task 33: Centralize Object Labels and Split Pickup/Use Input

**Description:** Apply one small Label3D style to physical object labels, use semantic input actions, and reserve `E` for pickup and LMB for actions on held items.

**Acceptance criteria:**

- [ ] Burger, Plate, and Payment Terminal labels use the same small style and exact object names.
- [ ] E only picks up; LMB only places/uses an already held item, while customer payment remains `Take Payment`.

**Verification:** Focused player-input harness and real scene tooltip inspection.

**Dependencies:** None.

**Files likely touched:** `scripts/interaction_tooltip.gd`, `scripts/pickup_item.gd`, `scripts/table_station.gd`, `scripts/player_controller.gd`, `project.godot`.

## Task 34: Render One Silhouette Highlight per Interactable

**Description:** Replace per-child hull overlays with one union mask and a thin screen-space selection edge.

**Acceptance criteria:**

- [ ] Burger/table/terminal show one thin outer yellow contour without interior component borders.
- [ ] Existing black comic outlines remain independent.

**Verification:** Runtime mask-controller assertions plus front/side/rear terminal captures.

**Dependencies:** Task 33.

**Files likely touched:** `scripts/interaction_outline_controller.gd`, `shaders/interaction_outline.gdshader`, `scenes/player/player.tscn`, `scripts/pickup_item.gd`, `scripts/table_station.gd`.

## Task 35: Adapt Payment Terminal and Exempt the Card

**Description:** Re-map wrapper screen/hitboxes/collisions/poses to the imported `POS_*` terminal and remove only the card's comic outline.

**Acceptance criteria:**

- [ ] Every payment key/screen aligns to the new model and cents entry/approval remain correct.
- [ ] Card retains its materials without a black hull outline.

**Verification:** Focused keypad test plus Compatibility terminal/card capture.

**Dependencies:** Task 34.

**Files likely touched:** `scenes/props/payment_terminal.tscn`, `scripts/payment_terminal_controller.gd`, `scripts/customer_controller.gd`, `scripts/customer_hand_props.gd`.

## Task 36: Add Shared Obstacle-Aware Held Carry

**Description:** Retract any held pickup smoothly through one filtered sphere-query solver rather than per-prop clipping hacks.

**Acceptance criteria:**

- [ ] Burger and terminal retract near world/furniture/NPC obstacles, never self-hit, then smoothly restore.
- [ ] Explicit terminal payment pose stays readable and does not invoke world pickup.

**Verification:** Focused physics-query harness and real camera captures.

**Dependencies:** Task 33.

**Files likely touched:** `scripts/player_controller.gd`, `scripts/pickup_item.gd`, `.tmp/verify_held_item_retraction.gd`.

## Task 37: Validate the Complete Interaction Loop

**Description:** Verify new inputs, labels, outline, terminal, card, carry safety, and existing customer progression in the real scene.

**Acceptance criteria:**

- [ ] All focused regressions and a main-scene smoke run pass.
- [ ] Visual captures cover tooltips, terminal keypad/screen, selection outline, card, and retraction.

**Verification:** Godot 4.7 parse/main run plus focused interaction, food, and payment tests.

**Dependencies:** Tasks 33-36.

## Checkpoint: Interaction Presentation Complete

- [ ] Object naming/input contract, silhouette outline, terminal/card, and carry retraction are verified.
- [ ] No new project parse/runtime errors.

# Controlled Customer Seating Alignment Task List

## Task 31: Define Station-Owned Seating and Exit Anchors

**Description:** Use the existing front approach anchor, tune the station-local seat anchor against the real chair, and add a clear exit anchor for the reverse transition.

**Acceptance criteria:**

- [x] Normal walking target ends at `ApproachPoint`; seat and exit targets remain local to the assigned station.
- [x] The tuned seat pose keeps hips on the front half of the seat and torso ahead of the backrest.

**Verification:** Focused seating harness plus front/side real-scene captures.

**Dependencies:** None.

**Files likely touched:** `scenes/restaurant/table_station.tscn`, `scripts/table_station.gd`, `.tmp/verify_customer_seating.gd`.

## Task 32: Make Controlled Sit/Stand Own Customer Movement and Collision

**Description:** Stop ordinary walk movement before alignment; move only through controlled station transitions, suspend the standing capsule while seated, then restore it once the character is clear of the chair.

**Acceptance criteria:**

- [x] No normal walking/tween overlap; the seated root is stable at the station anchor.
- [x] Stand-up reaches clear space before standing collision and normal walk resume; player furniture collision stays untouched.

**Verification:** Focused state/collision harness, food/payment flow regression, and main-scene smoke run.

**Dependencies:** Task 31.

**Files likely touched:** `scripts/customer_controller.gd`, `scenes/characters/customer.tscn`, `.tmp/verify_customer_seating.gd`.

## Checkpoint: Customer Seating Alignment

- [x] Sit/stand, menu progression, and player furniture collision pass focused checks.
- [x] Godot 4.7 main scene parses/runs without new seating errors.

# Card Payment Terminal Flow Task List

## Task 27: Request Payment from the Existing Food Sequence

**Description:** Add a state-driven payment request after the real `PutAwaySpoon` completion, plus a static banknote bubble, card attachment, and reusable cents-based order total.

**Acceptance criteria:**

- [x] One Burger produces a 200-cent total and the customer exposes only state-guarded payment-target APIs.
- [x] The card follows the actual animated calling arm and the banknote bubble appears only while payment is requested/waiting.

**Verification:** Focused RED/GREEN Godot sequence test and imported animation/bone audit.

**Dependencies:** None.

**Files likely touched:** `scripts/customer_controller.gd`, `scripts/customer_hand_props.gd`, `scripts/order_bubble_3d.gd`, `assets/ui/icons/banknote_payment.png`, `.tmp/verify_payment_flow.gd`.

## Task 28: Build the Reusable Physical Payment Terminal

**Description:** Wrap the terminal GLB without editing it, using real keypad nodes/hitboxes and a live per-instance screen controlled in integer cents.

**Acceptance criteria:**

- [x] Physical keypad hitboxes support digits, `<`, `X`, and `CHARGE`; the actual POS screen renders the current amount/result.
- [x] $2.00 approves only for the current burger order; $1.00 remains open and correctable.

**Verification:** Focused terminal controller Godot test and wrapper scene import.

**Dependencies:** Task 27.

**Files likely touched:** `scenes/props/payment_terminal.tscn`, `scripts/payment_terminal_controller.gd`, `.tmp/verify_payment_terminal.gd`.

## Checkpoint: After Tasks 27-28

- [x] Customer request and terminal input tests pass independently.
- [x] No source GLB or existing food/review flow resource changed.

## Task 29: Integrate Player Pickup and Payment Mode

**Description:** Extend the existing single-item interaction controller with terminal carry, valid-customer targeting, tweened mouse mode, and cleanup.

**Acceptance criteria:**

- [x] Terminal pickup reuses the existing highlight/tooltip and stays at a side carry pose.
- [x] Valid customer targeting shows exactly `Take Payment`; Escape cancels, and approval restores control/carry.

**Verification:** Focused player/payment interaction harness.

**Dependencies:** Tasks 27-28.

**Files likely touched:** `scripts/player_controller.gd`, `scripts/customer_controller.gd`, `scripts/game.gd`, `scenes/restaurant/restaurant.tscn`, `.tmp/verify_payment_interaction.gd`.

## Task 30: Validate the Complete Payment Departure Sequence

**Description:** Exercise delivery, payment, review, stand, and departure in the real main scene; inspect the important visual states and regressions.

**Acceptance criteria:**

- [x] Correct payment reaches review/stand/leave only after approval; existing final-emotion rules remain active.
- [x] Card, bubble, terminal screen/poses, phone, and tooltips are visually legible and no parse/runtime errors are introduced.

**Verification:** Main-scene harness, headless import, focused regressions, and captured visual frames.

**Dependencies:** Task 29.

**Files likely touched:** `.tmp/verify_payment_flow.gd`, `.tmp/payment_visual_preview.gd`, `README.md`, `tasks/plan.md`, `tasks/todo.md`.

## Checkpoint: Payment Flow Complete

- [x] All focused payment, food, customer, player, and import checks pass.
- [x] Source `credit_card.glb` and `terminal.glb` hashes match their baseline values.

# Flat Sticker Icon Style Skill Task List

## Task 25: Define the Reusable Icon-Style Skill

**Description:** Add a discoverable user skill that guides generation or updating of the project’s static sticker-style UI/game icons without copying the reference symbols.

**Acceptance criteria:**

- [x] `SKILL.md` has valid, discriminating frontmatter and covers all requested use, exclusion, style, consistency, and prompt guidance.
- [x] `agents/openai.yaml` makes normal automatic invocation and an explicit `$flat-sticker-icon-style` prompt discoverable.

**Verification:** Run the bundled skill validator and inspect the resulting instructions.

**Dependencies:** None.

**Files likely touched:** `C:\\Users\\idknow\\.agents\\skills\\flat-sticker-icon-style\\SKILL.md`, `C:\\Users\\idknow\\.agents\\skills\\flat-sticker-icon-style\\agents\\openai.yaml`.

## Task 26: Preserve the Visual References

**Description:** Store the user-supplied primary icon-sheet and secondary burger reference next to the reusable instructions.

**Acceptance criteria:**

- [x] Both references are present at the paths linked by the skill.
- [x] The primary sheet has precedence and no reference symbol is copied as a new icon.

**Verification:** Verify paths and run the skill validator.

**Dependencies:** Task 25.

**Files likely touched:** `C:\\Users\\idknow\\.agents\\skills\\flat-sticker-icon-style\\references\\korean-culture-icon-sheet.png`, `C:\\Users\\idknow\\.agents\\skills\\flat-sticker-icon-style\\references\\burger-food-icon.png`.

## Checkpoint: Flat Sticker Icon Style Skill

- [x] The complete skill validates without placeholders.
- [x] No project gameplay files or installed plugin cache files changed.

# Playable Food Delivery Slice Task List

## Task 21: Build the Reusable Order Bubble

**Acceptance criteria:**

- [x] A billboarded, fading order bubble supports one to five icon slots and currently renders a burger order above the customer.
- [x] `ReadMenu` shows no head emoji; normal/impatient menu calls show the bubble, with impatience shake layered over float.

**Verification:** Godot parse plus focused component/controller harness.

**Dependencies:** None.

**Files likely touched:** `scripts/order_bubble_3d.gd`, `scenes/characters/customer.tscn`, `scripts/customer_controller.gd`.

## Task 22: Implement Burger Pickup and First-Person Carry

**Acceptance criteria:**

- [x] Burger-on-plate is accessible, targetable, outlined, and labels itself `Burger`.
- [x] E transfers it to a stable, angled player carry anchor.

**Verification:** focused interaction harness and main-scene smoke run.

**Dependencies:** Task 21.

**Files likely touched:** `scripts/pickup_item.gd`, `scenes/props/burger_plate.tscn`, `scenes/player/player.tscn`, `scripts/player_controller.gd`.

## Checkpoint: After Tasks 21-22

- [x] Scripts and scenes parse without errors.
- [x] Bubble and pickup path work independently in the actual main scene.

## Task 23: Place Food and Run the Customer Service Sequence

**Acceptance criteria:**

- [x] Table highlights and shows `Place` only for held food; placement snaps to `FoodSlot`.
- [x] Delivery cancels the pending failure path, hides order bubble, runs the available smooth food sequence, removes burger, and exposes an empty-plate pickup while customer calls without menu.
- [x] No-delivery impatience/review/exit path is still intact.

**Verification:** focused delivery and timeout harnesses plus transition assertions.

**Dependencies:** Tasks 21-22.

**Files likely touched:** `scripts/table_station.gd`, `scenes/restaurant/table_station.tscn`, `scripts/customer_controller.gd`, `scripts/game.gd`, `scripts/player_controller.gd`.

## Task 24: Validate and Document the Playable Slice

**Acceptance criteria:**

- [x] Main scene and focused test sequence run in Godot 4.7 with no new project errors.
- [x] Captures confirm the readable order bubble and delivered-food state; focused interaction harnesses confirm carrying, placement, empty plate, and failure review.

**Verification:** Godot parse, focused harness, main smoke, and inspected rendered frames.

**Dependencies:** Task 23.

**Files likely touched:** `README.md`, `tasks/plan.md`, `tasks/todo.md`.

# Customer Presentation Refinement Task List

## Task 18: Stabilize Hand Props and Reading Gaze

**Acceptance criteria:**

- [x] Menu and phone have named Godot-side attachment transforms, visible at a larger readable scale and stable across their relevant clips.
- [x] `ReadMenu` uses the existing head-look solver toward the menu; calling states restore player tracking.

**Verification:** focused controller assertions plus Godot script/scene parse.

## Task 19: Unify Above-Head Feedback and Lock Review Emotion

**Acceptance criteria:**

- [x] Rating and status feedback use the one above-head anchor, with a subtle bob layered beneath optional shake.
- [x] Final review score selects the specified emotion and remains unchanged during stand/leave.

**Verification:** focused sequence test records review display and final face state.

## Task 20: Render and Regress the Presentation Pass

**Acceptance criteria:**

- [x] Existing customer sequence, head look, and player controls remain valid.
- [x] Actual Compatibility-rendered frames show the intended menu, phone, icon, and exit presentation.

**Verification:** import, focused Godot harnesses, smoke run, and inspected render frames.

# Customer Automatic Escalation Task List

## Task 15: Build the Finite Escalation Flow

**Acceptance criteria:**

- [x] Uses the actual imported clips and one controller to execute all requested phases in order.
- [x] Reading, normal call, and impatient call durations/speed are exported tuning values.
- [x] The external menu follows `Menu_Hold`, while existing seating and head look stay intact.

**Verification:** focused controller test observes each state and animation.

## Task 16: Add Status and Impatience Feedback

**Acceptance criteria:**

- [x] The reusable world-space status component fills its supplied symbol upward and can shake without respawning.
- [x] Reading shows a filling indicator; normal call keeps it full; impatient call shakes it and sets the existing angry face.

**Verification:** runtime component/controller assertions and visual inspection.

## Task 17: Add Review, Departure, and Regression Proof

**Acceptance criteria:**

- [x] Phone and one-star indication appear only during the actual `LeaveReview` phase.
- [x] Customer performs `StandUp`, walks through the existing exit, and the automatic sequence completes once.
- [x] Main scene and existing player/head-look functionality remain valid without source/import edits.

**Verification:** Godot import, complete sequence harness, main-scene smoke/visual run, and file-status audit.

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
