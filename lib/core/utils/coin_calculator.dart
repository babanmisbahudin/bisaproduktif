/// Algoritma otomatis kalkulasi reward koin
/// berdasarkan judul + deskripsi + deadline habit/goal
class CoinCalculator {
  // ── HABIT ─────────────────────────────────────────────────────────────────

  /// Hitung koin untuk habit berdasarkan judul.
  /// Makin berat/disiplin habit, makin besar reward.
  static int forHabit(String title) {
    final t = title.toLowerCase();

    // Aktivitas fisik — usaha terbesar, reward tertinggi
    if (_has(t, [
      'olahraga', 'workout', 'gym', 'lari', 'jogging', 'sprint', 'fitnes',
      'fitness', 'renang', 'berenang', 'sepeda', 'bersepeda',
      'push up', 'sit up', 'pull up', 'squat', 'plank', 'angkat beban',
      'aerobik', 'zumba', 'badminton', 'basket', 'futsal', 'bola',
    ])) {
      return 50;
    }

    // Mindfulness & spiritual
    if (_has(t, [
      'meditasi', 'yoga', 'sholat', 'ibadah', 'salat', 'doa', 'ngaji',
      'berdoa', 'syukur', 'grateful', 'gratitude', 'jurnal', 'refleksi',
      'puasa', 'sedekah',
    ])) {
      return 35;
    }

    // Belajar & produktivitas
    if (_has(t, [
      'baca', 'buku', 'belajar', 'coding', 'nulis', 'menulis',
      'kursus', 'latihan', 'skill', 'podcast', 'artikel', 'riset',
      'studi', 'review', 'presentasi', 'kuliah', 'les',
    ])) {
      return 30;
    }

    // Kebersihan & rumah tangga
    if (_has(t, [
      'rapih', 'rapikan', 'bersih', 'bersihin', 'cuci', 'gosok', 'mandi',
      'kamar', 'rumah', 'sapu', 'pel', 'piring', 'laundry', 'cuci baju',
      'setrika', 'buang sampah',
    ])) {
      return 25;
    }

    // Kesehatan & nutrisi
    if (_has(t, [
      'minum', 'air', 'putih', 'makan', 'sayur', 'buah', 'vitamin',
      'suplemen', 'tidur', 'istirahat', 'diet', 'sehat', 'sarapan',
      'jangan begadang', 'screen time',
    ])) {
      return 20;
    }

    // Sosial & relasi
    if (_has(t, [
      'telpon', 'hubungi', 'keluarga', 'teman', 'sahabat',
      'kunjungi', 'chat', 'sapa', 'kirim pesan',
    ])) {
      return 15;
    }

    return 20; // default
  }

  /// Nama kategori + emoji berdasarkan judul habit
  static HabitCategory habitCategory(String title) {
    final coins = forHabit(title);
    if (coins >= 50) return HabitCategory('Aktivitas Fisik 💪', coins);
    if (coins >= 35) return HabitCategory('Mindfulness 🧘', coins);
    if (coins >= 30) return HabitCategory('Belajar & Produktif 📚', coins);
    if (coins >= 25) return HabitCategory('Kebersihan & Rumah 🏠', coins);
    if (coins >= 20) return HabitCategory('Kesehatan 🌿', coins);
    return HabitCategory('Sosial & Relasi 🤝', coins);
  }

  // ── GOAL ──────────────────────────────────────────────────────────────────

  /// Hitung koin untuk goal berdasarkan judul + deskripsi + deadline.
  /// Goal jangka panjang & kategori berat = lebih banyak koin.
  static int forGoal(String title, String description, DateTime? deadline) {
    final t = '${title.toLowerCase()} ${description.toLowerCase()}';

    // Base koin berdasarkan kategori
    int base;
    if (_has(t, [
      'hemat', 'nabung', 'tabung', 'investasi', 'modal', 'keuangan',
      'rupiah', 'uang', 'dana', 'cicilan', 'hutang',
    ])) {
      base = 1000;
    } else if (_has(t, [
      'bisnis', 'project', 'proyek', 'startup', 'usaha', 'karir',
      'promosi', 'freelance', 'income', 'pendapatan', 'portfolio',
    ])) {
      base = 750;
    } else if (_has(t, [
      'olahraga', 'gym', 'diet', 'berat badan', 'kurus', 'otot',
      'fitnes', 'workout', 'lari', 'maraton',
    ])) {
      base = 600;
    } else if (_has(t, [
      'belajar', 'kursus', 'sertifikat', 'skill', 'coding', 'bahasa',
      'degree', 'sekolah', 'kuliah', 'ujian', 'nilai',
    ])) {
      base = 500;
    } else if (_has(t, [
      'baca', 'buku', 'nulis', 'novel', 'karya', 'tulisan', 'artikel',
    ])) {
      base = 350;
    } else if (_has(t, [
      'sehat', 'tidur', 'minum', 'vitamin', 'screen time', 'detoks',
    ])) {
      base = 300;
    } else {
      base = 300; // default
    }

    // Faktor durasi deadline
    if (deadline != null) {
      final days = deadline.difference(DateTime.now()).inDays;
      if (days > 90) return (base * 2.0).round();
      if (days > 30) return (base * 1.5).round();
      if (days > 14) return (base * 1.2).round();
      if (days <= 7) return (base * 0.7).round();
    }

    return base;
  }

  /// Nama kategori + emoji berdasarkan judul goal
  static GoalCategory goalCategory(
      String title, String description, DateTime? deadline) {
    final coins = forGoal(title, description, deadline);
    final t = '${title.toLowerCase()} ${description.toLowerCase()}';

    String name;
    if (_has(t, ['hemat', 'nabung', 'tabung', 'investasi', 'keuangan', 'uang'])) {
      name = 'Keuangan 💰';
    } else if (_has(t, ['bisnis', 'karir', 'startup', 'kerja', 'freelance'])) {
      name = 'Karir & Bisnis 🚀';
    } else if (_has(t, ['gym', 'olahraga', 'diet', 'berat badan', 'fitnes'])) {
      name = 'Kesehatan Fisik 💪';
    } else if (_has(t, ['belajar', 'kursus', 'skill', 'kuliah', 'sertifikat'])) {
      name = 'Pendidikan 📚';
    } else if (_has(t, ['baca', 'buku', 'nulis', 'novel'])) {
      name = 'Literasi 📖';
    } else {
      name = 'Personal 🎯';
    }

    // Tambah info durasi jika ada deadline
    if (deadline != null) {
      final days = deadline.difference(DateTime.now()).inDays;
      if (days > 30) {
        name += ' · Jangka Panjang';
      } else if (days > 7) {
        name += ' · Jangka Menengah';
      } else {
        name += ' · Jangka Pendek';
      }
    }

    return GoalCategory(name, coins);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static bool _has(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}

class HabitCategory {
  final String label;
  final int coins;
  const HabitCategory(this.label, this.coins);
}

class GoalCategory {
  final String label;
  final int coins;
  const GoalCategory(this.label, this.coins);
}
