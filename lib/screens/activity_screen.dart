import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../widgets/app_footer.dart';
import 'home_screen.dart';
import 'product_detail_screen.dart';

enum ProductSafety { aman, waspada, bahaya }

class ActivityProduct {
  final String brand;
  final String title;
  final String time;
  final String location;
  final ProductSafety safety;
  final IconData icon;
  final int calories;
  final int sugar;
  final int fiber;
  final int protein;
  final int sodium;
  final DateTime date;
  final String? warning;
  bool isConsumed;

  ActivityProduct({
    required this.brand,
    required this.title,
    required this.time,
    required this.location,
    required this.safety,
    required this.icon,
    required this.calories,
    required this.sugar,
    required this.fiber,
    required this.protein,
    required this.sodium,
    required this.date,
    required this.isConsumed,
    this.warning,
  });
}

enum HistoryFilter { semua, dikonsumsi, bahaya, waspada, aman }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final List<ActivityProduct> _products;
  HistoryFilter _selectedFilter = HistoryFilter.semua;
  String? _timeFilter;
  ProductSafety? _statusFilter;
  String? _nutritionFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _products = [
      ActivityProduct(
        brand: 'POCARI SWEAT',
        title: 'Pocari Sweat 500 ml',
        time: '10:45',
        location: 'Supermarket Menteng',
        safety: ProductSafety.aman,
        icon: Icons.local_drink_rounded,
        calories: 120,
        sugar: 4,
        fiber: 0,
        protein: 12,
        sodium: 35,
        date: now,
        isConsumed: true,
      ),
      ActivityProduct(
        brand: 'COCA-COLA',
        title: 'Coca-Cola 250 ml',
        time: '08:15',
        location: 'Kantin Kantor',
        safety: ProductSafety.waspada,
        icon: Icons.local_cafe_rounded,
        calories: 100,
        sugar: 22,
        fiber: 1,
        protein: 0,
        sodium: 25,
        date: now,
        isConsumed: true,
      ),
      ActivityProduct(
        brand: 'CHITATO',
        title: 'Chitato Sapi Panggang',
        time: '19:30',
        location: 'Indomaret Point',
        safety: ProductSafety.bahaya,
        icon: Icons.fastfood_rounded,
        calories: 260,
        sugar: 2,
        fiber: 2,
        protein: 4,
        sodium: 850,
        date: now.subtract(const Duration(days: 1)),
        isConsumed: true,
        warning:
            'Kandungan natrium sangat tinggi (850 mg). Konsumsi terbatas sangat disarankan.',
      ),
      ActivityProduct(
        brand: 'SEGAR',
        title: 'Salad Buah Segar',
        time: '12:45',
        location: 'Kantin Kampus',
        safety: ProductSafety.aman,
        icon: Icons.ramen_dining_rounded,
        calories: 95,
        sugar: 8,
        fiber: 6,
        protein: 3,
        sodium: 12,
        date: now.subtract(const Duration(days: 1)),
        isConsumed: true,
      ),
      ActivityProduct(
        brand: 'ROMA',
        title: 'Biskuit Gandum Utuh',
        time: '16:20',
        location: 'Rumah',
        safety: ProductSafety.waspada,
        icon: Icons.cookie_outlined,
        calories: 150,
        sugar: 12,
        fiber: 3,
        protein: 2,
        sodium: 180,
        date: DateTime(now.year, now.month, 3),
        isConsumed: false,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    return _products.where((product) {
      final searchable =
          '${product.title} ${product.brand} ${product.warning ?? ''}'
              .toLowerCase();
      final matchesSearch = query.isEmpty || searchable.contains(query);
      final matchesFilter = switch (_selectedFilter) {
        HistoryFilter.semua => true,
        HistoryFilter.dikonsumsi => product.isConsumed,
        HistoryFilter.bahaya => product.safety == ProductSafety.bahaya,
        HistoryFilter.waspada => product.safety == ProductSafety.waspada,
        HistoryFilter.aman => product.safety == ProductSafety.aman,
      };
      final matchesTime = switch (_timeFilter) {
        'Hari Ini' => product.date.year == now.year &&
            product.date.month == now.month &&
            product.date.day == now.day,
        'Minggu Ini' => now.difference(product.date).inDays < 7 &&
            product.date.isBefore(now.add(const Duration(days: 1))),
        'Bulan Ini' =>
          product.date.year == now.year && product.date.month == now.month,
        _ => true,
      };
      final matchesStatus =
          _statusFilter == null || product.safety == _statusFilter;
      final matchesNutrition = switch (_nutritionFilter) {
        'Gula Tinggi' => product.sugar >= 20,
        'Natrium Tinggi' => product.sodium >= 500,
        'Pengawet Sintetis' =>
          product.warning?.toLowerCase().contains('pengawet') ?? false,
        _ => true,
      };
      return matchesSearch &&
          matchesFilter &&
          matchesTime &&
          matchesStatus &&
          matchesNutrition;
    }).toList();
  }

  List<ActivityProduct> _productsForGroup(
    List<ActivityProduct> products,
    int dayOffset,
  ) {
    final now = DateTime.now();
    return products.where((product) {
      final target = now.subtract(Duration(days: dayOffset));
      return product.date.year == target.year &&
          product.date.month == target.month &&
          product.date.day == target.day;
    }).toList();
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final today = _productsForGroup(filtered, 0);
    final yesterday = _productsForGroup(filtered, 1);
    final month = filtered.where((product) {
      final now = DateTime.now();
      return product.date.year == now.year &&
          product.date.month == now.month &&
          !_productsForGroup(filtered, 0).contains(product) &&
          !_productsForGroup(filtered, 1).contains(product);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildSearchAndFilters(),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SummaryCard(products: _products),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyHistory(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (today.isNotEmpty) _buildGroup('Hari Ini', today),
                          if (yesterday.isNotEmpty)
                            _buildGroup('Kemarin', yesterday),
                          if (month.isNotEmpty) _buildGroup('Bulan Ini', month),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(currentIndex: 3, onTap: _onTabTapped),
    );
  }

  Widget _buildSearchAndFilters() {
    final labels = <String>['Semua', 'Dikonsumsi', 'Bahaya', 'Waspada', 'Aman'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivitas', style: _text(23, FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryAccent,
                      size: 20,
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
              hintText: 'Cari produk, merek, atau zat aditif...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: labels.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, index) => _FilterChip(
                    label: labels[index],
                    selected: _selectedFilter.index == index,
                    onTap: () => setState(
                      () => _selectedFilter = HistoryFilter.values[index],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _showFilterSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 34,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.primaryAccent,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroup(String title, List<ActivityProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title (${products.length} Produk)',
                style: _text(14, FontWeight.w700),
              ),
              Text(
                '${products.length} PRODUK',
                style: _text(9, FontWeight.w600, AppColors.textMuted),
              ),
            ],
          ),
        ),
        ...products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HistoryItemCard(
              product: product,
              onConsumedChanged: (value) =>
                  setState(() => product.isConsumed = value),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductDetailScreen(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showFilterSheet() {
    var timeFilter = _timeFilter;
    var statusFilter = _statusFilter;
    var nutritionFilter = _nutritionFilter;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Aktivitas', style: _text(18, FontWeight.w700)),
                const SizedBox(height: 16),
                _sheetCategory(
                  'Waktu',
                  ['Hari Ini', 'Minggu Ini', 'Bulan Ini'],
                  timeFilter,
                  (value) => setSheetState(() => timeFilter = value),
                ),
                _sheetCategory(
                  'Status',
                  ['Aman', 'Waspada', 'Bahaya'],
                  statusFilter == null ? null : _statusLabel(statusFilter!),
                  (value) => setSheetState(
                    () => statusFilter = _statusFromLabel(value),
                  ),
                ),
                _sheetCategory(
                  'Masalah Nutrisi',
                  ['Gula Tinggi', 'Natrium Tinggi', 'Pengawet Sintetis'],
                  nutritionFilter,
                  (value) => setSheetState(() => nutritionFilter = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setSheetState(() {
                        timeFilter = null;
                        statusFilter = null;
                        nutritionFilter = null;
                      }),
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _timeFilter = timeFilter;
                            _statusFilter = statusFilter;
                            _nutritionFilter = nutritionFilter;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Terapkan Filter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetCategory(
    String title,
    List<String> options,
    String? selected,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _text(12, FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => _FilterChip(
                    label: option,
                    selected: selected == option,
                    onTap: () => onSelected(option),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ProductSafety status) => switch (status) {
        ProductSafety.aman => 'Aman',
        ProductSafety.waspada => 'Waspada',
        ProductSafety.bahaya => 'Bahaya',
      };

  ProductSafety _statusFromLabel(String label) => switch (label) {
        'Aman' => ProductSafety.aman,
        'Waspada' => ProductSafety.waspada,
        _ => ProductSafety.bahaya,
      };

  TextStyle _text(
    double size,
    FontWeight weight, [
    Color color = AppColors.textPrimary,
  ]) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryAccent : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryAccent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<ActivityProduct> products;

  const _SummaryCard({required this.products});

  @override
  Widget build(BuildContext context) {
    final consumed = products.where((product) => product.isConsumed).toList();
    final safe = consumed
        .where((product) => product.safety == ProductSafety.aman)
        .length;
    final alert = consumed
        .where((product) => product.safety == ProductSafety.waspada)
        .length;
    final danger = consumed
        .where((product) => product.safety == ProductSafety.bahaya)
        .length;
    final total = consumed.length;
    final safePercent = total == 0 ? 0 : (safe / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primaryAccent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ringkasan Bulan Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$safePercent% Aman',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                _ProgressSegment(
                  value: safe,
                  total: total,
                  color: AppColors.primaryAccent,
                ),
                _ProgressSegment(
                  value: alert,
                  total: total,
                  color: const Color(0xFFFFB74D),
                ),
                _ProgressSegment(
                  value: danger,
                  total: total,
                  color: const Color(0xFFE57373),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Legend('Aman', safe, total, AppColors.primaryAccent),
              _Legend('Waspada', alert, total, const Color(0xFFFFB74D)),
              _Legend('Bahaya', danger, total, const Color(0xFFE57373)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final int value;
  final int total;
  final Color color;

  const _ProgressSegment({
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        flex: value == 0 ? 1 : value,
        child: Container(
          height: 8,
          color:
              total == 0 || value == 0 ? color.withValues(alpha: 0.15) : color,
        ),
      );
}

class _Legend extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _Legend(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label (${total == 0 ? 0 : (value / total * 100).round()}%)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
}

class _HistoryItemCard extends StatelessWidget {
  final ActivityProduct product;
  final ValueChanged<bool> onConsumedChanged;
  final VoidCallback onTap;

  const _HistoryItemCard({
    required this.product,
    required this.onConsumedChanged,
    required this.onTap,
  });

  Color get _statusColor => switch (product.safety) {
        ProductSafety.aman => AppColors.primaryAccent,
        ProductSafety.waspada => const Color(0xFFFFB74D),
        ProductSafety.bahaya => const Color(0xFFE57373),
      };

  String get _statusLabel => switch (product.safety) {
        ProductSafety.aman => 'Aman',
        ProductSafety.waspada => 'Waspada',
        ProductSafety.bahaya => 'Bahaya',
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: _cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: _statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              product.icon,
                              color: _statusColor,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _statusLabel,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: _statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${product.time} • ${product.location}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          _NutritionPill('Kalori', '${product.calories} kkal'),
                          _NutritionPill(
                            'Gula',
                            '${product.sugar} g',
                            warning: product.sugar >= 20,
                          ),
                          _NutritionPill(
                            product.fiber > 0 ? 'Serat' : 'Protein',
                            product.fiber > 0
                                ? '${product.fiber} g'
                                : '${product.protein} g',
                          ),
                          _NutritionPill(
                            'Natrium',
                            '${product.sodium} mg',
                            warning: product.sodium >= 500,
                          ),
                        ],
                      ),
                      if (product.warning != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFE57373),
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  product.warning!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: const Color(0xFFC62828),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SizedBox(
                            width: 25,
                            height: 25,
                            child: Checkbox(
                              value: product.isConsumed,
                              onChanged: (value) =>
                                  onConsumedChanged(value ?? false),
                              activeColor: AppColors.primaryAccent,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          Text(
                            'Dikonsumsi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _NutritionPill extends StatelessWidget {
  final String label;
  final String value;
  final bool warning;

  const _NutritionPill(this.label, this.value, {this.warning = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          decoration: BoxDecoration(
            color: warning ? const Color(0xFFFFF1F1) : const Color(0xFFF1F5FC),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color:
                      warning ? const Color(0xFFC62828) : AppColors.textPrimary,
                ),
              ),
              if (warning)
                Text(
                  'Tinggi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 7,
                    color: const Color(0xFFC62828),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 42,
                  color: AppColors.primaryAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada riwayat ditemukan',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Coba ubah kata kunci atau filter pencarian Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
