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
