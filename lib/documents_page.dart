import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'resume_repository.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, required this.repository});
  final ResumeRepository repository;
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  bool _uploading = false;
  @override
  Widget build(BuildContext context) => SafeArea(child: StreamBuilder<List<Resume>>(
    stream: widget.repository.watchAll(),
    builder: (context, snapshot) => Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(children: [
      Padding(padding: const EdgeInsets.all(24), child: Row(children: [Expanded(child: Text('Meu CV', style: Theme.of(context).textTheme.headlineSmall)), FilledButton.icon(onPressed: _uploading ? null : _pickAndUpload, icon: const Icon(Icons.upload_file), label: const Text('Enviar CV'))])),
      if (snapshot.hasError) const Expanded(child: Center(child: Text('Nao foi possivel carregar seus documentos.')))
      else if (!snapshot.hasData) const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (snapshot.data!.isEmpty) const Expanded(child: Center(child: Text('Envie um CV em PDF ou DOCX para iniciar suas analises.')))
      else Expanded(child: ListView.builder(itemCount: snapshot.data!.length, itemBuilder: (context, index) { final resume = snapshot.data![index]; return ListTile(leading: const Icon(Icons.description_outlined), title: Text(resume.fileName), subtitle: Text('${(resume.fileSizeBytes / 1024).ceil()} KB | ${resume.mimeType == 'application/pdf' ? 'PDF' : 'DOCX'}'), trailing: IconButton(tooltip: 'Excluir CV', icon: const Icon(Icons.delete_outline), onPressed: () => widget.repository.remove(resume))); })),
    ]))),
  ));
  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx'], withData: true);
    final file = result?.files.singleOrNull;
    if (file?.bytes == null || file == null) return;
    final mimeType = file.extension?.toLowerCase() == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    setState(() => _uploading = true);
    try { await widget.repository.upload(fileName: file.name, mimeType: mimeType, bytes: file.bytes!); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CV enviado com seguranca.'))); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
    finally { if (mounted) setState(() => _uploading = false); }
  }
}