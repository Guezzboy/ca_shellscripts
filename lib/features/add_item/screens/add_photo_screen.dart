import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _detectedName = '';
  String _detectedNumber = '';
  bool _processing = false;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _picker = ImagePicker();

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
            // Image preview
            _buildImageZone(),
            const SizedBox(height: 16),

            // Capture buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Appareil photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            ),

            if (_imageFile != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              if (_processing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Analyse de l\'image en cours...'),
                    ],
                  ),
                )
              else ...[
                if (_detectedName.isNotEmpty)
                  _buildDetectionResult(),
                const SizedBox(height: 16),
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
              ],
            ] else ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.blue.shade700, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Astuce Phase 2',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'La reconnaissance automatique par OCR (Google ML Kit) '
                      'sera activée dans la prochaine version. '
                      'Pour l\'instant, saisissez le nom manuellement après avoir pris la photo.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
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
                Text(
                  'Aucune photo sélectionnée',
                  style: TextStyle(color: Colors.brown.shade500),
                ),
              ],
            ),
    );
  }

  Widget _buildDetectionResult() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.ownedGreenLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.ownedGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Résultat détection :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text('"$_detectedName"',
              style: const TextStyle(fontSize: 15)),
          if (_detectedNumber.isNotEmpty)
            Text('Numéro : #$_detectedNumber',
                style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _nameController.text = _detectedName;
                  _numberController.text = _detectedNumber;
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Confirmer'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppTheme.ownedGreen,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _detectedName = '';
                  _detectedNumber = '';
                }),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations de l\'item :',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, maxWidth: 1200, imageQuality: 85);
    if (xfile == null) return;
    setState(() {
      _imageFile = File(xfile.path);
      _detectedName = '';
      _detectedNumber = '';
      _nameController.clear();
      _numberController.clear();
    });

    // Phase 2: run OCR here
    // For now we skip auto-detection and let the user fill in manually.
    // When google_mlkit_text_recognition is integrated:
    //   final recognizer = TextRecognizer();
    //   final inputImage = InputImage.fromFile(_imageFile!);
    //   final result = await recognizer.processImage(inputImage);
    //   _parseOcrResult(result.text);
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
