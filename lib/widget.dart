import 'package:etwowconnect2/providers.dart';
import 'package:etwowconnect2/toast.dart';
import 'package:etwowconnect2/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

class ScooterWidget extends ConsumerWidget {
  const ScooterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(bleScanner);
    final scooter = ref.watch(scooterProvider);
    final scooterProviderNotifier = ref.watch(scooterProvider.notifier);
    final send = scooterProviderNotifier.send;

    var status = "Scanning $gTName or $gTSportName";
    var connected = false;

    connectionState.whenData((state) {
      if (state.connectionState == DeviceConnectionState.connected) {
        status = 'Connected';
        connected = true;
      } else if (state.connectionState == DeviceConnectionState.connecting) {
        status = 'Connecting';
      } else if (state.connectionState == DeviceConnectionState.disconnecting) {
        status = 'Disconnecting';
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        status = 'Disconnected';
      }
    });

    lockOn() async {
      if (scooter.speed == 0) {
        if (await send([0x05, 0x05, 0x01])) {
          toast("Locked");
        }
      } else {
        toast("Cannot lock as speed is not 0");
      }
    }

    lockOff() async {
      if (await send([0x05, 0x05, 0x00])) {
        toast("Lock removed");
      }
    }

    lightOn() async {
      if (await send([0x06, 0x05, 0x01])) {
        toast("Lights on");
      }
    }

    lightOff() async {
      if (await send([0x06, 0x05, 0x00])) {
        toast("Lights off");
      }
    }

    setSpeed(int mode) async {
      if (await send([0x02, 0x05, mode])) {
        toast("Speed set to L$mode mode");
      }
    }

    const QuickActions quickActions = QuickActions();
    quickActions.initialize((shortcutType) async {
      switch (shortcutType) {
        case 'action_lock':
          await lockOn();
          break;
        case 'action_unlock':
          await lockOff();
          break;
        case 'action_set_speed_0':
          await setSpeed(0);
          break;
        case 'action_set_speed_2':
          await setSpeed(2);
          break;
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'action_lock', localizedTitle: 'lock 🔒', icon: "ic_launcher"),
      const ShortcutItem(type: 'action_unlock', localizedTitle: 'unlock 🔓', icon: "ic_launcher"),
      const ShortcutItem(type: 'action_set_speed_2', localizedTitle: '20 km/h ⚡️', icon: "ic_launcher"),
      const ShortcutItem(type: 'action_set_speed_0', localizedTitle: '⚡️⚡️⚡️', icon: "ic_launcher"),
    ]);
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Twow GT SE & Sport Unofficial App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.lock_open),
                  color: Colors.green,
                  tooltip: 'Lock',
                  onPressed: connected ? lockOff : null,
                  iconSize: 120,
                ),
                IconButton(
                  icon: const Icon(Icons.lock),
                  color: Colors.red,
                  tooltip: 'Lock',
                  onPressed: connected ? lockOn : null,
                  iconSize: 120,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.lightbulb),
                  tooltip: 'Light',
                  color: Colors.yellow,
                  onPressed: connected ? lightOff : null,
                  iconSize: 80,
                ),
                IconButton(
                  icon: const Icon(Icons.lightbulb),
                  tooltip: 'Light',
                  onPressed: connected ? lightOn : null,
                  iconSize: 80,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '6km/h',
                  color: Colors.green,
                  onPressed: scooter.mode != null && scooter.mode != 1 ? () => setSpeed(1) : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '20km/h',
                  color: Colors.blue,
                  onPressed: scooter.mode != null && scooter.mode != 2 ? () => setSpeed(2) : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '25km/h',
                  color: Colors.yellow,
                  onPressed: scooter.mode != null && scooter.mode != 3 ? () => setSpeed(3) : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '35km/h',
                  color: Colors.red,
                  onPressed: scooter.mode != null && scooter.mode != 0 ? () => setSpeed(0) : null,
                  iconSize: 70,
                ),
              ],
            ),
            Text(
              scooter.speed != null ? "Speed: ${scooter.speed! / 10}" : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              scooter.trip != null ? "Trip: ${scooter.trip! / 10}" : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              scooter.odo != null ? "Odometer: ${scooter.odo}" : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              scooter.zeroStart != null ? "Zero Start: ${scooter.zeroStart}" : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              scooter.battery != null ? "Battery: ${scooter.battery} %" : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              status,
              style: const TextStyle(fontSize: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}
