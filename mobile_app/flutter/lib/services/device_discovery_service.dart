import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';

class DiscoveredDevice {
  const DiscoveredDevice({
    required this.ipAddress,
    required this.hostname,
    required this.deviceName,
  });

  final String ipAddress;
  final String hostname;
  final String deviceName;

  String get baseUrl => 'http://$ipAddress';
}

class DeviceDiscoveryService {
  Future<List<DiscoveredDevice>> discover({Duration timeout = const Duration(seconds: 4)}) async {
    if (kIsWeb) {
      throw UnsupportedError('Use Manual IP on web.');
    }

    final client = MDnsClient();
    await client.start();

    final found = <String, DiscoveredDevice>{};

    try {
      final ptrStream = client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_http._tcp.local'),
      );

      final ptrRecords = await ptrStream.toList().timeout(timeout, onTimeout: () => <PtrResourceRecord>[]);

      for (final ptr in ptrRecords) {
        final serviceInstance = ptr.domainName;

        final srvRecords = await client
            .lookup<SrvResourceRecord>(ResourceRecordQuery.service(serviceInstance))
            .toList()
            .timeout(const Duration(seconds: 2), onTimeout: () => <SrvResourceRecord>[]);

        for (final srv in srvRecords) {
          final target = srv.target;

          final aRecords = await client
              .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(target))
              .toList()
              .timeout(const Duration(seconds: 2), onTimeout: () => <IPAddressResourceRecord>[]);

          for (final a in aRecords) {
            final instanceName = serviceInstance.split('._http._tcp.local').first;
            final isHelioZone = serviceInstance.toLowerCase().contains('heliozone') ||
                target.toLowerCase().contains('heliozone') ||
                instanceName.toLowerCase().contains('heliozone');

            if (!isHelioZone) {
              continue;
            }

            final device = DiscoveredDevice(
              ipAddress: a.address.address,
              hostname: target,
              deviceName: instanceName.isEmpty ? 'HelioZone' : instanceName,
            );

            found[device.ipAddress] = device;
          }
        }
      }

      if (found.isEmpty) {
        found['heliozone.local'] = const DiscoveredDevice(
          ipAddress: 'heliozone.local',
          hostname: 'heliozone.local',
          deviceName: 'HelioZone',
        );
      }

      return found.values.toList()
        ..sort((a, b) => a.deviceName.toLowerCase().compareTo(b.deviceName.toLowerCase()));
    } finally {
      client.stop();
    }
  }
}
