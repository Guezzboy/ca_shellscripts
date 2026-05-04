import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

/// Builds item card border/background matching wireframe card states.
class _CardDecoration {
  final ThemeTokens tokens;
  _CardDecoration(this.tokens);

  BoxDecoration build(bool owned, bool wanted) {
    if (owned) {
      return BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.accent, width: 1.3),
      );
    }
    // Missing / wanted: grey dashed border with light fill
    return BoxDecoration(
      color: tokens.ink.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: tokens.ink.withOpacity(0.3),
        strokeAlign: BorderSide.strokeAlignInside,
      ),
      // Dashed effect via custom gradient background
    );
  }

  Widget buildCheckmark(ThemeTokens tokens) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.accent,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.check, color: Colors.white, size: 11),
    );
  }
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
    final tokens = context.themeTokens;
    final item = widget.item;
    final hasMultiplePhotos = item.imagePaths.length > 1;
    final deco = _CardDecoration(tokens);

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
                    color: tokens.accent.withOpacity(_flashOpacity.value),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
        child: Container(
          decoration: deco.build(item.owned, item.wanted),
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
                          const BorderRadius.vertical(top: Radius.circular(11)),
                      child: _buildImage(item, tokens),
                    ),
                    // Number badge (top-left)
                    if (item.number != null)
                      Positioned(
                        top: 4,
                        left: 5,
                        child: Text(
                          item.number!,
                          style: TextStyle(
                            color: tokens.accentDeep,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    // Quick-toggle icon (top-right)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _cycleState,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: item.owned
                                ? tokens.accent
                                : item.wanted
                                    ? Colors.amber.shade700
                                    : tokens.ink.withOpacity(0.30),
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
                    // Owned checkmark (bottom-right of image)
                    if (item.owned)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: deco.buildCheckmark(tokens),
                      ),
                    // Wanted badge
                    if (item.wanted && !item.owned)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: tokens.accentDeep,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.search,
                              color: Colors.white, size: 11),
                        ),
                      ),
                    // Rare star
                    if (item.isRare)
                      const Positioned(
                        bottom: 4,
                        left: 4,
                        child: Text('⭐', style: TextStyle(fontSize: 10)),
                      ),
                    // Photo dots
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
              Container(
                height: 1,
                color: tokens.ink.withOpacity(0.08),
              ),
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
                            ? tokens.ink
                            : tokens.ink.withOpacity(0.5),
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

  Widget _buildImage(DisplayItem item, ThemeTokens tokens) {
    Widget img;
    if (item.imagePaths.isNotEmpty) {
      img = Image.file(
        File(item.imagePaths[_photoIndex]),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(tokens),
      );
    } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      img = CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _placeholder(tokens),
        progressIndicatorBuilder: (_, url, progress) =>
            progress.downloaded == progress.totalSize
                ? const SizedBox.shrink()
                : _loading(progress, tokens),
      );
    } else {
      return _placeholder(tokens);
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

  Widget _placeholder(ThemeTokens tokens) => Container(
        color: tokens.ink.withOpacity(0.05),
        child: Icon(Icons.image_outlined,
            size: 28, color: tokens.ink.withOpacity(0.15)),
      );

  Widget _loading(DownloadProgress progress, ThemeTokens tokens) =>
      Container(
        color: tokens.ink.withOpacity(0.05),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            value: progress.totalSize != null && progress.totalSize! > 0
                ? progress.downloaded / progress.totalSize!
                : null,
            color: tokens.ink.withOpacity(0.5),
          ),
        ),
      );
}
