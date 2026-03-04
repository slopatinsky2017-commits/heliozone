import 'dart:async';

import '../models/zone_models.dart';
import 'api_service.dart';

class ZoneControlService {
  Future<List<DeviceCommandResult>> applyToZone({
    required Zone zone,
    required List<Device> devices,
    required ZoneCommand command,
    int retries = 1,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final targetDevices = devices.where((d) => zone.deviceIds.contains(d.deviceId)).toList();

    final futures = targetDevices.map((device) => _applyToDevice(device, command, retries, timeout));
    return Future.wait(futures);
  }

  Future<DeviceCommandResult> _applyToDevice(
    Device device,
    ZoneCommand command,
    int retries,
    Duration timeout,
  ) async {
    final api = ApiService(baseUrl: device.baseUrl);

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        await _send(api, command).timeout(timeout);
        return DeviceCommandResult(deviceId: device.deviceId, deviceName: device.name, success: true);
      } catch (e) {
        if (attempt == retries) {
          return DeviceCommandResult(
            deviceId: device.deviceId,
            deviceName: device.name,
            success: false,
            error: e.toString(),
          );
        }
      }
    }

    return DeviceCommandResult(deviceId: device.deviceId, deviceName: device.name, success: false, error: 'unknown');
  }

  Future<void> _send(ApiService api, ZoneCommand c) async {
    if (c.mode != null || c.sunrise != null || c.sunset != null || c.white != null || c.blue != null || c.red != null || c.farRed != null) {
      await api.postControl(
        mode: c.mode,
        sunrise: c.sunrise,
        sunset: c.sunset,
        white: c.white,
        blue: c.blue,
        red: c.red,
        farRed: c.farRed,
      );
    }

    if (c.power != null) {
      await api.setPower(c.power!);
    }
    if (c.ppfdTarget != null) {
      await api.setParTarget(c.ppfdTarget!);
    }
    if (c.dliTarget != null) {
      await api.setDliTarget(c.dliTarget!);
    }
  }
}
