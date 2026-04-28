import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Picks an ML Kit-friendly [ResolutionPreset] and image format for the
/// current device. Lower-tier devices fall back to medium so 30fps survives.
class CameraCapabilityProbe {
  CameraCapabilityProbe({DeviceInfoPlugin? info})
      : _info = info ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _info;

  Future<ResolutionPreset> selectResolution() async {
    if (Platform.isAndroid) {
      final android = await _info.androidInfo;
      if (android.version.sdkInt < 28) return ResolutionPreset.medium;
      return ResolutionPreset.high;
    }
    if (Platform.isIOS) {
      final ios = await _info.iosInfo;
      final major = int.tryParse(ios.systemVersion.split('.').first) ?? 0;
      return major >= 13 ? ResolutionPreset.high : ResolutionPreset.medium;
    }
    return ResolutionPreset.medium;
  }

  ImageFormatGroup selectFormat() {
    if (Platform.isIOS) return ImageFormatGroup.bgra8888;
    return ImageFormatGroup.nv21;
  }
}
