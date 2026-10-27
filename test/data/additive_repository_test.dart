import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/datasources/additive_data_source.dart';
import 'package:nutricheck/data/models/additive.dart';
import 'package:nutricheck/data/models/additive_category.dart';
import 'package:nutricheck/data/models/additive_dataset.dart';
import 'package:nutricheck/data/models/health_condition.dart';
import 'package:nutricheck/data/models/risk_level.dart';
import 'package:nutricheck/data/repositories/additive_repository.dart';

/// Data source palsu yang membaca file JSON asli dari disk, sehingga test
/// sekaligus memvalidasi isi basis data.
class _FileAdditiveDataSource implements AdditiveDataSource {
  int fetchCount = 0;

  @override
  Future<AdditiveDataset> fetchDataset() async {
    fetchCount++;
    final raw = File('assets/data/additives.json').readAsStringSync();
    return AdditiveDataset.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<int> fetchVersion() async => (await fetchDataset()).version;
}

void main() {
  late _FileAdditiveDataSource dataSource;
  late AdditiveRepository repo;

  setUp(() {
    dataSource = _FileAdditiveDataSource();
    repo = AdditiveRepository(dataSource: dataSource);
  });

  group('Validasi additives.json', () {
    test('semua entri valid, id unik, dan trigger dikenal', () async {
      final all = await repo.getAll();
      expect(all, isNotEmpty);
      expect(repo.version, greaterThan(0));

      final ids = all.map((a) => a.id.toLowerCase()).toList();
      expect(ids.toSet().length, ids.length, reason: 'id duplikat');

      for (final a in all) {
        expect(a.summary, isNotEmpty, reason: '${a.id} tanpa summary');
        expect(a.sources, isNotEmpty, reason: '${a.id} tanpa sumber');
        for (final trigger in a.conditionTriggers) {
          expect(HealthCondition.byId(trigger), isNotNull,
              reason: '${a.id}: trigger "$trigger" tidak dikenal');
        }
        if (a.eNumber != null) {
          expect(a.id, a.eNumber, reason: 'id harus sama dengan eNumber');
        }
        if (!a.bpomPermitted) {
          expect(a.riskLevel, RiskLevel.bahaya);
        }
      }
    });

    test('toJson -> fromJson menghasilkan data yang sama (siap Firestore)',
        () async {
      for (final a in await repo.getAll()) {
        final copy = Additive.fromJson(a.toJson());
        expect(copy.toJson(), a.toJson());
      }
    });
  });

  group('AdditiveRepository', () {
    test('data hanya dimuat sekali', () async {
      await repo.getAll();
      await repo.search('benzoat');
      await repo.getById('E211');
      expect(dataSource.fetchCount, 1);

      await repo.load(forceRefresh: true);
      expect(dataSource.fetchCount, 2);
    });

    test('normalizeCode mengenali berbagai format kode', () {
      expect(AdditiveRepository.normalizeCode('E211'), 'E211');
      expect(AdditiveRepository.normalizeCode('e-211'), 'E211');
      expect(AdditiveRepository.normalizeCode('INS 211'), 'E211');
      expect(AdditiveRepository.normalizeCode('211'), 'E211');
      expect(AdditiveRepository.normalizeCode('E150D'), 'E150d');
      expect(AdditiveRepository.normalizeCode('benzoat'), isNull);
    });

    test('getById menerima kode dan slug', () async {
      expect((await repo.getById('ins 211'))?.name, 'Natrium Benzoat');
      expect((await repo.getById('e150d'))?.id, 'E150d');
      expect((await repo.getById('formalin'))?.bpomPermitted, isFalse);
      expect(await repo.getById('E999'), isNull);
    });

    test('search mengurutkan berdasarkan relevansi dan mendukung filter',
        () async {
      final byCode = await repo.search('E621');
      expect(byCode.first.id, 'E621');

      final byAlias = await repo.search('micin');
      expect(byAlias.first.id, 'E621');

      final byName = await repo.search('benzoat');
      expect(byName.map((a) => a.id), containsAll(['E210', 'E211']));

      final sweeteners =
          await repo.search('', category: AdditiveCategory.pemanis);
      expect(sweeteners.every((a) => a.category == AdditiveCategory.pemanis),
          isTrue);

      final dangerous = await repo.search('', riskLevel: RiskLevel.bahaya);
      expect(dangerous.map((a) => a.id), containsAll(['formalin', 'E250']));
    });

    test('findInIngredients mendeteksi kode dan nama dari teks komposisi',
        () async {
      const komposisi = 'Air, gula, pengatur keasaman (asam sitrat), '
          'pengawet natrium benzoat, pewarna tartrazin CI 19140, '
          'perisa, pemanis buatan INS 951, garam.';
      final found = await repo.findInIngredients(komposisi);
      final ids = found.map((a) => a.id).toList();

      expect(ids, containsAll(['E330', 'E211', 'E102', 'E951']));
      expect(ids, isNot(contains('E210')),
          reason: '"natrium benzoat" tidak boleh terdeteksi sebagai asam benzoat');
      // Diurutkan dari risiko tertinggi.
      expect(found.first.riskLevel.severity,
          greaterThanOrEqualTo(found.last.riskLevel.severity));
    });

    test('findInIngredients tidak salah mendeteksi kode yang mirip', () async {
      final found = await repo.findInIngredients('mengandung E3300 dan E2110');
      expect(found, isEmpty);
    });

    test('findTriggersForConditions memakai id dari label survey', () async {
      final ids = HealthCondition.idsFromLabels(
          ['Riwayat Asma', 'Label Tidak Dikenal']);
      expect(ids, ['asthma']);

      final triggers = await repo.findTriggersForConditions(ids);
      expect(triggers.map((a) => a.id), containsAll(['E220', 'E102', 'E211']));
      expect(triggers.every((a) => a.conditionTriggers.contains('asthma')),
          isTrue);
    });

    test('maxDailyIntakeMg menghitung batas berdasarkan berat badan',
        () async {
      final benzoat = await repo.getById('E211');
      expect(benzoat!.maxDailyIntakeMg(60), 1200);
      final msg = await repo.getById('E621');
      expect(msg!.maxDailyIntakeMg(60), isNull);
    });
  });
}
