import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import 'rating_dialog.dart';

class UniversalRatingWidget extends ConsumerStatefulWidget {
  final String itemId;
  final ItemType itemType;
  final String itemTitle;
  final bool showTitle;
  final double? size;
  final bool interactive;

  const UniversalRatingWidget({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    this.showTitle = true,
    this.size,
    this.interactive = true,
  });

  @override
  ConsumerState<UniversalRatingWidget> createState() =>
      _UniversalRatingWidgetState();
}

class _UniversalRatingWidgetState extends ConsumerState<UniversalRatingWidget> {
  Rating? _currentRating;

  @override
  void initState() {
    super.initState();
    _loadCurrentRating();
  }

  @override
  void didUpdateWidget(UniversalRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId ||
        oldWidget.itemType != widget.itemType) {
      _loadCurrentRating();
    }
  }

  void _loadCurrentRating() {
    final ratingService = RatingService();
    _currentRating = ratingService.getRatingForItem(
      widget.itemId,
      widget.itemType,
    );
  }

  Future<void> _showRatingDialog() async {
    if (!widget.interactive) return;

    final result = await showRatingDialog(
      context: context,
      itemId: widget.itemId,
      itemType: widget.itemType,
      itemTitle: widget.itemTitle,
      existingComment: _currentRating?.comment,
      existingRating: _currentRating?.rating,
    );

    if (result == true && mounted) {
      // Reload rating after dialog closes
      setState(() {
        _loadCurrentRating();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final starSize = widget.size ?? 24.0;

    if (_currentRating == null) {
      // Show rating prompt for unrated items
      return GestureDetector(
        onTap: _showRatingDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_border,
                color: Theme.of(context).primaryColor,
                size: starSize,
              ),
              if (widget.showTitle) ...[
                const SizedBox(width: 8),
                Text(
                  'Rate this ${widget.itemType.displayName.toLowerCase()}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    // Show current rating
    return GestureDetector(
      onTap: _showRatingDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getRatingColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getRatingColor().withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stars display
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < _currentRating!.rating.numericValue
                      ? Icons.star
                      : Icons.star_border,
                  color: _getRatingColor(),
                  size: starSize,
                );
              }),
            ),
            if (widget.showTitle) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentRating!.rating.displayName,
                      style: TextStyle(
                        color: _getRatingColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (_currentRating!.hasComment) ...[
                      const SizedBox(height: 2),
                      Text(
                        '"${_currentRating!.comment!.length > 30 ? '${_currentRating!.comment!.substring(0, 30)}...' : _currentRating!.comment!}"',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (widget.interactive) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit,
                color: _getRatingColor().withOpacity(0.7),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRatingColor() {
    if (_currentRating == null) return Theme.of(context).primaryColor;

    switch (_currentRating!.rating) {
      case RatingValue.veryPoor:
        return Colors.red;
      case RatingValue.poor:
        return Colors.orange;
      case RatingValue.average:
        return Colors.yellow.shade700;
      case RatingValue.good:
        return Colors.lightGreen;
      case RatingValue.excellent:
        return Colors.green;
    }
  }
}

// Compact version for smaller spaces
class CompactRatingWidget extends ConsumerWidget {
  final String itemId;
  final ItemType itemType;
  final String itemTitle;
  final double size;
  final bool interactive;

  const CompactRatingWidget({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    this.size = 16,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingService = RatingService();
    final rating = ratingService.getRatingForItem(itemId, itemType);

    if (rating == null) {
      return GestureDetector(
        onTap: interactive ? () => _showRatingDialog(context) : null,
        child: Icon(
          Icons.star_border,
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          size: size,
        ),
      );
    }

    return GestureDetector(
      onTap: interactive ? () => _showRatingDialog(context) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: _getRatingColor(rating.rating), size: size),
          const SizedBox(width: 2),
          Text(
            rating.rating.numericValue.toString(),
            style: TextStyle(
              color: _getRatingColor(rating.rating),
              fontSize: size * 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    await showRatingDialog(
      context: context,
      itemId: itemId,
      itemType: itemType,
      itemTitle: itemTitle,
      existingComment: RatingService()
          .getRatingForItem(itemId, itemType)
          ?.comment,
      existingRating: RatingService()
          .getRatingForItem(itemId, itemType)
          ?.rating,
    );
  }

  Color _getRatingColor(RatingValue rating) {
    switch (rating) {
      case RatingValue.veryPoor:
        return Colors.red;
      case RatingValue.poor:
        return Colors.orange;
      case RatingValue.average:
        return Colors.yellow.shade700;
      case RatingValue.good:
        return Colors.lightGreen;
      case RatingValue.excellent:
        return Colors.green;
    }
  }
}
