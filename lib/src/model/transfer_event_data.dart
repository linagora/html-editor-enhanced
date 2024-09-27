
import 'package:equatable/equatable.dart';
import 'package:html_editor_enhanced/src/converters/transfer_method_converter.dart';
import 'package:html_editor_enhanced/src/model/transfer_method.dart';
import 'package:html_editor_enhanced/src/model/transfer_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_event_data.g.dart';

/// Data used to communicate between `Dart` and `iframe` in the web
/// All properties that must be here must be declared in EventDataProperties
@JsonSerializable(
  explicitToJson: true,
  includeIfNull: false,
  converters: [
    TransferMethodConverter()
  ]
)
class TransferEventData with EquatableMixin {

  final String id;
  final TransferType type;
  final TransferMethod? method;
  final dynamic data;

  TransferEventData({
    required this.id,
    required this.type,
    this.method,
    this.data
  });

  factory TransferEventData.fromJson(Map<String, dynamic> json) => _$TransferEventDataFromJson(json);

  Map<String, dynamic> toJson() => _$TransferEventDataToJson(this);

  @override
  List<Object?> get props => [id, type, method, data];
}