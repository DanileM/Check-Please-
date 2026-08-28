# Current Task: Independent Room Surfaces and Storeroom Rename

## Overview

Rename the rear-left room to Storeroom and make Main Hall, Storeroom, and Kitchen separately editable visual-material targets. Structural collision remains shared and unchanged; each room receives its own non-overlapping visual floor and wall surfaces in the existing restaurant scene.

## Discovery

- `Architecture/Floor` is one full `18 x 24 m` visual mesh. `FloorBody` is the matching, independent physical collision and can remain whole after the visual split.
- Existing rear-room wall collisions are already separate `StaticBody3D` nodes. They are not addressed by scripts, so they can move into a `StructuralCollision` grouping without changing behaviour.
- `InteriorRooms/Toilet/Doorway` and `InteriorRooms/Kitchen/Doorway` are unused, invisible `Marker3D` nodes. There are no visible room-label/debug meshes to remove.
- The `restaurant_floor.gdshader` derives its grid from mesh UVs. Splitting a mesh without a world-space grid would make tile density and grout seams differ by room.

## Architecture Decisions

- Replace only visual meshes with `Architecture/MainHall`, `Architecture/Storeroom`, and `Architecture/Kitchen` room roots. Each root owns a named floor MeshInstance and wall MeshInstances with its own local material resource.
- Keep all collision under `Architecture/StructuralCollision`, with no alterations to shape extents, solid wall coverage, or open doorway spans.
- Use a world-space floor grid in the existing floor shader so the three independent floor meshes meet as one continuous tile surface at equal height.
- Rename every active scene node from `Toilet` to `Storeroom`; remove the unused room `Marker3D` nodes rather than replacing them.

## Ordered Slices

1. **Name and hierarchy cleanup:** rename active rear-left nodes to Storeroom, remove unused room markers, and create clean visual/collision grouping. Verify no active `Toilet` references remain. *(small; scene + focused test)*
2. **Independent visual materials:** split floors and walls into room-owned meshes, each using an independent local floor/wall material target. Update the floor shader to retain a continuous grid. *(medium; scene + shader)*
3. **Regression proof:** verify all three material targets are distinct, floor surfaces do not overlap/gap, player collision/doorways remain valid, and existing pickup/customer flows parse/run. *(small; focused tests)*

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Split floor produces different tile size/seams | Use world X/Z coordinates in the existing floor shader rather than per-mesh UV coordinates. |
| Visual refactor changes collision | Retain the same collision shapes and transforms under a dedicated structural node. |
| Two room faces occupy the same wall plane | Offset the two face-only interior wall visuals to opposite sides of the structural wall. |

## Result

- `Architecture` now contains editor-facing `MainHall`, `Storeroom`, `Kitchen`, and `StructuralCollision` roots. The previous `InteriorRooms` grouping is gone.
- The three named floor meshes have independent local ShaderMaterial resources. The world-space tile grid in `restaurant_floor.gdshader` keeps their initial terracotta tiles continuous across both shared room boundaries.
- Each room's wall meshes use its own material resource: Main Hall preserves decorative left/right/rear variants, Storeroom shares one warm room wall material, and Kitchen shares one teal room wall material.
- Removed the two unused invisible room Marker3D nodes. Customer/table markers are outside `Architecture` and remain untouched.

# Current Task: Rear Service Rooms Architecture

## Overview

Replace the obsolete `InteriorArchitecture` scene with editor-visible rear service rooms in the existing 18 x 24 m restaurant shell. The new block begins at `z = -4.60`: a smaller Toilet occupies the rear-left, while a larger Kitchen occupies the rear-right. Explicit wall sections preserve separate open doorways and collision.

## Discovery

- The shell is explicit in `scenes/restaurant/restaurant.tscn`: floor `18 x 24`, side walls at `x = +/-9`, rear wall at `z = -12`, and ceiling at `y = 4.10`. The storefront/open entry remains at `+Z` in `storefront_exterior.tscn`.
- `InteriorArchitecture` is a static packed scene referenced only once by `restaurant.tscn`; it has no script, autoload, helper code, or other usage. It can be removed without deleting shared materials.
- `Restaurant/Architecture/BackWall/BackWall` is an obsolete, mesh-only duplicate inside the open room. It has no collision and will be removed with the replacement room layout.
- There is no `NavigationRegion3D`, `NavigationMesh`, or `NavigationAgent3D` in this project. The current customer movement is direct between entry, the existing table at `z = 3`, and exit; it never enters the rear service block.
- Burger and terminal pickups are at `z = 5.9`, and the table/customer path is at `z = 3`, all safely in the dining area ahead of the new rear divider.

## Architecture Decisions

- Keep the exterior shell, floor, ceiling, storefront, pickups, table, customer markers, and gameplay scripts intact.
- Use explicit `MeshInstance3D` + matching `StaticBody3D/CollisionShape3D` wall sections under `Restaurant/Architecture/InteriorRooms`; do not replace the removed scene with another procedural generator.
- Put the rear divider at `z = -4.60`, with a left Toilet width of about `5.4 m` and a right Kitchen width of about `12.2 m`. The divider between rooms is at `x = -3.5`.
- Doorways are open, collision-free gaps: Toilet `0.95 m` centered at `x = -6.20`; Kitchen `1.10 m` centered at `x = 2.20`. Wall height remains `4.1 m`, thickness `0.22 m`.
- Add only two low-cost room fill lights. Do not add fixtures, appliances, doors, or gameplay to either room.

