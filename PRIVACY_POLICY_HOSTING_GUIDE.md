# Panduan Hosting Privacy Policy untuk AdMob

Anda memerlukan **URL publik** untuk Privacy Policy yang bisa diakses oleh Google dan users. Pilih salah satu cara di bawah:

---

## ✅ PILIHAN 1: GitHub Pages (FREE & EASY) - REKOMENDASI

### Step 1: Siapkan GitHub
```bash
# Jika belum install git
# Download dari: https://git-scm.com

git config --global user.name "Your Name"
git config --global user.email "your-email@gmail.com"
```

### Step 2: Buat GitHub Repository
1. Login ke [GitHub](https://github.com)
2. Click **+** → **New repository**
3. Name: `bisaproduktif-privacy`
4. Description: `Privacy Policy for BisaProduktif App`
5. Make it **Public**
6. Click **Create repository**

### Step 3: Upload Privacy Policy
```bash
# Clone repository
git clone https://github.com/YOUR-USERNAME/bisaproduktif-privacy.git
cd bisaproduktif-privacy

# Copy PRIVACY_POLICY.md file ke folder
cp /path/to/PRIVACY_POLICY.md ./index.md

# Buat file .gitignore
echo ".DS_Store" > .gitignore

# Commit & push
git add .
git commit -m "Add privacy policy"
git push origin main
```

### Step 4: Enable GitHub Pages
1. Buka repository settings
2. Scroll ke **GitHub Pages** section
3. Source: **main** branch
4. Root: **/ (root)**
5. Custom domain: (biarkan kosong atau masukkan domain sendiri)
6. Save

### Step 5: Get Your URL
GitHub akan generate URL:
```
https://YOUR-USERNAME.github.io/bisaproduktif-privacy/
```

**Contoh:**
```
https://babanmisbahudin.github.io/bisaproduktif-privacy/
```

---

## ✅ PILIHAN 2: Vercel (FREE & FAST)

### Step 1: Deploy
```bash
# Install vercel CLI
npm install -g vercel

# Di folder dengan PRIVACY_POLICY.md
vercel

# Follow prompts, pilih:
# - Scope: personal
# - Linked to: existing project
# - Deploy: yes
```

### Step 2: Get Your URL
Vercel akan generate:
```
https://bisaproduktif-privacy.vercel.app
```

---

## ✅ PILIHAN 3: Netlify (FREE)

1. Zip folder dengan `PRIVACY_POLICY.md`
2. Login ke [Netlify](https://netlify.com)
3. Drag & drop folder
4. Get your site URL:
```
https://bisaproduktif-privacy.netlify.app
```

---

## ✅ PILIHAN 4: Your Own Website (JIKA PUNYA)

Jika Anda sudah punya website:

```bash
# Upload ke root domain
# File: public_html/privacy-policy.html

# Atau buat subdomain:
# privacy.yourdomain.com/index.html
```

**URL:**
```
https://yourdomain.com/privacy-policy.html
```

---

## ⚙️ Setup untuk AdMob

Setelah privacy policy online:

### Di Google Play Console:
1. Open **BisaProduktif** app
2. Go to **App content → Privacy Policy**
3. Paste URL:
```
https://YOUR-USERNAME.github.io/bisaproduktif-privacy/
```
4. Save

### Di AdMob Console:
1. Account Settings → Policies
2. Add Privacy Policy URL if required
3. Save

---

## 🔍 Testing

Verify privacy policy accessible:

```bash
# Linux/Mac
curl https://YOUR-USERNAME.github.io/bisaproduktif-privacy/

# Atau cukup buka di browser
# Harus loading tanpa error 404
```

---

## 📝 Update Privacy Policy

Jika ada perubahan:

```bash
# GitHub method
git pull
# Edit PRIVACY_POLICY.md
git add .
git commit -m "Update privacy policy - add new feature"
git push

# Changes live immediately
```

---

## ❗ Important Notes

1. **Public Access**: Privacy policy HARUS accessible tanpa login/password
2. **HTTPS**: URL harus HTTPS (GitHub/Vercel/Netlify provide gratis)
3. **Performance**: Harus load < 3 detik
4. **Mobile Friendly**: Should readable di mobile (Markdown format OK)
5. **Update Regularly**: Setiap ada perubahan feature, update privacy policy

---

## 📌 Recommended Setup for BisaProduktif

```
Pilihan: GitHub Pages
URL: https://YOUR-USERNAME.github.io/bisaproduktif-privacy/
Setup Time: ~5 menit
Cost: Free
Maintenance: Easy (git push)
```

---

## ✅ Verification Checklist

- [ ] Privacy policy URL accessible di browser
- [ ] URL HTTPS (not HTTP)
- [ ] Page loads < 3 seconds
- [ ] Content readable on mobile
- [ ] URL added to Google Play Console
- [ ] URL added to AdMob if required
- [ ] Screenshot saved for reference

---

**Setelah setup complete, gunakan URL ini untuk AdMob!**
