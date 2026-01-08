import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final ApiService _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _isMonthView = false;
  List<PlannerEvent> _events = [];
  bool _isLoading = true;
  bool _initialScrollDone = false;
  late final PageController _weekPageController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _weekPageController = PageController(initialPage: 1000); // Start far out to allow back swiping
    _scrollController = ScrollController();
    _fetchEvents();
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final now = DateTime.now();
        const double hourHeight = 60.0;
        final double currentOffset = (now.hour * hourHeight) + (now.minute / 60.0 * hourHeight);
        
        final double viewportHeight = _scrollController.position.viewportDimension;
        double targetOffset = currentOffset - (viewportHeight / 2);
        
        if (targetOffset < 0) targetOffset = 0;
        if (targetOffset > _scrollController.position.maxScrollExtent) {
          targetOffset = _scrollController.position.maxScrollExtent;
        }
        
        _scrollController.jumpTo(targetOffset);
      }
    });
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      // Fetch for the whole month to handle month view and day view cache
      final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
      
      final events = await _apiService.getEvents(startDate: start, endDate: end);
      setState(() {
        _events = events;
        _isLoading = false;
        if (!_initialScrollDone) {
          _initialScrollDone = true;
          _scrollToCurrentTime();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error?
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _focusedMonth = date; // Update focused month too
      if (_isMonthView) {
        _isMonthView = false; // Switch back to day view on selection from month
      }
    });

    // Reset the week page controller to the current week when a new date is selected
    // so that the selected date is always in the visible range of the current page.
    if (_weekPageController.hasClients) {
      _weekPageController.jumpToPage(1000);
    }

    _fetchEvents(); // Refetch if month changed, optimizations can be done later
  }

  void _onTodayPressed() {
    _onDateSelected(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventSheet(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isMonthView) _buildWeekSelector(),
            Expanded(
              child: _isMonthView ? _buildMonthView() : _buildDayView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FButton(
            onPress: _onTodayPressed,
            label: const Text('Today'),
            style: FButtonStyle.secondary,
          ),
          GestureDetector(
            onTap: () => setState(() => _isMonthView = !_isMonthView),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isMonthView ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: PageView.builder(
        controller: _weekPageController,
        onPageChanged: (index) {
          // You can use the index to update the base date if needed,
          // but usually calculating based on page offset from 1000 is safer.
        },
        itemBuilder: (context, pageIndex) {
          // Calculate the start of the week for this page
          // pageIndex 1000 is our "current" week. 1001 is next, 999 is prev.
          final offset = pageIndex - 1000;
          final currentMonday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          final startOfWeek = currentMonday.add(Duration(days: offset * 7));
          
          final dates = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: dates.map((date) {
              final isSelected = date.year == _selectedDate.year && 
                                 date.month == _selectedDate.month && 
                                 date.day == _selectedDate.day;
              final isToday = date.year == DateTime.now().year && 
                              date.month == DateTime.now().year && 
                              date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () => _onDateSelected(date),
                child: Container(
                  width: 45,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected 
                        ? Border.all(color: Colors.black, width: 2) 
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date).substring(0, 3),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMonthView() {
    // Simple grid implementation
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday; // 1 = Mon, 7 = Sun

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontSize: 12)))
                .toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth + startingWeekday - 1,
            itemBuilder: (context, index) {
              if (index < startingWeekday - 1) return const SizedBox();
              
              final day = index - (startingWeekday - 1) + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () => _onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<List<PlannerEvent>> _groupEvents(List<PlannerEvent> events) {
    if (events.isEmpty) return [];
    
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    List<List<PlannerEvent>> clusters = [];
    List<PlannerEvent> currentCluster = [events.first];
    DateTime clusterEnd = events.first.endTime;
    
    for (int i = 1; i < events.length; i++) {
        final e = events[i];
        if (e.startTime.isBefore(clusterEnd)) {
            currentCluster.add(e);
            if (e.endTime.isAfter(clusterEnd)) clusterEnd = e.endTime;
        } else {
            clusters.add(currentCluster);
            currentCluster = [e];
            clusterEnd = e.endTime;
        }
    }
    clusters.add(currentCluster);
    return clusters;
  }

  Widget _buildDayView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dailyEvents = _events.where((e) => 
      e.startTime.year == _selectedDate.year && 
      e.startTime.month == _selectedDate.month && 
      e.startTime.day == _selectedDate.day
    ).toList();
    
    final clusters = _groupEvents(dailyEvents);
    final double hourHeight = 60.0;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           SizedBox(
             width: 50,
             child: Column(
               children: List.generate(24, (index) => SizedBox(
                 height: hourHeight,
                 child: Align(
                   alignment: Alignment.topCenter,
                   child: Text(
                      DateFormat('h a').format(DateTime(0, 0, 0, index)),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                   ),
                 ),
               )),
             ),
           ),
           Expanded(
             child: LayoutBuilder(
               builder: (context, constraints) {
                 final double width = constraints.maxWidth;
                 List<Widget> children = [];
                 
                 for (int i = 0; i < 24; i++) {
                   children.add(Positioned(
                      top: i * hourHeight,
                      left: 0, right: 0,
                      height: 1,
                      child: Container(color: Colors.grey.withOpacity(0.1)),
                   ));
                   children.add(Positioned(
                      top: i * hourHeight,
                      left: 0, right: 0,
                      height: hourHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _showAddEventSheet(initialStartTime: TimeOfDay(hour: i, minute: 0)),
                        child: Container(),
                      ),
                   ));
                 }
                 
                 for (var cluster in clusters) {
                    List<List<PlannerEvent>> columns = [];
                    for (var event in cluster) {
                        bool placed = false;
                        for (var col in columns) {
                            if (!col.last.endTime.isAfter(event.startTime)) {
                                col.add(event);
                                placed = true;
                                break;
                            }
                        }
                        if (!placed) columns.add([event]);
                    }
                    
                    double colWidth = width / columns.length;
                    
                    for (int c = 0; c < columns.length; c++) {
                        for (var event in columns[c]) {
                            double startMin = event.startTime.hour * 60 + event.startTime.minute.toDouble();
                            double endMin = event.endTime.hour * 60 + event.endTime.minute.toDouble();
                            double top = (startMin / 60) * hourHeight;
                            double h = ((endMin - startMin) / 60) * hourHeight;
                            if (h < 25) h = 25; 
                            
                            children.add(Positioned(
                                top: top,
                                left: c * colWidth,
                                width: colWidth,
                                height: h,
                                child: GestureDetector(
                                    onTap: () => _showEditEventSheet(event),
                                    child: Container(
                                        margin: const EdgeInsets.only(left: 1, right: 1, bottom: 1),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                            color: event.colorObj.withOpacity(0.12),
                                            border: Border(
                                              left: BorderSide(color: event.colorObj, width: 3),
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                if (h > 30)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Text(
                                                      "${DateFormat('h:mm').format(event.startTime)} - ${DateFormat('h:mm').format(event.endTime)}",
                                                      style: TextStyle(
                                                        fontSize: 9, 
                                                        fontWeight: FontWeight.w600,
                                                        color: event.colorObj.withOpacity(0.8),
                                                      ),
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    event.title, 
                                                    maxLines: h < 45 ? 1 : 3, 
                                                    overflow: TextOverflow.fade, 
                                                    softWrap: h >= 45,
                                                    style: TextStyle(
                                                      fontSize: h < 30 ? 10 : 11, 
                                                      fontWeight: FontWeight.bold, 
                                                      color: event.colorObj,
                                                      height: 1.1,
                                                    )
                                                  ),
                                                ),
                                            ],
                                        )
                                    )
                                )
                            ));
                        }
                    }
                 }
                 
                 // Current Time Indicator
                 final now = DateTime.now();
                 if (_selectedDate.year == now.year &&
                     _selectedDate.month == now.month &&
                     _selectedDate.day == now.day) {
                   
                   final double currentMinutes = now.hour * 60 + now.minute.toDouble();
                   final double top = (currentMinutes / 60) * hourHeight;
                   
                   children.add(Positioned(
                     top: top,
                     left: 0,
                     right: 0,
                     child: Row(
                       children: [
                         Container(
                           width: 8,
                           height: 8,
                           decoration: const BoxDecoration(
                             color: Colors.red,
                             shape: BoxShape.circle,
                           ),
                         ),
                         Expanded(
                           child: Container(
                             height: 2,
                             color: Colors.red,
                           ),
                         ),
                       ],
                     ),
                   ));
                 }

                 return SizedBox(
                     height: 24 * hourHeight,
                     child: Stack(children: children),
                 );
               }
             ),
           ),
        ],
      ),
    );
  }

  void _showAddEventSheet({TimeOfDay? initialStartTime}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventSheet(
        selectedDate: _selectedDate,
        initialStartTime: initialStartTime,
        existingEvents: _events,
        onSave: (event) async {
          setState(() {
            _events.add(event); 
            // In a real app we'd likely just re-fetch or optimistically add
            // For now, let's just refetch to be safe with sorting/overlapping logic from backend if any
          });
          _fetchEvents();
        },
      ),
    );
  }

  void _showEditEventSheet(PlannerEvent event) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventSheet(
        selectedDate: event.startTime,
        event: event,
        existingEvents: _events,
        onSave: (updatedEvent) async {
           _fetchEvents();
        },
        onDelete: (id) async {
           // Delete logic here or passed through
           await _apiService.deleteEvent(id);
           _fetchEvents();
        },
      ),
    );
  }
}

