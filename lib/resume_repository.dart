import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class Resume {
  const Resume({required this.id, required this.fileName, required this.mimeType, required this.fileSizeBytes, required this.createdAt});
  final String id;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final DateTime createdAt;
  factory Resume.fromJson(Map<String, dynamic> json) => Resume(id: json['id'] as String, fileName: json['file_name'] as String, mimeType: json['mime_type'] as String, fileSizeBytes: json['file_size_bytes'] as int, createdAt: DateTime.parse(json['created_at'] as String));
}

class ResumeRepository {
  ResumeRepository(this._client);
  final SupabaseClient _client;
  static const _bucket = 'user-resumes';
  static const maxBytes = 10 * 1024 * 1024;

  Stream<List<Resume>> watchAll() => _client.from('resumes').stream(primaryKey: ['id']).order('created_at', ascending: false).map((rows) => rows.map(Resume.fromJson).toList(growable: false));

  Future<Map<String, dynamic>> analyzeLatestForJob(String jobId) async {
    final resume = await _client.from('resumes').select('id').order('created_at', ascending: false).limit(1).maybeSingle();
    if (resume == null) throw StateError('Envie um CV antes de iniciar a analise.');
    final response = await _client.functions.invoke('analyze-resume', body: {'resumeId': resume['id'], 'jobId': jobId});
    if (response.data is! Map<String, dynamic>) throw StateError('A analise retornou uma resposta invalida.');
    return response.data as Map<String, dynamic>;
  }

  Future<void> upload({required String fileName, required String mimeType, required Uint8List bytes}) async {
    if (!['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'].contains(mimeType)) throw const FormatException('Envie somente arquivos PDF ou DOCX.');
    if (bytes.isEmpty || bytes.length > maxBytes) throw const FormatException('O arquivo deve ter no maximo 10 MB.');
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Sessao expirada. Entre novamente.');
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await _client.storage.from(_bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeType, upsert: false));
    try {
      await _client.from('resumes').insert({'user_id': userId, 'file_name': fileName, 'storage_path': path, 'mime_type': mimeType, 'file_size_bytes': bytes.length});
    } catch (_) {
      await _client.storage.from(_bucket).remove([path]);
      rethrow;
    }
  }

  Future<void> remove(Resume resume) async {
    final row = await _client.from('resumes').select('storage_path').eq('id', resume.id).single();
    await _client.storage.from(_bucket).remove([row['storage_path'] as String]);
    await _client.from('resumes').delete().eq('id', resume.id);
  }
}