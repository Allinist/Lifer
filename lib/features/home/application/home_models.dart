class HomeProductCardData {
  const HomeProductCardData({
    required this.productId,
    required this.name,
    required this.productType,
    required this.topLine,
    required this.bottomLine,
  });

  final String productId;
  final String name;
  final String productType;
  final String topLine;
  final String bottomLine;
}

class ReminderCardData {
  const ReminderCardData({
    required this.eventId,
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.urgencyScore,
  });

  final String eventId;
  final String productId;
  final String title;
  final String subtitle;
  final int urgencyScore;
}

class OtherProductGroupData {
  const OtherProductGroupData({
    required this.title,
    required this.itemCount,
    required this.items,
  });

  final String title;
  final int itemCount;
  final List<OtherProductItemData> items;
}

class OtherProductItemData {
  const OtherProductItemData({
    required this.productId,
    required this.name,
  });

  final String productId;
  final String name;
}
