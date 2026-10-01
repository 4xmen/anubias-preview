import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ============================================================
// CONTEXT MENU
// ============================================================
//
// This function is completely independent from the page.
//
// It does not know anything about:
//   - EditorPage
//   - EditorComponent
//   - Your business logic
//
// It only knows how to:
//   1. Display the menu.
//   2. Return the selected action.
//
// The page decides what Setting Delete / Sort / Duplicate actually do.
// ============================================================


void showContextMenu({
  required BuildContext context,
  required Offset position,

  // These callbacks receive the component hash.
  required void Function(String hash) onProp,
  required void Function(String hash) onDelete,

  // Nullable because Sort or duplicate is optional.
  void Function(String hash) ?onDuplicate,
  void Function(String hash)? onSort,

  required String hash,
}) {
  // Get the overlay used by Flutter for popup menus.
  final overlay = Overlay.of(context)
      .context
      .findRenderObject() as RenderBox;

  // Convert the mouse position into a RelativeRect.
  //
  // showMenu() uses this information to determine
  // where the popup should appear.
  final menuPosition = RelativeRect.fromRect(
    Rect.fromLTWH(
      position.dx,
      position.dy,
      0,
      0,
    ),
    Offset.zero & overlay.size,
  );

  showMenu<String>(
    context: context,

    // Open the menu exactly where the user right-clicked.
    position: menuPosition,

    // --------------------------------------------------------
    // MENU ITEMS
    // --------------------------------------------------------

    items: <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'props',

        child: const Row(
          children: [
            Icon(
              Icons.settings,
              size: 18,
              color: Colors.white,
            ),

            SizedBox(width: 10),

            Text(
              'Properties',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',

        child: const Row(
          children: [
            Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.white,
            ),

            SizedBox(width: 10),

            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),

      // Add Sort only if the caller provided an onSort callback.
      if (onSort != null)
        PopupMenuItem<String>(
          value: 'sort',

          child: const Row(
            children: [
              Icon(
                Icons.swap_vert,
                size: 18,
                color: Colors.white,
              ),

              SizedBox(width: 10),

              Text(
                'Sort',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

      // Visual separator between action groups.
      const PopupMenuDivider(),
      // Add Sort only if the caller provided an onDuplicate callback.
      if (onDuplicate != null)
      PopupMenuItem<String>(
        value: 'duplicate',

        child: const Row(
          children: [
            Icon(
              Icons.copy_outlined,
              size: 18,
              color: Colors.white,
            ),

            SizedBox(width: 10),

            Text(
              'Duplicate',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    ],

    // --------------------------------------------------------
    // MENU STYLE
    // --------------------------------------------------------

    // Only the context menu is dark.
    // The rest of the application remains unchanged.
    color: const Color(0xFF242424),

    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ).then((value) {
    // Clicking outside the menu returns null.
    if (value == null) {
      return;
    }

    // --------------------------------------------------------
    // ACTION DISPATCH
    // --------------------------------------------------------

    switch (value) {
      case 'props':
        onProp(hash);
        break;
      case 'delete':
        onDelete(hash);
        break;

      case 'sort':
        onSort?.call(hash);
        break;

      case 'duplicate':
        onDuplicate?.call(hash);
        break;
    }
  });
}