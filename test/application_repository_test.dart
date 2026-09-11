import 'package:ai_job_assistant/application_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publishes create, update and remove events without a page reload', () async {
    final repository = ApplicationRepository(initialApplications: []);
    final emittedLists = <List<JobApplication>>[];
    final subscription = repository.changes.listen(emittedLists.add);

    await repository.refresh();
  await Future<void>.delayed(Duration.zero);
    await repository.create(company: 'Acme', role: 'Flutter Developer');
  await Future<void>.delayed(Duration.zero);

    final createdApplication = emittedLists.last.single;
    await repository.update(createdApplication.copyWith(status: ApplicationStatus.interview));
  await Future<void>.delayed(Duration.zero);
    await repository.remove(createdApplication.id);
  await Future<void>.delayed(Duration.zero);

    expect(emittedLists, hasLength(4));
    expect(emittedLists[0], isEmpty);
    expect(emittedLists[1].single.company, 'Acme');
    expect(emittedLists[2].single.status, ApplicationStatus.interview);
    expect(emittedLists[3], isEmpty);

    await subscription.cancel();
    await repository.dispose();
  });
}