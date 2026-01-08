import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/goal_model.dart';
import '../services/api_service.dart';
import '../utils/icon_utils.dart';
import '../utils/currency_input_formatter.dart';
import 'icon_selection_screen.dart';

class AddGoalScreen extends StatefulWidget {
  final Goal? goal;

  const AddGoalScreen({super.key, this.goal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _savedController;
  late TextEditingController _noteController;
  
  DateTime? _completionDate;
  String _selectedColor = '#4B0082';
  String _selectedIcon = 'star';
  bool _isLoading = false;

  final List<String> _colors = [
    '#4B0082', '#F44336', '#E91E63', '#9C27B0', '#673AB7', 
    '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4', '#009688', 
    '#4CAF50', '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107', 
    '#FF9800', '#FF5722', '#795548', '#9E9E9E', '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetController = TextEditingController(text: widget.goal != null ? formatter.format(widget.goal!.target).trim() : '');
    _savedController = TextEditingController(text: widget.goal != null ? formatter.format(widget.goal!.saved).trim() : '0');
    _noteController = TextEditingController(text: widget.goal?.note ?? '');
    _completionDate = widget.goal?.deadline;
    _selectedColor = widget.goal?.color ?? '#4B0082';
    _selectedIcon = widget.goal?.icon ?? 'star';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _hexToColor(_selectedColor),
            onColorChanged: (color) {
              setState(() {
                _selectedColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              });
            },
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Got it'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_completionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a completion date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final goal = Goal(
        id: widget.goal?.id,
        name: _nameController.text,
        target: double.parse(_targetController.text.replaceAll(RegExp(r'[^\d.]'), '')),
        saved: double.parse(_savedController.text.replaceAll(RegExp(r'[^\d.]'), '')),
        color: _selectedColor,
        icon: _selectedIcon,
        deadline: _completionDate!,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (widget.goal == null) {
        await _apiService.createGoal(goal);
      } else {
        await _apiService.updateGoal(goal);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _completionDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _completionDate = picked);
    }
  }

  Future<void> _selectIcon() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IconSelectionScreen(currentIcon: _selectedIcon),
      ),
    );
    if (result != null) {
      setState(() => _selectedIcon = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Edit Goal' : 'Add Goal',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveGoal,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Amount Input (Main Focus)
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Target Amount',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [CurrencyInputFormatter()],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '₹',
                          border: InputBorder.none,
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
                          if (double.tryParse(cleanValue) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // Goal Name
              const Text(
                'Goal Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              FTextField(
                controller: _nameController,
                hint: 'e.g. New Car',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Amount Saved Already
              const Text(
                'Amount Saved Already',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              FTextField(
                controller: _savedController,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
                  if (double.tryParse(cleanValue) == null) return 'Invalid number';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Completion Date
              const Text(
                'Completion Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
                      const SizedBox(width: 12),
                      Text(
                        _completionDate == null
                            ? 'Select Date'
                            : DateFormat('MMM dd, yyyy').format(_completionDate!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _completionDate == null ? Colors.black54 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Goal Color
              const Text(
                'Goal Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ..._colors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _hexToColor(color),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: !_colors.contains(_selectedColor)
                            ? _hexToColor(_selectedColor)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: !_colors.contains(_selectedColor)
                            ? Border.all(color: Colors.black, width: 3)
                            : Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: !_colors.contains(_selectedColor)
                          ? const Icon(Icons.check, color: Colors.white)
                          : const Icon(Icons.add, color: Colors.black),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Goal Icon
              const Text(
                'Goal Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectIcon,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(IconUtils.getIcon(_selectedIcon), size: 24, color: Colors.black87),
                      const SizedBox(width: 12),
                      Text(
                        'Select Icon',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Note
              const Text(
                'Note (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              FTextField(
                controller: _noteController,
                hint: 'Add a note...',
                maxLines: 3,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
