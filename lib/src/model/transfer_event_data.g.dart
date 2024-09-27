// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_event_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferEventData _$TransferEventDataFromJson(Map<String, dynamic> json) =>
    TransferEventData(
      id: json['id'] as String,
      type: $enumDecode(_$TransferTypeEnumMap, json['type']),
      method:
          const TransferMethodConverter().fromJson(json['method'] as String?),
      data: json['data'],
    );

Map<String, dynamic> _$TransferEventDataToJson(TransferEventData instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'type': _$TransferTypeEnumMap[instance.type]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'method', const TransferMethodConverter().toJson(instance.method));
  writeNotNull('data', instance.data);
  return val;
}

const _$TransferTypeEnumMap = {
  TransferType.toDart: 'toDart',
  TransferType.toIframe: 'toIframe',
};
