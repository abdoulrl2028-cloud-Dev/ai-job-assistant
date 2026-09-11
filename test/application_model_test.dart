import 'package:ai_job_assistant/application_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses job application data returned by Supabase', () {
    final application = JobApplication.fromJson({
      'id': 'b3e1e233-f52f-4ac5-a674-e5bf5c89b865',
      'company': 'Acme',
      'role': 'Flutter Developer',
      'status': 'interview',
      'created_at': '2026-09-11T12:00:00.000Z',
    });

    expect(application.status, ApplicationStatus.interview);
    expect(application.company, 'Acme');
  });
}
