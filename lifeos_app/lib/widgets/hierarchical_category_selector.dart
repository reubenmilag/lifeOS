import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// Selection mode for the category selector
enum CategorySelectionMode {
  /// Single selection - only one category can be selected
  single,
  /// Multi selection - multiple categories can be selected with parent/child rules
  multi,
}

/// Result of category selection
class CategorySelectionResult {
  final List<Category> selectedCategories;
  final List<String> selectedIds;

  CategorySelectionResult({
    required this.selectedCategories,
    required this.selectedIds,
  });
}

/// A hierarchical category selector with expandable accordion-style UI
class HierarchicalCategorySelector extends StatefulWidget {
  final List<Category> categories;
  final List<String>? initialSelectedIds;
  final String? initialSingleSelectedId;
  final CategorySelectionMode mode;
  final String? filterType; // 'income', 'expense', or null for all
  final String title;
  final ValueChanged<CategorySelectionResult>? onSelectionChanged;

  const HierarchicalCategorySelector({
    super.key,
    required this.categories,
    this.initialSelectedIds,
    this.initialSingleSelectedId,
    this.mode = CategorySelectionMode.single,
    this.filterType,
    this.title = 'Select Category',
    this.onSelectionChanged,
  });

  @override
  State<HierarchicalCategorySelector> createState() =>
      _HierarchicalCategorySelectorState();
}

