# Project structure

- `scenes/main.tscn`: boot scene.
- `scenes/restaurant/restaurant.tscn`: editable Restaurant V1.
- `scenes/restaurant/korean_decor.tscn`: collision-free mural, signage, ceiling, lighting, and hanging-decor layer.
- `scenes/restaurant/table_station.tscn`: reusable table/service unit.
- `scenes/characters/customer.tscn`: NPC wrapper around `customer_1.glb`.
- `scenes/player/player.tscn`: first-person waiter.
- `scripts/customer_controller.gd`: customer state loop and animation sequencing.
- `scripts/table_station.gd`: table service sockets.
- `scripts/comic_style.gd`: comic/pencil outline pass.
- `assets/**/*.glb`: modular 3D assets.