## Ordered Slices

1. **Remove obsolete architecture safely:** remove the packed-scene reference/node, delete the unused `interior_architecture.tscn`, and make the restaurant’s optional legacy decor styling null-safe. Verify Godot parses without missing-resource failures. *(small; 3 files)*
2. **Build explicit rear service block:** add material-matched rear-divider sections, a Toilet/Kitchen partition, matching collision, and basic room lights directly in the restaurant scene. Verify doorway gaps and wall bounds. *(medium; 1 file + focused harness)*
3. **Regression and visual validation:** run scene parse, player collision/doorway assertions, pickup/table/customer-path checks, and capture views from the dining area and both rooms. *(small; test/docs)*

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| A full-width collider closes a doorway | Give every visible solid wall segment its own matching collision; omit collision in the two door spans. |
| Rear rooms become unlit after division | Add one warm non-shadowed OmniLight3D inside each room. |
| Furniture or existing flow is trapped | Keep the divider behind `z = -4.60`; all active objects use `z >= 3`. |
| Old scene removal causes a missing node error | Search all references first and guard the now-optional legacy decor path in `restaurant.gd`. |

## Result

- Removed the only `InteriorArchitecture` scene reference/node and deleted `scenes/restaurant/interior_architecture.tscn`; no generator scripts or shared helpers existed.
- Added explicit room geometry at `Architecture/InteriorRooms`: 0.22 m wall segments/colliders, lintels, visual doorway trim, a rear-left Toilet, rear-right Kitchen, and a full-height divider at `x = -3.5`.
- Focused physics checks confirm both player-door paths are clear while the rear divider and room partition block the capsule. Existing food/payment and full customer food-delivery checks still pass.
- No project navigation system exists to rebake. The direct customer route stays in the dining area, forward of the new divider.
- The available headless runner uses Godot's dummy renderer and cannot capture a viewport; the capture harness now detects that condition instead of claiming an image was rendered.

# Current Task: Interaction Presentation, Carry, and New Terminal Integration

## Current Task: Payment Interaction Regression Fix Pass

### Overview

Repair the live payment/pickup presentation without replacing its architecture: render only the imported payment card in the animated calling arm, keep held-item collision response subtle, correct terminal poses, restore contextual payment targeting, and unify world-pickup tooltip bounds/range.

### Discovery

- `CustomerHandProps` already instances `res://assets/props/credit_card.glb` on `Arm_R_2`, the arm with the larger `CallWaiter` rotation delta (1.23 rad vs 0.57 rad left), but it also overrides the GLB material colors and adds procedural `PaymentCardReadableFace` / `PaymentCardReadableChip` meshes. Those overlays are the wrong temporary card visual.
- `PlayerController` owns the only interaction ray and clamps it globally at 3.0m. It traverses collider parents but has no dedicated payment-range gate or payment target volume. Its carry solver samples all the way to `held_item_min_distance = 0.30`, allowing up to roughly 0.67m of backward movement.
- `InteractionTooltip` receives a manual local height. Imported terminal scale makes its 0.32 local height nearly 1.0m in world space, while the burger uses a separate 0.42 height.
- The new `terminal.glb` wrapper uses the correct keypad/screen hierarchy; its close interaction pose is readable, but the ordinary carry pose still uses a legacy rear-facing rotation.

### Ordered Slices

1. **Real card in animated hand:** remove temporary card geometry/material replacements and tune the existing `Arm_R_2` BoneAttachment transform. Verify the GLB-only prop moves during `CallWaiter` and hides after approval. *(small; 2 files + focused test)*
2. **Bounded interaction contracts:** separate 7.5m pickup hover from 3.0m held actions/payment, add a narrow payment target collider, and derive pickup labels from complete world visual bounds. Verify E/LMB routing and equal Burger/Terminal/Plate spacing. *(medium; 4 files + focused test)*
3. **Carry and terminal polish:** use a full-volume, oriented proxy sweep that prioritizes collision safety over the former 0.11 m presentation cap; ease only the unobstructed return. Verify wall/NPC response and keypad-facing normal/close poses. *(small; 3 files + focused test)*
4. **End-to-end regression:** run payment, keypad, food/plate, interaction, and main-scene checks; inspect captures; fix any failure before completion. *(small; tests/docs)*

### Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Dedicated payment collider intercepts normal character movement | Use an `Area3D`, enable its ray layer only in `WAIT_FOR_PAYMENT`, and keep it out of body collision. |
| 7.5m ray accidentally enables distant actions | Gate table and payment targets by independent 3.0m action distances. |
| Retraction cap allows edge clipping at extreme wall contact | Keep padded query/smoothing but cap viewmodel movement; geometry occludes the last edge instead of moving the item into the camera. |


