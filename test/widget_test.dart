import 'package:flutter_test/flutter_test.dart';
import 'package:stream/main.dart';

void main() {
  testWidgets('SolarPlantApp arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const SolarPlantApp());
    await tester.pump();
    expect(find.byType(SolarPlantApp), findsOneWidget);
  });
}
