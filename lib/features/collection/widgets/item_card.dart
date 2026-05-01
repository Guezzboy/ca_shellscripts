import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/display_item.dart';
import '../../../shared/theme/app_theme.dart';

class ItemCard extends StatefulWidget {
  final DisplayItem item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasMultiplePhotos = item.imagePaths.length > 1;

    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragEnd: hasMultiplePhotos
          ? (d) => setState(() {
                final v = d.primaryVelocity ?? 0;
                _photoIndex = v < 0
                    ? (_photoIndex + 1) % item.imagePaths.length
                    : (_photoIndex - 1 + item.imagePaths.length) %
                        item.imagePaths.length;
              })
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: item.owned ? AppTheme.ownedLight : AppTheme.surface,
          border: Border(
            left: BorderSide(
              color: item.owned ? AppTheme.owned : AppTheme.border,
              width: item.owned ? 3 : 1,
            ),
            top: const BorderSide(color: AppTheme.border),
            right: const BorderSide(color: AppTheme.border),
            bottom: const BorderSide(color: AppTheme.border),
          ),
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
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)),
                    child: _buildImage(item),
                  ),
                  // Number badge
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
                  // Owned check
                  if (item.owned)
                    Positioned(
                      top: 3,
                      right: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppTheme.owned,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 10),
                      ),
                    ),
                  // Photo counter dots
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
    );
  }

  Widget _buildImage(DisplayItem item) {
    if (item.imagePaths.isNotEmpty) {
      return Image.file(File(item.imagePaths[_photoIndex]),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        item.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _loading(progress),
      );
    }
    return _placeholder();
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
                ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                : null,
            color: AppTheme.textSecondary,
          ),
        ),
      );
}
