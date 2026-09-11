import 'package:ai_job_assistant/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires secure backend configuration before showing private data', (tester) async {
    await tester.pumpWidget(const AiJobAssistantApp());

    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
