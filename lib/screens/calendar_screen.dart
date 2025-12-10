import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/widgets/task_card.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:intl/date_symbol_data_local.dart'; // Web hatası için şart

class CalendarScreen extends StatefulWidget {
  final DatabaseService dbService;
  const CalendarScreen({super.key, required this.dbService});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Personel Filtresi
  String? _selectedMemberId;

  // Web Yükleme Kontrolü
  bool _isLocaleLoaded = false;

  // Tab Controller
  late TabController _tabController;
  
  // YENİ: Personel Listesi için Kaydırma Kontrolcüsü
  final ScrollController _memberScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // 1. Web için Tarih Formatını Başlat
    initializeDateFormatting('tr_TR', null).then((_) {
      if (mounted) setState(() => _isLocaleLoaded = true);
    });

    // 2. Tab Controller'ı Başlat
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberScrollController.dispose(); // Kontrolcüyü kapatmayı unutma
    super.dispose();
  }

  // Görev Filtreleme
  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null || !isSameDay(task.dueDate, day)) {
        return false;
      }
      if (_selectedMemberId != null) {
        if (_selectedMemberId == 'unassigned') {
          return task.assignedMemberId == null;
        }
        return task.assignedMemberId == _selectedMemberId;
      }
      return true;
    }).toList();
  }

  void _navigateToDetail(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task, dbService: widget.dbService)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Yüklenmediyse bekle
    if (!_isLocaleLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final allTasks = taskProvider.tasks;
    final allSelectedEvents = _getTasksForDay(_selectedDay ?? _focusedDay, allTasks);

    // Listeyi İkiye Ayır
    final activeEvents = allSelectedEvents.where((t) => !t.isDone).toList();
    final completedEvents = allSelectedEvents.where((t) => t.isDone).toList();

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SafeArea(
            child: Column(
              children: [
                // --- 1. PERSONEL FİLTRESİ (SCROLLBAR EKLENDİ) ---
                Container(
                  height: 70, // Yüksekliği biraz artırdık (Scrollbar sığsın diye)
                  margin: const EdgeInsets.only(top: 10, bottom: 5),
                  child: Scrollbar(
                    controller: _memberScrollController, // Scrollbar'ı listeye bağla
                    thumbVisibility: true, // Çubuğu her zaman göster
                    trackVisibility: true, // Arka plan izini göster (opsiyonel)
                    thickness: 6, // Çubuk kalınlığı
                    radius: const Radius.circular(10), // Yuvarlak köşeler
                    child: ListView(
                      controller: _memberScrollController, // Listeyi Scrollbar'a bağla
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding güncellendi
                      children: [
                        _buildFilterChip("Tümü", null, Icons.people, themeProvider),
                        _buildFilterChip("Havuz", "unassigned", Icons.layers, themeProvider),
                        ...taskProvider.teamMembers.map((member) {
                          return _buildFilterChip(member.name, member.id, Icons.person, themeProvider);
                        }),
                      ],
                    ),
                  ),
                ),

                // --- 2. TAKVİM ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: [
                      if (!isDarkMode)
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: TableCalendar<Task>(
                    firstDay: DateTime.utc(2020, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    locale: 'tr_TR', 
                    eventLoader: (day) => _getTasksForDay(day, allTasks),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(color: themeProvider.primaryColor, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(color: themeProvider.secondaryColor.withOpacity(0.5), shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: themeProvider.secondaryColor, shape: BoxShape.circle),
                      defaultTextStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      weekendTextStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                      leftChevronIcon: Icon(Icons.chevron_left, color: isDarkMode ? Colors.white : Colors.black54),
                      rightChevronIcon: Icon(Icons.chevron_right, color: isDarkMode ? Colors.white : Colors.black54),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),

                // --- 3. TAB BAR ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: themeProvider.secondaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: themeProvider.secondaryColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Yapılacaklar"),
                            const SizedBox(width: 8),
                            if (activeEvents.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                child: Text("${activeEvents.length}", style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Tamamlananlar"),
                            const SizedBox(width: 8),
                            if (completedEvents.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                child: Text("${completedEvents.length}", style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- 4. GÖREV LİSTELERİ ---
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.backgroundDark : Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTaskList(activeEvents, taskProvider, context),
                        _buildTaskList(completedEvents, taskProvider, context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LİSTE OLUŞTURUCU ---
  Widget _buildTaskList(List<Task> tasks, TaskProvider taskProvider, BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 50, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 10),
            Text(
              "Bu listede görev yok.", 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: TaskCard(
            task: task,
            categories: const {}, 
            onTap: () => _navigateToDetail(task),
            onToggleDone: () {
              if (taskProvider.canCompleteTask(task)) {
                taskProvider.toggleTaskStatus(task);
              } else {
                 String ownerName = taskProvider.getMemberName(task.assignedMemberId) ?? "Başkası";
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Bu görev $ownerName kişisine ait."), backgroundColor: Colors.red)
                 );
              }
            },
          ),
        );
      },
    );
  }

  // --- FİLTRE ÇİPİ ---
  Widget _buildFilterChip(String label, String? memberId, IconData icon, ThemeProvider theme) {
    bool isSelected = _selectedMemberId == memberId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMemberId = memberId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.secondaryColor : Colors.grey.withOpacity(0.3),
            width: 1.5
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey.shade700
              ),
            ),
          ],
        ),
      ),
    );
  }
}