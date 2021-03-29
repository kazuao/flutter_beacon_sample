import 'package:device_info/device_info.dart';

class Commons {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  // UUIDの取得
  Future<String> getIosDeviceInfo() async {
    final iosDeviceInfo = await deviceInfo.iosInfo;
    return iosDeviceInfo.identifierForVendor;
  }
}
