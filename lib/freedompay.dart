
import 'freedompay_platform_interface.dart';

class Freedompay {
  Future<String?> getPlatformVersion() {
    return FreedompayPlatform.instance.getPlatformVersion();
  }
}
