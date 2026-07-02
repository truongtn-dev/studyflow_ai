import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_ai/app.dart';
import 'package:studyflow_ai/providers/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    final themeProvider = ThemeProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: const StudyFlowApp(),
      ),
    );
    expect(find.text('StudyFlow AI'), findsOneWidget);
  });
}
