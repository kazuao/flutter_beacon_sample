import 'dart:async';

import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';

import 'commons.dart';

class BeaconOutgoing extends StatefulWidget {
  @override
  _BeaconOutgoingState createState() => _BeaconOutgoingState();
}

class _BeaconOutgoingState extends State<BeaconOutgoing> {
  Commons common = Commons();

  final BeaconBroadcast beaconBroadcast = BeaconBroadcast();
  StreamSubscription<bool> _isAdvertisingSubscription;
  BeaconStatus _isTransmissionSupported;
  var _isAdvertising = false;
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  final int majorId = 1;
  final int minorId = 1;

  @override
  void initState() {
    super.initState();

    beaconBroadcast
        .checkTransmissionSupported()
        .then((isTransmissionSupported) {
      setState(() {
        _isTransmissionSupported = isTransmissionSupported;
      });
    });

    _isAdvertisingSubscription =
        beaconBroadcast.getAdvertisingStateChange().listen((isAdvertising) {
      setState(() {
        _isAdvertising = isAdvertising;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_isAdvertisingSubscription != null) {
      _isAdvertisingSubscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beacon Outgoing')),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Is transmission supported?',
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              '$_isTransmissionSupported',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Container(height: 16.0),
            Text(
              'Is beacon started?',
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              '$_isAdvertising',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Container(height: 16.0),
            Container(
              child: ElevatedButton(
                onPressed: () {
                  startBeacon();
                },
                child: Text('START'),
              ),
            ),
            Container(
              child: ElevatedButton(
                onPressed: () {
                  beaconBroadcast.stop();
                },
                child: Text('STOP'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startBeacon() async {
    String iosDeviceInfo = await common.getIosDeviceInfo();
    print(iosDeviceInfo);

    beaconBroadcast
        .setUUID(iosDeviceInfo)
        .setMajorId(majorId)
        .setMinorId(minorId)
        .start();
  }
}