## Overview

Standardize the real first-person interaction loop around object-name world labels, clean single-object silhouette highlighting, collision-aware held-item retraction, semantic `E`/LMB actions, and the newly imported payment-terminal GLB. Existing food/payment state logic and source GLBs remain intact.

## Discovery

- `scripts/player_controller.gd` is the interaction owner. It currently binds raw `KEY_E` to a mixed pickup/place/payment `_interact()` method; LMB is reserved only for payment keypad clicks.
- `PickupItem` and `TableStation` each instantiate their own 48px/9px-outline `Label3D`, while the customer context is a HUD label. `PaymentTerminalController.get_tooltip_text()` incorrectly returns `Take Payment` for a physical pickup.
- Interaction highlighting applies `pencil_outline.gdshader` as an inverted-hull `material_overlay` to *every* child mesh. This produces the unwanted internal terminal lines and must remain separate from `ComicStyle`'s black art outline.
- The new source model is `assets/props/terminal.glb`, root `TerminalRoot`, with `POS_Body`, `POS_Key_0…9`, `POS_Key_Cancel`, `POS_Key_Clear`, `POS_Key_Charge`, `POS_Screen`, `POS_ScreenFrame`, and `POS_TopPanel`. Its screen replaced the old `POS_ScreenInner`, and its button coordinates differ from the wrapper's old hitboxes.
- Held items are reparented directly to `Player/Head/Camera3D/CarryAnchor`; their colliders are disabled but there is no obstacle query or safe-distance retraction. Default environment, furniture, and NPC bodies share the gameplay collision layer, while the player capsule must be excluded.
- `CustomerController` applies `ComicStyle` to its full imported model after creating the dynamic card attachment, then applies it again directly to the card; both paths explain the unwanted black card outline.

## Architecture Decisions

- Add one reusable `InteractionTooltip` factory/configuration so pickup and placement world labels share typography, scale, billboarding, and object-first wording.
- Replace per-mesh interaction hulls with a player-owned mask camera and full-screen edge pass. It renders temporary white clone meshes on a camera-excluded layer, so all child meshes contribute to one union mask without altering global comic outlines.
- Keep `PickupItem` as the carry-data owner and let `PlayerController` own one reusable sphere-query retraction path for every held item. It ignores the player/held item and only moves the display transform smoothly toward the camera.
- Adapt the existing terminal wrapper/controller to `POS_*` nodes and preserve cents/payment behavior. Use wrapper `Area3D` hitboxes only; do not edit the GLB.
- Add semantic InputMap actions in `project.godot`: `interact_pickup` (`E`) and `use_held_item` (left mouse). Pickup remains exclusive to `E`; LMB uses only an already held item.

## Ordered Slices

1. **Tooltip and action contract:** centralize world-label presentation, rename physical-object labels, and split player input into semantic pickup vs held-item use. Verify Burger/Plate/Payment Terminal labels and E/LMB routing. *(medium; 5 files)*
2. **Unified selection outline:** add a player-owned mask/edge outline controller; migrate pickup/table highlighting from per-mesh hull overlays. Verify multi-mesh terminal produces no internal yellow lines. *(medium; 5 files)*
3. **New terminal and card presentation:** map the new `POS_*` model to screen overlay, hitboxes, collision bounds, carry/interactive poses; exempt card meshes from comic outline. Verify cents entry and correct payment. *(medium; 4 files)*
4. **Collision-aware carry:** add shared sphere-query carry retraction, filtered against player/self, with smooth in/out movement. Verify Burger and terminal against wall, furniture, and customer. *(medium; 3 files)*
5. **End-to-end visual regression:** render tooltip/outline/terminal/carry views and run food/payment/headless regressions. *(small; tests/docs)*

## Acceptance Checks

- World labels are small and consistent: `Burger`, `Plate`, `Payment Terminal`; customer payment stays contextual as `Take Payment`.
- The selected object has only a thin outer yellow contour, including the terminal from every angle; the black comic outline remains unchanged and absent from the card.
- New terminal buttons/screen/carry poses align to the imported `POS_*` hierarchy and retain integer-cent payment behavior.
- `E` picks up only; LMB places/uses only held items; collision-aware carry never renders deeply through obstacle/NPC geometry.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Screen-space mask camera visibility leaks into main camera | High | Reserve a dedicated visual layer excluded from the player camera and cover it with a focused visual harness. |
| New model plane orientation mirrors the live screen | High | Derive the display surface from `POS_Screen` transform and inspect rendered cents/keypad frames. |
| Retraction self-hits or fights terminal tween | High | Exclude player/held colliders, use only default obstacle layer, and keep explicit terminal payment pose separate from ordinary carry retraction. |
| Input migration triggers a keypad click on entry | Medium | Consume LMB before payment mode is enabled and test first click independently. |

## Result

