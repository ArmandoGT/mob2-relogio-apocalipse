import 'package:flutter_test/flutter_test.dart';

import 'package:relogio_apocalipse/main.dart';

void main() {
  testWidgets('renderiza a tela inicial do app', (WidgetTester tester) async {
    await tester.pumpWidget(const RelogioApocalipseApp(firebaseEnabled: false));
    await tester.pumpAndSettle();

    expect(find.text('Relógio do Apocalipse'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
