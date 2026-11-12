class SearchCategory {
  const SearchCategory(this.label, {this.tag, this.isAdditive = false});

  final String label;
  final String? tag;
  final bool isAdditive;
}