- `InteractionTooltip` is one 26px/5px-outline Label3D configuration. It follows a top-level anchor with unit scale, so imported prop scale cannot enlarge physical names. Labels are exactly `Burger`, `Plate`, `Payment Terminal`, and `Table`; customer context remains `Take Payment`.
- `InteractionOutlineController` renders white clones only into a dedicated mask layer and derives a screen-space outer edge. A multi-mesh terminal therefore has one thin yellow silhouette without button/screen outlines. The normal camera never renders the clone layer.
- Terminal wrapper now uses `assets/props/terminal.glb` `POS_Screen` and exact `POS_Key_*` transforms. Its interactive pose was computed from the live screen basis, producing an upright, readable keypad and live `$2.00` screen. Every keypad hitbox was ray-tested; integer-cent payment flow remains intact.
- Credit-card root joins `comic_outline_exempt`; `ComicStyle` skips that subtree while retaining its Godot-side material treatment.
- Player carry now samples a padded sphere along the intended carry path against gameplay bodies, excluding the Player. Burger and terminal smoothly retract at 18/s and restore at 10/s. The terminal close pose uses the same guard during payment mode.
- Validated with Godot 4.7 editor parse, object/input contract, outline mask, terminal layout, all 13 key rays, cents approval, wall/NPC retraction, food delivery, payment departure, customer presentation, and a 600-frame main-scene smoke. Compatibility captures were inspected for terminal screen/keypad, silhouette, card, and retracted burger.

# Current Task: Controlled Customer Seating Alignment

## Overview

Fix the existing table-station seating transition without changing player/furniture collision. The customer will navigate only to the station's front `ApproachPoint`, stop all walking ownership, align, ease into a visually tuned front-half `SeatPoint`, play the imported `SitDown`, remain root-locked while seated, and reverse safely through the approach area before normal walking resumes.

## Discovery

- `CustomerController` currently owns movement directly with `move_and_slide()`; there is no `NavigationAgent3D`, `NavigationRegion3D`, or navigation mesh in this project.
- `TableStationA` already exposes local `ApproachPoint` `(0, 0, 1.72)`, `SeatPoint` `(0, 0, 1.12)`, and `LookPoint`; the chair's static player collider occupies the same local chair center around `z=1.12`.
- The current `_align_to_seat()` disables the customer's collision mask and moves the root directly from approach to that center point before `SitDown`. That places the animated body too far back into the backrest. The same routine is not mirrored on exit, where the root is reset to the center point after `StandUp` and immediately walks away.
- Furniture stays in its own `StaticBody3D` nodes. The customer has one standing capsule, while the player collision must remain unchanged.

## Architecture Decisions

- Preserve the assigned `TableStation` contract; add/use its own `ApproachPoint`, tuned `SeatPoint`, and `ExitPoint` rather than any hardcoded restaurant path.
- Separate normal walking, controlled chair transition, and seated root locking. The controller will never call normal walking movement while a seating tween owns the transform.
- Disable only the customer standing capsule during the controlled sit/seated interval; restore it only after the root has been moved to a clear exit marker during departure. Chair/table `StaticBody3D` layers and player behavior remain untouched.
- Tune the local seat marker from real rendered poses, then encode that transform in the station scene so future stations can define their own anchors.

## Ordered Slices

1. **Anchors and movement ownership:** add an exit anchor, make the controller stop walking at approach, perform the alignment/seat tween after navigation, and root-lock while seated. Add a focused seating assertion. *(medium; 3 files)*
2. **Collision-safe reverse transition:** disable the standing capsule through seating and restore it only after a controlled transition to the station exit anchor. Verify stand/leave and unchanged furniture collision. *(small; 2 files)*
3. **Visual/regression validation:** capture front/side seating poses in the real main scene, tune marker placement against `SitDown`, then rerun sequence and smoke checks. *(small; tests/docs)*

## Acceptance Checks

- Customer stops at `ApproachPoint`, aligns smoothly, and reaches a station-defined front-half seated anchor without chair/backrest clipping.
- While seated, the root remains at the seat anchor and neither walking nor standing collision moves it.
- `StandUp` exits to a clear station-defined anchor before collision and normal walking are restored; player still cannot pass chair/table.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Imported animation has root displacement | High | Render actual `SitDown`/`StandUp` poses and lock the CharacterBody root only after each clip completes. |
| Capsule restoration overlaps furniture | High | Restore it only after the controlled move reaches the front `ExitPoint`. |
| Existing progression regressions | Medium | Run focused seating and food/payment sequence harnesses after each slice. |

## Result

- Tuned `TableStationA/SeatPoint` from local `z=1.12` to `z=1.38` using Compatibility-rendered `SitDown` poses; this places the customer in the front half of the real chair rather than through its backrest.
- Added station-local `ExitPoint` at `(0, 0, 1.88)`. The customer reaches it with a short controller-owned tween after `StandUp`, before the standing capsule and normal walk are restored.
- `CustomerController` now treats approach, chair transfer, stable seated phases, and exit transfer as separate motion owners. It never mixes its normal `move_and_slide()` walk loop with a seating tween; seated phases pin only the character root, not skeleton animation.
- The customer's standing `CollisionShape3D` is deferred-disabled during the intentional sit/seated period and re-enabled only after clearing the chair. Chair/table `StaticBody3D` nodes and player collision layers were not changed.
- Godot parse, focused seating/exit, food delivery, payment, and 600-frame main-scene checks pass. Rendered front/side and stand/leave captures were inspected. The existing terminal-screen warning and Windows certificate-store warning remain unrelated to this seating change.

