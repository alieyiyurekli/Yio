# Profil Düzenleme Özelliği - Detaylı Implementasyon Planı

## Durum Analizi

### Mevcut Dosyalar
| Dosya | Durum | Satır |
|-------|-------|-------|
| `lib/screens/profile/edit_profile_screen.dart` | ✅ UI hazır, navigasyon eksik | 1022 |
| `lib/providers/edit_profile_provider.dart` | ✅ State management hazır | 323 |
| `lib/screens/settings/settings_screen.dart` | ⚠️ onTap boş | 57-64 |
| `lib/core/router/go_router_config.dart` | ❌ Route yok | - |
| `lib/main.dart` | ❌ Provider kayıtlı değil | - |

---

## Adım 1: Route Konfigürasyonu

### 1.1 AppRoutes.editProfile Sabiti Ekle
**Dosya:** `lib/core/router/go_router_config.dart`

`AppRoutes` sınıfına (satır ~37) yeni sabit:
```dart
/// Profil düzenleme sayfası
static const editProfile = '/edit-profile';
```

### 1.2 GoRouter'a Route Ekle
**Dosya:** `lib/core/router/go_router_config.dart`

`routes` listesine (satır ~375) yeni GoRoute:
```dart
// Edit Profile — profil düzenleme sayfası
GoRoute(
  path: AppRoutes.editProfile,
  name: 'editProfile',
  builder: (context, state) => const EditProfileScreen(),
),
```

---

## Adım 2: Provider Kaydı

### 2.1 EditProfileProvider import Ekle
**Dosya:** `lib/main.dart`

Mevcut import'ların yanına:
```dart
import '../providers/edit_profile_provider.dart';
import '../services/firebase_profile_image_service.dart';
```

### 2.2 Provider Kaydı
**Dosya:** `lib/main.dart`

`MultiProvider` içinde `ChangeNotifierProvider<EditProfileProvider>` ekle.

---

## Adım 3: SettingsScreen Navigasyon

### 3.1 EditProfileScreen import Ekle
**Dosya:** `lib/screens/settings/settings_screen.dart`

Import'lar arasına:
```dart
import '../../screens/profile/edit_profile_screen.dart';
```

### 3.2 onTap Callback Doldur
**Dosya:** `lib/screens/settings/settings_screen.dart` (satır ~60)

Boş onTap'i doldur:
```dart
onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const EditProfileScreen(),
    ),
  );
},
```

---

## Adım 4: EditProfileScreen İyileştirmeleri (Gerekirse)

### 4.1 UserService Import Kontrolü
`edit_profile_screen.dart`'ta `UserService` ve `FirebaseProfileImageService` import'ları kontrol edilecek.

### 4.2 Provider Kullanımı
Mevcut `EditProfileProvider` kullanımı zaten doğru. Sadece provider kayıtlı değil.

---

## Değiştirilecek Dosyalar Listesi

| # | Dosya | İşlem | Öncelik |
|---|-------|-------|---------|
| 1 | `lib/core/router/go_router_config.dart` | AppRoutes + GoRoute | 🔴 |
| 2 | `lib/main.dart` | Provider kaydı | 🔴 |
| 3 | `lib/screens/settings/settings_screen.dart` | onTap + import | 🔴 |

---

## Implementasyon Sırası

1. ✅ Planı oluştur
2. ⬜ AppRoutes.editProfile sabiti ekle
3. ⬜ GoRouter'a route ekle
4. ⬜ main.dart'a import ve provider kaydı
5. ⬜ SettingsScreen navigasyon
6. ⬜ Test ve doğrulama

---

## Notlar

- `EditProfileProvider` zaten mevcut ve doğru implement edilmiş
- `EditProfileScreen` zaten mevcut, sadece navigation eksik
- MaterialPageRoute kullanıyoruz (GoRouter entegrasyonu opsiyonel)
- Firebase entegrasyonu zaten `UserService` üzerinden yapılıyor