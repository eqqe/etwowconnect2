import 'dart:typed_data';
import 'package:etwowconnect2/types.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble/src/discovered_devices_registry.dart';

const testDeviceId = "01:02:03";

class FakeFlutterReactiveBle implements FlutterReactiveBle {
  @override
  Stream<DiscoveredDevice> scanForDevices(
      {required List<Uuid> withServices, ScanMode scanMode = ScanMode.balanced, bool requireLocationServicesEnabled = true}) {
    return Stream.fromIterable([
      DiscoveredDevice(
          id: testDeviceId,
          name: gTName,
          rssi: -50,
          manufacturerData: Uint8List(0),
          serviceData: const {},
          serviceUuids: const [],
          connectable: Connectable.available)
    ]);
  }

  @override
  Stream<ConnectionStateUpdate> connectToDevice(
      {required String id, Map<Uuid, List<Uuid>>? servicesWithCharacteristicsToDiscover, Duration? connectionTimeout}) {
    return Stream.fromIterable([
      const ConnectionStateUpdate(
        connectionState: DeviceConnectionState.connecting,
        deviceId: testDeviceId,
        failure: null,
      ),
      const ConnectionStateUpdate(
        connectionState: DeviceConnectionState.connected,
        deviceId: testDeviceId,
        failure: null,
      ),
    ]);
  }

  @override
  Future<void> writeCharacteristicWithResponse(QualifiedCharacteristic characteristic, {required List<int> value}) {
    if (characteristic.deviceId == testDeviceId && characteristic.characteristicId == writeCharacteristicId[gTName] && value[0] == 0x55) {
      if (value[1] == 0x02 && value[2] == 0x05 && value[3] == 0x02) {
        return Future(() => null);
      }
      else if (value[1] == 0x05 && value[2] == 0x05 && value[3] == 0x01) {
        return Future(() => null);
      }
    }
    throw UnimplementedError();
  }

  @override
  LogLevel logLevel = LogLevel.verbose;

  @override
// TODO: implement characteristicValueStream
  Stream<CharacteristicValue> get characteristicValueStream => throw UnimplementedError();

  @override
  Future<void> clearGattCache(String deviceId) {
    throw UnimplementedError();
  }

  @override
  Stream<ConnectionStateUpdate> connectToAdvertisingDevice(
      {required String id,
      required List<Uuid> withServices,
      required Duration prescanDuration,
      Map<Uuid, List<Uuid>>? servicesWithCharacteristicsToDiscover,
      Duration? connectionTimeout}) {
    // TODO: implement connectToAdvertisingDevice
    throw UnimplementedError();
  }

  @override
// TODO: implement connectedDeviceStream
  Stream<ConnectionStateUpdate> get connectedDeviceStream => throw UnimplementedError();

  @override
  Future<void> deinitialize() {
    // TODO: implement deinitialize
    throw UnimplementedError();
  }

  @override
  Future<void> discoverAllServices(String deviceId) {
    // TODO: implement discoverAllServices
    throw UnimplementedError();
  }

  @override
  Future<List<DiscoveredService>> discoverServices(String deviceId) {
    // TODO: implement discoverServices
    throw UnimplementedError();
  }

  @override
  Future<List<Service>> getDiscoveredServices(String deviceId) {
    // TODO: implement getDiscoveredServices
    throw UnimplementedError();
  }

  @override
  Future<void> initialize() {
    // TODO: implement initialize
    throw UnimplementedError();
  }

  @override
  Future<List<int>> readCharacteristic(QualifiedCharacteristic characteristic) {
    // TODO: implement readCharacteristic
    throw UnimplementedError();
  }

  @override
  Future<void> requestConnectionPriority({required String deviceId, required ConnectionPriority priority}) {
    // TODO: implement requestConnectionPriority
    throw UnimplementedError();
  }

  @override
  Future<int> requestMtu({required String deviceId, required int mtu}) {
    // TODO: implement requestMtu
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Characteristic>> resolve(QualifiedCharacteristic characteristic) {
    // TODO: implement resolve
    throw UnimplementedError();
  }

  @override
  Future<Characteristic> resolveSingle(QualifiedCharacteristic characteristic) {
    // TODO: implement resolveSingle
    throw UnimplementedError();
  }

  @override
// TODO: implement scanRegistry
  DiscoveredDevicesRegistryImpl get scanRegistry => throw UnimplementedError();

  @override
// TODO: implement status
  BleStatus get status => throw UnimplementedError();

  @override
// TODO: implement statusStream
  Stream<BleStatus> get statusStream => throw UnimplementedError();

  @override
  Stream<List<int>> subscribeToCharacteristic(QualifiedCharacteristic characteristic) {
    // TODO: implement subscribeToCharacteristic
    throw UnimplementedError();
  }

  @override
  Future<void> writeCharacteristicWithoutResponse(QualifiedCharacteristic characteristic, {required List<int> value}) {
    // TODO: implement writeCharacteristicWithoutResponse
    throw UnimplementedError();
  }
}

mixin FakeToastMixin {
  void toast(message) {}
}