# app-ads.txt Setup Guide

## Apa itu app-ads.txt?

`app-ads.txt` adalah file yang membantu Google memverifikasi bahwa iklan di aplikasi Anda asli dan dijual melalui penerbit yang sah.

## Langkah Setup

### 1. Dapatkan Publisher ID dari AdMob
- Login ke [AdMob Console](https://admob.google.com)
- Buka **Settings** → **Account Information**
- Catat Publisher ID Anda (format: `pub-xxxxxxxxxxxxxxxx`)

Untuk BisaProduktif:
```
pub-2488741073756667
```

### 2. Buat File app-ads.txt

Buat file dengan nama `app-ads.txt` dengan konten:

```
google.com, pub-2488741073756667, DIRECT, f08c47fec0942fa0
```

**Penjelasan:**
- `google.com` - Google AdMob
- `pub-2488741073756667` - Publisher ID Anda
- `DIRECT` - Penjualan langsung ke Google
- `f08c47fec0942fa0` - Verification ID (selalu sama untuk Google)

### 3. Upload ke Website/Domain

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

### 4. Verifikasi di Google Play Console

1. Buka [Google Play Console](https://play.google.com/console)
2. Pilih aplikasi BisaProduktif
3. Buka **Monetization** → **Ads** (atau sesuai menu)
4. Masukkan URL app-ads.txt:
   ```
   https://yourdomain.com/app-ads.txt
   ```
5. Verifikasi dengan tombol **Verify**

## Testing

Setelah upload:

```bash
# Test dengan curl
curl https://yourdomain.com/app-ads.txt

# Harus return:
# google.com, pub-2488741073756667, DIRECT, f08c47fec0942fa0
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| File tidak ditemukan | Cek URL dan file permission (harus accessible public) |
| CORS error | File harus accessible tanpa authentication |
| Verification gagal | Tunggu 24 jam setelah upload, publisher ID harus benar |

## Reference

- [Google app-ads.txt Documentation](https://support.google.com/admob/answer/6294239)
- [App-ads.txt Official Spec](https://iabtechlab.com/ads-txt/)

---

**Status**: Ready to implement setelah domain siap
