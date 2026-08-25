import 'package:flutter/material.dart';
import 'package:gui/base/parsers.dart';
import 'package:gui/base/ui_render.dart';

// ---------------------------------------------------------------
// RemoteScaffold
//
// Scaffold is intentionally NOT a LiveNode.
//
// The application currently has only one page-level Scaffold,
// and the Scaffold itself is always recreated through FULL_RENDER.
//
// Therefore:
// - Scaffold does not live inside NodeStore.
// - Scaffold does not use ListenableBuilder.
// - Scaffold does not participate in PATCH updates.
// - Only its child components are represented as LiveNodes.
//
// Expected JSON structure:
//
// {
//   "type": "scaffold",
//   "hash": "scaffold-1",
//   "backgroundColor": "#FFFFFF",
//   "children": {
//     "visual": [
//       {
//         "type": "appbar",
//         "hash": "appbar-1",
//         ...
//       },
//       {
//         "type": "text",
//         "hash": "text-1",
//         ...
//       },
//       {
//         "type": "column",
//         "hash": "column-1",
//         ...
//       }
//     ],
//     "nonVisual": [
//       {
//         "type": "...",
//         "hash": "...",
//         ...
//       }
//     ]
//   }
// }
//
// Rendering:
//
// Scaffold
// ├── appBar: renderNode("appbar-1")
// └── body:
//     ├── renderNode("text-1")
//     └── renderNode("column-1")
// ---------------------------------------------------------------

class RemoteScaffold extends StatelessWidget {
  /// Scaffold-level properties.
  ///
  /// These are NOT stored inside LiveNode.
  final Map<String, dynamic> props;

  /// Hashes of visual nodes that belong to the Scaffold body.
  ///
  /// Example:
  /// [
  ///   "text-1",
  ///   "column-1",
  ///   "container-1"
  /// ]
  final List<String> bodyChildren;

  /// Special Scaffold slots.
  ///
  /// These are kept separately because they are not normal body children.
  final String? appBarHash;
  final String? floatingActionButtonHash;
  final String? drawerHash;
  final String? endDrawerHash;
  final String? bottomNavigationBarHash;

  const RemoteScaffold({
    super.key,
    required this.props,
    required this.bodyChildren,
    this.appBarHash,
    this.floatingActionButtonHash,
    this.drawerHash,
    this.endDrawerHash,
    this.bottomNavigationBarHash,
  });

  // ---------------------------------------------------------------
  // Factory: Build the page-level Scaffold from FULL_RENDER JSON.
  //
  // IMPORTANT:
  // The Scaffold itself is NOT inserted into NodeStore.
  //
  // Only actual child components are converted into LiveNodes.
  // ---------------------------------------------------------------
  static RemoteScaffold fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> scaffoldProps = {};

    // -------------------------------------------------------------
    // Copy Scaffold-level properties.
    //
    // "type", "hash", "children" are structural information and
    // should not be treated as normal Scaffold properties.
    // -------------------------------------------------------------
    json.forEach((key, value) {
      if (key != 'type' &&
          key != 'hash' &&
          key != 'children' &&
          key != 'validator') {
        scaffoldProps[key] = value;
      }
    });

    // -------------------------------------------------------------
    // Body children.
    //
    // Every visual node that is not a special Scaffold slot
    // becomes a body child.
    // -------------------------------------------------------------
    final List<String> bodyChildren = [];

    // -------------------------------------------------------------
    // Scaffold special slots.
    // -------------------------------------------------------------
    String? appBarHash;
    String? floatingActionButtonHash;
    String? drawerHash;
    String? endDrawerHash;
    String? bottomNavigationBarHash;

    // -------------------------------------------------------------
    // Read children container.
    // -------------------------------------------------------------
    final children = json['children'];

