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
  final List<String> _imagePaths = [];
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
            // Photo gallery
            _buildPhotoGallery(),
            const SizedBox(height: 12),

            // Add photo button(s)
            _buildAddPhotoButtons(),

            if (_imagePaths.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              _buildForm(),
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
              _buildHint(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Photo gallery ─────────────────────────────────────────────────────────

  Widget _buildPhotoGallery() {
    if (_imagePaths.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.brown.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 48, color: Colors.brown.shade300),
            const SizedBox(height: 8),
            Text('Aucune photo',
                style: TextStyle(color: Colors.brown.shade500)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _imagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _buildPhotoThumbnail(index),
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(_imagePaths[index]),
            width: 160,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
        // Photo number badge
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}/${_imagePaths.length}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _imagePaths.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Add photo buttons ─────────────────────────────────────────────────────

  Widget _buildAddPhotoButtons() {
    if (_isDesktop) {
      return OutlinedButton.icon(
        onPressed: _pickFileDesktop,
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(_imagePaths.isEmpty
            ? 'Choisir des images'
            : 'Ajouter une autre photo'),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImageMobile(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: Text(_imagePaths.isEmpty ? 'Photo' : '+ Photo'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImageMobile(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: Text(_imagePaths.isEmpty ? 'Galerie' : '+ Galerie'),
          ),
        ),
      ],
    );
  }

  // ── Form ─────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              '${_imagePaths.length} photo${_imagePaths.length > 1 ? "s" : ""}',
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
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

  Widget _buildHint() {
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
              _isDesktop
                  ? 'Sélectionne une ou plusieurs images depuis tes fichiers.'
                  : 'Tu peux prendre plusieurs photos du même verre (face, dos, détail…).',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickFileDesktop() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      final paths =
          result.files.map((f) => f.path).whereType<String>().toList();
      setState(() => _imagePaths.addAll(paths));
    }
  }

  Future<void> _pickImageMobile(ImageSource source) async {
    if (source == ImageSource.gallery) {
      // image_picker supports multiple from gallery
      final files = await _picker.pickMultiImage(
          maxWidth: 1200, imageQuality: 85);
      if (files.isNotEmpty) {
        setState(() => _imagePaths.addAll(files.map((f) => f.path)));
      }
    } else {
      final xfile = await _picker.pickImage(
          source: source, maxWidth: 1200, imageQuality: 85);
      if (xfile != null) {
        setState(() => _imagePaths.add(xfile.path));
      }
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

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
            imagePaths: List.unmodifiable(_imagePaths),
            source: 'photo',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '"$name" ajouté avec ${_imagePaths.length} photo(s).')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