# Current Task: Card Payment Terminal Flow

## Overview

Extend the existing successful burger path in place: after `Eat → PutAwaySpoon`, the seated customer asks to pay by waving the real `credit_card.glb`; the player picks up the real `terminal.glb`, enters a mouse-driven 3D terminal mode, inputs the order total in cents, and then resumes the existing review/departure sequence on approval.

## Discovery

- New immutable assets are `assets/props/credit_card.glb` (root `CreditCardRoot`) and `assets/props/terminal.glb` (root `TerminalRoot`). The terminal has real `POS_Key_0…9`, `POS_Key_Cancel`, `POS_Key_Clear`, `POS_Key_Charge`, and `POS_Screen` meshes.
- The customer controller already owns the successful food sequence and stops only after `PutAwaySpoon → CallWaiter`; it has no price/order or payment state. The actual rig has `Arm_L_2`, `Arm_R_2`, and no separate hand bone, so the calling-arm attachment will use the arm demonstrated by the imported animation rather than an invented socket.
- `PickupItem`, `Player/Head/Camera3D/CarryAnchor`, the interaction ray, highlights/tooltips, and the speech-bubble/status systems are all reusable. There is no current food price system.
- The terminal source units are small and its real button/screen meshes are individually addressable. It needs a Godot wrapper for collision hitboxes and a per-instance screen material; neither GLB will be edited.

## Architecture Decisions

- Keep `CustomerController` as the single state authority. Add explicit request/wait/accepted states; terminal approval advances the state rather than setting a parallel collection of booleans.
- Introduce a minimal `order_line_items` total inside the customer controller. It starts with one Burger line at 200 cents, sums quantities in integer cents, and is exposed only through payment-target APIs.
- Make `PaymentTerminalController` extend `PickupItem`, preserving the existing carry, world tooltip, and outline language. Its wrapper owns physical button hitboxes, a runtime SubViewport screen, cents input, and a supplied payment target—not a hardcoded customer path.
- Extend the existing `OrderBubble3D` with a static banknote asset and a `payment` icon ID. The new icon uses `flat-sticker-icon-style`; the same above-head float/fade behavior is retained.
- Player interaction mode is a small extension of the current controller: normal carry remains side-biased; payment mode tweens the held terminal forward, unlocks the cursor, blocks FPS look/movement, and ray-clicks only wrapper hitboxes.

## Ordered Slices

1. **Payment request contract:** write a failing focused sequence test, add the banknote icon/bubble mapping, card attachment, cents order total, and `Eat → PutAwaySpoon → Request/WaitPayment` states. Verify the imported calling arm holds the card and payment bubble is above the head. *(medium; 5 files)*
2. **Terminal asset and input:** add a terminal wrapper using actual model nodes, physical keypad hitboxes, a per-instance live screen, integer-cent editing, backspace/clear, wrong-amount rejection, and approved signal. Verify input/result logic in a focused Godot test. *(medium; 3 files)*
3. **Player payment interaction:** add terminal pickup/side carry plus valid-customer targeting, existing-style outline/tooltip, central tween, cursor/control lock, click routing, cancellation, and cleanup. Verify wrong and correct payment flows without changing source GLBs. *(medium; 4 files)*
4. **End-to-end regression:** run food delivery through terminal approval, `LeaveReview`, `StandUp`, and exit; inspect terminal/card/bubble/carry views and rerun existing customer, player, and import tests. *(small; tests/docs)*

## Acceptance Checks

- The food path has actual animation completion boundaries: `Eat → PutAwaySpoon → CallWaiter + card → WaitPayment → LeaveReview → StandUp → Leave`.
- Payment input is only via physical terminal hitboxes, is stored/validated in cents, and a wrong value leaves card/customer waiting untouched.
- The player may carry only the terminal, receives the exact `Take Payment` target text only when the customer is waiting, and returns to normal control/carry after approval or Escape.
- Both new GLB source files remain byte-identical; payment feedback stays above the customer head and uses the project’s static icon style.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Calling arm is misidentified | High | Sample the actual imported CallWaiter bone transforms before selecting the card attachment. |
| Model screen UV orientation differs | Medium | Use an isolated wrapper material and visually inspect the live SubViewport before finalizing. |
| Terminal button areas interfere with pickup | Medium | Disable keypad colliders while carried normally; enable only in explicit terminal interaction mode on a dedicated layer. |
| Existing failure/review flow regresses | High | Preserve its branch and run its current focused regression tests after each relevant slice. |

## Result