class AddEventSheet extends StatefulWidget {
  final DateTime selectedDate;
  final TimeOfDay? initialStartTime;
  final PlannerEvent? event;
  final List<PlannerEvent> existingEvents;
  final Function(PlannerEvent event) onSave;
  final Function(String id)? onDelete;

  const AddEventSheet({
    super.key,
    required this.selectedDate,
    this.initialStartTime,
    this.event,
    this.existingEvents = const [],
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late DateTime _selectedDate;
  final ApiService _apiService = ApiService();
  late String _selectedColor;

  final List<String> _presetColors = [
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#18181B', // Zinc/Black
  ];

  String _selectedTimeZone = 'IST (UTC+05:30)';
  
  // Map of Timezone label to offset hours
  final Map<String, double> _timeZones = {
    'IST (UTC+05:30)': 5.5,
    'PST (UTC-08:00)': -8.0,
    'PDT (UTC-07:00)': -7.0,
    'EST (UTC-05:00)': -5.0,
    'EDT (UTC-04:00)': -4.0,
    'UTC': 0.0,
    'CET (UTC+01:00)': 1.0,
    'GMT (UTC+00:00)': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _notesController = TextEditingController(text: widget.event?.notes ?? '');
    
    // Default to passed date, but allow changing
    _selectedDate = widget.selectedDate;
    _selectedColor = widget.event?.color ?? _presetColors.first;
    
    if (widget.event != null) {
      _startTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.event!.endTime);
    } else {
      _startTime = widget.initialStartTime ?? TimeOfDay.now();
      _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mimic the design style of AddTransactionScreen
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.event != null ? 'Edit Event' : 'New Event',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title Field
              const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FTextField(
                controller: _titleController,
                hint: 'Event Title',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Date Selection
               const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
               const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Time Zone Dropdown
              const Text('Time Zone', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timeZones.containsKey(_selectedTimeZone) ? _selectedTimeZone : _timeZones.keys.first,
                    isExpanded: true,
                    items: _timeZones.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedTimeZone = newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Color Selection
              const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final colorHex = _presetColors[index];
                    final colorValue = Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
                    final isSelected = _selectedColor == colorHex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorValue,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: colorValue.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected 
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Time Inputs
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _buildTimePicker(
                          _startTime,
                          (time) {
                            setState(() {
                              _startTime = time;
                              // Auto set end time to 1 hour after
                              final startDateTime = DateTime(2022, 1, 1, time.hour, time.minute);
                              final endDateTime = startDateTime.add(const Duration(hours: 1));
                              _endTime = TimeOfDay.fromDateTime(endDateTime);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _buildTimePicker(
                          _endTime,
                          (time) => setState(() => _endTime = time),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Notes Field
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FTextField(
                controller: _notesController,
                hint: 'Add details (Optional)',
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  if (widget.event != null) ...[
                    Expanded(
                      child: FButton(
                        style: FButtonStyle.destructive,
                        label: const Text('Delete'),
                        onPress: () async {
                           if (widget.onDelete != null) {
                             await widget.onDelete!(widget.event!.id!);
                             if (mounted) Navigator.pop(context);
                           }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: FButton(
                      onPress: _validateAndSave,
                      label: Text(widget.event != null ? 'Update' : 'Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildTimePicker(TimeOfDay time, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (newTime != null) onChanged(newTime);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16),
            const SizedBox(width: 8),
            Text(
              time.format(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Check if the proposed time range overlaps with any existing event
  /// Returns [true] if overlap exists
  bool _checkConflict(DateTime start, DateTime end) {
     for (var e in widget.existingEvents) {
       // Skip self if editing
       if (widget.event != null && e.id == widget.event!.id) continue;
       
       // Check date match first (since start/end includes dates)
       if (e.startTime.year == start.year && 
           e.startTime.month == start.month && 
           e.startTime.day == start.day) {
             
         // Overlap logic: (StartA < EndB) and (EndA > StartB)
         if (start.isBefore(e.endTime) && end.isAfter(e.startTime)) {
           return true;
         }
       }
     }
     return false;
  }

  Future<void> _validateAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Calculate UTC Time based on selected Time Zone
    // Our target is to create a DateTime that represents the absolute moment in time
    // equivalent to the user's input in the selected time zone.
    
    // First, verify end time is after start time (handling day wrap roughly)
    var startHour = _startTime.hour;
    var startMinute = _startTime.minute;
    var endHour = _endTime.hour;
    var endMinute = _endTime.minute;
    
    // Create base date times
    DateTime localStart = DateTime(
      _selectedDate.year, 
      _selectedDate.month, 
      _selectedDate.day, 
      startHour, 
      startMinute
    );
    
    DateTime localEnd = DateTime(
      _selectedDate.year, 
      _selectedDate.month, 
      _selectedDate.day, 
      endHour, 
      endMinute
    );
    
    if (localEnd.isBefore(localStart)) {
      // Assume next day if end time is earlier
      localEnd = localEnd.add(const Duration(days: 1));
    }
    
    // 2. Adjust for Time Zone
    // The user input e.g. 10:00. This is 10:00 in 'Selected Zone'.
    // We want to convert this to UTC.
    // UTC = ZoneTime - Offset
    
    final offsetHours = _timeZones[_selectedTimeZone]!;
    final offsetDuration = Duration(minutes: (offsetHours * 60).round());
             
    // We treat the constructed DateTime as if it were in that zone, then subtract offset to get UTC
    // Note: DateTime constructor makes it Local or UTC. We just need the numbers.
    // Correct logic: 
    // If I say 10:00 PST (UTC-8), then UTC is 10 + 8 = 18:00.
    // So UTC = Time - Offset.  (10 - (-8) = 18).
    // Let's manually construct the UTC timestamp.
    
    final finalStart = DateTime.utc(
      _selectedDate.year, 
      _selectedDate.month, 
      _selectedDate.day, 
      startHour, 
      startMinute
    ).subtract(offsetDuration); // Subtracting the offset (e.g. -8 hours) means Adding 8 hours. Correct.
    
    final finalEnd = DateTime.utc(
      localEnd.year, 
      localEnd.month, 
      localEnd.day, 
      endHour, 
      endMinute
    ).subtract(offsetDuration);


    // 3. Conflict Detection
    // Use the *calculated* final times to check against existing events (which are in local/utc converted)
    // Wait, existing events in _events list are already converted to Local device time by the UI loader.
    // So to compare correctly, I should compare against what these times would be in Local device time.
    final deviceLocalStart = finalStart.toLocal();
    final deviceLocalEnd = finalEnd.toLocal();
    
    if (_checkConflict(deviceLocalStart, deviceLocalEnd)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Scheduling Conflict'),
          content: const Text(
            'There is already an event scheduled during this time slot. Do you want to save it anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
    }

    final event = PlannerEvent(
      id: widget.event?.id,
      title: _titleController.text,
      startTime: finalStart, // Save as UTC
      endTime: finalEnd,     // Save as UTC
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      color: _selectedColor,
    );

    try {
      PlannerEvent savedEvent;
      if (widget.event != null) {
        savedEvent = await _apiService.updateEvent(event);
      } else {
        savedEvent = await _apiService.createEvent(event);
      }
      widget.onSave(savedEvent);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Error handling
    }
  }
}
