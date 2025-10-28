import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'freedompay_platform_interface.dart';

/// An implementation of [FreedompayPlatform] that uses method channels.
class MethodChannelFreedompay extends FreedompayPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('freedompay');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