- Completed in four verified slices: the customer now uses state-guarded integer-cents payment APIs after `PutAwaySpoon`; a new reusable terminal wrapper supplies real keypad hitboxes and a live screen without altering its GLB; player input cleanly switches between carry and payment modes; and the full flow reaches the existing review/departure path only after `$2.00` approval.
- The banknote bubble reuses the above-head presentation and the generated static `banknote_payment.png`; the card uses a Godot-side attachment/material treatment on the confirmed `Arm_R_2` calling arm. The terminal's live display uses a thin runtime quad over its imported screen so it remains visible in GL Compatibility.
- Focused request, keypad, player-mode, complete payment, and updated food-delivery regressions pass. A Compatibility-rendered preview confirms the bubble and the centered `$2.00` terminal screen.

# Current Task: Flat Sticker Icon Style Skill

## Overview

Create one discoverable, reusable instruction skill for the project’s static food, order, status, reaction, speech-bubble, restaurant, and item icon assets. It will preserve the supplied Korean icon sheet as the primary visual reference and the supplied burger as a food-specific secondary reference; it will not generate an icon in this task.

## Discovery

- The environment discovers user-authored skills from `C:\\Users\\idknow\\.agents\\skills`, where each skill is a folder containing `SKILL.md` and optionally `agents/openai.yaml`.
- No existing skill in that directory matches icon, sticker, flat, or image-generation work, and no root skills index or manifest is present to update.
- The installed `agent-skills` package is a cache and is not the correct location for a user-authored reusable skill.

## Architecture Decisions

- Keep the new skill self-contained, with concise automatic-selection metadata and a matching UI metadata file.
- Preserve the two user-provided images beside the instructions as local references so later requests retain the source-of-truth style even when the current chat attachments are unavailable.
- Make the Korean icon sheet primary for the visual grammar; use the burger only to clarify food-icon construction. The skill explicitly prohibits copying their individual symbols.

## Ordered Slices

1. **Skill definition:** create `flat-sticker-icon-style` with trigger conditions, visual rules, prompt template, generation workflow, and a consistency/QA checklist. Verify its frontmatter and metadata. *(small; 2 files)*
2. **Reference preservation and discovery:** add the two supplied reference images beneath the skill and validate the completed directory with the installed skill validator. *(small; 2 assets)*

## Acceptance Checks

- The skill is automatically discoverable from the user skill root and clearly targets only the requested sticker-style UI/game-icon work.
- It records every stated visual trait, the first-anchor-icon workflow, reference precedence, and the supplied prompt template.
- It contains durable local copies of both style references, has no scaffold placeholders, and passes the skill validator.

## Result

- Added the discoverable `flat-sticker-icon-style` user skill with compact instructions, UI metadata, and preserved local primary/secondary visual references.
- The built-in Python validator could not run because this environment has no runnable Python interpreter. Equivalent static checks passed: required files, frontmatter keys/name, metadata, reference links, trigger/prompt/anchor guidance, and SHA-256 equality of both copied images.

# Current Task: Playable Food Delivery Slice

## Discovery

- `Game` wires one `CustomerController`, `TableStationA`, player camera, and entry/exit markers. `Player/Head/Camera3D/InteractRay` is already the correct first-person targeting point.
- `CustomerController` owns the complete finite failure path and its state transitions. It already has configurable read/wait timings, reusable above-head `CustomerStatusIcon`, and additive head targeting.
- `TableStationA` provides a real `FoodSlot` marker but has no interaction or placed-food ownership yet. The restaurant has a playable table and an accessible floor space near the entry-side service path.
- Existing user-provided assets include `assets/food/burger.glb` and `assets/props/plate.glb`; neither source asset will be modified.
- Runtime audit confirms the imported animation set includes `Walk`, `SitDown`, `StandUp`, `TakeMenu`, `ReadMenu`, `CallWaiterMenu`, `PutAwayMenu`, `TakeSpoon`, `Eat`, `PutAwaySpoon`, `CallWaiter`, and `LeaveReview`. `Spoon_R` is the actual spoon socket.

## Architecture Decisions

- Keep `CustomerController` as the only customer state authority. Add explicit delivery/eating states and a single delivered-food hook rather than a parallel state machine.
- Add three small reusable world components: a world-space order bubble, a pickup/carry item, and a table placement target. Player interaction remains camera-ray based and asks those components for tooltip/highlight/action behavior.
- Put the bubble and the rating in the existing above-head area. Reading has no head icon; the bubble owns its fade/reveal/float and the status icon remains responsible for rating feedback.
- Instantiate burger + plate only from independent Godot scenes. The world item transfers to a camera-local carry anchor, then to `FoodSlot`, so it never drifts in animation/world space.
- Preserve the existing timeout failure path. Food delivery is a separate interruption that transitions through menu put-away, available spoon/eating presentation, burger removal, and no-menu waiter call.

## Ordered Slices

1. **Order bubble (medium; 3 files):** add the reusable world-space bubble component, attach it above the customer, and drive its burger order only during menu waiter calls. Verify no menu-reading emoji remains, with fade/reveal/float and impatience shake.
2. **Pickup and carry path (medium; 4 files):** add reusable pickup-item/highlight behavior plus a burger-on-plate scene and a camera-local carry anchor. Verify ray targeting changes the tooltip, highlights the plate, and transfers it into the held anchor.
3. **Table placement and food state path (large vertical slice; 5 files):** make `FoodSlot` a conditional place target, transfer the plate to it, and add the delivered-food sequence plus empty-plate pickup. Verify delivery interrupts waiting cleanly and retains the non-delivery failure route.
4. **Runtime validation and polish (small; 3 files):** add focused Godot assertions, run the playable main scene and visual captures, fix transition/parse issues, and document the final flow.

