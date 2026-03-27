# BisaProduktif - PROJECT DOCUMENTATION

**Last Updated**: Maret 2026
**Version**: 1.0

---

## TABLE OF CONTENTS
1. [Project Overview](#project-overview)
2. [Privacy Policy](#privacy-policy)
3. [App-ads.txt Setup](#app-adstxt-setup)
4. [Privacy Policy Hosting](#privacy-policy-hosting)

---

## PROJECT OVERVIEW

BisaProduktif adalah aplikasi Flutter untuk productivity tracking dengan gamified system.

**Tech Stack:**
- Framework: Flutter (Android)
- State Management: Provider
- Backend: Firebase (Auth + Firestore)
- Database Local: Hive + SharedPreferences
- Ads: Google AdMob
- Weather: OpenWeatherMap API
- Authentication: Google Sign-In

**Key Contacts:**
- Email: babanmisbahudin200@gmail.com
- AdMob Publisher ID: `pub-2488741073756667`

---

## PRIVACY POLICY

**Terakhir diperbarui: Maret 2026**

### 1. Informasi yang Kami Kumpulkan

#### A. Informasi yang Anda Berikan
- **Nama Pengguna** - saat registrasi/login
- **Gender** - untuk personalisasi avatar
- **Nomor WhatsApp** - untuk reward redemption verification
- **Email** - melalui Google Sign-In (opsional)

#### B. Informasi yang Dikumpulkan Otomatis
- **Data Penggunaan** - aktivitas di app (habits, goals, rewards)
- **Device Information** - jenis device, OS version
- **Lokasi (IP-based)** - untuk deteksi cuaca, bukan GPS
- **Crash Reports & Analytics** - untuk improve performance

#### C. Data Iklan
Ketika Anda menonton iklan AdMob:
- **Watch Duration** - berapa lama Anda menonton
- **Ad Interaction** - apakah Anda click atau skip iklan
- **Ad ID** - untuk tie ke reward system

### 2. Bagaimana Kami Menggunakan Data

| Data | Kegunaan | Legal Basis |
|------|----------|-------------|
| Nama, Gender | Personalisasi experience | Kontrak |
| WhatsApp | Reward verification | Kontrak |
| Aktivitas (habits/goals) | Core app functionality | Kontrak |
| Analytics | Improve app performance | Legitimate Interest |
| Iklan viewing | Award coins, track anti-fraud | Kontrak |
| Email (Google Sign-In) | Backup data ke cloud | Consent |

### 3. Third-Party Services

#### Google AdMob
- **Purpose**: Display iklan, reward system
- **Data shared**: Ad interaction, watch duration
- **Privacy Policy**: https://policies.google.com/privacy
- **Opt-out**: Settings → Privacy → Reject Personalized Ads

#### Firebase (Google)
- **Purpose**: User authentication, data backup, analytics
- **Data shared**: User profile, activity logs
- **Privacy Policy**: https://firebase.google.com/support/privacy

#### Google Analytics
- **Purpose**: Track app usage, crash reporting
- **Data shared**: Device info, crash logs, analytics events
- **Privacy Policy**: https://policies.google.com/privacy

#### OpenWeatherMap API
- **Purpose**: Weather data untuk scene background
- **Data shared**: Approximate location (IP-based only)
- **Privacy Policy**: https://openweathermap.org/privacy

### 4. Data Security

Kami menerapkan:
- ✅ **SSL/TLS Encryption** - semua komunikasi dengan server dienkripsi
- ✅ **Firebase Security Rules** - database hanya accessible oleh owner
- ✅ **No Password Stored Locally** - gunakan Google Sign-In atau session token
- ✅ **Anti-Fraud Detection** - trust score system untuk deteksi suspicious activity
- ✅ **Server-Side Validation** - coin transactions diverifikasi di backend

### 5. Data Retention

- **User Data**: Disimpan selama akun aktif
- **Activity Logs**: Disimpan maksimal 90 hari untuk audit
- **Crash Reports**: Disimpan 30 hari untuk debugging
- **Deleted Account**: Soft-deleted (data tetap di backup), hard-delete setelah 90 hari

### 6. Your Privacy Rights (GDPR/EEA)

Jika Anda berada di EEA, UK, atau Switzerland:

- **Right to Access**: Request data apa yang kami simpan tentang Anda
- **Right to Rectification**: Minta kami update data yang tidak akurat
- **Right to Erasure**: "Right to be forgotten" - minta hapus semua data
- **Right to Data Portability**: Download data Anda dalam format standar
- **Right to Withdraw Consent**: Ubah preference iklan kapan saja

**Cara Exercise Your Rights:**
Email: babanmisbahudin200@gmail.com dengan:
- Full name & user ID
- Type of request (access/delete/export)
- Response dalam 30 hari

### 7. Children's Privacy

BisaProduktif tidak menerima users di bawah 13 tahun (16 tahun untuk EEA). Jika kami tahu ada child yang register, kami akan delete akun + data mereka.

### 8. Consent Management

Saat membuka aplikasi, Anda akan diminta memberikan consent untuk:

1. **Essential Data** - Required for app to function (nama, aktivitas)
2. **Analytics** - Help improve app performance
3. **Personalized Ads** - Show relevant ads based on interest

Anda dapat mengubah preference kapan saja di:
**Settings → Privacy → Change Consent Preferences**

---

## APP-ADS.TXT SETUP

### Apa itu app-ads.txt?

`app-ads.txt` adalah file yang membantu Google memverifikasi bahwa iklan di aplikasi Anda asli dan dijual melalui penerbit yang sah.

### Langkah Setup

#### 1. Dapatkan Publisher ID dari AdMob
- Login ke [AdMob Console](https://admob.google.com)
- Buka **Settings** → **Account Information**
- Catat Publisher ID Anda (format: `pub-xxxxxxxxxxxxxxxx`)

**Untuk BisaProduktif:**
```
pub-2488741073756667
```

#### 2. Buat File app-ads.txt

Buat file dengan nama `app-ads.txt` dengan konten:

```
google.com, pub-2488741073756667, DIRECT, f08c47fec0942fa0
```

**Penjelasan:**
- `google.com` - Google AdMob
- `pub-2488741073756667` - Publisher ID Anda
- `DIRECT` - Penjualan langsung ke Google
- `f08c47fec0942fa0` - Verification ID (selalu sama untuk Google)

#### 3. Upload ke Website/Domain

Jika Anda memiliki website, upload file ke:
```
https://yourdomain.com/app-ads.txt
```

**Contoh struktur:**
```
/public/app-ads.txt          (untuk root domain)
atau
/app-ads.txt                 (jika di root folder)
```

#### 4. Verifikasi di Google Play Console

1. Buka [Google Play Console](https://play.google.com/console)
2. Pilih aplikasi BisaProduktif
3. Buka **Monetization** → **Ads** (atau sesuai menu)
4. Masukkan URL app-ads.txt:
   ```
   https://yourdomain.com/app-ads.txt
   ```
5. Verifikasi dengan tombol **Verify**

#### Testing

Setelah upload:

```bash
# Test dengan curl
curl https://yourdomain.com/app-ads.txt

# Harus return:
# google.com, pub-2488741073756667, DIRECT, f08c47fec0942fa0
```

#### Troubleshooting

| Problem | Solution |
|---------|----------|
| File tidak ditemukan | Cek URL dan file permission (harus accessible public) |
| CORS error | File harus accessible tanpa authentication |
| Verification gagal | Tunggu 24 jam setelah upload, publisher ID harus benar |

#### Reference

- [Google app-ads.txt Documentation](https://support.google.com/admob/answer/6294239)
- [App-ads.txt Official Spec](https://iabtechlab.com/ads-txt/)

---

## PRIVACY POLICY HOSTING

Privacy policy sudah di-host di GitHub Pages dan bisa diakses di:

```
https://babanmisbahudin.github.io/bisaproduktif/
```

### Files:
- **HTML Version**: `/web/privacy-policy.html` - Responsive design, bisa dibaca di mobile
- **Markdown Version**: `PRIVACY_POLICY.md` - Source markdown

### Setup (sudah selesai):
✅ Privacy policy HTML file di `/docs/index.html`
✅ GitHub Pages configured dengan `/docs` folder
✅ Master branch dipilih sebagai source
✅ URL live dan accessible

### Update Privacy Policy:

Jika ada perubahan:

```bash
# Edit file
vim web/privacy-policy.html

# Commit & push
git add web/privacy-policy.html
git commit -m "Update privacy policy"
git push origin master
```

Changes live dalam 1-2 menit.

### Paste ke Google Play Console:

1. Open Google Play Console
2. Select BisaProduktif
3. App content → Privacy Policy
4. Paste URL: `https://babanmisbahudin.github.io/bisaproduktif/`
5. Save

---

## IMPORTANT CONTACTS & IDs

**AdMob:**
- Publisher ID: `pub-2488741073756667`
- Verification ID: `f08c47fec0942fa0`
- Test Ad Unit ID: `ca-app-pub-3940256099954163/5224354917`

**Firebase:**
- Project: BisaProduktif
- Auth: Google Sign-In enabled
- Firestore: Production mode

**Privacy & Compliance:**
- Privacy Officer Email: babanmisbahudin200@gmail.com
- Privacy Policy URL: https://babanmisbahudin.github.io/bisaproduktif/
- GDPR Compliant: Yes (CMP implemented)

---

**Generated**: Maret 2026
