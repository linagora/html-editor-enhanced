import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart';

class WebUtils {
  const WebUtils._();

  static Map<String, dynamic> convertMessageEventToDataMap(MessageEvent event) {
    final dataRaw = event.data;
    Map<String, dynamic> data = {};

    try {
      if (dataRaw is JSString) {
        data = jsonDecode(dataRaw.toDart);
      } else if (dataRaw is String) {
        data = jsonDecode(dataRaw as String);
      } else {
        debugPrint(
          'WebUtils::convertMessageEventToDataMap >> ⚠️ Unknown event data type: ${dataRaw.runtimeType}',
        );
      }
    } catch (e, stack) {
      debugPrint(
        'WebUtils::convertMessageEventToDataMap >> ❌ Failed to decode event data: $e\n$stack',
      );
    }

    return data;
  }
}
