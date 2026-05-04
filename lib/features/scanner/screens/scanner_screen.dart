import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/isbn_lookup_service.dart';
import '../../../core/services/badge_checker.dart';
import '../../../shared/theme/app_theme.dart';

/// Scanner screen — Hybrid code-barres + photo.
/// Code mode: live mobile_scanner barcode detection with ISBN lookup.
/// Photo mode: delegates to the existing add_photo_screen flow.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _codeMode = true;
  bool _flashOn = false;

  // ── Barcode state ──
  MobileScannerController? _barcodeCtrl;
  final _isbnService = IsbnLookupService();
  bool _lookingUp = false;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    _initBarcode();
  }

  void _initBarcode() {
    _barcodeCtrl = MobileScannerController();
  }

  @override
  void dispose() {
    _barcodeCtrl?.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    _barcodeCtrl?.toggleTorch();
    setState(() => _flashOn = !_flashOn);
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_lookingUp) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw == _lastScanned) continue;
      // Debounce duplicate scans
      _lastScanned = raw;

      // Try to extract ISBN
      final isbn = _extractIsbn(raw);
      if (isbn == null) continue;

      setState(() => _lookingUp = true);
      final book = await _isbnService.lookupIsbn(isbn);
      if (!mounted) return;
      setState(() => _lookingUp = false);

      if (book != null) {
        BadgeChecker.afterScan(context);
        _barcodeCtrl?.stop();
        await _showBookConfirmation(book, isbn);
        _barcodeCtrl?.start();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ISBN introuvable dans les bases.')),
          );
        }
      }
      _lastScanned = null;
      break;
    }
  }

  String? _extractIsbn(String raw) {
    // Clean: keep only digits and X
    final clean = raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
    // ISBN-10: 10 chars, ISBN-13: 13 chars
    if (clean.length == 10 || clean.length == 13) return clean.toUpperCase();
    // Also try to find ISBN pattern in the string
    final m = RegExp(r'(?:ISBN[:\s]*)?(\d[\dXx]{9,12})').firstMatch(raw);
    return m?.group(1)?.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
  }

  Future<void> _showBookConfirmation(BookData book, String isbn) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookConfirmSheet(book: book, isbn: isbn),
    );
    if (result == 'add' && mounted) {
      // Navigate to add item with pre-filled book data
      context.push('/add-item', extra: {
        'isbn': isbn,
        'title': book.title,
        'author': book.authorString,
        'publisher': book.publisher,
        'publish_year': book.year,
        'cover_url': book.coverUrl,
      });
    }
    if (result == 'add_existing' && mounted) {
      context.push('/add-item', extra: {'isbn': isbn});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: SafeArea(
        child: Column(
          children: [
            // ── top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Scanner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: _flashOn ? tokens.accent : Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── tab switch: Code / Photo ──
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModeSwitch(
                tokens: tokens,
                codeMode: _codeMode,
                onToggle: (v) {
                  setState(() => _codeMode = v);
                  if (v) {
                    _barcodeCtrl?.start();
                  } else {
                    _barcodeCtrl?.stop();
                  }
                },
              ),
            ),

            // ── scanner body ──
            Expanded(
              child: _codeMode ? _buildBarcodeView() : _buildPhotoPlaceholder(),
            ),

            // ── bottom controls ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Gallery — switch to collections tab for photo add
                  GestureDetector(
                    onTap: () => context.go('/collections'),
                    child: const Icon(Icons.upload_file,
                        color: Colors.white70, size: 22),
                  ),
                  // Shutter / scan indicator
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _lookingUp
                            ? tokens.accent.withOpacity(0.5)
                            : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: _lookingUp
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tokens.accent,
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF4A72B),
                                    Color(0xFFE07A1F),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Info button
                  const Icon(Icons.info_outline,
                      color: Colors.white24, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeView() {
    if (_barcodeCtrl == null) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _barcodeCtrl,
          onDetect: _onBarcodeDetected,
        ),
        // Viewfinder overlay
        const Center(child: _Viewfinder()),
        // Hint text
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Text(
            'Placez le code-barres dans le cadre',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return GestureDetector(
      onTap: () => context.go('/collections'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white54, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Prendre une photo\nd\'un objet à ajouter',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode switch ──

class _ModeSwitch extends StatelessWidget {
  final ThemeTokens tokens;
  final bool codeMode;
  final ValueChanged<bool> onToggle;

  const _ModeSwitch({
    required this.tokens,
    required this.codeMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchPill(
            label: 'Code',
            icon: Icons.qr_code,
            active: codeMode,
            accent: tokens.accent,
            onTap: () => onToggle(true),
          ),
          _SwitchPill(
            label: 'Photo',
            icon: Icons.camera_alt_outlined,
            active: !codeMode,
            accent: tokens.accent,
            onTap: () => onToggle(false),
          ),
        ],
      ),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _SwitchPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? Colors.white : Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Viewfinder ──

class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 220,
        height: 160,
        child: CustomPaint(
          painter: _ViewfinderPainter(),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const accent = Color(0xFFF4A72B);
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;

    // top-left
    canvas.drawLine(const Offset(0, cornerLen), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    // top-right
    canvas.drawLine(Offset(size.width - cornerLen, 0),
        Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLen), paint);
    // bottom-left
    canvas.drawLine(Offset(0, size.height - cornerLen),
        Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height),
        Offset(cornerLen, size.height), paint);
    // bottom-right
    canvas.drawLine(Offset(size.width - cornerLen, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Book confirmation bottom sheet ──

class _BookConfirmSheet extends StatelessWidget {
  final BookData book;
  final String isbn;

  const _BookConfirmSheet({required this.book, required this.isbn});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.ink.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Book cover + info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 96,
                  color: tokens.ink.withOpacity(0.06),
                  child: book.coverUrl != null
                      ? Image.network(book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.book,
                              size: 32, color: tokens.ink.withOpacity(0.3)))
                      : Icon(Icons.book,
                          size: 32, color: tokens.ink.withOpacity(0.3)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title ?? 'Livre inconnu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                    ),
                    if (book.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.ink.withOpacity(0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (book.authorString.isNotEmpty)
                      Text(
                        book.authorString,
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.ink.withOpacity(0.7),
                        ),
                      ),
                    if (book.publisher != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${book.publisher}${book.year != null ? ' · ${book.year}' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.ink.withOpacity(0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'ISBN: $isbn',
                      style: TextStyle(
                        fontSize: 10,
                        color: tokens.ink.withOpacity(0.45),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'add_existing'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ajouter\nmanuellement',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'add'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter à ma collection',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
