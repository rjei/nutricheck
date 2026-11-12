# Basis Data Zat Aditif

Basis data zat aditif NutriCheck (SRS 6.1 & 6.3). Tahap awal bersifat **lokal & statis**
(`assets/data/additives.json`), dirancang agar bisa dipindah ke **Firebase Cloud Firestore**
(SRS 6.2) tanpa mengubah UI.

## Arsitektur

```
UI (screens/widgets)
        │  hanya memanggil
        ▼
AdditiveRepository          lib/data/repositories/additive_repository.dart
  (cache, search, getById, findInIngredients, findTriggersForConditions)
        │  bergantung pada interface
        ▼
AdditiveDataSource          lib/data/datasources/additive_data_source.dart
  ├─ LocalAdditiveDataSource      ← sekarang (aset JSON)
  └─ FirestoreAdditiveDataSource  ← nanti (fase cloud)
```

| File | Isi |
|------|-----|
| `lib/data/models/additive.dart` | Model `Additive` + `fromJson`/`toJson` |
| `lib/data/models/additive_dataset.dart` | Wrapper dataset + `version` untuk sinkronisasi |
| `lib/data/models/risk_level.dart` | `aman` / `waspada` / `bahaya` |
| `lib/data/models/additive_category.dart` | Kategori fungsi BTP |
| `lib/data/models/health_condition.dart` | Id kondisi kesehatan yang direferensikan aditif |
| `lib/constants/risk_level_style.dart` | Warna & ikon indikator (hijau/kuning/merah) |

## Contoh Pemakaian

```dart
final repo = AdditiveRepository.instance;

final hasil = await repo.search('benzoat');                 // pencarian manual
final e211  = await repo.getById('INS 211');                // E211, e-211, 211 juga bisa
final ditemukan = await repo.findInIngredients(teksKomposisi); // input manual / OCR
final pemicu = await repo.findTriggersForConditions(
  HealthCondition.idsFromLabels(user.selectedConditions),   // label survey -> id
);

// Warna indikator
Container(color: e211!.riskLevel.backgroundColor,
          child: Icon(e211.riskLevel.icon, color: e211.riskLevel.color));
```

## Skema Data

```jsonc
{
  "version": 1,                       // naikkan setiap kali data diubah
  "updatedAt": "2026-10-27T00:00:00Z",
  "additives": [{
    "id": "E211",                     // = eNumber; slug untuk bahan tanpa kode (mis. "formalin")
    "eNumber": "E211",                // null jika tidak punya kode
    "name": "Natrium Benzoat",
    "aliases": ["sodium benzoate"],   // dipakai untuk pencarian & deteksi teks komposisi
    "category": "pengawet",           // lihat AdditiveCategory.key
    "riskLevel": "waspada",           // aman | waspada | bahaya
    "summary": "...",                 // penjelasan singkat untuk awam
    "healthEffects": ["..."],
    "adiMgPerKgBw": 20,               // null = tidak ditentukan
    "adiNote": "...",
    "conditionTriggers": ["asthma"],  // id HealthCondition
    "bpomPermitted": true,
    "commonIn": ["minuman bersoda"],
    "sources": ["JECFA", "Peraturan BPOM No. 11 Tahun 2019"],
    "updatedAt": "2026-10-27T00:00:00Z"
  }]
}
```

### Aturan Menambah / Mengubah Data
1. `id` harus unik & tidak boleh diubah (dipakai sebagai document id Firestore dan direferensikan riwayat/produk).
2. `conditionTriggers` hanya boleh berisi id yang ada di `HealthCondition.all`.
3. Bahan dengan `bpomPermitted: false` wajib `riskLevel: "bahaya"`.
4. Naikkan `version` setiap ada perubahan.
5. Jalankan `flutter test test/data` — test memvalidasi seluruh aturan di atas.

## Rencana Migrasi ke Firebase

**Struktur Firestore**
```
additives/{id}           ← satu dokumen per Additive.toJson() (updatedAt -> Timestamp)
meta/additives           ← { version: 2, updatedAt: Timestamp }
```

**Langkah**
1. Tambah `firebase_core` + `cloud_firestore`, jalankan `flutterfire configure`.
2. Buat `FirestoreAdditiveDataSource implements AdditiveDataSource`:
   - `fetchVersion()` → baca `meta/additives.version`.
   - `fetchDataset()` → ambil koleksi `additives`, ubah `Timestamp` → ISO string, lalu `Additive.fromJson`.
3. Strategi *offline-first*: saat startup tetap pakai data lokal; di latar belakang bandingkan
   `fetchVersion()` cloud vs `repo.version`. Jika lebih baru → `repo.setDataSource(firestoreSource)`
   + `repo.load(forceRefresh: true)` (Firestore offline persistence menyimpan cache otomatis).
   Aset JSON tetap menjadi *fallback* bila tidak ada internet saat pertama kali dibuka.
4. Upload awal: skrip seeding membaca `assets/data/additives.json` dan menulis tiap entri ke
   `additives/{id}` (format JSON sudah kompatibel).
5. Security rules: `additives` & `meta` **read-only** untuk klien; penulisan hanya via admin/console.

> Informasi bersifat edukatif dan tidak menggantikan saran medis profesional (SRS 6.3).
