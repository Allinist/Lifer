class ProductDetailViewData {
  const ProductDetailViewData({
    required this.productId,
    required this.name,
    required this.productTypeLabel,
    required this.categoryLabel,
    required this.latestPriceLabel,
    required this.stockLabel,
    required this.expiryLabel,
  });

  final String productId;
  final String name;
  final String productTypeLabel;
  final String categoryLabel;
  final String latestPriceLabel;
  final String stockLabel;
  final String expiryLabel;
}
