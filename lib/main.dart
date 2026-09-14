import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gui/base/parsers.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:gui/base/config.dart';
import 'package:gui/base/theme.dart';
import 'package:gui/base/ui_render.dart';
import 'package:gui/base/page_render.dart';

import 'base/drop_area.dart';


WebSocketChannel? OutChannelWs;

bool selectMe( String hash ){

  final message = {
    'type': 'select',
    'hash': hash,
  };

  OutChannelWs?.sink.add(jsonEncode(message));
  return true;
}
void main() {
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: design.theme,
          home: const MyHomePage(title: 'So far, so Good'),
          builder: (context, child) {
            return Directionality(
              textDirection: design.textDirection,
              child: child!,
            );
          },
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

    return _scaffold ??
        Scaffold(body: Center(
            child: DropArea(),
        ));
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
