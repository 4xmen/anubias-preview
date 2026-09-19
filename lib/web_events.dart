import 'dart:js_interop';
import 'package:web/web.dart' as web;

void onWindowLoaded(void Function() callback) {
  if (web.document.readyState == 'complete') {
    callback();
    return;
  }

  web.window.addEventListener(
    'load',
    callback.toJS,
  );
}

