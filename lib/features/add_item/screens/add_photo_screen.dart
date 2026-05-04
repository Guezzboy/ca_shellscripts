import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:uuid/uuid.dart';
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
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  bool _ocrRunning = false;
  String? _ocrSuggestion;

  bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _textRecognizer.close();
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
    final tokens = context.themeTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, size: 16, color: tokens.accent),
            const SizedBox(width: 6),
            Text(
              '${_imagePaths.length} photo${_imagePaths.length > 1 ? "s" : ""}',
              style: TextStyle(
                  color: tokens.accent, fontWeight: FontWeight.w600),
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
        if (_ocrRunning)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        if (_ocrSuggestion != null && !_ocrRunning) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Text('Suggestion :',
                  style: TextStyle(fontSize: 12, color: tokens.ink.withOpacity(0.6))),
              const SizedBox(width: 6),
              ActionChip(
                label: Text(_ocrSuggestion!,
                    style: const TextStyle(fontSize: 12)),
                avatar:
                    const Icon(Icons.text_fields, size: 14),
                onPressed: () {
                  _nameController.text = _ocrSuggestion!;
                  _nameController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _ocrSuggestion!.length),
                  );
                  setState(() => _ocrSuggestion = null);
                },
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _ocrSuggestion = null),
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
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
      if (paths.isNotEmpty) _runOcr(paths.last);
    }
  }

  Future<void> _pickImageMobile(ImageSource source) async {
    if (source == ImageSource.gallery) {
      // image_picker supports multiple from gallery
      final files = await _picker.pickMultiImage(
          maxWidth: 1200, imageQuality: 85);
      if (files.isNotEmpty) {
        final paths = files.map((f) => f.path).toList();
        setState(() => _imagePaths.addAll(paths));
        _runOcr(paths.last);
      }
    } else {
      final xfile = await _picker.pickImage(
          source: source, maxWidth: 1200, imageQuality: 85);
      if (xfile != null) {
        setState(() => _imagePaths.add(xfile.path));
        _runOcr(xfile.path);
      }
    }
  }

  // ── OCR ────────────────────────────────────────────────────────────────────

  Future<void> _runOcr(String imagePath) async {
    setState(() {
      _ocrRunning = true;
      _ocrSuggestion = null;
    });
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      if (!mounted) return;

      // Prendre le premier bloc de texte non vide comme suggestion
      final blocks = recognizedText.blocks;
      if (blocks.isNotEmpty) {
        final firstLine = blocks.first.lines;
        if (firstLine.isNotEmpty) {
          final text = firstLine.first.text.trim();
          if (text.isNotEmpty) {
            setState(() => _ocrSuggestion = text);
          }
        }
      }
    } catch (_) {
      // OCR failed silently — the user can type manually
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Copy a temporary image file to the app's persistent photos directory.
  Future<String> _copyToAppDir(String sourcePath) async {
    final dir = await pp.getApplicationDocumentsDirectory();
    final photosDir = Directory('${dir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = sourcePath.split('.').lastOrNull ?? 'jpg';
    final destPath = '${photosDir.path}/${const Uuid().v4()}.$ext';
    await File(sourcePath).copy(destPath);
    return destPath;
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
      // Copy images from temp picker paths to persistent app directory
      final persistentPaths = <String>[];
      for (final path in _imagePaths) {
        try {
          final dest = await _copyToAppDir(path);
          persistentPaths.add(dest);
        } catch (_) {
          // If copy fails (e.g., temp file already gone), keep original path as fallback
          persistentPaths.add(path);
        }
      }

      await ref
          .read(collectionItemsProvider(widget.collectionId).notifier)
          .addCustomItem(
            name: name,
            number: _numberController.text.trim().isEmpty
                ? null
                : _numberController.text.trim(),
            imagePaths: List.unmodifiable(persistentPaths),
            source: 'photo',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '"$name" ajouté avec ${persistentPaths.length} photo(s).')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
