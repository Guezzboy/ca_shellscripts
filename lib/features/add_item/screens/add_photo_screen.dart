import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/item_providers.dart';
import '../../../shared/theme/app_theme.dart';

class AddPhotoScreen extends ConsumerStatefulWidget {
  final String collectionId;

  const AddPhotoScreen({super.key, required this.collectionId});

  @override
  ConsumerState<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends ConsumerState<AddPhotoScreen> {
  File? _imageFile;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _picker = ImagePicker();

  bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajout par photo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageZone(),
            const SizedBox(height: 16),
            _buildCaptureButtons(),
            if (_imageFile != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              _buildManualForm(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveItem,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Ajout...' : 'Ajouter à la collection'),
              ),
            ] else ...[
              const SizedBox(height: 16),
              if (_isDesktop)
                _buildDesktopNote()
              else
                _buildOcrNote(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageZone() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade300),
      ),
      child: _imageFile != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(_imageFile!, fit: BoxFit.contain),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined,
                    size: 48, color: Colors.brown.shade300),
                const SizedBox(height: 8),
                Text('Aucune image sélectionnée',
                    style: TextStyle(color: Colors.brown.shade500)),
              ],
            ),
    );
  }

  Widget _buildCaptureButtons() {
    if (_isDesktop) {
      return ElevatedButton.icon(
        onPressed: _pickFileDesktop,
        icon: const Icon(Icons.folder_open),
        label: const Text('Choisir une image depuis les fichiers'),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImageMobile(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Appareil photo'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImageMobile(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galerie'),
          ),
        ),
      ],
    );
  }

  Widget _buildManualForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations de l\'item :',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom *',
            hintText: 'Ex: Verre Mickey Mouse',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _numberController,
          decoration: const InputDecoration(
            labelText: 'Numéro (optionnel)',
            hintText: 'Ex: 042',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildDesktopNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sur Linux desktop, sélectionne une image depuis tes fichiers. '
              'L\'appareil photo est disponible sur Android.',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_fix_high, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reconnaissance automatique (OCR) prévue en Phase 2. '
              'Pour l\'instant, saisis le nom manuellement.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFileDesktop() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
        _nameController.clear();
        _numberController.clear();
      });
    }
  }

  Future<void> _pickImageMobile(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, maxWidth: 1200, imageQuality: 85);
    if (xfile == null) return;
    setState(() {
      _imageFile = File(xfile.path);
      _nameController.clear();
      _numberController.clear();
    });
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(collectionItemsProvider(widget.collectionId).notifier)
          .addCustomItem(
            name: name,
            number: _numberController.text.trim().isEmpty
                ? null
                : _numberController.text.trim(),
            imagePath: _imageFile?.path,
            source: 'photo',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" ajouté avec photo.')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
