import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/risk_level_style.dart';
import '../data/datasources/product_data_source.dart';
import '../data/models/additive.dart';
import '../data/models/product.dart';
import '../data/repositories/additive_repository.dart';
import '../data/repositories/product_repository.dart';
import '../models/search_category.dart';
import '../widgets/additive_card.dart';
import '../widgets/app_header.dart';
import '../widgets/info_box.dart';
import '../widgets/message_panel.dart';
import '../widgets/product_card.dart';
import '../widgets/search_filter_panel.dart';
import '../widgets/searchbar.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.productRepository,
    this.additiveRepository,
  });

  final ProductRepository? productRepository;
  final AdditiveRepository? additiveRepository;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  static const List<SearchCategory> _categories = [
    SearchCategory('Semua'),
    SearchCategory('Minuman', tag: 'en:beverages'),
    SearchCategory('Snack', tag: 'en:snacks'),
    SearchCategory('Susu & Olahan', tag: 'en:dairies'),
    SearchCategory('Bumbu Dapur', tag: 'en:condiments'),
    SearchCategory('Mi Instan', tag: 'en:instant-noodles'),
    SearchCategory('Zat Aditif', isAdditive: true),
  ];

  SearchCategory _selectedCategory = _categories.first;

  // State Filter
  bool _isAdvancedFilterOpen = false;
  String? _selectedNutriScore; // 'a', 'b', 'c', 'd', 'e'
  String? _selectedNutritionFilter; // 'Gula Tinggi', 'Natrium Tinggi'

  List<Product> _products = [];
  int _totalCount = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<Additive> _additiveResults = [];
  int _requestId = 0;

  ProductRepository get _productRepository =>
      widget.productRepository ?? ProductRepository.instance;

  AdditiveRepository get _additiveRepository =>
      widget.additiveRepository ?? AdditiveRepository.instance;

  bool get _isAdditiveMode =>
      _selectedCategory.isAdditive ||
          (_selectedCategory.tag == null &&
              AdditiveRepository.normalizeCode(_searchQuery) != null);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text;
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _refresh);
  }

  void _onSearchSubmitted(String query) {
    _debounce?.cancel();
    _refresh();
  }

  void _selectCategory(SearchCategory category) {
    if (identical(category, _selectedCategory)) return;
    _debounce?.cancel();
    setState(() => _selectedCategory = category);
    _refresh();
  }

  Future<void> _refresh() async {
    final requestId = ++_requestId;
    final query = _searchQuery.trim();

    if (_isAdditiveMode) {
      try {
        final results = await _additiveRepository.search(query);
        if (!mounted || requestId != _requestId) return;
        setState(() {
          _additiveResults = results;
          _isLoading = false;
          _errorMessage = null;
        });
      } catch (_) {
        if (!mounted || requestId != _requestId) return;
        setState(() {
          _additiveResults = [];
          _isLoading = false;
          _errorMessage = 'Gagal memuat basis data aditif.';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _productRepository.search(
        query,
        categoryTag: _selectedCategory.tag,
      );
      if (!mounted || requestId != _requestId) return;

      final filteredProducts = result.products.where((p) {
        if (_selectedNutriScore != null) {
          final grade = p.nutriscoreGrade?.toLowerCase();
          if (grade != _selectedNutriScore) return false;
        }

        if (_selectedNutritionFilter == 'Gula Tinggi') {
          final sugar = p.nutrition.sugarsG ?? 0;
          if (sugar < 22.5) return false;
        }
        if (_selectedNutritionFilter == 'Natrium Tinggi') {
          final sodium = p.nutrition.sodiumMg ?? 0;
          if (sodium < 600) return false;
        }
        return true;
      }).toList();

      setState(() {
        _products = filteredProducts;
        _totalCount = filteredProducts.length;
        _page = result.page;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _products = [];
        _totalCount = 0;
        _hasMore = false;
        _isLoading = false;
        _errorMessage = e is ProductSourceException
            ? e.message
            : 'Terjadi kesalahan saat mencari produk.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _productRepository.search(
        _searchQuery.trim(),
        categoryTag: _selectedCategory.tag,
        page: _page + 1,
      );
      if (!mounted || requestId != _requestId) return;
      final known = _products.map((p) => p.barcode).toSet();

      final moreFiltered = result.products.where((p) {
        if (_selectedNutriScore != null) {
          final grade = p.nutriscoreGrade?.toLowerCase();
          if (grade != _selectedNutriScore) return false;
        }
        if (_selectedNutritionFilter == 'Gula Tinggi') {
          if ((p.nutrition.sugarsG ?? 0) < 22.5) return false;
        }
        if (_selectedNutritionFilter == 'Natrium Tinggi') {
          if ((p.nutrition.sodiumMg ?? 0) < 600) return false;
        }
        return true;
      }).where((p) => !known.contains(p.barcode));

      setState(() {
        _products = [..._products, ...moreFiltered];
        _page = result.page;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ProductSourceException ? e.message : 'Gagal memuat produk berikutnya.',
          ),
        ),
      );
    }
  }

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product,
          repository: widget.productRepository,
        ),
      ),
    );
  }

  void _showAdditiveDetail(Additive additive) {
    final adiText = additive.adiMgPerKgBw != null
        ? '${additive.adiMgPerKgBw! % 1 == 0 ? additive.adiMgPerKgBw!.toStringAsFixed(0) : additive.adiMgPerKgBw} mg/kg BB'
        : (additive.adiNote ?? 'Tidak ditentukan');
    final risk = additive.riskLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              additive.category.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6D7A77),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              additive.displayName,
                              style: GoogleFonts.comfortaa(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF191C1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: risk.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          risk.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: risk.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InfoBox(
                          label: 'KODE / ADITIF',
                          value: additive.eNumber ?? 'Tanpa kode E',
                          valueColor: const Color(0xFF0F5132),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoBox(
                          label: 'BATAS HARIAN (ADI)',
                          value: adiText,
                          valueColor: risk.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Penjelasan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    additive.summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF3D4947),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5132),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      child: const Text('Selesai Mengulas'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final additiveMode = _isAdditiveMode;
    final resultCount = additiveMode ? _additiveResults.length : _totalCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: const AppHeader(
        showDefaultActions: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomSearchBar(
                          controller: _searchController,
                          onChanged: (_) {},
                          onSubmitted: _onSearchSubmitted,
                          onClear: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          hintText: 'Cari produk, merek, aditif (E-Code)...',
                          showTrailingFilter: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F5132)),
                          onPressed: () {
                            setState(() {
                              _isAdvancedFilterOpen = !_isAdvancedFilterOpen;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Panel Filter Ekspansif Menggunakan Widget Terpisah
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: SearchFilterPanel(
                      selectedNutriScore: _selectedNutriScore,
                      selectedNutritionFilter: _selectedNutritionFilter,
                      onNutriScoreSelected: (grade) {
                        setState(() => _selectedNutriScore = grade);
                        _refresh();
                      },
                      onNutritionSelected: (nutri) {
                        setState(() => _selectedNutritionFilter = nutri);
                        _refresh();
                      },
                      onReset: () {
                        setState(() {
                          _selectedNutriScore = null;
                          _selectedNutritionFilter = null;
                        });
                        _refresh();
                      },
                    ),
                    crossFadeState: _isAdvancedFilterOpen
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = identical(_selectedCategory, category);
                        return GestureDetector(
                          onTap: () => _selectCategory(category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F5132) : Colors.white,
                              borderRadius: BorderRadius.circular(9999),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                )
                              ],
                            ),
                            child: Text(
                              category.label,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : const Color(0xFF3D4947),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Katalog & Hasil Pencarian',
                        style: GoogleFonts.comfortaa(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF191C1E),
                        ),
                      ),
                      Text(
                        additiveMode ? '$resultCount Aditif' : '$resultCount Produk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    additiveMode
                        ? 'Basis data zat aditif lokal (BPOM & JECFA)'
                        : 'Hanya produk yang beredar di Indonesia • Data: Open Food Facts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading && _products.isNotEmpty && !additiveMode)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: Color(0xFF0F5132),
                        backgroundColor: Color(0xFFD1E7DD),
                      ),
                    ),
                ],
              ),
            ),
          ),

          ..._buildResults(additiveMode),
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResults(bool additiveMode) {
    if (_errorMessage != null) {
      return [
        SliverToBoxAdapter(
          child: MessagePanel(
            icon: Icons.cloud_off_rounded,
            title: 'Tidak dapat memuat data',
            message: _errorMessage!,
            actionLabel: 'Coba Lagi',
            onAction: _refresh,
          ),
        ),
      ];
    }

    if (additiveMode) {
      if (_additiveResults.isEmpty) {
        return const [
          SliverToBoxAdapter(
            child: MessagePanel(
              icon: Icons.search_off_rounded,
              title: 'Tidak ada aditif ditemukan',
              message: 'Coba kata kunci lain seperti "E211", "micin", atau "pemanis".',
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final additive = _additiveResults[index];
                return AdditiveCard(
                  additive: additive,
                  onTap: () => _showAdditiveDetail(additive),
                );
              },
              childCount: _additiveResults.length,
            ),
          ),
        ),
      ];
    }

    if (_isLoading && _products.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0F5132)),
            ),
          ),
        ),
      ];
    }

    if (_products.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: MessagePanel(
            icon: Icons.search_off_rounded,
            title: 'Tidak ada produk ditemukan',
            message: 'Tidak ada produk Indonesia yang cocok. Coba kata kunci lain '
                'seperti "indomie", "teh botol", atau "kecap".',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index == _products.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: _isLoadingMore
                        ? const CircularProgressIndicator(color: Color(0xFF0F5132))
                        : OutlinedButton(
                      onPressed: _loadMore,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F5132),
                        side: const BorderSide(color: Color(0xFFD1E7DD)),
                      ),
                      child: Text(
                        'Muat Lebih Banyak',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }
              final product = _products[index];
              return ProductCard(
                product: product,
                onTap: () => _openProduct(product),
              );
            },
            childCount: _products.length + (_hasMore ? 1 : 0),
          ),
        ),
      ),
    ];
  }
}