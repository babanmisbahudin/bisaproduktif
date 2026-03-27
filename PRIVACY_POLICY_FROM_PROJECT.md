# Privacy Policy dari Project Repository

Privacy Policy sudah ada di project dalam format HTML yang siap di-publish:

```
File: web/privacy-policy.html
Status: Ready
```

## 🚀 Setup (Super Simpel - 2 MENIT)

### Step 1: Push Project ke GitHub

Jika belum:
```bash
cd ~/AndroidStudioProjects/bisaproduktif

git remote add origin https://github.com/YOUR-USERNAME/bisaproduktif.git
git branch -M main
git push -u origin main
```

Atau jika sudah punya repo:
```bash
git add .
git commit -m "Add privacy policy HTML"
git push origin main
```

### Step 2: Enable GitHub Pages

1. Buka https://github.com/YOUR-USERNAME/bisaproduktif
2. Click **Settings** (gear icon)
3. Scroll ke sidebar kiri → **Pages**
4. Source: **main** branch
5. Folder: **/root**
6. Click **Save**

Tunggu 1-2 menit...

### Step 3: Your Privacy Policy URL

GitHub akan generate:

```
https://YOUR-USERNAME.github.io/bisaproduktif/web/privacy-policy.html
```

**Contoh:**
```
https://babanmisbahudin.github.io/bisaproduktif/web/privacy-policy.html
```

## ✅ Paste ke Google Play Console

1. Open Google Play Console
2. Select BisaProduktif
3. App content → Privacy Policy
4. Paste URL:
   ```
   https://YOUR-USERNAME.github.io/bisaproduktif/web/privacy-policy.html
   ```
5. Save

## 🔍 Test

Buka di browser:
```
https://YOUR-USERNAME.github.io/bisaproduktif/web/privacy-policy.html
```

Harus bisa dibaca dengan baik.

## 💡 Update Privacy Policy

Jika ada perubahan di masa depan:

```bash
# Edit file web/privacy-policy.html
vim web/privacy-policy.html

# Commit & push
git add web/privacy-policy.html
git commit -m "Update privacy policy"
git push origin main
```

Changes live immediately (dalam 1-2 menit).

---

**Itu saja!** Privacy policy langsung live dari GitHub Pages.
