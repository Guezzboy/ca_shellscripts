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
    return GestureDetector(
      onTap: widget.onTap,
      // Swipe left/right to browse photos
      onHorizontalDragEnd: item.imagePaths.length > 1
          ? (details) {
              if (details.primaryVelocity == null) return;
              setState(() {
                if (details.primaryVelocity! < 0) {
                  _photoIndex =
                      (_photoIndex + 1) % item.imagePaths.length;
                } else {
                  _photoIndex = (_photoIndex - 1 + item.imagePaths.length) %
                      item.imagePaths.length;
                }
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: item.owned ? AppTheme.ownedGreenLight : AppTheme.cardCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: item.owned ? AppTheme.ownedGreen : Colors.brown.shade200,
            width: item.owned ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image zone
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(9)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(item),
                    // Owned badge
                    if (item.owned)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppTheme.ownedGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    // Custom badge
                    if (item.isCustom)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('PERSO',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    // Multiple photos indicator
                    if (item.imagePaths.length > 1)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_photoIndex + 1}/${item.imagePaths.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Panini divider bar
            Container(
              height: 3,
              color: item.owned ? AppTheme.ownedGreen : Colors.brown.shade300,
            ),
            // Info zone
            Expanded(
              flex: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown.shade900,
                      ),
                    ),
                    if (item.number != null)
                      Text(
                        '#${item.number}',
                        style: TextStyle(
                            fontSize: 9, color: Colors.brown.shade500),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(DisplayItem item) {
    // Custom item with local photos
    if (item.imagePaths.isNotEmpty) {
      return Image.file(
        File(item.imagePaths[_photoIndex]),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    // Base item with network image
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        item.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: AppTheme.primaryBrown,
            ),
          );
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.brown.shade100,
      child: Icon(Icons.image_outlined,
          size: 32, color: Colors.brown.shade300),
    );
  }
}
