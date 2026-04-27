class InventoryBatchViewData {
  const InventoryBatchViewData({
    required this.productId,
    required this.title,
    required this.summary,
    required this.metric,
  });

  final String productId;
  final String title;
  final String summary;
  final String metric;
}

class DurableUsageViewData {
  const DurableUsageViewData({
    required this.productId,
    required this.title,
    required this.summary,
    required this.metric,
  });

  final String productId;
  final String title;
  final String summary;
  final String metric;
}

enum InventorySegment {
  consumable,
  durable;

  String get value => switch (this) {
        InventorySegment.consumable => 'consumable',
        InventorySegment.durable => 'durable',
      };

  String get label => switch (this) {
        InventorySegment.consumable => '消耗品',
        InventorySegment.durable => '常驻品',
      };
}
