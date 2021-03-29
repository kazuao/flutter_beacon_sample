import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';

import 'commons.dart';

class BeaconReceive extends StatefulWidget {
  @override
  _BeaconReceiveState createState() => _BeaconReceiveState();
}

class _BeaconReceiveState extends State<BeaconReceive>
    with WidgetsBindingObserver {
  Commons common = Commons();

  final StreamController<BluetoothState> streamController = StreamController();
  StreamSubscription<BluetoothState> _streamBluetooth;
  StreamSubscription<RangingResult> _streamRanging;
  final _regionBeacons = <Region, List<Beacon>>{};
  final _beacons = <Beacon>[];
  bool authorizationStatusOk = false;
  bool locationServiceEnabled = false;
  bool bluetoothEnabled = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    listeningState();
  }

  listeningState() async {
    print('Listening to bluetooth state');
    _streamBluetooth = flutterBeacon
        .bluetoothStateChanged()
        .listen((BluetoothState state) async {
      print('BluetoothState = $state');
      streamController.add(state);

      switch (state) {
        case BluetoothState.stateOn:
          initScanBeacon();
          break;
        case BluetoothState.stateOff:
          await pauseScanBeacon();
          await checkAllRequirements();
          break;
      }
    });
  }

  checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    final bluetoothEnabled = bluetoothState == BluetoothState.stateOn;
    final authorizationStatus = await flutterBeacon.authorizationStatus;
    final authorizationStatusOk =
        authorizationStatus == AuthorizationStatus.allowed ||
            authorizationStatus == AuthorizationStatus.always;
    final locationServiceEnabled =
        await flutterBeacon.checkLocationServicesIfEnabled;
    print(bluetoothState);
    print(bluetoothEnabled);
    print(authorizationStatus);
    print(authorizationStatusOk);
    print(locationServiceEnabled);
    setState(() {
      this.authorizationStatusOk = authorizationStatusOk;
      this.locationServiceEnabled = locationServiceEnabled;
      this.bluetoothEnabled = bluetoothEnabled;
    });
  }

  initScanBeacon() async {
    try {
      await flutterBeacon.initializeAndCheckScanning;
      await checkAllRequirements();
    } on PlatformException catch (e) {
      print(e);
    }

    if (!authorizationStatusOk ||
        !locationServiceEnabled ||
        !bluetoothEnabled) {
      print('RETURNED, authorizationStatusOk=$authorizationStatusOk, '
          'locationServiceEnabled=$locationServiceEnabled, '
          'bluetoothEnabled=$bluetoothEnabled');
      return;
    }

    String iosDeviceInfo = await common.getIosDeviceInfo();
    print(iosDeviceInfo);
    final regions = [
      Region(identifier: 'Apple Airlocate', proximityUUID: iosDeviceInfo),
    ];

    if (_streamRanging != null) {
      if (_streamRanging.isPaused) {
        _streamRanging.resume();
        return;
      }
    }

    _streamRanging =
        flutterBeacon.ranging(regions).listen((RangingResult result) {
      print(result);
      if (result != null && mounted) {
        setState(() {
          _regionBeacons[result.region] = result.beacons;
          _beacons.clear();
          _regionBeacons.values.forEach((list) {
            _beacons.addAll(list);
          });

          _beacons.sort(_compareParameters);
        });
      }
    });
  }

  pauseScanBeacon() async {
    _streamRanging?.pause();
    if (_beacons.isNotEmpty) {
      setState(() {
        _beacons.clear();
      });
    }
  }

  int _compareParameters(Beacon a, Beacon b) {
    int compare = a.proximityUUID.compareTo(b.proximityUUID);

    if (compare == 0) {
      compare = a.major.compareTo(b.major);
    }

    if (compare == 0) {
      compare = a.minor.compareTo(b.minor);
    }

    return compare;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print('AppLifecycleState = $state');
    if (state == AppLifecycleState.resumed) {
      if (_streamBluetooth != null && _streamBluetooth.isPaused) {
        _streamBluetooth.resume();
      }

      await checkAllRequirements();
      if (authorizationStatusOk && locationServiceEnabled && bluetoothEnabled) {
        await initScanBeacon();
      } else {
        await pauseScanBeacon();
        await checkAllRequirements();
      }
    } else if (state == AppLifecycleState.paused) {
      _streamBluetooth?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    streamController?.close();
    _streamRanging.cancel();
    _streamBluetooth.cancel();
    flutterBeacon.close;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon Receive'),
        centerTitle: false,
        actions: [
          if (!authorizationStatusOk)
            IconButton(
              icon: Icon(Icons.portable_wifi_off),
              color: Colors.red,
              onPressed: () async => await flutterBeacon.requestAuthorization,
            ),
          if (!locationServiceEnabled)
            IconButton(
              icon: Icon(Icons.location_off),
              color: Colors.red,
              onPressed: () {},
            ),
          StreamBuilder(
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                final state = snapshot.data;

                if (state == BluetoothState.stateOn) {
                  return IconButton(
                    icon: Icon(Icons.bluetooth_connected),
                    color: Colors.lightBlueAccent,
                    onPressed: () async => {},
                  );
                }

                if (state == BluetoothState.stateOff) {
                  return IconButton(
                    icon: Icon(Icons.bluetooth),
                    color: Colors.red,
                    onPressed: () async => {},
                  );
                }

                return IconButton(
                  icon: Icon(Icons.bluetooth_disabled),
                  color: Colors.grey,
                  onPressed: () async => {},
                );
              }
              return SizedBox.shrink();
            },
            stream: streamController.stream,
            initialData: BluetoothState.stateUnknown,
          ),
        ],
      ),
      body: _beacons == null || _beacons.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: _beacons.map((beacon) {
                  return ListTile(
                    title: Text(beacon.proximityUUID),
                    subtitle: new Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Flexible(
                            child: Text(
                                'Major: ${beacon.major}\nMinor: ${beacon.minor}',
                                style: TextStyle(fontSize: 13.0)),
                            flex: 1,
                            fit: FlexFit.tight),
                        Flexible(
                            child: Text(
                                'Accuracy: ${beacon.accuracy}m\nRSSI: ${beacon.rssi}',
                                style: TextStyle(fontSize: 13.0)),
                            flex: 2,
                            fit: FlexFit.tight)
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
