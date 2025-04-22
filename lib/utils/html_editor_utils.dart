
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HtmlEditorUtils {
  static HtmlEditorUtils? _instance;

  HtmlEditorUtils._();

  factory HtmlEditorUtils() => _instance ??= HtmlEditorUtils._();

  Future<String> loadAssetAsString(String path) async {
    try {
      return rootBundle.loadString(path);
    } catch (e) {
      debugPrint('HtmlEditorUtils::loadAssetAsString:Exception = $e');
      return '';
    }
  }

  Future<void> loadAsset(String path) async {
    try {
      await rootBundle.load(path);
    } catch (e) {
      debugPrint('HtmlEditorUtils::loadAsset:Exception = $e');
    }
  }
}