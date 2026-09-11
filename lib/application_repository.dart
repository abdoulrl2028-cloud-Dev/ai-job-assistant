import 'dart:async';

class JobApplication {
  const JobApplication({
    required this.id,
    required this.company,
    required this.role,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String company;
  final String role;
  final ApplicationStatus status;
  final DateTime updatedAt;

  JobApplication copyWith({
    String? company,
    String? role,
    ApplicationStatus? status,
    DateTime? updatedAt,
  }) {
    return JobApplication(
      id: id,
      company: company ?? this.company,
      role: role ?? this.role,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ApplicationStatus { saved, applied, interview, offer }

extension ApplicationStatusLabel on ApplicationStatus {
  String get label => switch (this) {
        ApplicationStatus.saved => 'Salva',
        ApplicationStatus.applied => 'Enviada',
        ApplicationStatus.interview => 'Entrevista',
        ApplicationStatus.offer => 'Oferta',
      };
}

class ApplicationRepository {
  ApplicationRepository({List<JobApplication>? initialApplications})
      : _applications = initialApplications ??
            [
              JobApplication(
                id: 'nova',
                company: 'Atelier Nova',
                role: 'Product Designer',
                status: ApplicationStatus.interview,
                updatedAt: DateTime.now(),
              ),
              JobApplication(
                id: 'metrik',
                company: 'Metrik',
                role: 'UX/UI Designer',
                status: ApplicationStatus.applied,
                updatedAt: DateTime.now(),
              ),
            ];

  final StreamController<List<JobApplication>> _changes = StreamController.broadcast();
  List<JobApplication> _applications;
  bool _refreshInProgress = false;

  Stream<List<JobApplication>> get changes => _changes.stream;

  Future<void> refresh() async {
    if (_refreshInProgress) return;

    _refreshInProgress = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _emit();
    } finally {
      _refreshInProgress = false;
    }
  }

  Future<void> create({required String company, required String role}) async {
    _applications = [
      JobApplication(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        company: company,
        role: role,
        status: ApplicationStatus.saved,
        updatedAt: DateTime.now(),
      ),
      ..._applications,
    ];
    _emit();
  }

  Future<void> update(JobApplication application) async {
    _applications = _applications
        .map((item) => item.id == application.id ? application.copyWith(updatedAt: DateTime.now()) : item)
        .toList();
    _emit();
  }

  Future<void> remove(String id) async {
    _applications = _applications.where((application) => application.id != id).toList();
    _emit();
  }

  void _emit() => _changes.add(List.unmodifiable(_applications));

  Future<void> dispose() => _changes.close();
}