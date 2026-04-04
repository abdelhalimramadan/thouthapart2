// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_token_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceTokenRequest _$DeviceTokenRequestFromJson(Map<String, dynamic> json) =>
    _DeviceTokenRequest(
      fcmToken: json['fcmToken'] as String,
      deviceType: json['deviceType'] as String,
      deviceModel: json['deviceModel'] as String?,
      osVersion: json['osVersion'] as String?,
    );

Map<String, dynamic> _$DeviceTokenRequestToJson(_DeviceTokenRequest instance) =>
    <String, dynamic>{
      'fcmToken': instance.fcmToken,
      'deviceType': instance.deviceType,
      'deviceModel': instance.deviceModel,
      'osVersion': instance.osVersion,
    };
