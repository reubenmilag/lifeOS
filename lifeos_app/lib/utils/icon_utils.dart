import 'package:flutter/material.dart';

class IconUtils {
  static const Map<String, IconData> iconMap = {
    'star': Icons.star,
    'home': Icons.home,
    'work': Icons.work,
    'school': Icons.school,
    'flight': Icons.flight,
    'directions_car': Icons.directions_car,
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'local_hospital': Icons.local_hospital,
    'fitness_center': Icons.fitness_center,
    'pets': Icons.pets,
    'savings': Icons.savings,
    'attach_money': Icons.attach_money,
    'card_giftcard': Icons.card_giftcard,
    'computer': Icons.computer,
    'phone_iphone': Icons.phone_iphone,
    'music_note': Icons.music_note,
    'camera_alt': Icons.camera_alt,
    'book': Icons.book,
    'sports_soccer': Icons.sports_soccer,
  };

  static IconData getIcon(String name) {
    return iconMap[name] ?? Icons.star;
  }

  static String getName(IconData icon) {
    return iconMap.entries
        .firstWhere((element) => element.value == icon,
            orElse: () => const MapEntry('star', Icons.star))
        .key;
  }
}
