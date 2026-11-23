import 'package:flutter_test/flutter_test.dart';

import 'package:news_byte/app/app.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const NewsByte());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
