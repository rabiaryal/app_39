import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class RatingDialog extends ConsumerStatefulWidget {
  final String itemId;
  final ItemType itemType;
  final String itemTitle;
  final String? existingComment;
  final RatingValue? existingRating;

  const RatingDialog({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    this.existingComment,
    this.existingRating,
  });

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  RatingValue? _selectedRating;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.existingRating;
    _commentController.text = widget.existingComment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ratingService = RatingService();

      if (widget.existingRating != null) {
        // Update existing rating
        final existingRating = ratingService.getRatingForItem(
          widget.itemId,
          widget.itemType,
        );
        if (existingRating != null) {
          await ratingService.updateRating(
            ratingId: existingRating.id,
            rating: _selectedRating,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );
        }
      } else {
        // Create new rating
        await ratingService.createRating(
          itemId: widget.itemId,
          itemType: widget.itemType,
          rating: _selectedRating!,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRating != null
                  ? 'Rating updated successfully!'
                  : 'Thank you for your feedback!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving rating: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingRating != null
            ? 'Update Rating'
            : 'Rate Your Experience',
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _getItemIcon(),
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.itemType.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.itemTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rating stars
            Text(
              'How would you rate this ${widget.itemType.displayName.toLowerCase()}?',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Star rating selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: RatingValue.values.map((rating) {
                return IconButton(
                  onPressed: () => setState(() => _selectedRating = rating),
                  icon: Icon(
                    _selectedRating != null &&
                            RatingValue.values.indexOf(rating) <=
                                RatingValue.values.indexOf(_selectedRating!)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }).toList(),
            ),

            // Rating labels
            if (_selectedRating != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _selectedRating!.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Comment field
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Comments (optional)',
                hintText: 'Share your thoughts...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.comment_outlined),
              ),
              maxLines: 3,
              maxLength: 500,
            ),

            const SizedBox(height: 16),

            // Selected rating display
            if (_selectedRating != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRatingColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRatingColor().withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedRating!.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedRating!.displayName,
                        style: TextStyle(
                          color: _getRatingColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedRating == null
              ? null
              : _submitRating,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingRating != null ? 'Update' : 'Submit'),
        ),
      ],
    );
  }

  IconData _getItemIcon() {
    switch (widget.itemType) {
      case ItemType.event:
        return Icons.event;
      case ItemType.task:
        return Icons.task;
      case ItemType.appointment:
        return Icons.calendar_today;
      case ItemType.note:
        return Icons.note;
      case ItemType.transaction:
        return Icons.account_balance_wallet;
    }
  }

  Color _getRatingColor() {
    if (_selectedRating == null) return Colors.grey;

    switch (_selectedRating!) {
      case RatingValue.veryPoor:
        return Colors.red;
      case RatingValue.poor:
        return Colors.orange;
      case RatingValue.average:
        return Colors.yellow;
      case RatingValue.good:
        return Colors.lightGreen;
      case RatingValue.excellent:
        return Colors.green;
    }
  }
}

// Helper function to show rating dialog
Future<bool?> showRatingDialog({
  required BuildContext context,
  required String itemId,
  required ItemType itemType,
  required String itemTitle,
  String? existingComment,
  RatingValue? existingRating,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => RatingDialog(
      itemId: itemId,
      itemType: itemType,
      itemTitle: itemTitle,
      existingComment: existingComment,
      existingRating: existingRating,
    ),
  );
}
