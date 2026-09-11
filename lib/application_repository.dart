import 'package:supabase_flutter/supabase_flutter.dart';

class JobApplication {
  const JobApplication({
    required this.id,
    required this.company,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String company;
  final String role;
  final ApplicationStatus status;
  final DateTime createdAt;

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] as String,
      company: json['company'] as String,
      role: json['role'] as String,
      status: ApplicationStatusLabel.fromDatabase(json['status'] as String? ?? 'saved'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  JobApplication copyWith({
    String? company,
    String? role,
    ApplicationStatus? status,
  }) {
    return JobApplication(
      id: id,
      company: company ?? this.company,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

enum ApplicationStatus { saved, applied, interview, offer }

extension ApplicationStatusLabel on ApplicationStatus {
  String get value => name;

  String get label => switch (this) {
        ApplicationStatus.saved => 'Salva',
        ApplicationStatus.applied => 'Enviada',
        ApplicationStatus.interview => 'Entrevista',
        ApplicationStatus.offer => 'Oferta',
      };

  static ApplicationStatus fromDatabase(String value) {
    return ApplicationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ApplicationStatus.saved,
    );
  }
}

class ApplicationRepository {
  ApplicationRepository(this._client);

  final SupabaseClient _client;

  Stream<List<JobApplication>> watchAll() {
    return _client
        .from('job_applications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(JobApplication.fromJson).toList(growable: false));
  }

  Future<void> create({required String company, required String role}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sessao expirada. Entre novamente.');
    }
    await _client.from('job_applications').insert({
      'user_id': userId,
      'company': company,
      'role': role,
      'status': ApplicationStatus.saved.value,
    });
  }

  Future<void> update(JobApplication application) {
    return _client
        .from('job_applications')
        .update({
          'company': application.company,
          'role': application.role,
          'status': application.status.value,
        })
        .eq('id', application.id);
  }

  Future<void> remove(String id) {
    return _client.from('job_applications').delete().eq('id', id);
  }
}
