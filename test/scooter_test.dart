import 'dart:async';

import 'package:etwowconnect2/types.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake.dart';
import 'package:etwowconnect2/scooter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScooterModel', () {
    late ScooterModel scooterModel;
    late FakeFlutterReactiveBle fakeBle;

    setUp(() {
      fakeBle = FakeFlutterReactiveBle();
      scooterModel = ScooterModel(fakeBle);
      scooterModel.deviceName = gTName;
      scooterModel.deviceId = testDeviceId;
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial null', () {
      expect(scooterModel.mode, null);
      expect(scooterModel.speed, null);
      expect(scooterModel.odo, null);
      expect(scooterModel.mode, null);
      expect(scooterModel.locked, null);
      expect(scooterModel.zeroStart, null);
      expect(scooterModel.lights, null);
      expect(scooterModel.trip, null);
      expect(scooterModel.battery, null);
      expect(scooterModel.connectionState, null);
      expect(scooterModel.connected, false);
    });

    test('Lock action should not work before connecting', () async {
      scooterModel.speed = 0;
      bool result = await scooterModel.lock();
      expect(result, false);
    });

    group('scan wait for connected', () {
      setUp(() async {
        scooterModel.scan();
        fakeBle.feedFakeCharacteristicsStreams();
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return scooterModel.speed == null;
        }).timeout(const Duration(milliseconds: 5000));

        expect(scooterModel.speed, testScooterInfo.speed);
        expect(scooterModel.odo, testScooterInfo.odo);
        expect(scooterModel.mode, testScooterInfo.mode);
        expect(scooterModel.locked, testScooterInfo.locked);
        expect(scooterModel.zeroStart, testScooterInfo.zeroStart);
        expect(scooterModel.lights, testScooterInfo.lights);
        expect(scooterModel.trip, testScooterInfo.trip);
        expect(scooterModel.battery, testScooterInfo.battery);
      });
      test('Lock action scanned cannot lock speed not 0', () async {
        expect(await scooterModel.lock(), false);
      });

      test('Lock and unlock when speed 0', () async {
        fakeBle.scooterInfo.speed = 0;
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return !(scooterModel.speed == 0);
        }).timeout(const Duration(milliseconds: 50));
        expect(await scooterModel.lock(), true);
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return !scooterModel.locked!;
        }).timeout(const Duration(milliseconds: 50));
        expect(scooterModel.locked, true);

        expect(await scooterModel.unlock(), true);
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return scooterModel.locked!;
        }).timeout(const Duration(milliseconds: 50));
        expect(scooterModel.locked, false);
      });

      test('Set mode from 2 to 0 and back to 2', () async {
        expect(scooterModel.mode, 2);
        expect(await scooterModel.setMode(0), true);
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return !(scooterModel.mode! == 0);
        }).timeout(const Duration(milliseconds: 50));
        expect(scooterModel.mode, 0);

        expect(await scooterModel.setMode(2), true);
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return !(scooterModel.mode! == 2);
        }).timeout(const Duration(milliseconds: 50));
        expect(scooterModel.mode, 2);
      });

      test('Switch the lights off', () async {
        expect(scooterModel.lights, true);
        expect(await scooterModel.lightOff(), true);
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return scooterModel.lights!;
        }).timeout(const Duration(milliseconds: 50));
        expect(scooterModel.lights, false);
      });

      test('Disconnection', () async {
        fakeBle.connectionStateController?.add(getFakeConnectionStateUpdate(DeviceConnectionState.disconnecting));
        fakeBle.connectionStateController?.add(getFakeConnectionStateUpdate(DeviceConnectionState.disconnected));
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return scooterModel.speed != null;
        }).timeout(const Duration(milliseconds: 50));
        expect(scooterModel.mode, null);
        expect(scooterModel.speed, null);
        expect(scooterModel.odo, null);
        expect(scooterModel.mode, null);
        expect(scooterModel.locked, null);
        expect(scooterModel.zeroStart, null);
        expect(scooterModel.lights, null);
        expect(scooterModel.trip, null);
        expect(scooterModel.connectionState, DeviceConnectionState.disconnected);
        expect(scooterModel.connected, false);
        fakeBle.connectionStateController?.close();
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return scooterModel.speed == null;
        }).timeout(const Duration(milliseconds: 5000));
        expect(scooterModel.speed, testScooterInfo.speed);
      });
    });
  });
}
