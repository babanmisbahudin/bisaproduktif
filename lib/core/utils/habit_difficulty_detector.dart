import '../../data/models/habit_model.dart';

/// Algoritma auto-detect tingkat kesulitan habit berdasarkan nama kegiatan.
/// User tidak bisa memilih sendiri — sistem yang menentukan.
class HabitDifficultyDetector {
  /// Deteksi kategori dari judul habit
  static HabitCategory detect(String title) {
    final t = title.toLowerCase().trim();
    if (t.isEmpty) return HabitCategory.sedang;

    if (_matchesSangatBerat(t)) return HabitCategory.sangatBerat;
    if (_matchesBerat(t))       return HabitCategory.berat;
    if (_matchesRingan(t))      return HabitCategory.ringan;
    return HabitCategory.sedang; // default
  }

  // ── Sangat Berat (💎 15 koin) ──────────────────────────────────────────────
  // Kegiatan yang butuh komitmen ekstrem, meninggalkan kebiasaan buruk,
  // atau ibadah sunnah berat
  static bool _matchesSangatBerat(String t) {
    return _containsAny(t, [
      // Ibadah ekstrem
      'puasa daud', 'puasa senin kamis', 'puasa senin', 'puasa kamis',
      'tahajud', 'sholat tahajud', 'qiyamul lail',
      'hafalan quran', 'hafalan surat', 'menghafal quran',
      'i\'tikaf', 'itikaf',
      // Melepas kebiasaan buruk
      'berhenti rokok', 'quit smoking', 'stop rokok', 'tidak merokok',
      'berhenti main game', 'stop gadget', 'detox media sosial',
      'berhenti begadang', 'tidak begadang',
      'berhenti minum kopi', 'stop alkohol',
      // Olahraga ekstrem
      'marathon', 'half marathon', 'triathlon', 'ultramarathon',
      'lari 10km', 'lari 10 km', 'lari 15km', 'lari 20km',
      'cold shower', 'mandi air dingin setiap hari',
      'plank 5 menit', 'plank 10 menit',
      // Komitmen harian berat
      'bangun jam 4', 'bangun jam 3', 'bangun sebelum subuh',
      'tidur sebelum jam 10', 'tidur jam 9',
      'intermittent fasting', 'one meal a day', 'omad',
    ]);
  }

  // ── Berat (🔥 10 koin) ────────────────────────────────────────────────────
  // Olahraga terstruktur, diet ketat, ibadah sunnah rutin, belajar intensif
  static bool _matchesBerat(String t) {
    return _containsAny(t, [
      // Olahraga
      'gym', 'angkat beban', 'weight lifting', 'bench press',
      'lari', 'jogging', 'sprint', 'lari pagi', 'lari sore',
      'berenang', 'renang', 'swimming',
      'bersepeda', 'sepeda', 'cycling',
      'push up', 'push-up', 'pushup',
      'pull up', 'pull-up', 'pullup',
      'sit up', 'sit-up', 'situp',
      'squat', 'deadlift', 'burpee',
      'hiit', 'tabata', 'circuit training',
      'yoga', 'pilates',
      'martial art', 'karate', 'taekwondo', 'silat', 'boxing', 'tinju',
      'futsal', 'basket', 'badminton', 'tenis',
      'olahraga', 'workout', 'training', 'latihan',
      // Diet
      'diet', 'kalori', 'calorie', 'makan sehat ketat',
      'no sugar', 'tanpa gula', 'no junk food', 'tanpa junkfood',
      'puasa makan', 'skip makan siang',
      // Ibadah terstruktur
      'puasa', 'berpuasa', 'sholat dhuha', 'sholat rawatib',
      'shodaqoh', 'sedekah harian', 'infaq',
      // Belajar intensif
      'coding', 'programming', 'belajar bahasa', 'kursus',
      'ujian', 'latihan soal', 'belajar 2 jam', 'belajar 3 jam',
      'baca jurnal', 'riset', 'skripsi', 'thesis',
      // Kerja produktif berat
      'deadline', 'presentasi', 'pitching', 'public speaking',
      'menulis artikel', 'nulis artikel', 'blog post',
    ]);
  }

  // ── Ringan (🌱 3 koin) ────────────────────────────────────────────────────
  // Kebiasaan kecil yang mudah dilakukan, tidak butuh effort besar
  static bool _matchesRingan(String t) {
    return _containsAny(t, [
      // Hidrasi & makan dasar
      'minum air', 'minum 8 gelas', 'minum vitamin', 'vitamin',
      'makan buah', 'makan sayur', 'sarapan',
      // Kebersihan & kesehatan ringan
      'sikat gigi', 'cuci tangan', 'mandi',
      'tidur cukup', 'tidur 7', 'tidur 8', 'tidur tepat waktu',
      'stretching', 'peregangan', 'jalan santai', 'jalan kaki 10',
      // Spiritual ringan
      'baca doa', 'doa pagi', 'doa malam', 'doa sebelum tidur',
      'dzikir', 'istighfar', 'bersyukur', 'syukur',
      'senyum', 'berbagi', 'sapa tetangga',
      // Mental & journaling
      'jurnal', 'journaling', 'nulis jurnal', 'menulis jurnal',
      'meditasi', 'meditasi 5 menit', 'meditasi 10 menit',
      'afirmasi', 'bersyukur', 'gratitude',
      'istirahat', 'relaksasi', 'me time',
      // Sosial ringan
      'hubungi orang tua', 'telepon orang tua', 'wa orang tua',
      'hubungi keluarga', 'kunjungi', 'sapa',
      // Produktif ringan
      'baca berita', 'baca 10 menit', 'baca 15 menit',
      'rapikan meja', 'beresin kamar', 'beberes',
      'cek email', 'balas pesan', 'to-do list', 'todo',
    ]);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  /// Daftar contoh kegiatan per kategori (untuk ditampilkan ke user)
  static const Map<HabitCategory, List<String>> examples = {
    HabitCategory.ringan: [
      'Minum 8 gelas air',
      'Minum vitamin',
      'Doa pagi & malam',
      'Dzikir setelah sholat',
      'Jurnal harian',
      'Meditasi 5 menit',
      'Hubungi orang tua',
      'Rapikan kamar',
      'Stretching pagi',
      'Sarapan sehat',
    ],
    HabitCategory.sedang: [
      'Sholat 5 waktu',
      'Baca Quran',
      'Sholat Dhuha',
      'Belajar 30 menit',
      'Membaca buku',
      'Review materi',
      'Masak sendiri',
      'Bersih-bersih rumah',
      'Sedekah',
      'Jalan kaki 30 menit',
    ],
    HabitCategory.berat: [
      'Gym / angkat beban',
      'Lari pagi',
      'Push-up & sit-up',
      'Yoga / Pilates',
      'Berenang',
      'Diet ketat',
      'Belajar coding',
      'Puasa sunnah',
      'Latihan soal ujian',
      'Olahraga 1 jam',
    ],
    HabitCategory.sangatBerat: [
      'Puasa Senin & Kamis',
      'Sholat Tahajud',
      'Hafalan Al-Quran',
      'Berhenti merokok',
      'Detox media sosial',
      'Bangun sebelum Subuh',
      'Lari 10 km',
      'Marathon training',
      'Cold shower',
      'Intermittent fasting',
    ],
  };
}