## Acceptance Checks

- `ReadMenu` has no indicator; `CallWaiterMenu` shows a floating burger bubble, and the bubble fades out on delivery/failure.
- Looking at burger plate shows `Burger`, pickup places it in a stable first-person carry position, and the table only offers `Place` while carrying a placeable item.
- Delivery follows the ordered, blended sequence; burger disappears after configured eating duration, leaving a pickupable empty plate and a no-menu waiter call.
- Missing delivery still produces angry impatience, a shaking bubble, 1/5 review feedback above the head, and sad departure.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Food animation/socket names differ from assumptions | Medium | Runtime-audit the imported clip and bone lists before wiring delivery; confirmed `TakeSpoon`, `Eat`, `PutAwaySpoon`, and `Spoon_R`. |
| Interaction ray hits child colliders | Medium | Resolve interaction component by walking the collider parent chain. |
| Concurrent old automatic await resumes after delivery | High | Use delivery-specific flag/token checks and consume the same wait interruption before entering food states. |

## Result

- Added `OrderBubble3D`: a procedural, resolution-independent SubViewport bubble with a 1–5 slot row, a static transparent burger asset now, bottom-up accent reveal, fade, billboard, float, and optional impatience shake. The icon row is centered in the body and the tail is drawn as one continuous silhouette.
- Added `PickupItem` and `burger_plate.tscn`. The item exposes world tooltip/highlight, carry and table transfer, burger visibility, and empty-plate reuse without changing either GLB asset.
- `PlayerController` now resolves interactables from its existing camera ray. `E` transfers burger to `CarryAnchor`, then lets the correct waiting table display `Place` and snap the item to `FoodSlot`.
- `CustomerController` accepts food only while calling with the menu, interrupts the timeout safely, uses the confirmed `PutAwayMenu -> TakeSpoon -> Eat -> PutAwaySpoon -> CallWaiter` flow, and exposes the empty plate. The untouched no-delivery flow still shakes the order bubble, submits 1/5, and exits sad.
- Focused component, interaction, table, delivery, escalation, presentation, head-look, and player-input checks pass. Compatibility captures were inspected for the readable burger bubble and the delivered-food state; carry/placement and empty-plate transfer are covered by the focused interaction harness.

# Current Task: Customer Presentation Refinement

## Discovery

- `CustomerController` owns the finite state flow, face transforms, and the independent menu/phone attachments under the imported skeleton.
- `HeadLookModifier` already applies a post-animation additive yaw/pitch offset to `Head_2`; its target can be switched without changing the rig or Blender animation.
- `CustomerStatusIcon` already owns billboard, fill, and shake below `StatusIconAnchor`; `EmotionAnchor` remains a separate temporary-label anchor.
- `MenuAttachment` uses `Menu_Hold` and `PhoneAttachment` uses `Phone_Hold`; presentation offsets need to remain local to these sockets. The former `OneStarReview` child label explains why the prior rating appeared too low.

## Architecture Decisions

- Keep the controller as the state authority. Add small state-aware presentation helpers rather than a second controller or Blender changes.
- Add configurable transform presets beneath the two existing `BoneAttachment3D` nodes; apply them on state entry so props remain bone-relative and stable throughout the imported clips.
- Reuse the existing head-look modifier: set its target to a local menu marker while reading, restore the player camera in calling states, and disable it elsewhere.
- Consolidate transient feedback under `StatusIconAnchor`; let `CustomerStatusIcon` support a review symbol, persistent display, bobbing, and shake layering.
- Store the final review score on the controller and apply one locked emotion when review is submitted; do not reset it during stand/leave.

## Ordered Slices

1. **Head-target and prop foundation:** add safe menu/phone attachment references and preset transforms; switch the existing additive head solver to the menu marker only in `STUDY_MENU`. Verify parse and state/head-target assertions. *(3 files, medium)*
2. **Feedback and review lock:** move review display to the head-status component, add subtle bobbing, and lock the final face from the configurable review score. Verify status state, float/shake composition, and leaving emotion. *(3 files, medium)*
3. **Visual regression:** render the actual main scene through the existing preview camera; inspect menu/read, calling, review, and exit frames. Then run existing sequence, head-look, player-input, and import checks. *(tests/docs, small)*

## Acceptance Checks

- Menu and phone remain socketed to their original bones, visibly larger, tilted, and hidden outside their intended states.
- Reading uses the existing additive head solver toward a menu-local target; both waiter-call states return to the player target.
- All feedback, including the final rating, is above the head and bobs gently; impatient shaking layers over that motion.
- `final_review_score` selects and locks sad (<2), neutral (2–3), or happy (>3) through exit.

## Result

