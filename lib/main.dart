import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gui/base/parsers.dart';
import 'package:gui/web_events.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:gui/base/config.dart';
import 'package:gui/base/theme.dart';
import 'package:gui/base/ui_render.dart';
import 'package:gui/base/page_render.dart';

import 'base/drop_area.dart';

const DEBUG_SHOW_LIVE_TREE = false;
const DEBUG_TIE_LIST = false;

WebSocketChannel? OutChannelWs;
bool isOnDropEvent = false;
String resourceUrl = '';

bool selectMe(String hash) {
  final message = {'type': 'select', 'hash': hash};
  OutChannelWs?.sink.add(jsonEncode(message));
  return true;
}

bool focusMe(String hash) {
  final message = {'type': 'focus', 'hash': hash};
  OutChannelWs?.sink.add(jsonEncode(message));
  return true;
}

bool blurMe(String hash) {
  final message = {'type': 'blur', 'hash': hash};
  OutChannelWs?.sink.add(jsonEncode(message));
  return false;
}

String fixResourceUrl(String resHash) {
  return resHash.replaceFirst('resource:', resourceUrl);
}

void deleteMe(String hash) {
  final message = {'type': 'delete', 'hash': hash};
  OutChannelWs?.sink.add(jsonEncode(message));
}

void duplicateMe(String hash) {
  final message = {'type': 'duplicate', 'hash': hash};
  OutChannelWs?.sink.add(jsonEncode(message));
}

void sortMe(String hash) {
  final message = {'type': 'sort', 'hash': hash};
  OutChannelWs?.sink.add(jsonEncode(message));
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  onWindowLoaded(() {
    print('🔥 WINDOW LOADED');
  });

  // Disable the browser's default right-click context menu.
  // This allows Flutter to handle right-click events.
  BrowserContextMenu.disableContextMenu();

  runApp(AppRoot(design: appDesign));
}

class AppRoot extends StatelessWidget {
  final AppDesignConfig design;

