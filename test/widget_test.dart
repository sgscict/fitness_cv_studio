import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_cv_studio/main.dart';

void main() {
  testWidgets('FitnessCvStudioApp launches and renders navigation destinations', (WidgetTester tester) async {
    await tester.pumpWidget(const FitnessCvStudioApp());
    await tester.pumpAndSettle();

    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('AI Camera CV'), findsOneWidget);
    expect(find.text('CV Sandbox'), findsOneWidget);
    expect(find.text('Exercise Guide'), findsOneWidget);
  });
}
