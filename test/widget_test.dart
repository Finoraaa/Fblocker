import 'package:flutter_test/flutter_test.dart';
import 'package:fblocker/main.dart';
import 'package:fblocker/services/blocker_service.dart';

void main() {
  testWidgets('Finora Fblocker smoke test', (WidgetTester tester) async {
    final service = BlockerService();
    await tester.pumpWidget(FinoraApp(service: service));

    expect(find.text('FINORA'), findsOneWidget);
    expect(find.text('BLOCKER'), findsOneWidget);
  });
}
