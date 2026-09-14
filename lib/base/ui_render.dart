import 'package:flutter/material.dart';
import 'package:gui/base/image_render.dart';
import 'package:gui/base/parsers.dart';
import 'package:gui/main.dart';

class LiveNode extends ChangeNotifier {
  final String hash;
  final String type;
  Map<String, dynamic> props;
  List<String> childrenHashes;

  LiveNode({
    required this.hash,
    required this.type,
    required this.props,
    this.childrenHashes = const [],
  });

  // ---------------------------------------------------------------
  // Factory: Create LiveNode from parsed JSON Map and insert into NodeStore
  // ---------------------------------------------------------------
  static LiveNode fromJson(Map<String, dynamic> json) {
    final String hash = json['hash']?.toString() ?? '';
    final String type = json['type']?.toString() ?? 'unknown';

    // Everything except "type", "hash" and "validator" goes into props
    final Map<String, dynamic> props = {};
    json.forEach((key, value) {
      if (key != 'type' && key != 'hash' && key != 'validator') {
        props[key] = value;
      }
    });

    // Optional: extract children hashes if present
    List<String> children = [];
    if (props.containsKey('children') && props['children'] is List) {
      children = (props['children'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty && e != 'null')
          .toList();
      // We keep the original "children" inside props too (optional)
    }

    final node = LiveNode(
      hash: hash,
      type: type,
      props: props,
      childrenHashes: children,
    );

    // Automatically register in NodeStore
    nodeStore.put(node);

    return node;
  }

  // ---------------------------------------------------------------
  // UpdateForce Data
  // ---------------------------------------------------------------
  void updateForce() {
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Update a single property (used by PATCH)
  // ---------------------------------------------------------------
  // sample
  // nodeStore.updateProp(
  //   'fff1ca21-84ed-2f0c-a77f-d4edd0eb74fd',
  //   'fontSize',
  //   30,
  // );
  void updateProp(String key, dynamic value) {
    if (props[key] == value) return; // no change → no notify
    props[key] = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Replace multiple properties at once
  // ---------------------------------------------------------------
  void updateProps(Map<String, dynamic> newProps) {
    props.addAll(newProps);
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Optional helper
  // ---------------------------------------------------------------
  T? getProp<T>(String key) {
    final value = props[key];
    if (value is T) return value;
    return null;
  }

  @override
  String toString() => 'LiveNode(hash: $hash, type: $type)';
}

// store all ui live nodes by hash
class NodeStore {
  final Map<String, LiveNode> _nodes = {};

  LiveNode? get(String hash) => _nodes[hash];

  void put(LiveNode node) {
    _nodes[node.hash] = node;
  }

  void clear() {
    _nodes.clear();
  }

  // update prop of hash
  void updateProp(String hash, String prop, dynamic value) {
    final node = _nodes[hash];
    if (node != null) {
      node.updateProp(prop, value);
    }
  }

  String getKeys() {
    return _nodes.keys.toList().toString();
  }
}

final nodeStore = NodeStore(); // global singleton of node store

Widget renderNode(String hash) {
  final node = nodeStore.get(hash);
  if (node == null) return const SizedBox.shrink();

  switch (node.type) {
    case 'text':
      return RemoteText(hash: hash);

    // case 'column':
    //   return RemoteColumn(hash: hash);
    //
    // case 'page':
    //   return RemoteScaffold(hash: hash);
    //
    case 'appbar':
      return RemoteAppBar(hash: hash);
    case 'image':
      return RemoteImage(hash: hash);

    // ...
    default:
      return Text('Unknown type: ${node.type}');
  }
}

// ---------------------------------------------------------------
// RemoteText Widget
// ---------------------------------------------------------------
class RemoteText extends StatelessWidget {
  final String hash;

  const RemoteText({super.key, required this.hash});

  @override
  Widget build(BuildContext context) {
    final node = nodeStore.get(hash);
    if (node == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: node,
      builder: (context, _) {
        final props = node.props;

        int? maxLines = (props['maxLine'] is num)
            ? (props['maxLine'] as num).toInt()
            : int.tryParse(props['maxLine']?.toString() ?? '');

        // visible handling with Offstage (cleaner than Visibility in many cases)
        final bool isVisible =
            props['visible'] != false && props['visible'] != 'false';

        final textWidget = Text(
          props['text']?.toString() ?? '',
          textAlign: parseTextAlign(props['align']?.toString()),
          maxLines: (maxLines == null || maxLines <= 0) ? null : maxLines,
          overflow: parseTextOverflow(props['overflow']?.toString()),
          softWrap: props['softWrap'] != false && props['softWrap'] != 'false',
          style: TextStyle(
            fontSize: (props['fontSize'] as num?)?.toDouble() ?? 14.0,
            height: (props['height'] as num?)?.toDouble(),
            color: parseColor(props['color']?.toString()),
            fontWeight: parseFontWeight(props['weight']?.toString()),
          ),
        );

        // print(textWidget);
        // Offstage keeps the widget in the tree but does not paint / layout it
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            selectMe(hash);
          },
          child: Offstage(offstage: !isVisible, child: textWidget),
        );
      },
    );
  }
}


// ---------------------------------------------------------------
// RemoteAppBar Widget
// ---------------------------------------------------------------
class RemoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String hash;

  const RemoteAppBar({
    super.key,
    required this.hash,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final node = nodeStore.get(hash);

    if (node == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: node,
      builder: (context, _) {
        final props = node.props;

        String? nullableString(dynamic value) {
          if (value == null || value.toString() == 'null') {
            return null;
          }

          return value.toString();
        }

        final bool isVisible =
            props['visible'] != false && props['visible'] != 'false';

        if (!isVisible) {
          return const SizedBox.shrink();
        }

        final bool showBack =
            props['back'] == true || props['back'] == 'true';

        final String title = props['title']?.toString() ?? '';

        final Color? backgroundColor = parseColor(
          nullableString(props['color']),
        );

        final Color? foregroundColor = parseColor(
          nullableString(props['textColor']),
        );

        final List<dynamic> actions = props['actions'] is List
            ? props['actions'] as List
            : const [];

        return Listener(
          // Capture pointer events from the entire AppBar,
          // including title, leading, actions, and empty areas.
          behavior: HitTestBehavior.opaque,

          onPointerUp: (_) {
            selectMe(hash);
          },

          child: AppBar(
            automaticallyImplyLeading: false,
            title: Text(title),
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            leading: showBack
                ? IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back),
            )
                : null,
            actions: [
              for (final action in actions)
                if (action is Map)
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      parseIcon(action['icon']?.toString() ?? ''),
                    ),
                    tooltip: nullableString(action['tooltip']),
                  ),
            ],
          ),
        );
      },
    );
  }
}
