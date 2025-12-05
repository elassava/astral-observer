# 🛸 UFO Sightings Visualization Project

MATLAB tabanlı UFO gözlem verilerini analiz eden ve görselleştiren kapsamlı bir proje.

## 📁 Proje Yapısı

```
ufoapp/
├── dataset/
│   ├── scrubbed.csv          # Ham veri (80,334 satır)
│   ├── ufo_cleaned.mat       # Temizlenmiş veri
│   ├── basic_stats.png       # Temel istatistikler
│   ├── ufo_map.png          # Dünya haritası
│   ├── ufo_map_usa.png      # USA haritası
│   └── ufo_interactive_map.html  # İnteraktif web haritası
├── preprocess_data.m         # Veri temizleme scripti
├── visualize_map.m           # Harita görselleştirme
└── README.md                 # Bu dosya
```

## 🚀 Kullanım

### 1. Veri Önişleme (Preprocessing)

İlk adım olarak ham veriyi temizleyin:

```matlab
preprocess_data
```

Bu script:
- ✅ CSV dosyasını yükler
- ✅ Eksik koordinatları temizler
- ✅ Tarih formatlarını düzenler
- ✅ Şekil kategorilerini standardize eder
- ✅ HTML karakterlerini temizler
- ✅ Temizlenmiş veriyi `ufo_cleaned.mat` olarak kaydeder
- ✅ Temel istatistikleri görselleştirir

**Çıktılar:**
- `dataset/ufo_cleaned.mat` - Temizlenmiş veri
- `dataset/basic_stats.png` - Yıl, şekil ve ülke bazında istatistikler

### 2. Harita Görselleştirme

Temizlenen veriyi harita üzerinde gösterin:

```matlab
visualize_map
```

Bu script:
- 🗺️ Dünya haritası üzerinde UFO noktalarını gösterir
- 🎨 Şekil bazında renklendirme yapar
- 🇺🇸 USA odaklı ayrı bir harita oluşturur
- 🌐 İnteraktif HTML harita üretir (Leaflet.js)

**Çıktılar:**
- `dataset/ufo_map.png` - Global görünüm
- `dataset/ufo_map_usa.png` - USA görünüm
- `dataset/ufo_interactive_map.html` - İnteraktif harita

İnteraktif haritayı tarayıcıda açmak için:
```matlab
web('dataset/ufo_interactive_map.html')
```

## 📊 Veri Yapısı

### Ham Veri Kolonları
| Kolon | Açıklama |
|-------|----------|
| `datetime` | Gözlem tarihi ve saati |
| `city` | Şehir |
| `state` | Eyalet (USA için) |
| `country` | Ülke kodu |
| `shape` | UFO şekli (disk, light, triangle, vb.) |
| `duration (seconds)` | Gözlem süresi (saniye) |
| `duration (hours/min)` | Gözlem süresi (okunabilir) |
| `comments` | Gözlem açıklaması |
| `date posted` | Raporlama tarihi |
| `latitude` | Enlem |
| `longitude` | Boylam |

### Temizlenmiş Veri Ek Kolonları
- `datetime_parsed`: Datetime formatında tarih
- `year`, `month`, `day`: Ayrıştırılmış tarih bileşenleri

## 📈 Veri İstatistikleri

- **Toplam Gözlem:** ~80,000
- **Tarih Aralığı:** 1949 - 2013
- **Ülke Sayısı:** ~10
- **En Çok Gözlem:** ABD (United States)
- **En Çok Görülen Şekiller:**
  1. Light
  2. Circle
  3. Triangle
  4. Fireball
  5. Sphere

## 🎯 Özellikler

### ✅ Tamamlanan
- [x] Veri temizleme ve preprocessing
- [x] Eksik değer kontrolü
- [x] Koordinat validasyonu
- [x] Şekil standardizasyonu
- [x] Temel istatistiksel görselleştirme
- [x] Global harita görselleştirme
- [x] USA odaklı harita
- [x] İnteraktif HTML harita (Leaflet.js)
- [x] Hover ile detay gösterimi

### 🔄 Gelecek Geliştirmeler
- [ ] MATLAB App Designer ile GUI
- [ ] Tarih bazlı filtreleme
- [ ] Şekil bazlı filtreleme
- [ ] Zaman serisi analizi
- [ ] Heat map görselleştirme
- [ ] Kümeleme (clustering) analizi
- [ ] Animasyonlu zaman çizelgesi
- [ ] Excel export özelliği

## 🛠️ Teknik Gereksinimler

- MATLAB R2019b veya üzeri
- Mapping Toolbox
- Statistics and Machine Learning Toolbox

## 📝 Notlar

- Performans için harita görselleştirmelerinde veri alt kümeleri kullanılmıştır
- İnteraktif HTML harita maksimum 1000 marker gösterir
- Tüm koordinatlar WGS84 datum kullanır

## 🌐 İnteraktif Harita Özellikleri

İnteraktif HTML haritada:
- **🖱️ Hover:** Mouse ile noktaların üzerine gelin
- **📍 Popup:** Noktaya tıklayınca:
  - Şehir adı
  - Gözlem tarihi
  - UFO şekli
  - Açıklama özeti
- **🗺️ Zoom/Pan:** Haritada gezinin
- **🎨 Legend:** Sağ altta şekil renk kodları

## 📧 İletişim

Sorularınız için: [email@example.com]

---
**Not:** Bu proje eğitim amaçlıdır ve NUFORC (National UFO Reporting Center) verilerini kullanmaktadır.
