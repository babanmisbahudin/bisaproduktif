import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Suggested Goal untuk ditampilkan ke user
class SuggestedGoal {
  final String title;
  final String description;
  final int coinReward;
  final Color color;
  final String category; // 'fitness', 'learning', 'wellness', 'financial', 'social'

  SuggestedGoal({
    required this.title,
    required this.description,
    required this.coinReward,
    required this.color,
    required this.category,
  });
}

/// Service untuk suggest goals berdasarkan habits user
class GoalSuggestionService {
  // Database goal suggestions dengan keyword matching
  static final List<Map<String, dynamic>> _goalDatabase = [
    // ── FITNESS ────────────────────────────────────────────────────────────────
    {
      'title': 'Olahraga 5x seminggu selama sebulan',
      'description': 'Konsisten berolahraga minimal 30 menit setiap hari, 5 hari per minggu selama 1 bulan penuh',
      'coins': 1200,
      'category': 'fitness',
      'color': AppColors.taskOrange,
      'keywords': ['olahraga', 'lari', 'gym', 'fitness', 'yoga', 'push', 'pull', 'cardio', 'sepeda'],
    },
    {
      'title': 'Capai target weight fitness',
      'description': 'Turunkan atau naikan berat badan sesuai target, lakukan tracking berat badan setiap minggu',
      'coins': 1500,
      'category': 'fitness',
      'color': AppColors.taskOrange,
      'keywords': ['olahraga', 'gym', 'fitness', 'sehat', 'berat badan', 'diet'],
    },
    {
      'title': 'Lari marathon 10km',
      'description': 'Latih stamina dengan lari jarak jauh, capai target 10km dalam 1 hari',
      'coins': 1000,
      'category': 'fitness',
      'color': AppColors.taskOrange,
      'keywords': ['lari', 'jogging', 'marathon', 'cardio', 'olahraga'],
    },

    // ── LEARNING ────────────────────────────────────────────────────────────────
    {
      'title': 'Selesaikan 1 online course',
      'description': 'Ambil dan selesaikan 1 kursus online di platform seperti Udemy, Coursera, atau lainnya',
      'coins': 1400,
      'category': 'learning',
      'color': AppColors.primary,
      'keywords': ['belajar', 'kursus', 'online', 'course', 'programming', 'coding', 'bahasa'],
    },
    {
      'title': 'Baca 3 buku dalam sebulan',
      'description': 'Baca minimal 3 buku (fiksi/non-fiksi) dan tulis ringkasan singkat untuk setiap buku',
      'coins': 1100,
      'category': 'learning',
      'color': AppColors.primary,
      'keywords': ['baca', 'buku', 'membaca', 'literatur', 'novel', 'penulis'],
    },
    {
      'title': 'Kuasai skill programming baru',
      'description': 'Belajar dan praktik bahasa pemrograman baru (Python, JavaScript, Dart, dll) dalam 1 bulan',
      'coins': 1300,
      'category': 'learning',
      'color': AppColors.primary,
      'keywords': ['programming', 'coding', 'belajar', 'python', 'javascript', 'dart', 'flutter'],
    },

    // ── WELLNESS ───────────────────────────────────────────────────────────────
    {
      'title': 'Tidur berkualitas 30 hari',
      'description': 'Tidur 7-8 jam setiap malam selama 30 hari berturut-turut',
      'coins': 1000,
      'category': 'wellness',
      'color': AppColors.taskYellow,
      'keywords': ['tidur', 'meditasi', 'relaksasi', 'istirahat', 'wellness'],
    },
    {
      'title': 'Meditasi 365 hari',
      'description': 'Lakukan meditasi mindfulness 10 menit setiap hari selama 1 tahun penuh',
      'coins': 1500,
      'category': 'wellness',
      'color': AppColors.taskYellow,
      'keywords': ['meditasi', 'mindfulness', 'yoga', 'relaksasi', 'wellness', 'mental health'],
    },
    {
      'title': 'Kurangi screen time 50%',
      'description': 'Kurangi waktu bermain gadget hingga 50% dari biasanya selama 2 minggu',
      'coins': 1100,
      'category': 'wellness',
      'color': AppColors.taskYellow,
      'keywords': ['relaksasi', 'istirahat', 'gadget', 'wellness', 'mental'],
    },

    // ── FINANCIAL ──────────────────────────────────────────────────────────────
    {
      'title': 'Tabung 1 juta rupiah',
      'description': 'Kumpulkan dan simpan 1 juta rupiah dalam 3 bulan melalui tabungan atau investasi',
      'coins': 1300,
      'category': 'financial',
      'color': Colors.green,
      'keywords': ['tabung', 'hemat', 'keuangan', 'investasi', 'uang', 'budget'],
    },
    {
      'title': 'Buat budget dan patuh',
      'description': 'Buat budget bulanan terperinci dan patuhi dengan pengeluaran ≤ budget',
      'coins': 1100,
      'category': 'financial',
      'color': Colors.green,
      'keywords': ['hemat', 'budget', 'keuangan', 'investasi', 'uang'],
    },

    // ── SOCIAL ─────────────────────────────────────────────────────────────────
    {
      'title': 'Networking dengan 10 orang baru',
      'description': 'Bertemu dan bangun koneksi dengan 10 orang baru dalam 1 bulan',
      'coins': 1200,
      'category': 'social',
      'color': Colors.purple,
      'keywords': ['networking', 'sosial', 'meeting', 'komunitas', 'teman'],
    },
    {
      'title': 'Volunteer 10 jam',
      'description': 'Ikhlas melakukan kegiatan sosial/volunteer minimal 10 jam dalam 1 bulan',
      'coins': 1400,
      'category': 'social',
      'color': Colors.purple,
      'keywords': ['sosial', 'volunteer', 'komunitas', 'baik', 'membantu'],
    },
  ];

