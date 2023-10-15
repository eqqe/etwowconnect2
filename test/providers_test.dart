import 'package:etwowconnect2/providers.dart';
import 'package:etwowconnect2/types.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake.dart';



class ScooterNotifierTester extends ScooterNotifier with FakeToastMixin {
  ScooterNotifierTester(FakeFlutterReactiveBle ble) : super(ble: ble);
}

void main() {
  group('ScooterNotifierTester send', () {
    test('set speed', () async {
      ScooterNotifierTester scooterNotifierTester = prepare();
      scooterNotifierTester.state.connectionState = DeviceConnectionState.connected;
      scooterNotifierTester.state.deviceName = gTName;
      scooterNotifierTester.state.deviceId = testDeviceId;
      final res = await scooterNotifierTester.setSpeed(2);
      expect(res, true);
    });

    test('fail set speed disconnected', () async {
      ScooterNotifierTester scooterNotifierTester = prepare();
      scooterNotifierTester.state.connectionState = DeviceConnectionState.disconnected;
      scooterNotifierTester.state.deviceName = gTName;
      scooterNotifierTester.state.deviceId = testDeviceId;
      expect(await scooterNotifierTester.setSpeed(2), false);
    });
    test('fail set speed device id', () async {
      ScooterNotifierTester scooterNotifierTester = prepare();
      scooterNotifierTester.state.connectionState = DeviceConnectionState.connected;
      scooterNotifierTester.state.deviceName = gTName;
      scooterNotifierTester.state.deviceId = "fail";
      expect(await scooterNotifierTester.setSpeed(2), false);
    });
  });

  group('ScooterNotifierTester updateValues', () {
    test('read mode lights, locked, zero start', () async {
      ScooterNotifierTester scooterNotifierTester = prepare();
      scooterNotifierTester.updateValues([0x3, 2]);
      expect(scooterNotifierTester.state.mode, 2);
      expect(scooterNotifierTester.state.zeroStart, false);
      expect(scooterNotifierTester.state.lights, false);
      expect(scooterNotifierTester.state.locked, false);

      scooterNotifierTester.updateValues([0x3, 0xf1]);
      expect(scooterNotifierTester.state.mode, 1);
      expect(scooterNotifierTester.state.zeroStart, true);
      expect(scooterNotifierTester.state.lights, true);
      expect(scooterNotifierTester.state.locked, true);

      scooterNotifierTester.updateValues([0x3, 0xe0]);
      expect(scooterNotifierTester.state.mode, 0);
      expect(scooterNotifierTester.state.zeroStart, true);
      expect(scooterNotifierTester.state.lights, false);
      expect(scooterNotifierTester.state.locked, true);
    });

    test('read instant speed 26.0 km/h', () async {
      ScooterNotifierTester scooterNotifierTester = prepare();
      scooterNotifierTester.updateValues([0x1, 5, 1]);
      expect(scooterNotifierTester.state.speed, 260);
    });

    test('reset', () async {
      ScooterNotifierTester scooterNotifierTester = prepare();
      scooterNotifierTester.state.deviceName = gTName;
      scooterNotifierTester.state.deviceId = testDeviceId;
      scooterNotifierTester.state.speed = 24;
      scooterNotifierTester.state.locked = false;
      scooterNotifierTester.state.lights = true;
      scooterNotifierTester.state.zeroStart = false;
      scooterNotifierTester.state.mode = 0;
      scooterNotifierTester.reset();
      expect(scooterNotifierTester.state.deviceName, gTName);
      expect(scooterNotifierTester.state.deviceId, testDeviceId);
      expect(scooterNotifierTester.state.speed, null);
      expect(scooterNotifierTester.state.locked, null);
      expect(scooterNotifierTester.state.lights, null);
      expect(scooterNotifierTester.state.zeroStart, null);
      expect(scooterNotifierTester.state.mode, null);
    });

    test('lock if speed 0', () async {
      ScooterNotifierTester scooterNotifierTester = prepare();
      scooterNotifierTester.state.connectionState = DeviceConnectionState.connected;
      scooterNotifierTester.state.deviceName = gTName;
      scooterNotifierTester.state.deviceId = testDeviceId;
      expect(await scooterNotifierTester.lockOn(), false);
      scooterNotifierTester.state.speed = 50;
      expect(await scooterNotifierTester.lockOn(), false);
      scooterNotifierTester.state.speed = 0;
      expect(await scooterNotifierTester.lockOn(), true);
    });
  });
}

ScooterNotifierTester prepare() {
  WidgetsFlutterBinding.ensureInitialized();
  final ble = FakeFlutterReactiveBle();

  final scooterNotifierTester = ScooterNotifierTester(ble);
  return scooterNotifierTester;
}
