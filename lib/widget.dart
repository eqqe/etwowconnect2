import 'package:etwowconnect2/providers.dart';
import 'package:etwowconnect2/toast.dart';
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

    var status = "";

    connectionState.whenData((state) {
      if (state.connectionState == DeviceConnectionState.connected) {
        status = 'Connected';
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
        await send([0x05, 0x05, 0x01]);
        toast("Locked");
      } else {
        toast("Cannot lock as speed is not 0");
      }
    }

    lockOff() async {
      await send([0x05, 0x05, 0x00]);
      toast("Lock removed");
    }

    lightOn() async {
      await send([0x06, 0x05, 0x01]);
      toast("Lights on");
    }

    lightOff() async {
      await send([0x06, 0x05, 0x00]);
      toast("Lights off");
    }

    setSpeed(int mode) async {
      await send([0x02, 0x05, mode]);
      toast("Speed set to L$mode mode");
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Twow GT SE Unofficial App'),
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
                  onPressed: lockOff,
                  iconSize: 120,
                ),
                IconButton(
                  icon: const Icon(Icons.lock),
                  color: Colors.red,
                  tooltip: 'Lock',
                  onPressed: lockOn,
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
                  onPressed: lightOff,
                  iconSize: 80,
                ),
                IconButton(
                  icon: const Icon(Icons.lightbulb),
                  tooltip: 'Light',
                  onPressed: lightOn,
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
                  onPressed: scooter.mode != null && scooter.mode != 1
                      ? () => setSpeed(1)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '20km/h',
                  color: Colors.blue,
                  onPressed: scooter.mode != null && scooter.mode != 2
                      ? () => setSpeed(2)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '25km/h',
                  color: Colors.yellow,
                  onPressed: scooter.mode != null && scooter.mode != 3
                      ? () => setSpeed(3)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '35km/h',
                  color: Colors.red,
                  onPressed: scooter.mode != null && scooter.mode != 0
                      ? () => setSpeed(0)
                      : null,
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
              scooter.zeroStart != null
                  ? "Zero Start: ${scooter.zeroStart}"
                  : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              scooter.battery != null
                  ? "Battery: ${scooter.battery} %"
                  : "",
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