    if (children is Map) {
      // ===========================================================
      // VISUAL NODES
      //
      // Visual nodes are actual UI components.
      //
      // Example:
      //
      // visual:
      //   appbar
      //   text
      //   column
      //   container
      //
      // All of these are registered as LiveNodes.
      // ===========================================================
      final visual = children['visual'];

      if (visual is List) {
        for (final value in visual) {
          if (value is! Map) {
            continue;
          }

          // Convert Map<dynamic, dynamic> into the exact type
          // expected by LiveNode.fromJson().
          final nodeJson = Map<String, dynamic>.from(value);

          final type = nodeJson['type']?.toString();
          final hash = nodeJson['hash']?.toString();

          // Invalid nodes are ignored.
          if (hash == null || hash.isEmpty) {
            continue;
          }

          // -------------------------------------------------------
          // Register the actual UI node in NodeStore.
          //
          // Scaffold itself is NOT registered.
          // -------------------------------------------------------
          LiveNode.fromJson(nodeJson);

          // -------------------------------------------------------
          // Scaffold special slots.
          // -------------------------------------------------------
          switch (type) {
            case 'appbar':
              appBarHash = hash;
              break;

            case 'floatingActionButton':
              floatingActionButtonHash = hash;
              break;

            case 'drawer':
              drawerHash = hash;
              break;

            case 'endDrawer':
              endDrawerHash = hash;
              break;

            case 'bottomNavigationBar':
              bottomNavigationBarHash = hash;
              break;

          // -----------------------------------------------------
          // Everything else belongs to the Scaffold body.
          // -----------------------------------------------------
            default:
              bodyChildren.add(hash);
              break;
          }
        }
      }

      // ===========================================================
      // NON-VISUAL NODES
      //
      // These nodes exist in the LiveNode tree but are not rendered
      // directly by Scaffold.
      //
      // They are still registered in NodeStore because another
      // visual node may reference them by hash.
      // ===========================================================
      final nonVisual = children['nonVisual'];

      if (nonVisual is List) {
        for (final value in nonVisual) {
          if (value is! Map) {
            continue;
          }

          final nodeJson = Map<String, dynamic>.from(value);

          final hash = nodeJson['hash']?.toString();

          if (hash == null || hash.isEmpty) {
            continue;
          }

          // Register non-visual node in NodeStore.
          LiveNode.fromJson(nodeJson);
        }
      }
    }

    // -------------------------------------------------------------
    // Debug information.
    // -------------------------------------------------------------
    debugPrint('RemoteScaffold created');
    debugPrint('appBar: $appBarHash');
    debugPrint('body: $bodyChildren');
    debugPrint('floatingActionButton: $floatingActionButtonHash');
    debugPrint('drawer: $drawerHash');
    debugPrint('endDrawer: $endDrawerHash');
    debugPrint('bottomNavigationBar: $bottomNavigationBarHash');

    // -------------------------------------------------------------
    // Create the page-level Scaffold renderer.
    //
    // Notice that there is NO LiveNode for this Scaffold.
    // -------------------------------------------------------------
    return RemoteScaffold(
      props: scaffoldProps,
      bodyChildren: bodyChildren,
      appBarHash: appBarHash,
      floatingActionButtonHash: floatingActionButtonHash,
      drawerHash: drawerHash,
      endDrawerHash: endDrawerHash,
      bottomNavigationBarHash: bottomNavigationBarHash,
    );
  }

  // ---------------------------------------------------------------
  // Build the actual Flutter Scaffold.
  //
  // No ListenableBuilder is needed here because the Scaffold itself
  // is never patched. A FULL_RENDER creates a completely new
  // RemoteScaffold instance.
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------
    // Build the Scaffold body.
    //
    // Each hash is resolved through NodeStore and rendered through
    // the normal renderNode() mechanism.
    // -------------------------------------------------------------
    Widget? body;

    if (bodyChildren.isNotEmpty) {
      body = Column(
        children: bodyChildren
            .map(renderNode)
            .toList(),
      );
    }

    // -------------------------------------------------------------
    // Resolve Scaffold special slots.
    // -------------------------------------------------------------
    Widget? appBar;

    if (appBarHash != null) {
      appBar = renderNode(appBarHash!);
    }

    Widget? floatingActionButton;

    if (floatingActionButtonHash != null) {
      floatingActionButton = renderNode(floatingActionButtonHash!);
    }

    Widget? drawer;

    if (drawerHash != null) {
      drawer = renderNode(drawerHash!);
    }

    Widget? endDrawer;

    if (endDrawerHash != null) {
      endDrawer = renderNode(endDrawerHash!);
    }

    Widget? bottomNavigationBar;

    if (bottomNavigationBarHash != null) {
      bottomNavigationBar = renderNode(bottomNavigationBarHash!);
    }

    // -------------------------------------------------------------
    // Create the real Flutter Scaffold.
    // -------------------------------------------------------------
    return Scaffold(
      backgroundColor: parseColor(
        props['backgroundColor']?.toString(),
      ),

      // -----------------------------------------------------------
      // AppBar
      //
      // AppBar is a special Scaffold slot and therefore does not
      // participate in the normal body list.
      // -----------------------------------------------------------
      appBar: appBar as PreferredSizeWidget?,

      // -----------------------------------------------------------
      // Body
      //
      // All visual nodes that are not Scaffold special slots are
      // rendered here in their original visual order.
      // -----------------------------------------------------------
      body: body,

      // -----------------------------------------------------------
      // Floating Action Button
      // -----------------------------------------------------------
      floatingActionButton: floatingActionButton,

      // -----------------------------------------------------------
      // Drawer
      // -----------------------------------------------------------
      drawer: drawer,

      // -----------------------------------------------------------
      // End Drawer
      // -----------------------------------------------------------
      endDrawer: endDrawer,

      // -----------------------------------------------------------
      // Bottom Navigation Bar
      // -----------------------------------------------------------
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}