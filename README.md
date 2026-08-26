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
- Current seating test: one imported table, one imported chair, and one customer. The customer walks to `ApproachPoint`, aligns to `SeatPoint`, plays the imported `SitDown`, then repeats imported `CallWaiter` while seated.
- Modular table stations already contain `ApproachPoint`, `SeatPoint`, `WaiterPoint`, `FoodSlot`, and `DrinkSlot`.
- `customer_1.glb` is the supplied NPC model.
- The current active NPC slice deliberately stops after `Walk -> SitDown -> CallWaiter`. Menu, food, review, standing, and exit flow remain future work.
- `customer_seating_enabled` is active in `scenes/main.tscn`.
- Temporary emotion mapping is active: neutral / sad / happy / angry.
- Emotion feedback above the NPC uses fade-in + upward movement + fade-out.
- Imported embedded Menu/Spoon meshes are hidden except during their animation phases. Phone uses the separate `phone.glb` asset and the `Phone_Hold` socket when available.
- Comic character uses muted material variation, dark architectural trim, and the existing inverted-hull pencil outline only on selected mural/sign elements rather than giant shell planes.

## Asset split
`assets/furniture` — table, chair, bar counter/shelf, booth.
`assets/environment` — pendant lamp, TV, wall art, plant.
`assets/props` — menu, phone, spoon, glass, plate, tray.
`assets/characters` — customer models.

## Important architecture decision
Props are independent assets. In production, glasses, plates, phones, menus and utensils should move between world sockets (tray/table/hand) instead of being baked permanently into customer models. The current customer still contains embedded Menu/Spoon nodes, so V1 hides/shows those for reliable alignment while the external-prop socket pipeline is already present for the phone.

## Next development layers
The project is structured to add: order taking, kitchen tickets, food/tray carrying, table patience, tips/reviews, shift/day economy, additional customers, and restaurant upgrades without rebuilding the level architecture.
