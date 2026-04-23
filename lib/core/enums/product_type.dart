enum ProductType {
  consumable,
  durable;

  String get label => switch (this) {
        ProductType.consumable => '消耗品',
        ProductType.durable => '常驻品',
      };
}
