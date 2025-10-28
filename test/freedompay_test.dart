import 'package:flutter_test/flutter_test.dart';
import 'package:freedompay/freedompay.dart';
import 'package:freedompay/freedompay_platform_interface.dart';
import 'package:freedompay/freedompay_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFreedompayPlatform
    with MockPlatformInterfaceMixin
    implements FreedompayPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FreedompayPlatform initialPlatform = FreedompayPlatform.instance;

  test('$MethodChannelFreedompay is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFreedompay>());
  });

  test('getPlatformVersion', () async {
    Freedompay freedompayPlugin = Freedompay();
    MockFreedompayPlatform fakePlatform = MockFreedompayPlatform();
    FreedompayPlatform.instance = fakePlatform;

    expect(await freedompayPlugin.getPlatformVersion(), '42');
  });
}
