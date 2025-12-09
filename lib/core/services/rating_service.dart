import 'package:uuid/uuid.dart';
import '../models/rating.dart';
import 'hive_service.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final Uuid _uuid = const Uuid();

  // Create a new rating
  Future<Rating> createRating({
    required String itemId,
    required ItemType itemType,
    required RatingValue rating,
    String? comment,
  }) async {
    final newRating = Rating(
      id: _uuid.v4(),
      itemId: itemId,
      itemType: itemType,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await HiveService.ratingsBox.put(newRating.id, newRating);
    return newRating;
  }

  // Get rating for a specific item
  Rating? getRatingForItem(String itemId, ItemType itemType) {
    return HiveService.ratingsBox.values
        .where(
          (rating) => rating.itemId == itemId && rating.itemType == itemType,
        )
        .cast<Rating?>()
        .firstWhere((element) => true, orElse: () => null);
  }

  // Update an existing rating
  Future<Rating> updateRating({
    required String ratingId,
    RatingValue? rating,
    String? comment,
  }) async {
    final existingRating = HiveService.ratingsBox.get(ratingId);
    if (existingRating == null) {
      throw Exception('Rating not found');
    }

    final updatedRating = existingRating.copyWith(
      rating: rating,
      comment: comment,
      updatedAt: DateTime.now(),
    );

    await HiveService.ratingsBox.put(ratingId, updatedRating);
    return updatedRating;
  }

  // Delete a rating
  Future<void> deleteRating(String ratingId) async {
    await HiveService.ratingsBox.delete(ratingId);
  }

  // Get all ratings for a specific item type
  List<Rating> getRatingsForType(ItemType itemType) {
    return HiveService.ratingsBox.values
        .where((rating) => rating.itemType == itemType)
        .toList();
  }

  // Get all ratings
  List<Rating> getAllRatings() {
    return HiveService.ratingsBox.values.toList();
  }

  // Get average rating for an item type
  double getAverageRatingForType(ItemType itemType) {
    final ratings = getRatingsForType(itemType);
    if (ratings.isEmpty) return 0.0;

    final total = ratings.fold<double>(
      0,
      (sum, rating) => sum + rating.numericRating,
    );
    return total / ratings.length;
  }

  // Get rating statistics
  Map<String, dynamic> getRatingStatistics() {
    final allRatings = getAllRatings();

    if (allRatings.isEmpty) {
      return {
        'totalRatings': 0,
        'averageRating': 0.0,
        'ratingDistribution': {},
        'ratingsByType': {},
      };
    }

    // Calculate rating distribution
    final distribution = <RatingValue, int>{};
    for (final rating in RatingValue.values) {
      distribution[rating] = 0;
    }

    for (final rating in allRatings) {
      distribution[rating.rating] = (distribution[rating.rating] ?? 0) + 1;
    }

    // Calculate ratings by type
    final ratingsByType = <ItemType, int>{};
    for (final rating in allRatings) {
      ratingsByType[rating.itemType] =
          (ratingsByType[rating.itemType] ?? 0) + 1;
    }

    // Calculate average rating
    final totalRating = allRatings.fold<double>(
      0,
      (sum, rating) => sum + rating.numericRating,
    );
    final averageRating = totalRating / allRatings.length;

    return {
      'totalRatings': allRatings.length,
      'averageRating': averageRating,
      'ratingDistribution': distribution.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'ratingsByType': ratingsByType.map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }

  // Check if an item has been rated
  bool hasRating(String itemId, ItemType itemType) {
    return getRatingForItem(itemId, itemType) != null;
  }

  // Get recent ratings (last N days)
  List<Rating> getRecentRatings({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return HiveService.ratingsBox.values
        .where((rating) => rating.createdAt.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get ratings with comments
  List<Rating> getRatingsWithComments() {
    return HiveService.ratingsBox.values
        .where((rating) => rating.hasComment)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Search ratings by comment content
  List<Rating> searchRatingsByComment(String query) {
    final lowercaseQuery = query.toLowerCase();
    return HiveService.ratingsBox.values
        .where(
          (rating) =>
              rating.hasComment &&
              rating.comment!.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  // Get ratings by value
  List<Rating> getRatingsByValue(RatingValue ratingValue) {
    return HiveService.ratingsBox.values
        .where((rating) => rating.rating == ratingValue)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Export ratings data
  List<Map<String, dynamic>> exportRatings() {
    return HiveService.ratingsBox.values
        .map((rating) => rating.toJson())
        .toList();
  }

  // Import ratings data
  Future<void> importRatings(List<Map<String, dynamic>> ratingsData) async {
    for (final ratingData in ratingsData) {
      try {
        final rating = Rating.fromJson(ratingData);
        await HiveService.ratingsBox.put(rating.id, rating);
      } catch (e) {
        print('Error importing rating: $e');
        // Continue with next rating
      }
    }
  }
}
