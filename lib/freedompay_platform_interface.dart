import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'freedompay_method_channel.dart';

abstract class FreedompayPlatform extends PlatformInterface {
  /// Constructs a FreedompayPlatform.
  FreedompayPlatform() : super(token: _token);

  static final Object _token = Object();

  static FreedompayPlatform _instance = MethodChannelFreedompay();

  /// The default instance of [FreedompayPlatform] to use.
  ///
  /// Defaults to [MethodChannelFreedompay].
  static FreedompayPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FreedompayPlatform] when
  /// they register themselves.
  static set instance(FreedompayPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
