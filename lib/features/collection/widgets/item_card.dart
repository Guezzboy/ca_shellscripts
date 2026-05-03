import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/display_item.dart';
import '../../../shared/theme/app_theme.dart';

class ItemCard extends StatefulWidget {
  final DisplayItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleOwned;
  /// 3-way cycle: neutral → wanted → owned → neutral
  final VoidCallback onCycle;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleOwned,
    required this.onCycle,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard>
    with SingleTickerProviderStateMixin {
  int _photoIndex = 0;
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flashOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  void _cycleState() {
    HapticFeedback.mediumImpact();
    _flashCtrl.forward(from: 0);
    widget.onCycle();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasMultiplePhotos = item.imagePaths.length > 1;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: _cycleState,
      onHorizontalDragEnd: hasMultiplePhotos
          ? (d) => setState(() {
                final v = d.primaryVelocity ?? 0;
                _photoIndex = v < 0
                    ? (_photoIndex + 1) % item.imagePaths.length
                    : (_photoIndex - 1 + item.imagePaths.length) %
                        item.imagePaths.length;
              })
          : null,
      child: AnimatedBuilder(
        animation: _flashOpacity,
        builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [
            child!,
            if (_flashOpacity.value > 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.owned.withOpacity(_flashOpacity.value),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image zone
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                      child: _buildImage(item),
                    ),
                    // Number badge (top-left)
                    if (item.number != null)
                      Positioned(
                        top: 4,
                        left: 5,
                        child: Text(
                          item.number!,
                          style: const TextStyle(
                            color: AppTheme.numberRed,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    // Quick-toggle icon (top-right, always visible)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: GestureDetector(
                        onTap: _cycleState,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: item.owned
                                ? AppTheme.owned
                                : item.wanted
                                    ? Colors.amber.shade700
                                    : Colors.black.withOpacity(0.30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.owned
                                ? Icons.check
                                : item.wanted
                                    ? Icons.search
                                    : Icons.add,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                    ),
                    // Owned badge (bottom-right of image)
                    if (item.owned)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppTheme.owned,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 11),
                        ),
                      ),
                    // Wanted badge (bottom-right, only when wanted and not owned)
                    if (item.wanted && !item.owned)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.search,
                              color: Colors.white, size: 11),
                        ),
                      ),
                    // Rare star (bottom-left)
                    if (item.isRare)
                      const Positioned(
                        bottom: 4,
                        left: 4,
                        child: Text('⭐', style: TextStyle(fontSize: 10)),
                      ),
                    // Photo dots (bottom-center)
                    if (hasMultiplePhotos)
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            item.imagePaths.length,
                            (i) => Container(
                              width: i == _photoIndex ? 6 : 4,
                              height: i == _photoIndex ? 6 : 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _photoIndex
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Separator
              Container(height: 1, color: AppTheme.border),
              // Name zone
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
                  child: Center(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: item.owned
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(DisplayItem item) {
    Widget img;
    if (item.imagePaths.isNotEmpty) {
      img = Image.file(
        File(item.imagePaths[_photoIndex]),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      img = Image.network(
        item.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _loading(progress),
      );
    } else {
      return _placeholder();
    }

    if (!item.owned) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: img,
      );
    }

    return img;
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFEFEDE8),
        child: const Icon(Icons.image_outlined,
            size: 28, color: Color(0xFFBBB8B2)),
      );

  Widget _loading(ImageChunkEvent progress) => Container(
        color: const Color(0xFFEFEDE8),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            color: AppTheme.textSecondary,
          ),
        ),
      );
}
