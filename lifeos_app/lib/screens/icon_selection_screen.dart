import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../utils/icon_utils.dart';

class IconSelectionScreen extends StatelessWidget {
  final String currentIcon;

  const IconSelectionScreen({
    super.key,
    required this.currentIcon,
  });

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: const Text('Select Icon'),
        actions: [
          FButton.icon(
            onPress: () => Navigator.of(context).pop(),
            child: FIcon(FAssets.icons.x),
          ),
        ],
      ),
      content: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: IconUtils.iconMap.length,
        itemBuilder: (context, index) {
          final iconName = IconUtils.iconMap.keys.elementAt(index);
          final iconData = IconUtils.iconMap.values.elementAt(index);
          final isSelected = iconName == currentIcon;

          return GestureDetector(
            onTap: () {
              Navigator.of(context).pop(iconName);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? context.theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? context.theme.colorScheme.primary
                      : context.theme.colorScheme.border,
                  width: 2,
                ),
              ),
              child: Icon(
                iconData,
                color: isSelected
                    ? context.theme.colorScheme.primary
                    : context.theme.colorScheme.foreground,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }
}