- Added `CustomerHandProps`, which keeps independent props attached to their original bones while applying explicit readable menu and portrait-phone presets.
- `ReadMenu` reuses the existing post-animation head solver toward `MenuReadTarget`; the normal/impatient call states restore the player camera target.
- Rating/status feedback now shares `StatusIconAnchor`, bobs at 0.026 m, preserves impatience shake, and keeps the review score visible through departure. The 1/5 test path locks the sad face.
- Focused tests, prior customer/head/player tests, a 600-frame main smoke run, and a Compatibility render all pass.

# Current Task: Customer Automatic Escalation

## Discovery

- The single controller is `scripts/customer_controller.gd`; `Game` starts it automatically after supplying the station, entry/exit points, and player camera.
- The imported `AnimationPlayer` and `Skeleton3D` live below `Visual/CustomerModel`. The actual clips are `Walk`, `SitDown`, `StandUp`, `TakeMenu`, `ReadMenu`, `CallWaiterMenu`, `PutAwayMenu`, and `LeaveReview`.
- `Menu_Hold` and `Phone_Hold` are the prop bones. `menu.glb` and `phone.glb` are independent imported scenes and expose no prop animation of their own.
- Existing head tracking is a post-animation `SkeletonModifier3D` on `Head_2`; calling states must continue to enable it.

## Architecture Decisions

- Extend the existing controller instead of adding a second NPC or service system. The default sequence is finite: it ends after the customer exits.
- Keep timing and animation-speed tuning as exported variables on the controller. Clip completion remains authoritative for non-looping clips.
- Attach the independent menu and phone to their respective named bones; visibility is driven only by the corresponding imported animation phase.
- Add one small reusable world-space status-icon component. It owns bottom-up fill and shake, while the controller owns when each state displays it.
- Keep a future `on_waiter_interaction()` hook, but add no input binding or waiter-service implementation.

## Ordered Slices

1. **Sequence foundation (RED/GREEN):** write the focused escalation test, then add state/configuration support and external menu attachment through `TakeMenu`, reading, normal call, and put-away.
2. **Escalation feedback:** add a reusable filled/shaking status icon; integrate impatient call, angry face, and exact timeouts while preserving `CallWaiterMenu` head look.
3. **Review and departure:** attach/show phone and one-star indicator for `LeaveReview`; run `StandUp`, walk to the existing exit, and end the sequence.
4. **Validation and polish:** run Godot import/parse and a full controller harness, check the playable main scene and visible state transitions, then update project documentation.

## Acceptance Checks

- The state order is deterministic: walk → sit → menu/read → normal call → impatient call → put away → review → stand → exit.
- `ReadMenu` runs for the configured duration with an upward-filling status symbol; impatient call uses 1.6× animation speed, angry face, and a shaking full icon.
- Menu/phone are separate assets attached to `Menu_Hold`/`Phone_Hold`; the one-star review indication is visible only during review.
- No GLB/import file changes, no player input interaction, no extra customer controller, and no change to seating/head-look anatomy.

## Result

- All four slices are complete. The focused Godot harness observes every state, both menu-call phases retaining head look, the filling/shaking icon states, the 1.6× impatient animation speed, external prop visibility, review indicator, and the single completed exit.
- A Compatibility-rendered main-scene capture visually confirms the filling book, call feedback, one-star review, stand-up, and departure.

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

# Implementation Plan: Visual-Preserving Performance Pass

## Decisions

- Keep VSync enabled in the project; benchmarking uses a runtime-only override.
- Keep room material domains intact; do not batch static geometry without profiler evidence.
- Replace held-item sampling with one item-configured shape cast, not render-mesh collision.

## Ordered slices

1. **Baseline:** record available runtime structural metrics and focused behaviour checks.
2. **Collision:** align the two facade edge-post shapes; use per-item ShapeCast3D proxies for held Burger/Plate and Payment Terminal.
3. **Idle rendering:** stop outline/status/order SubViewports when hidden; preserve active screen updates.
4. **Outlines and lights:** disable outline-shadow participation; reduce only visually redundant customer outlines and shadow passes after comparison.
5. **Verification:** run parse, focused collision/interaction checks, and repeat the same metrics. Defer batching/occlusion unless justified.

## Risks

| Risk | Mitigation |
| --- | --- |
| Cast proxy is too large or small | Keep independent, exported proxy data and regression-test wall/NPC contacts. |
| Viewport freezes after re-enable | Toggle update mode with visibility lifecycle tests. |
| Comic silhouette degrades | Limit initial filtering to tiny/internal meshes and preserve major body meshes. |

## Follow-up: Full-volume held-prop wall safety

- [x] Terminal proxy now exceeds the visual terminal body and uses the current item basis.
- [x] Burger/Plate uses its existing shallow cylinder proxy.
- [x] One `cast_motion` checks physical layer 1, excludes Player, and determines the final safe position.
- [x] Inward correction is immediate; only outward restoration is smoothed.
- [x] Front, corner, camera tilt, lateral movement, NPC, interactive-terminal, Burger, payment, parsing, and main-scene smoke checks pass.
