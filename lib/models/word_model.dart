import 'dart:convert';

class WordModel {
  final String? id;
  final String? userId;
  final String word;
  final String definition;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? sampleSentence;

  // SRS attributes
  final int repetitions;
  final int interval; // in days
  final double easeFactor;
  final DateTime nextReviewDate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  WordModel({
    this.id,
    this.userId,
    required this.word,
    required this.definition,
    required this.synonyms,
    required this.antonyms,
    this.sampleSentence,
    this.repetitions = 0,
    this.interval = 0,
    this.easeFactor = 2.5,
    DateTime? nextReviewDate,
    this.createdAt,
    this.updatedAt,
  }) : this.nextReviewDate = nextReviewDate ?? DateTime.now();

  bool get isDue {
    return DateTime.now().isAfter(nextReviewDate);
  }

  /// Implements the SuperMemo-2 (SM-2) algorithm.
  /// [quality] ranges from 1 to 5:
  /// 1: Again (Total blackout / wrong)
  /// 2: Hard (Remembered with extreme difficulty)
  /// 3: Hard-Medium (Remembered with difficulty)
  /// 4: Good (Remembered with minor hesitation)
  /// 5: Easy (Perfect response)
  WordModel updateSRS(int quality) {
    int nextRepetitions;
    int nextInterval;
    double nextEaseFactor;

    if (quality < 3) {
      nextRepetitions = 0;
      nextInterval = 1;
    } else {
      if (repetitions == 0) {
        nextInterval = 1;
      } else if (repetitions == 1) {
        nextInterval = 6;
      } else {
        nextInterval = (interval * easeFactor).round();
      }
      nextRepetitions = repetitions + 1;
    }

    // Calculate new Ease Factor
    // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    nextEaseFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (nextEaseFactor < 1.3) {
      nextEaseFactor = 1.3;
    }

    DateTime nextDate = DateTime.now().add(Duration(days: nextInterval));

    return copyWith(
      repetitions: nextRepetitions,
      interval: nextInterval,
      easeFactor: nextEaseFactor,
      nextReviewDate: nextDate,
      updatedAt: DateTime.now(),
    );
  }

  WordModel copyWith({
    String? id,
    String? userId,
    String? word,
    String? definition,
    List<String>? synonyms,
    List<String>? antonyms,
    String? sampleSentence,
    int? repetitions,
    int? interval,
    double? easeFactor,
    DateTime? nextReviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      sampleSentence: sampleSentence ?? this.sampleSentence,
      repetitions: repetitions ?? this.repetitions,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'word': word,
      'definition': definition,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'sample_sentence': sampleSentence,
      'repetitions': repetitions,
      'interval': interval,
      'ease_factor': easeFactor,
      'next_review_date': nextReviewDate.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      word: json['word'] as String,
      definition: json['definition'] as String,
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
      sampleSentence: json['sample_sentence'] as String?,
      repetitions: json['repetitions'] as int? ?? 0,
      interval: json['interval'] as int? ?? 0,
      easeFactor: (json['ease_factor'] as num? ?? 2.5).toDouble(),
      nextReviewDate: json['next_review_date'] != null
          ? DateTime.parse(json['next_review_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
