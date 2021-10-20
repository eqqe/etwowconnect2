import 'dart:async';
import 'dart:typed_data';
import 'package:etwowconnect2/scooter.dart';
import 'package:etwowconnect2/types.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble/src/discovered_devices_registry.dart';

const testDeviceId = "01:02:03";

final testScooterInfo = ScooterInfo.from(2, false, true, true, 10, 2, 70, 20);

class FakeFlutterReactiveBle implements FlutterReactiveBle {
  final scooterInfo = ScooterInfo.from(testScooterInfo.mode, testScooterInfo.locked, testScooterInfo.zeroStart, testScooterInfo.lights,
      testScooterInfo.odo, testScooterInfo.trip, testScooterInfo.battery, testScooterInfo.speed);
  StreamController<List<int>>? _characteristicsStreamController;
  StreamController<ConnectionStateUpdate>? connectionStateController;

  feedFakeCharacteristicsStreams() async {
    while (true) {
      _characteristicsStreamController?.add([1, scooterInfo.speed!, 0]);
      _characteristicsStreamController?.add([2, scooterInfo.battery!]);
      if (scooterInfo.lights! || scooterInfo.locked! || scooterInfo.zeroStart!) {
        final value =
            (scooterInfo.zeroStart! ? 1 : 0) << 3 | 1 << 2 | (scooterInfo.locked! ? 1 : 0) << 1 | (scooterInfo.lights! ? 1 : 0);
        _characteristicsStreamController?.add([3, value * 0x10 + scooterInfo.mode!]);
      }
      _characteristicsStreamController?.add([4, 0, scooterInfo.trip!]);
      _characteristicsStreamController?.add([5, 0, 0, 0, 0, scooterInfo.odo!]);

      await Future.delayed(const Duration(milliseconds: 1));
    }
  }


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
    connectionStateController = StreamController<ConnectionStateUpdate>();
    connectionStateController!.add(getFakeConnectionStateUpdate(DeviceConnectionState.connecting));
    connectionStateController!.add(getFakeConnectionStateUpdate(DeviceConnectionState.connected));
    return connectionStateController!.stream;
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(QualifiedCharacteristic characteristic) {
    _characteristicsStreamController = StreamController<List<int>>();
    return _characteristicsStreamController!.stream;
  }

  @override
  Future<void> writeCharacteristicWithResponse(QualifiedCharacteristic characteristic, {required List<int> value}) {
    if (characteristic.deviceId == testDeviceId && characteristic.characteristicId == writeCharacteristicId[gTName] && value[0] == 0x55) {
      if (value[1] == 2 && value[2] == 5 && [0, 1, 2, 3].contains(value[3])) {
        scooterInfo.mode = value[3];
        return Future(() => null);
      } else if (value[1] == 5 && value[2] == 5 && [0, 1].contains(value[3])) {
        scooterInfo.locked = value[3] == 1;
        return Future(() => null);
      }
      else if (value[1] == 6 && value[2] == 5 && [0, 1].contains(value[3])) {
        scooterInfo.lights = value[3] == 1;
        return Future(() => null);
      }
    }
    throw UnimplementedError();
  }

  @override
  LogLevel logLevel = LogLevel.verbose;

  @override
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
  Future<void> writeCharacteristicWithoutResponse(QualifiedCharacteristic characteristic, {required List<int> value}) {
    // TODO: implement writeCharacteristicWithoutResponse
    throw UnimplementedError();
  }
}

ConnectionStateUpdate getFakeConnectionStateUpdate(DeviceConnectionState deviceConnectionState) {
  return ConnectionStateUpdate(
    connectionState: deviceConnectionState,
    deviceId: testDeviceId,
    failure: null,
  );
}