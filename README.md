# 🛡️ Finora Fblocker

[![Multi-Platform Build CI](https://github.com/Finoraaa/Fblocker/actions/workflows/build-all.yml/badge.svg)](https://github.com/Finoraaa/Fblocker/actions/workflows/build-all.yml)
[![Release](https://github.com/Finoraaa/Fblocker/actions/workflows/release.yml/badge.svg)](https://github.com/Finoraaa/Fblocker/actions/workflows/release.yml)
[![Platforms](https://img.shields.io/badge/platforms-Windows%20|%20Android%20|%20iOS%20|%20Linux%20|%20macOS-red.svg)](https://github.com/Finoraaa/Fblocker)
[![Brand](https://img.shields.io/badge/brand-Finora-FF2A44.svg)](https://github.com/Finoraaa)

**Finora Fblocker**, tüm cihaz ve işletim sistemlerinde sorunsuz çalışacak şekilde tasarlanmış, yüksek performanslı, açık kaynaklı yeni nesil siber reklam ve izleyici engelleyicidir.

Tek bir kod tabanından **GitHub Actions CI/CD** aracılığıyla tüm hedef işletim sistemleri için otomatik olarak yerel (native) paketler derlenir.

---

## 🎨 Tasarım & Renk Paleti (Finora Cyber Palette)

Fblocker, modern siber güvenlik ve gizlilik estetiğini yansıtan özel bir renk şeması ile üretilmiştir:

| Renk | Kod | Kullanım Alanı |
|---|---|---|
| **Siyah (Deep Onyx)** | `#090A0E` / `#111319` | Ana arka plan ve derin yüzeyler |
| **Koyu Gri (Carbon / Slate)** | `#171922` / `#2B2F3E` | Kartlar, kenarlıklar ve arayüz bileşenleri |
| **Açık Gri (Muted Silver)** | `#888E9E` / `#B4B9C8` | İkincil metinler, sayaç alt etiketleri |
| **Beyaz (Crisp White)** | `#FFFFFF` / `#F3F5FA` | Başlıklar, metinler ve vurgular |
| **Finora Kırmızısı (Crimson & Neon)** | `#FF2A44` / `#B8152B` | Kalkan, butonlar, engelleme sayaçları ve uyarı rozetleri |

---

## 📦 Desteklenen İşletim Sistemleri & Çıktılar

| İşletim Sistemi | Çıktı Formatı | Paket Türü | GitHub Actions Derleyicisi |
|---|---|---|---|
| 🪟 **Windows** | `.exe` / `.zip` | Inno Setup Kurulum Sihirbazı (`Fblocker-Setup.exe`) & Taşınabilir Arşiv (`Fblocker-windows-x64.zip`) | `windows-latest` |
| 🤖 **Android** | `.apk` | Bağımsız Kurulabilir Release APK (`Fblocker.apk`) | `ubuntu-latest` (Java 17 + Android SDK) |
| 🐧 **Linux** | `.deb` | Debian / Ubuntu / Mint Kurulum Paketi (`fblocker-linux-amd64.deb`) | `ubuntu-latest` |
| 🐧 **Linux** | `.AppImage` | Evrensel Çalıştırılabilir Linux Paketi (`Fblocker-linux-x86_64.AppImage`) | `ubuntu-latest` (appimagetool) |
| 🍎 **macOS** | `.dmg` / `.zip` | Apple Disk Image (`Fblocker-macOS.dmg`) ve Uygulama Paketi | `macos-latest` |
| 📱 **iOS** | `.ipa` | Sideloadable IPA Paketi (`Fblocker-iOS-unsigned.ipa`) | `macos-latest` (Xcode CLI) |

---

## ⚙️ GitHub Actions CI/CD Mimarisi

Uygulamanın GitHub Actions yapılandırması iki ana iş akışından oluşur:

1. **`.github/workflows/build-all.yml`**:
   - `main` dalına her kod gönderildiğinde (`push`) veya manuel tetiklendiğinde (`workflow_dispatch`) çalışır.
   - 5 işletim sistemi derleyicisini paralel olarak ayağa kaldırır.
   - Her platformun derlenmiş çıktılarını GitHub Artifacts olarak depolar.

2. **`.github/workflows/release.yml`**:
   - Yeni bir versiyon etiketi (`v*`, örn: `v1.0.0`) basıldığında veya manuel sürüm oluşturulduğunda çalışır.
   - Tüm platformlar için paketleri derler ve otomatik olarak bir **GitHub Release** yayınlayarak tüm ikili dosyaları (`.exe`, `.apk`, `.deb`, `.AppImage`, `.dmg`, `.ipa`) ekler.

---

## 🚀 Yerel Geliştirme ve Derleme

### Gereksinimler
- Flutter SDK (>= 3.13)
- Git

### Projeyi Çalıştırma

```bash
# Bağımlılıkları yükleyin
flutter pub get

# Testleri çalıştırın
flutter test

# Yerel ortamınızda başlatın (Linux/Windows/macOS/Android)
flutter run
```

### Manuel Derleme Komutları

```bash
# Linux
flutter build linux --release
./packaging/linux/build-deb.sh 1.0.0
./packaging/linux/build-appimage.sh

# Android
flutter build apk --release

# Windows (Windows ortamında)
flutter build windows --release

# macOS (macOS ortamında)
flutter build macos --release

# iOS (macOS ortamında)
flutter build ios --release --no-codesign
```

---

## 🗺️ Yol Haritası (Roadmap)

- [x] Tüm işletim sistemleri için tek kod tabanından çapraz derleme altyapısı (Windows, Linux, macOS, Android, iOS)
- [x] GitHub Actions matrisi (.exe, .apk, .deb, .AppImage, .dmg, .ipa)
- [x] Finora siyah-gri-beyaz-kırmızı modern siber güvenlik arayüzü
- [x] Canlı trafik inceleme günlüğü, kalkan animasyonu ve istatistik sayaçları
- [x] Dahili kural veritabanı (Finora Core, EasyList, AdGuard) ve Beyaz/Kara liste yönetimi
- [ ] Platforma özel yerel VPN / Local TUN arayüzü (Android VpnService & iOS NetworkExtension entegrasyonu)
- [ ] Yerel sistem DNS ve hosts dosyası proxy servisi
- [ ] Finora Cloud Kalkanı ve otomatik kural güncelleme senkronizasyonu

---

## 📄 Lisans & Marka

© 2026 **Finora**. Tüm hakları saklıdır.  
Resmi Depo: [Finoraaa/Fblocker](https://github.com/Finoraaa/Fblocker.git)