  const AppRoot({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: design,
      builder: (context, _) {
        return Listener(
          // behavior: HitTestBehavior.translucent,
          // onPointerDown: (event) {
          //   if (event.kind == PointerDeviceKind.mouse) {
          //     print(
          //       '🔥 MOUSE DOWN: '
          //       '${event.position.dx}, ${event.position.dy}',
          //     );
          //   }
          // },
          //
          // onPointerUp: (event) {
          //   if (event.kind == PointerDeviceKind.mouse) {
          //     print(
          //       '🔥 MOUSE UP: '
          //       '${event.position.dx}, ${event.position.dy}',
          //     );
          //   }
          // },

          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: design.theme,
            home: const MyHomePage(title: 'So far, so Good'),
            builder: (context, child) {
              return Directionality(
                textDirection: design.textDirection,
                child: child!,
              );
            },
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // screenshot key
  final GlobalKey _screenshotKey = GlobalKey();
  StatelessWidget? _sample;

  static const List<int> candidatePorts = [
    38473,
    39127,
    40291,
    41753,
    42819,
    43967,
    45103,
    46241,
    47389,
    48527,
  ];

  // rust server ip
  static const String serverHost = '127.0.0.1';

  // WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  int? _connectedPort;

  bool _connecting = false;

  String _status = 'connecting...';

  final StringBuffer _receivedText = StringBuffer();
  final Map<String, Widget> widgets = {};

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  RemoteScaffold? _scaffold;

  Future<void> _connectToServer() async {
    _scaffold = null;

    if (_connecting) return;

    setState(() {
      _connecting = true;
      _connectedPort = null;
      _status = 'Finding server ...';
      _receivedText.clear();
    });

    for (final port in candidatePorts) {
      if (!mounted) return;

      setState(() {
        _status = 'Detect available ports $port...';
      });

      WebSocketChannel? channel;

      try {
        channel = WebSocketChannel.connect(Uri.parse('ws://$serverHost:$port'));
        debugPrint(Uri.parse('ws://$serverHost:$port').toString());

        // timeout to reconnect
        await channel.ready.timeout(const Duration(milliseconds: 800));

        // connect success
        OutChannelWs = channel;

        setState(() {
          _connectedPort = port;
          _connecting = false;
          _status = 'Connected to: $serverHost:$port';
        });

        _subscription = channel.stream.listen(
          (message) {
            if (!mounted) return;

            String text;

            if (message is String) {
              text = message;
            } else if (message is List<int>) {
              text = utf8.decode(message, allowMalformed: true);
            } else {
              text = message.toString();
            }

            try {
              final dynamic payload = jsonDecode(text);

              if (payload is Map<String, dynamic>) {
                // JSON object
                final type = payload['type'];
                final data = payload['data'];
                // print(payload);

                switch (type) {
                  case 'SCREENSHOT':
                    takeScreenshot();
                    break;
                  case 'SET_RESOURCE_URL':
                    resourceUrl = payload['url'];
                    break;
                  case 'DROP_START':
                    isOnDropEvent = true;
                    break;
                  case 'DROP_END':
                    isOnDropEvent = false;
                    break;
                  case 'UPDATE_DESIGN':
                    setState(() {
                      if (data['isDark'] != null) {
                        appDesign.setDarkMode(data['isDark']);
                      }
                      if (data['isRTL'] != null) {
                        appDesign.setRTL(data['isRTL']);
                      }
                      if (data['color'] != null) {
                        appDesign.setMainColor(parseColorSafe(data['color']));
                      }
                      if (data['lang'] != null) {
                        appDesign.setLanguage(data['lang']);
                      }
                      if (data['country'] != null) {
                        appDesign.setLanguage(data['country']);
                      }
                    });
                    break;

                  case 'FULL_RENDER':
                    // handle full render
                    setState(() {
                      nodeStore.clear();
                      _scaffold = RemoteScaffold.fromJson(data);
                    });
                    // var x = LiveNode.fromJson(data['children']['visual'][2]);
                    // setState(() {
                    //   _sample = renderNode(x.hash) as StatelessWidget?;
                    // });
                    //_scaffold
                    // x.updateForce();

                    break;
                  case 'UPDATE_PROP_ON_SINGLE_COMPONENT':
                    if (data['payload'] is Map) {
                      data['payload'].forEach((key, value) {
                        nodeStore.updateProp(
                          data['hash_id'].toString(),
                          key,
                          value,
                        );
                      });
                    }
                    break;
                  default:
                    // unknown type
                    break;
                }
              } else if (payload is List) {
                // json array
                print('Received JSON array: $payload');
              }
            } on FormatException {
              // Not json
              print('Invalid JSON: $text');
            }

            // setState(() {
            //   _receivedText.write(text);
            //   _receivedText.write('\n');
            // });
          },
          onError: (Object error) {
            if (!mounted) return;

            setState(() {
              _status = 'Error WebSocket: $error';
            });
          },
          onDone: () {
            if (!mounted) return;

            setState(() {
              _status = 'Disconnect';
              _connectedPort = null;
            });
          },
        );

        // can't find go next port
        return;
      } catch (e) {
        debugPrint('WebSocket port $port failed: $e');

        try {
          await channel?.sink.close();
        } catch (_) {}

        // go next port
      }
    }

    if (!mounted) return;

    setState(() {
      _connecting = false;
      _status = 'All port non connectable.';
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    OutChannelWs?.sink.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _connectedPort != null;

    const scrollable = false;

    // print(_scaffold);

    return RepaintBoundary(
      key: _screenshotKey,
      child: _scaffold ?? Scaffold(body: Center(child: DropArea())),
    );
  }

  /// screenshot data
  Future<void> takeScreenshot() async {
    try {
      final boundary =
          _screenshotKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 2.0);

      final byteData = await image.toByteData(format: ImageByteFormat.png);

      if (byteData == null) {
        print('Failed to create PNG');
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      sendScreenshot(bytes);
      // print('==========================');
      // print('Screenshot created!');
      // print('Bytes: ${bytes.length}');
      // print('Width: ${image.width}');
      // print('Height: ${image.height}');
      // print('==========================');
    } catch (e, stackTrace) {
      print('Screenshot error: $e');
      print(stackTrace);
    }
  }
}

// Scaffold(
//   appBar: null,
//   body: SingleChildScrollView(
//     physics: scrollable
//         ? AlwaysScrollableScrollPhysics()
//         : NeverScrollableScrollPhysics(),
//     child: Column(
//       children: [
//         Text("hello1"),
//         Text("world"),
//         Text(
//           "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.",
//         ),
//         Text(
//           "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.",
//         ),
//         Text(
//           "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.",
//         ),
//         Text(
//           "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.",
//         ),
//         Text(
//           "Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.",
//         ),
//         ElevatedButton(
//           onPressed: () {},
//           style: ElevatedButton.styleFrom(
//             shape: CircleBorder(),
//             padding: EdgeInsets.all(20),
//             backgroundColor: Colors.blue, // <-- Button color
//             foregroundColor: Colors.red, // <-- Splash color
//           ),
//           child: Icon(Icons.menu, color: Colors.white),
//         ),
//       ],
//     ),
//   ),
// );



void sendScreenshot(Uint8List screenshot) {
  const signature = 'SCRN';

  final signatureBytes = Uint8List.fromList(
    signature.codeUnits,
  );

  final packet = Uint8List(
    signatureBytes.length + screenshot.length,
  );

  packet.setRange(
    0,
    signatureBytes.length,
    signatureBytes,
  );

  packet.setRange(
    signatureBytes.length,
    packet.length,
    screenshot,
  );

  OutChannelWs?.sink.add(packet);
}