  /// Suggest goals berdasarkan list habit titles user
  ///
  /// Contoh:
  /// suggestGoals(['Lari pagi', 'Push-up', 'Yoga'])
  /// akan return fitness-related goals
  static List<SuggestedGoal> suggestGoals(List<String> habitTitles) {
    if (habitTitles.isEmpty) {
      // Return some default suggestions jika tidak ada habits
      return _getRandomSuggestions(3);
    }

    // Gabung semua habit titles menjadi satu string untuk keyword matching
    final combinedHabits = habitTitles.join(' ').toLowerCase();

    // Hitung score untuk setiap goal berdasarkan keyword match
    final scoredGoals = <Map<String, dynamic>>[];
    for (final goal in _goalDatabase) {
      int score = 0;
      final keywords = goal['keywords'] as List<String>;

      for (final keyword in keywords) {
        if (combinedHabits.contains(keyword.toLowerCase())) {
          score++;
        }
      }

      if (score > 0) {
        scoredGoals.add({
          ...goal,
          'score': score,
        });
      }
    }

    // Jika tidak ada match, return default suggestions
    if (scoredGoals.isEmpty) {
      return _getRandomSuggestions(3);
    }

    // Sort berdasarkan score (descending) dan ambil top 3
    scoredGoals.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final topGoals = scoredGoals.take(3).toList();

    return topGoals.map((g) => SuggestedGoal(
      title: g['title'] as String,
      description: g['description'] as String,
      coinReward: g['coins'] as int,
      color: g['color'] as Color,
      category: g['category'] as String,
    )).toList();
  }

  /// Get random suggestions jika tidak ada keyword match
  static List<SuggestedGoal> _getRandomSuggestions(int count) {
    final suggestions = <SuggestedGoal>[];
    final List<int> indices = [];

    // Ambil random indices
    while (indices.length < count && indices.length < _goalDatabase.length) {
      final randomIdx = DateTime.now().microsecond % _goalDatabase.length;
      if (!indices.contains(randomIdx)) {
        indices.add(randomIdx);
      }
    }

    for (final idx in indices) {
      final g = _goalDatabase[idx];
      suggestions.add(SuggestedGoal(
        title: g['title'] as String,
        description: g['description'] as String,
        coinReward: g['coins'] as int,
        color: g['color'] as Color,
        category: g['category'] as String,
      ));
    }

    return suggestions;
  }
}
