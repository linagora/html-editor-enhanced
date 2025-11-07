
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart';

class HtmlEditorUtils {
  const HtmlEditorUtils._();

  static Future<String> loadAssetAsString(String path) async {
    try {
      return rootBundle.loadString(path);
    } catch (e) {
      debugPrint('HtmlEditorUtils::loadAssetAsString:Exception = $e');
      return '';
    }
  }

  static Future<void> loadAsset(String path) async {
    try {
      await rootBundle.load(path);
    } catch (e) {
      debugPrint('HtmlEditorUtils::loadAsset:Exception = $e');
    }
  }

  static Map<String, dynamic> convertMessageEventToDataMap(MessageEvent event) {
    final dataRaw = event.data;
    Map<String, dynamic> data = {};

    try {
      if (dataRaw is JSString) {
        data = jsonDecode(dataRaw.toDart);
      } else if (dataRaw is String) {
        data = jsonDecode(dataRaw as String);
      } else {
        debugPrint('HtmlEditorUtils::convertMessageEventToDataMap >> ⚠️ Unknown event data type: ${dataRaw.runtimeType}');
      }
    } catch (e, stack) {
      debugPrint(
        'HtmlEditorUtils::convertMessageEventToDataMap >> ❌ Failed to decode event data: $e\n$stack',
      );
    }

    return data;
  }
}