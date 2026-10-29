import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/risk_level_style.dart';
import '../data/datasources/product_data_source.dart';
import '../data/models/additive.dart';
import '../data/models/product.dart';
import '../data/models/risk_level.dart';
import '../data/repositories/additive_repository.dart';
import '../data/repositories/product_repository.dart';
import 'notification_screen.dart';
import 'product_detail_screen.dart';

/// Kategori filter. [tag] adalah tag kategori Open Food Facts; chip
/// [isAdditive] menampilkan basis data aditif lokal, bukan produk.
class _SearchCategory {
  const _SearchCategory(this.label, {this.tag, this.isAdditive = false});

  final String label;
  final String? tag;
  final bool isAdditive;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.productRepository,
    this.additiveRepository,
  });

  /// Untuk pengujian; default memakai [ProductRepository.instance].
  final ProductRepository? productRepository;

  /// Untuk pengujian; default memakai [AdditiveRepository.instance].
  final AdditiveRepository? additiveRepository;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  static const List<_SearchCategory> _categories = [
    _SearchCategory('Semua'),
    _SearchCategory('Minuman', tag: 'en:beverages'),
    _SearchCategory('Snack', tag: 'en:snacks'),
    _SearchCategory('Susu & Olahan', tag: 'en:dairies'),
    _SearchCategory('Bumbu Dapur', tag: 'en:condiments'),
    _SearchCategory('Mi Instan', tag: 'en:instant-noodles'),
    _SearchCategory('Zat Aditif', isAdditive: true),
  ];

  _SearchCategory _selectedCategory = _categories.first;

  // Hasil produk (Open Food Facts, hanya Indonesia).
  List<Product> _products = [];
  int _totalCount = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Hasil aditif (basis data lokal).
  List<Additive> _additiveResults = [];

  /// Mencegah respons lama menimpa hasil pencarian yang lebih baru.
  int _requestId = 0;

  ProductRepository get _productRepository =>
      widget.productRepository ?? ProductRepository.instance;

  AdditiveRepository get _additiveRepository =>
      widget.additiveRepository ?? AdditiveRepository.instance;

  /// Mode aditif: chip "Zat Aditif" dipilih, atau pengguna mengetik kode E
  /// (mis. "E211", "INS 211") pada kategori "Semua".
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

  void _selectCategory(_SearchCategory category) {
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
      setState(() {
        _products = result.products;
        _totalCount = result.totalCount;
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
      setState(() {
        _products = [
          ..._products,
          ...result.products.where((p) => !known.contains(p.barcode)),
        ];
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
                        child: _InfoBox(
                          label: 'KODE / ADITIF',
                          value: additive.eNumber ?? 'Tanpa kode E',
                          valueColor: const Color(0xFF0F5132),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoBox(
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
                  if (additive.aliases.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Nama lain: ${additive.aliases.join(', ')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (additive.commonIn.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Umum ditemukan pada: ${additive.commonIn.join(', ')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  if (additive.healthEffects.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: risk.backgroundColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: risk.backgroundColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(risk.icon, color: risk.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final effect in additive.healthEffects)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• $effect',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: risk.color,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!additive.bpomPermitted) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Dilarang digunakan sebagai bahan tambahan pangan.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: RiskLevel.bahaya.color,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5132),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        'Selesai Mengulas',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'nutricheck',
          style: GoogleFonts.comfortaa(
            color: const Color(0xFF0F5132),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar & Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar Input
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _onSearchSubmitted,
                            textInputAction: TextInputAction.search,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF191C1E),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari produk, merek, aditif (E-Code)...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF6D7A77),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF0F5132),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      color: Colors.grey,
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                          ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Filter pencarian disesuaikan untuk standar BPOM'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Category Chips
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

                  // Results Title Header
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

          // Product / Search Result List
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
          child: _MessagePanel(
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
            child: _MessagePanel(
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
                return _AdditiveCard(
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
          child: _MessagePanel(
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
              return _ProductCard(product: product, onTap: () => _openProduct(product));
            },
            childCount: _products.length + (_hasMore ? 1 : 0),
          ),
        ),
      ),
    ];
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  static const Map<String, Color> _nutriScoreColors = {
    'a': Color(0xFF038141),
    'b': Color(0xFF85BB2F),
    'c': Color(0xFFD4A800),
    'd': Color(0xFFEE8100),
    'e': Color(0xFFE63E11),
  };

  @override
  Widget build(BuildContext context) {
    final grade = product.nutriscoreGrade;
    final gradeColor = grade == null ? null : _nutriScoreColors[grade];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: product.imageUrl == null
                    ? const _ProductIcon()
                    : Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ProductIcon(),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      Text(
                        product.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6D7A77),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF191C1E),
                      ),
                    ),
                    if (product.quantity != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 13,
                            color: Color(0xFF0F5132),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              product.quantity!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F5132),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (gradeColor != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nutri-Score ${grade!.toUpperCase()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductIcon extends StatelessWidget {
  const _ProductIcon();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.fastfood_rounded, color: Color(0xFF0F5132));
}

class _AdditiveCard extends StatelessWidget {
  const _AdditiveCard({required this.additive, required this.onTap});

  final Additive additive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final risk = additive.riskLevel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: risk.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.science_rounded, color: risk.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      additive.category.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6D7A77),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      additive.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF191C1E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: risk.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  additive.bpomPermitted ? risk.label : 'Dilarang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: risk.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                actionLabel!,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F5132),
                side: const BorderSide(color: Color(0xFFD1E7DD)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
