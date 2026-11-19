import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/datasources/ai_chat_data_source.dart';
import 'package:nutricheck/data/datasources/product_cache.dart';
import 'package:nutricheck/data/repositories/additive_repository.dart';
import 'package:nutricheck/data/repositories/product_repository.dart';
import 'package:nutricheck/models/chat_message.dart';
import 'package:nutricheck/services/ai_chat_service.dart';

import '../data/support/test_support.dart';

class _UnconfiguredAiDataSource implements AiChatDataSource {
  @override
  bool get isConfigured => false;

  @override
  Future<AiGenerationResult> generateReply({
    required String systemInstruction,
    required List<Map<String, dynamic>> history,
    required String userMessage,
    required AiToolExecutor onToolCall,
  }) {
    throw UnimplementedError();
  }
}

class _FakeConfiguredAiDataSource implements AiChatDataSource {
  @override
  bool get isConfigured => true;

  @override
  Future<AiGenerationResult> generateReply({
    required String systemInstruction,
    required List<Map<String, dynamic>> history,
    required String userMessage,
    required AiToolExecutor onToolCall,
  }) async {
    final additiveRes = await onToolCall('lookup_additive', {'query': 'E211'});
    final altRes = await onToolCall(
      'search_healthier_alternatives',
      {'query': 'biskuit'},
    );
    final foundAdditive = additiveRes['found'] == true;
    final foundAlt = altRes['found'] == true;
    return AiGenerationResult(
      text: 'Lookup=$foundAdditive, Alt=$foundAlt',
    );
  }
}

void main() {
  late AdditiveRepository additiveRepo;
  late FakeProductDataSource fakeProductSource;
  late ProductRepository productRepo;

  setUp(() {
    additiveRepo = AdditiveRepository(dataSource: FileAdditiveDataSource());
    fakeProductSource = FakeProductDataSource();
    productRepo = ProductRepository(
      dataSource: fakeProductSource,
      cache: InMemoryProductCache(),
      additives: additiveRepo,
    );
  });

  test('Mode lokal menjelaskan kode E211 dari AdditiveRepository', () async {
    final service = AiChatService(
      dataSource: _UnconfiguredAiDataSource(),
      additiveRepository: additiveRepo,
      productRepository: productRepo,
    );

    await service.sendMessage('Jelaskan E211');

    expect(service.messages.length, 2);
    expect(service.messages.first.role, ChatRole.user);
    expect(service.messages.last.role, ChatRole.assistant);
    expect(service.messages.last.isError, isFalse);
    expect(service.messages.last.text, contains('E211'));
    expect(service.messages.last.text, contains('BPOM'));
  });

  test('Mode lokal mencari alternatif produk Indonesia yang lebih sehat',
      () async {
    fakeProductSource.searchResults = [
      makeProduct(
        barcode: '8990001112223',
        name: 'Biskuit Gandum Alami',
        brand: 'SehatKita',
        ingredientsText: 'Tepung gandum, oat, minyak nabati',
      ),
      makeProduct(
        barcode: '8990001112224',
        name: 'Biskuit Krim Pengawet',
        brand: 'SnackX',
        ingredientsText: 'Tepung, gula, natrium benzoat (E211)',
        additiveCodes: const ['en:e211'],
      ),
    ];

    final service = AiChatService(
      dataSource: _UnconfiguredAiDataSource(),
      additiveRepository: additiveRepo,
      productRepository: productRepo,
    );

    await service.sendMessage('Carikan alternatif biskuit yang lebih sehat');

    final reply = service.messages.last;
    expect(reply.isError, isFalse);
    expect(reply.recommendedProducts, isNotEmpty);
    expect(
      reply.recommendedProducts.first.product.name,
      'Biskuit Gandum Alami',
    );
  });

  test(
      'Mode remote AI mengeksekusi tool lookup_additive dan search_healthier_alternatives',
      () async {
    fakeProductSource.searchResults = [
      makeProduct(
        barcode: '8990001112223',
        name: 'Biskuit Gandum Alami',
        brand: 'SehatKita',
        ingredientsText: 'Tepung gandum, oat',
      ),
    ];

    final service = AiChatService(
      dataSource: _FakeConfiguredAiDataSource(),
      additiveRepository: additiveRepo,
      productRepository: productRepo,
    );

    await service.sendMessage('Cek E211 dan cari alternatif biskuit');

    final reply = service.messages.last;
    expect(reply.text, 'Lookup=true, Alt=true');
    expect(reply.recommendedProducts.length, 1);
  });
}
