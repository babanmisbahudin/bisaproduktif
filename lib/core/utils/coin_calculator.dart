/// Algoritma otomatis kalkulasi reward koin
/// berdasarkan judul + deskripsi + deadline habit/goal
class CoinCalculator {
  // ── HABIT ─────────────────────────────────────────────────────────────────

  /// Hitung koin untuk habit berdasarkan judul.
  /// Makin berat/disiplin habit, makin besar reward.
  /// Optional: tambah bonus berdasarkan durasi (dalam hari)
  static int forHabit(String title, {int? durationDays}) {
    final t = title.toLowerCase();
    int base = _forHabitBase(t);

    if (durationDays != null) {
      base += _calculateHabitDurationBonus(durationDays);
    }

    return base;
  }

  /// Base coin calculation untuk habit (tanpa durasi)
  static int _forHabitBase(String t) {

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
  static HabitCategory habitCategory(String title, {int? durationDays}) {
    final coins = forHabit(title, durationDays: durationDays);
    final baseCoins = forHabit(title); // base tanpa durasi untuk kategori
    if (baseCoins >= 50) return HabitCategory('Aktivitas Fisik 💪', coins);
    if (baseCoins >= 35) return HabitCategory('Mindfulness 🧘', coins);
    if (baseCoins >= 30) return HabitCategory('Belajar & Produktif 📚', coins);
    if (baseCoins >= 25) return HabitCategory('Kebersihan & Rumah 🏠', coins);
    if (baseCoins >= 20) return HabitCategory('Kesehatan 🌿', coins);
    return HabitCategory('Sosial & Relasi 🤝', coins);
  }

  // ── GOAL ──────────────────────────────────────────────────────────────────

  /// Hitung koin untuk goal berdasarkan judul + deskripsi + deadline.
  /// Goal jangka panjang & kategori berat = lebih banyak koin.
  /// Optional: tambah bonus berdasarkan durasi user input (dalam bulan: 1, 3, 6)
  static int forGoal(
    String title,
    String description,
    DateTime? deadline, {
    int? durationMonths,
  }) {
    final t = '${title.toLowerCase()} ${description.toLowerCase()}';
    int base = _forGoalBase(t);

    // Faktor durasi: user input (durationMonths) prioritas dibanding deadline
    if (durationMonths != null) {
      base += _calculateGoalDurationBonus(durationMonths);
      return base;
    }

    // Fallback: gunakan deadline multiplier jika ada
    if (deadline != null) {
      final days = deadline.difference(DateTime.now()).inDays;
      if (days > 90) return (base * 2.0).round();
      if (days > 30) return (base * 1.5).round();
      if (days > 14) return (base * 1.2).round();
      if (days <= 7) return (base * 0.7).round();
    }

    return base;
  }

  /// Base coin calculation untuk goal (tanpa durasi)
  static int _forGoalBase(String t) {
    if (_has(t, [
      'hemat', 'nabung', 'tabung', 'investasi', 'modal', 'keuangan',
      'rupiah', 'uang', 'dana', 'cicilan', 'hutang',
    ])) {
      return 1000;
    } else if (_has(t, [
      'bisnis', 'project', 'proyek', 'startup', 'usaha', 'karir',
      'promosi', 'freelance', 'income', 'pendapatan', 'portfolio',
    ])) {
      return 750;
    } else if (_has(t, [
      'olahraga', 'gym', 'diet', 'berat badan', 'kurus', 'otot',
      'fitnes', 'workout', 'lari', 'maraton',
    ])) {
      return 600;
    } else if (_has(t, [
      'belajar', 'kursus', 'sertifikat', 'skill', 'coding', 'bahasa',
      'degree', 'sekolah', 'kuliah', 'ujian', 'nilai',
    ])) {
      return 500;
    } else if (_has(t, [
      'baca', 'buku', 'nulis', 'novel', 'karya', 'tulisan', 'artikel',
    ])) {
      return 350;
    } else if (_has(t, [
      'sehat', 'tidur', 'minum', 'vitamin', 'screen time', 'detoks',
    ])) {
      return 300;
    } else {
      return 300; // default
    }
  }

  /// Nama kategori + emoji berdasarkan judul goal
  static GoalCategory goalCategory(
    String title,
    String description,
    DateTime? deadline, {
    int? durationMonths,
  }) {
    final coins = forGoal(title, description, deadline, durationMonths: durationMonths);
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

  /// Hitung bonus koin untuk habit berdasarkan durasi (dalam hari)
  /// 30 hari = +5, 60 hari = +10, 90 hari = +15, dst
  static int _calculateHabitDurationBonus(int durationDays) {
    if (durationDays >= 90) return 15;
    if (durationDays >= 60) return 10;
    if (durationDays >= 30) return 5;
    return 2; // untuk durasi < 30 hari
  }

  /// Hitung bonus koin untuk goal berdasarkan durasi user input (dalam bulan)
  /// 1 bulan = +10, 3 bulan = +50, 6 bulan = +120
  static int _calculateGoalDurationBonus(int durationMonths) {
    if (durationMonths >= 6) return 120;
    if (durationMonths >= 3) return 50;
    if (durationMonths >= 1) return 10;
    return 0;
  }

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
