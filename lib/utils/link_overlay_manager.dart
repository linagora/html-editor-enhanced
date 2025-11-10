/// Represents the type of overlay currently visible in an editor.
enum LinkOverlayType {
  tooltip,
  editDialog,
}

/// A global manager that tracks and controls all link-related overlays
class LinkOverlayManager {
  LinkOverlayManager._internal();
  static final LinkOverlayManager instance = LinkOverlayManager._internal();

  /// Active overlay instances mapped by their type.
  final Map<LinkOverlayType, List<dynamic>> _activeOverlays = {
    LinkOverlayType.tooltip: [],
    LinkOverlayType.editDialog: [],
  };

  /// Registers a new overlay of the given [type].
  void register(LinkOverlayType type, dynamic overlay) {
    _activeOverlays[type]?.add(overlay);
  }

  /// Unregisters (removes) an overlay when it is hidden or disposed.
  void unregister(LinkOverlayType type, dynamic overlay) {
    _activeOverlays[type]?.remove(overlay);
  }

  /// Hides all overlays of a specific [type].
  void hideByType(LinkOverlayType type) {
    final overlays = List.from(_activeOverlays[type] ?? []);
    for (final overlay in overlays) {
      overlay.hide();
      unregister(type, overlay);
    }
  }

  /// Hides all overlays
  void hideAll() {
    for (final type in LinkOverlayType.values) {
      hideByType(type);
    }
  }

  /// Hides overlays of the same [type] except for the current one.
  void hideOthers(LinkOverlayType type, dynamic current) {
    final overlays = List.from(_activeOverlays[type] ?? []);
    for (final overlay in overlays) {
      if (overlay != current) {
        overlay.hide();
        unregister(type, overlay);
      }
    }
  }

  /// Checks whether any overlay (of any type) is currently visible.
  bool get hasActiveOverlays =>
      _activeOverlays.values.any((list) => list.isNotEmpty);
}
