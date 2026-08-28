extends Node3D

func _ready() -> void:
    # KoreanDecor is an optional legacy art set and is not part of the new room shell.
    # Keep this guard so removing its scene instance never produces startup errors.
    for decor_path in [&"KoreanDecor/BackWallMural", &"KoreanDecor/PosterCollage", &"KoreanDecor/VerticalTasteSign"]:
        var decor := get_node_or_null(NodePath(decor_path))
        if decor:
            ComicStyle.apply(decor, 0.004)
