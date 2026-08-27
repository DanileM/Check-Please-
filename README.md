# Check, Please! — Godot 4.7

This is the main development project, not a throwaway prototype. The current build establishes a finished restaurant shell, a walkable street block, the first-person controller, one reusable customer seating station, selective comic rendering, and the first playable customer seating sequence.

## Open
1. Extract the archive.
2. Open `project.godot` in Godot 4.7.
3. Wait for the `.glb` imports to finish.
4. Run the project (F6/F5).

## Current game foundation
- First-person waiter controller: WASD + mouse, no jump.
- Restaurant environment: muted coral, teal, cream, and charcoal architecture with approximately 0.64 m terracotta floor tiles, layered wall paneling, three ceiling bays, warm cove accents, four globe pendants, recessed spots, wall sconces, and selective illustrated outlines.
- Frontage: two large windows, an open centered glass entrance, an arched sign crown, facade planters, and simple box collision that keeps the doorway traversable while the glazing blocks the player.
- Street block: two neighboring facades on each side, an opposite-building backdrop, segmented concrete sidewalks, 0.15 m curbs with centered ramps, cool gray asphalt, restrained markings, trees, planters, and bollards.
- Current customer sequence: one imported table, one imported chair, one customer, and a burger-on-plate pickup. The customer walks to `ApproachPoint`, aligns to `SeatPoint`, sits, takes and reads a menu, then calls with a burger order bubble.
- Modular table stations already contain `ApproachPoint`, `SeatPoint`, `WaiterPoint`, `FoodSlot`, and `DrinkSlot`.
- `customer_1.glb` is the supplied NPC model.
- The active NPC flow branches cleanly. Without delivery it remains automatic: `Walk -> SitDown -> TakeMenu -> ReadMenu -> CallWaiterMenu -> impatient CallWaiterMenu -> PutAwayMenu -> LeaveReview -> StandUp -> exit`. Delivering the burger while the customer waits runs `CallWaiterMenu -> PutAwayMenu -> TakeSpoon -> Eat -> PutAwaySpoon -> CallWaiter + card -> WaitForPayment`; the burger then disappears and the empty plate becomes pickupable.
- Aim at a highlighted item and press `E`: the floor plate says `Burger`, the table says `Place` only while carrying food, and the post-meal plate says `Plate`. Food is held from the camera-local carry anchor and always snaps to `FoodSlot` on the table.
- A terminal sits beside the burger pickup. After the customer calls to pay, collect it, aim at the waiting customer for `E — Take Payment`, then click its physical keypad. Amounts use integer cents: the current burger is `$2.00`; a wrong amount stays editable, while `CHARGE` on `$2.00` approves payment and returns normal first-person control.
- `customer_seating_enabled` is active in `scenes/main.tscn`.
- Temporary emotion mapping is active: neutral / sad / happy / angry. The final leaving emotion is selected from the review score: `<2` sad, `2–3` neutral, `>3` happy.
- Feedback uses one world-space above-head anchor with a gentle bob; the reusable comic order bubble has one to five icon slots, fades/reveals on entry, and adds a small shake layer during impatience. Its current burger uses the static transparent asset `assets/ui/icons/burger_order.png`; reading deliberately has no bubble.
- Menu and phone use the separate `menu.glb` / `phone.glb` assets attached to `Menu_Hold` / `Phone_Hold`. Godot-side hand presets enlarge and tilt the menu, stage the portrait phone for review, and keep `★ 1/5` above the head through the leave transition.
- Comic character uses muted material variation, dark architectural trim, and the existing inverted-hull pencil outline only on selected mural/sign elements rather than giant shell planes.

## Asset split
`assets/furniture` — table, chair, bar counter/shelf, booth.
`assets/environment` — pendant lamp, TV, wall art, plant.
`assets/props` — menu, phone, spoon, glass, plate, tray.
`assets/characters` — customer models.

## Important architecture decision
Props are independent assets. In production, glasses, plates, phones, menus and utensils should move between world sockets (tray/table/hand) instead of being baked permanently into customer models. The current menu and phone already use the hand-socket pipeline; the model and its imported animations remain unchanged.

## Next development layers
The project is structured to add: order-taking UI, kitchen tickets, more food/tray variants, table patience balancing, tips/reviews, shift/day economy, additional customers, and restaurant upgrades without rebuilding the level architecture.
