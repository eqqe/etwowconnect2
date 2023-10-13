import 'package:etwowconnect2/providers.dart';
import 'package:etwowconnect2/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScooterWidget extends ConsumerWidget {
  const ScooterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scooter = ref.watch(scooterProvider);
    final scooterProviderNotifier = ref.watch(scooterProvider.notifier);

    var status = "Scanning $gTName or $gTSportName";
    var connected = false;

    if (scooter.connectionState == DeviceConnectionState.connected) {
      status = 'Connected';
      connected = true;
    } else if (scooter.connectionState == DeviceConnectionState.connecting) {
      status = 'Connecting';
    } else if (scooter.connectionState == DeviceConnectionState.disconnecting) {
      status = 'Disconnecting';
    } else if (scooter.connectionState == DeviceConnectionState.disconnected) {
      status = 'Disconnected';
    }


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
                  onPressed: connected ? scooterProviderNotifier.lockOff : null,
                  iconSize: 120,
                ),
                IconButton(
                  icon: const Icon(Icons.lock),
                  color: Colors.red,
                  tooltip: 'Lock',
                  onPressed: connected ? scooterProviderNotifier.lockOn : null,
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
                  onPressed: connected ? scooterProviderNotifier.lightOff : null,
                  iconSize: 80,
                ),
                IconButton(
                  icon: const Icon(Icons.lightbulb),
                  tooltip: 'Light',
                  onPressed: connected ? scooterProviderNotifier.lightOn : null,
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
                      ? () => scooterProviderNotifier.setSpeed(1)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '20km/h',
                  color: Colors.blue,
                  onPressed: scooter.mode != null && scooter.mode != 2
                      ? () => scooterProviderNotifier.setSpeed(2)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '25km/h',
                  color: Colors.yellow,
                  onPressed: scooter.mode != null && scooter.mode != 3
                      ? () => scooterProviderNotifier.setSpeed(3)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '35km/h',
                  color: Colors.red,
                  onPressed: scooter.mode != null && scooter.mode != 0
                      ? () => scooterProviderNotifier.setSpeed(0)
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
