import '../datasources/additive_data_source.dart';
import '../models/additive.dart';
import '../models/additive_category.dart';
import '../models/risk_level.dart';

/// Titik akses tunggal basis data zat aditif untuk seluruh aplikasi.
///
/// UI tidak boleh membaca JSON / Firestore secara langsung; selalu lewat
/// repository ini agar sumber data bisa diganti (lokal -> Firebase).
class AdditiveRepository {
  AdditiveRepository({required AdditiveDataSource dataSource})
      : _dataSource = dataSource;

  /// Instance default yang memakai aset lokal.
  static final AdditiveRepository instance =
      AdditiveRepository(dataSource: LocalAdditiveDataSource());

  AdditiveDataSource _dataSource;

  List<Additive> _additives = const [];
  final Map<String, Additive> _byId = {};
  int? _version;
  Future<void>? _loading;

  /// Versi dataset yang sedang dimuat (null jika belum dimuat).
  int? get version => _version;

  bool get isLoaded => _version != null;

  /// Mengganti sumber data, mis. ke Firestore saat fase cloud.
  /// Cache dibersihkan sehingga pemanggilan berikutnya memuat ulang.
  void setDataSource(AdditiveDataSource dataSource) {
    _dataSource = dataSource;
    _clear();
  }

  /// Memuat data (sekali saja kecuali [forceRefresh]).
  Future<void> load({bool forceRefresh = false}) {
    if (forceRefresh) _clear();
    return _loading ??= _doLoad();
  }

  Future<void> _doLoad() async {
    try {
      final dataset = await _dataSource.fetchDataset();
      _additives = List.unmodifiable(dataset.additives);
      _byId
        ..clear()
        ..addEntries(_additives.map((a) => MapEntry(a.id.toLowerCase(), a)));
      _version = dataset.version;
    } catch (_) {
      _loading = null; // izinkan percobaan ulang
      rethrow;
    }
  }

  void _clear() {
    _loading = null;
    _version = null;
    _additives = const [];
    _byId.clear();
  }

  Future<List<Additive>> getAll() async {
    await load();
    return _additives;
  }

  /// Mencari berdasarkan id atau kode E/INS dalam berbagai format:
  /// `E211`, `e-211`, `E 211`, `INS 211`, `211`, atau slug (`formalin`).
  Future<Additive?> getById(String idOrCode) async {
    await load();
    final key = idOrCode.trim().toLowerCase();
    return _byId[key] ?? _byId[normalizeCode(idOrCode)?.toLowerCase()];
  }

  /// Pencarian bebas berdasarkan kode, nama, alias, kategori, dan contoh
  /// produk. Hasil diurutkan berdasarkan relevansi.
  Future<List<Additive>> search(
    String query, {
    AdditiveCategory? category,
    RiskLevel? riskLevel,
  }) async {
    await load();
    final q = query.trim().toLowerCase();
    final code = normalizeCode(query)?.toLowerCase();

    final scored = <(Additive, int)>[];
    for (final additive in _additives) {
      if (category != null && additive.category != category) continue;
      if (riskLevel != null && additive.riskLevel != riskLevel) continue;

      final score = q.isEmpty ? 1 : _score(additive, q, code);
      if (score > 0) scored.add((additive, score));
    }

    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.name.compareTo(b.$1.name);
    });
    return scored.map((e) => e.$1).toList();
  }

  int _score(Additive a, String q, String? code) {
    final id = a.id.toLowerCase();
    final name = a.name.toLowerCase();
    final aliases = a.aliases.map((s) => s.toLowerCase());

    if (code != null && (id == code || a.eNumber?.toLowerCase() == code)) {
      return 100;
    }
    if (name == q || aliases.contains(q)) return 90;
    if (name.startsWith(q)) return 80;
    if (id.startsWith(q)) return 75;
    if (name.contains(q)) return 70;
    if (aliases.any((s) => s.contains(q))) return 60;
    if (a.category.label.toLowerCase().contains(q)) return 40;
    if (a.commonIn.any((s) => s.toLowerCase().contains(q))) return 20;
    return 0;
  }

  /// Mendeteksi aditif yang disebut dalam teks komposisi produk
  /// (input manual maupun hasil OCR). Mengenali kode E/INS dan nama/alias.
  Future<List<Additive>> findInIngredients(String ingredientsText) async {
    await load();
    final text = ingredientsText.toLowerCase();
    if (text.trim().isEmpty) return const [];

    final found = <Additive>[];
    for (final additive in _additives) {
      if (_mentions(text, additive)) found.add(additive);
    }
    found.sort((a, b) => b.riskLevel.severity.compareTo(a.riskLevel.severity));
    return found;
  }

  bool _mentions(String text, Additive additive) {
    final eNumber = additive.eNumber;
    if (eNumber != null) {
      final digits = RegExp.escape(eNumber.substring(1).toLowerCase());
      final pattern = RegExp(r'(?<![a-z0-9])(?:e|ins)\s*-?\s*' + digits + r'(?![a-z0-9])');
      if (pattern.hasMatch(text)) return true;
    }
    for (final term in [additive.name, ...additive.aliases]) {
      final t = term.toLowerCase();
      if (t.length < 4) continue;
      final pattern = RegExp(r'(?<![a-z0-9])' + RegExp.escape(t) + r'(?![a-z0-9])');
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }

  /// Aditif yang perlu diwaspadai untuk kondisi kesehatan tertentu
  /// (id dari `HealthCondition`).
  Future<List<Additive>> findTriggersForConditions(
    Iterable<String> conditionIds,
  ) async {
    await load();
    final ids = conditionIds.toSet();
    if (ids.isEmpty) return const [];
    return _additives.where((a) => a.isTriggerFor(ids)).toList();
  }

  /// Menormalkan input kode menjadi format `E<angka><huruf?>`.
  /// Mengembalikan `null` jika input bukan kode.
  static String? normalizeCode(String input) {
    final match = RegExp(r'^\s*(?:e|ins)?\s*-?\s*(\d{3,4})\s*([a-z])?\s*$',
            caseSensitive: false)
        .firstMatch(input);
    if (match == null) return null;
    final suffix = match.group(2)?.toLowerCase() ?? '';
    return 'E${match.group(1)}$suffix';
  }
}