class _HierarchicalCategorySelectorState
    extends State<HierarchicalCategorySelector> {
  final Set<String> _selectedIds = {};
  final Set<String> _expandedIds = {};
  String? _singleSelectedId;

  @override
  void initState() {
    super.initState();
    if (widget.mode == CategorySelectionMode.multi) {
      if (widget.initialSelectedIds != null) {
        _selectedIds.addAll(widget.initialSelectedIds!);
      }
    } else {
      _singleSelectedId = widget.initialSingleSelectedId;
    }
  }

  List<Category> get _filteredCategories {
    if (widget.filterType == null) return widget.categories;
    return widget.categories
        .where((c) => c.type == widget.filterType)
        .toList();
  }

  /// Get all child IDs for a parent category
  Set<String> _getAllChildIds(Category parent) {
    return parent.children.map((c) => c.id).toSet();
  }

  /// Check if all children of a parent are selected
  bool _areAllChildrenSelected(Category parent) {
    if (parent.children.isEmpty) return false;
    return parent.children.every((child) => _selectedIds.contains(child.id));
  }

  /// Check if some (but not all) children are selected
  bool _areSomeChildrenSelected(Category parent) {
    if (parent.children.isEmpty) return false;
    final selectedCount =
        parent.children.where((child) => _selectedIds.contains(child.id)).length;
    return selectedCount > 0 && selectedCount < parent.children.length;
  }

  /// Handle parent category tap in multi-select mode
  void _toggleParentSelection(Category parent) {
    setState(() {
      final childIds = _getAllChildIds(parent);
      
      if (_areAllChildrenSelected(parent) || _selectedIds.contains(parent.id)) {
        // Deselect parent and all children
        _selectedIds.remove(parent.id);
        _selectedIds.removeAll(childIds);
      } else {
        // Select parent and all children
        _selectedIds.add(parent.id);
        _selectedIds.addAll(childIds);
      }
      _notifySelectionChanged();
    });
  }

  /// Handle child category tap in multi-select mode
  void _toggleChildSelection(Category child, Category parent) {
    setState(() {
      if (_selectedIds.contains(child.id)) {
        _selectedIds.remove(child.id);
        // Also remove parent if it was selected
        _selectedIds.remove(parent.id);
      } else {
        _selectedIds.add(child.id);
        // Check if all siblings are now selected
        if (_areAllChildrenSelected(parent)) {
          _selectedIds.add(parent.id);
        }
      }
      _notifySelectionChanged();
    });
  }

  /// Handle single selection
  void _selectSingle(Category category) {
    setState(() {
      _singleSelectedId = category.id;
    });
    
    // Return immediately in single mode
    Navigator.of(context).pop(CategorySelectionResult(
      selectedCategories: [category],
      selectedIds: [category.id],
    ));
  }

  void _notifySelectionChanged() {
    if (widget.onSelectionChanged != null) {
      final allCategories = <Category>[];
      for (final parent in widget.categories) {
        if (_selectedIds.contains(parent.id)) {
          allCategories.add(parent);
        }
        for (final child in parent.children) {
          if (_selectedIds.contains(child.id)) {
            allCategories.add(child);
          }
        }
      }
      widget.onSelectionChanged!(CategorySelectionResult(
        selectedCategories: allCategories,
        selectedIds: _selectedIds.toList(),
      ));
    }
  }

  void _confirmSelection() {
    final allCategories = <Category>[];
    for (final parent in widget.categories) {
      if (_selectedIds.contains(parent.id)) {
        allCategories.add(parent);
      }
      for (final child in parent.children) {
        if (_selectedIds.contains(child.id)) {
          allCategories.add(child);
        }
      }
    }
    Navigator.of(context).pop(CategorySelectionResult(
      selectedCategories: allCategories,
      selectedIds: _selectedIds.toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.mode == CategorySelectionMode.multi)
                  TextButton(
                    onPressed: _selectedIds.isNotEmpty ? _confirmSelection : null,
                    child: Text(
                      'Done (${_selectedIds.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedIds.isNotEmpty
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 60),
              ],
            ),
          ),
          const Divider(height: 1),
          // Category list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                return _buildCategoryTile(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Category category) {
    final isExpanded = _expandedIds.contains(category.id);
    final hasChildren = category.children.isNotEmpty;

    // Determine selection state for multi-select
    CheckboxState checkState = CheckboxState.unchecked;
    if (widget.mode == CategorySelectionMode.multi) {
      if (_selectedIds.contains(category.id) || _areAllChildrenSelected(category)) {
        checkState = CheckboxState.checked;
      } else if (_areSomeChildrenSelected(category)) {
        checkState = CheckboxState.indeterminate;
      }
    }

    return Column(
      children: [
        // Parent tile
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (widget.mode == CategorySelectionMode.single) {
                if (hasChildren) {
                  setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(category.id);
                    } else {
                      _expandedIds.add(category.id);
                    }
                  });
                } else {
                  _selectSingle(category);
                }
              } else {
                _toggleParentSelection(category);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _parseColor(category.color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconData(category.icon),
                      color: _parseColor(category.color),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category name
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Selection indicator or expand arrow
                  if (widget.mode == CategorySelectionMode.multi)
                    _buildCheckbox(checkState, () => _toggleParentSelection(category))
                  else if (hasChildren)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.25 : 0,
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                      ),
                    )
                  else if (_singleSelectedId == category.id)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          ),
        ),
        // Children (expandable)
        if (hasChildren)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded || widget.mode == CategorySelectionMode.multi
                ? _buildChildrenList(category, isExpanded)
                : const SizedBox.shrink(),
          ),
        Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildChildrenList(Category parent, bool isExpanded) {
    if (widget.mode == CategorySelectionMode.multi && !isExpanded) {
      // In multi-select, show collapsed indicator if has selections
      final selectedCount = parent.children
          .where((c) => _selectedIds.contains(c.id))
          .length;
      if (selectedCount == 0) return const SizedBox.shrink();
      
      return GestureDetector(
        onTap: () {
          setState(() => _expandedIds.add(parent.id));
        },
        child: Container(
          padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
          child: Text(
            '$selectedCount subcategories selected • Tap to expand',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Collapse button for multi-select
          if (widget.mode == CategorySelectionMode.multi && isExpanded)
            InkWell(
              onTap: () {
                setState(() => _expandedIds.remove(parent.id));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 56),
                    Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Collapse',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...parent.children.map((child) => _buildChildTile(child, parent)),
        ],
      ),
    );
  }

  Widget _buildChildTile(Category child, Category parent) {
    final isSelected = widget.mode == CategorySelectionMode.multi
        ? _selectedIds.contains(child.id)
        : _singleSelectedId == child.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (widget.mode == CategorySelectionMode.single) {
            _selectSingle(child);
          } else {
            _toggleChildSelection(child, parent);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 72, right: 16, top: 10, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parseColor(child.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconData(child.icon),
                  color: _parseColor(child.color),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              if (widget.mode == CategorySelectionMode.multi)
                _buildCheckbox(
                  isSelected ? CheckboxState.checked : CheckboxState.unchecked,
                  () => _toggleChildSelection(child, parent),
                )
              else if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(CheckboxState state, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: state == CheckboxState.unchecked
              ? Colors.transparent
              : Theme.of(context).primaryColor,
          border: Border.all(
            color: state == CheckboxState.unchecked
                ? Colors.grey.shade400
                : Theme.of(context).primaryColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: state == CheckboxState.checked
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : state == CheckboxState.indeterminate
                ? const Icon(Icons.remove, size: 18, color: Colors.white)
                : null,
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  IconData _getIconData(String iconName) {
    // Map icon names to IconData
    const iconMap = {
      'restaurant': Icons.restaurant,
      'restaurant_menu': Icons.restaurant_menu,
      'local_bar': Icons.local_bar,
      'local_cafe': Icons.local_cafe,
      'shopping_cart': Icons.shopping_cart,
      'fastfood': Icons.fastfood,
      'shopping_bag': Icons.shopping_bag,
      'checkroom': Icons.checkroom,
      'hiking': Icons.hiking,
      'local_pharmacy': Icons.local_pharmacy,
      'devices': Icons.devices,
      'sports_esports': Icons.sports_esports,
      'card_giftcard': Icons.card_giftcard,
      'celebration': Icons.celebration,
      'favorite': Icons.favorite,
      'spa': Icons.spa,
      'home': Icons.home,
      'yard': Icons.yard,
      'diamond': Icons.diamond,
      'child_care': Icons.child_care,
      'pets': Icons.pets,
      'construction': Icons.construction,
      'bolt': Icons.bolt,
      'build': Icons.build,
      'account_balance': Icons.account_balance,
      'security': Icons.security,
      'key': Icons.key,
      'cleaning_services': Icons.cleaning_services,
      'directions_bus': Icons.directions_bus,
      'business_center': Icons.business_center,
      'flight': Icons.flight,
      'train': Icons.train,
      'local_taxi': Icons.local_taxi,
      'directions_car': Icons.directions_car,
      'local_gas_station': Icons.local_gas_station,
      'assignment': Icons.assignment,
      'local_parking': Icons.local_parking,
      'car_rental': Icons.car_rental,
      'verified_user': Icons.verified_user,
      'car_repair': Icons.car_repair,
      'theater_comedy': Icons.theater_comedy,
      'fitness_center': Icons.fitness_center,
      'smoking_rooms': Icons.smoking_rooms,
      'library_books': Icons.library_books,
      'volunteer_activism': Icons.volunteer_activism,
      'stadium': Icons.stadium,
      'school': Icons.school,
      'psychology': Icons.psychology,
      'medical_services': Icons.medical_services,
      'brush': Icons.brush,
      'luggage': Icons.luggage,
      'cake': Icons.cake,
      'casino': Icons.casino,
      'live_tv': Icons.live_tv,
      'self_improvement': Icons.self_improvement,
      'computer': Icons.computer,
      'wifi': Icons.wifi,
      'phone_android': Icons.phone_android,
      'mail': Icons.mail,
      'apps': Icons.apps,
      'support_agent': Icons.support_agent,
      'receipt_long': Icons.receipt_long,
      'family_restroom': Icons.family_restroom,
      'gavel': Icons.gavel,
      'health_and_safety': Icons.health_and_safety,
      'money_off': Icons.money_off,
      'receipt': Icons.receipt,
      'trending_up': Icons.trending_up,
      'collections': Icons.collections,
      'insert_chart': Icons.insert_chart,
      'real_estate_agent': Icons.real_estate_agent,
      'savings': Icons.savings,
      'currency_bitcoin': Icons.currency_bitcoin,
      'pie_chart': Icons.pie_chart,
      'show_chart': Icons.show_chart,
      'business': Icons.business,
      'inventory_2': Icons.inventory_2,
      'groups': Icons.groups,
      'hotel': Icons.hotel,
      'engineering': Icons.engineering,
      'workspace_premium': Icons.workspace_premium,
      'child_friendly': Icons.child_friendly,
      'elderly': Icons.elderly,
      'subscriptions': Icons.subscriptions,
      'music_note': Icons.music_note,
      'movie': Icons.movie,
      'cloud': Icons.cloud,
      'build_circle': Icons.build_circle,
      'warning': Icons.warning,
      'emergency': Icons.emergency,
      'local_hospital': Icons.local_hospital,
      'home_repair_service': Icons.home_repair_service,
      'more_horiz': Icons.more_horiz,
      'help_outline': Icons.help_outline,
      'attach_money': Icons.attach_money,
      'payments': Icons.payments,
      'work': Icons.work,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}

enum CheckboxState { unchecked, checked, indeterminate }

/// Helper function to show the category selector as a bottom sheet
Future<CategorySelectionResult?> showCategorySelector({
  required BuildContext context,
  required List<Category> categories,
  CategorySelectionMode mode = CategorySelectionMode.single,
  String? filterType,
  List<String>? initialSelectedIds,
  String? initialSingleSelectedId,
  String title = 'Select Category',
}) {
  return showModalBottomSheet<CategorySelectionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => HierarchicalCategorySelector(
      categories: categories,
      mode: mode,
      filterType: filterType,
      initialSelectedIds: initialSelectedIds,
      initialSingleSelectedId: initialSingleSelectedId,
      title: title,
    ),
  );
}
