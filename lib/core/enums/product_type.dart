enum ProductType {
  consumable,
  durable,
  pricingOnly;

  String get label => switch (this) {
        ProductType.consumable => '消耗品',
        ProductType.durable => '常驻品',
        ProductType.pricingOnly => '计价品',
      };
}
