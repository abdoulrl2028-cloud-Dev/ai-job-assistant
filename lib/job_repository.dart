import 'package:supabase_flutter/supabase_flutter.dart';

class JobPosting {
  const JobPosting({required this.id, required this.title, required this.company, required this.country, required this.city, required this.location, required this.workMode, required this.salary, required this.experienceLevel, required this.languages, required this.description, required this.technologies, required this.sourceName, required this.sourceUrl, required this.publishedAt});
  final String id;
  final String title;
  final String company;
  final String? country;
  final String? city;
  final String location;
  final String workMode;
  final String? salary;
  final String? experienceLevel;
  final List<String> languages;
  final String description;
  final List<String> technologies;
  final String sourceName;
  final String sourceUrl;
  final DateTime? publishedAt;

  factory JobPosting.fromJson(Map<String, dynamic> json) => JobPosting(
    id: json['id'] as String,
    title: json['title'] as String,
    company: json['company_name'] as String,
    country: json['country'] as String?,
    city: json['city'] as String?,
    location: json['location'] as String? ?? 'Nao informado',
    workMode: json['work_mode'] as String? ?? 'remote',
    salary: json['salary_text'] as String?,
    experienceLevel: json['experience_level'] as String?,
    languages: List<String>.from(json['languages'] as List? ?? const []),
    description: json['description'] as String? ?? '',
    technologies: List<String>.from(json['technologies'] as List? ?? const []),
    sourceName: (json['job_sources'] as Map<String, dynamic>?)?['name'] as String? ?? 'Fonte oficial',
    sourceUrl: json['source_url'] as String,
    publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
  );
}

class JobRepository {
  JobRepository(this._client);
  final SupabaseClient _client;

  Stream<List<JobPosting>> watchJobs() => _client
    .from('jobs')
    .stream(primaryKey: ['id'])
    .order('published_at', ascending: false)
    .map((rows) => rows.map(JobPosting.fromJson).toList(growable: false));

  Future<bool> isSaved(String jobId) async => (await _client.from('saved_jobs').select().eq('job_id', jobId).maybeSingle()) != null;

  Future<void> save(String jobId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('saved_jobs').upsert({'user_id': userId, 'job_id': jobId});
  }

  Future<void> removeSaved(String jobId) => _client.from('saved_jobs').delete().eq('job_id', jobId);
}