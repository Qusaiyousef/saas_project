import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Load font', () async {
    final data = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    expect(data.lengthInBytes > 0, true);
  });
}
