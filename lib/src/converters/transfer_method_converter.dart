
import 'package:html_editor_enhanced/src/model/transfer_method.dart';
import 'package:json_annotation/json_annotation.dart';

class TransferMethodConverter implements JsonConverter<TransferMethod?, String?> {
  const TransferMethodConverter();

  @override
  TransferMethod? fromJson(String? json) {
    return json != null ? TransferMethod(json): null;
  }

  @override
  String? toJson(TransferMethod? object) {
    return object?.value;
  }
}