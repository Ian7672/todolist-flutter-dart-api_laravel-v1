import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
      ),
      home: const TodoListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Task {
  final int id;
  final String title;
  final String priority;
  final String dueDate;
  final String createdAt;
  final String updatedAt;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.isDone,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      priority: json['priority'],
      dueDate: json['due_date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isDone: json['is_done'].toString().toLowerCase() == 'true',
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});
  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage>
    with TickerProviderStateMixin {
  final String baseUrl = 'http://127.0.0.1:8000/api';
  List<Task> tasks = [];
  String searchQuery = '';
  String filterStatus = 'all'; // all, completed, pending

  final TextEditingController titleController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String selectedPriority = 'low';
  DateTime? selectedDate;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    titleController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Task> getFilteredTasks() {
    List<Task> filtered = tasks.where((task) {
      bool matchesSearch = task.title.toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesFilter = filterStatus == 'all' ||
          (filterStatus == 'completed' && task.isDone) ||
          (filterStatus == 'pending' && !task.isDone);
      return matchesSearch && matchesFilter;
    }).toList();

    filtered.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      DateTime aDate = DateTime.parse(a.dueDate);
      DateTime bDate = DateTime.parse(b.dueDate);
      return aDate.compareTo(bDate);
    });

    return filtered;
  }

  Future<void> fetchTasks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks'));
      if (response.statusCode == 200) {
        List jsonData = json.decode(response.body);
        setState(() {
          tasks = jsonData.map((e) => Task.fromJson(e)).toList();
        });
      }
    } catch (e) {
      _showSnackbar('Error fetching tasks: $e', isError: true);
    }
  }

  Future<void> addTask() async {
    if (titleController.text.isEmpty || selectedDate == null) {
      _showSnackbar('Please fill all fields', isError: true);
      return;
    }
    try {
      await http.post(Uri.parse('$baseUrl/tasks'), body: {
        'title': titleController.text,
        'priority': selectedPriority,
        'due_date': selectedDate!.toIso8601String().split('T')[0],
      });
      titleController.clear();
      selectedDate = null;
      selectedPriority = 'low';
      fetchTasks();
      _showSnackbar('Task added successfully!');
    } catch (e) {
      _showSnackbar('Error adding task: $e', isError: true);
    }
  }

  Future<void> editTask(Task task) async {
    if (titleController.text.isEmpty || selectedDate == null) return;
    try {
      await http.put(Uri.parse('$baseUrl/tasks/${task.id}'), body: {
        'title': titleController.text,
        'priority': selectedPriority,
        'due_date': selectedDate!.toIso8601String().split('T')[0],
        'is_done': task.isDone.toString(),
      });
      titleController.clear();
      selectedDate = null;
      fetchTasks();
      _showSnackbar('Task updated successfully!');
    } catch (e) {
      _showSnackbar('Error updating task: $e', isError: true);
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/tasks/$id'));
      fetchTasks();
      _showSnackbar('Task deleted successfully!');
    } catch (e) {
      _showSnackbar('Error deleting task: $e', isError: true);
    }
  }

  Future<void> updateTaskStatus(Task task, bool newStatus) async {
    try {
      await http.put(Uri.parse('$baseUrl/tasks/${task.id}'), body: {
        'title': task.title,
        'priority': task.priority,
        'due_date': task.dueDate,
        'is_done': newStatus.toString(),
      });
      fetchTasks();
    } catch (e) {
      _showSnackbar('Error updating task status: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return raw;
    }
  }

  void showAddDialog() {
    titleController.clear();
    selectedDate = null;
    selectedPriority = 'low';
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_task, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tambah Tugas Baru',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Tugas',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Prioritas',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'low',
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.green.shade400, size: 12),
                        const SizedBox(width: 8),
                        const Text('Rendah'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.orange.shade400, size: 12),
                        const SizedBox(width: 8),
                        const Text('Sedang'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.red.shade400, size: 12),
                        const SizedBox(width: 8),
                        const Text('Tinggi'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedPriority = value!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate == null
                            ? 'Pilih Tanggal Deadline'
                            : 'Deadline: ${selectedDate.toString().split(' ')[0]}',
                        style: TextStyle(
                          color: selectedDate == null ? Colors.grey : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      addTask();
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showEditDialog(Task task) {
    titleController.text = task.title;
    selectedPriority = task.priority;
    selectedDate = DateTime.parse(task.dueDate);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.orange.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit, color: Colors.orange.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Tugas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Tugas',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Prioritas',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'low',
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.green.shade400, size: 12),
                        const SizedBox(width: 8),
                        const Text('Rendah'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.orange.shade400, size: 12),
                        const SizedBox(width: 8),
                        const Text('Sedang'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.red.shade400, size: 12),
                        const SizedBox(width: 8),
                        const Text('Tinggi'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedPriority = value!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate == null
                            ? 'Pilih Tanggal Deadline'
                            : 'Deadline: ${selectedDate.toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      editTask(task);
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'low':
      default:
        return Colors.green.shade100;
    }
  }

  IconData getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
      default:
        return Icons.arrow_downward;
    }
  }

  Widget _buildStatsCard() {
    int totalTasks = tasks.length;
    int completedTasks = tasks.where((task) => task.isDone).length;
    int pendingTasks = totalTasks - completedTasks;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.purple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalTasks.toString(), Icons.list_alt),
          _buildStatItem('Selesai', completedTasks.toString(), Icons.check_circle),
          _buildStatItem('Pending', pendingTasks.toString(), Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha((0.8 * 255).toInt()),

            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = getFilteredTasks();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.task_alt, color: Colors.blue.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'TaskFlow',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari tugas...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  switch (index) {
                    case 0:
                      filterStatus = 'all';
                      break;
                    case 1:
                      filterStatus = 'pending';
                      break;
                    case 2:
                      filterStatus = 'completed';
                      break;
                  }
                });
              },
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade700,
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Pending'),
                Tab(text: 'Selesai'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada tugas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan tugas pertama Anda!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada tugas yang cocok',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (ctx, i) {
                          final task = filteredTasks[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        child: Transform.scale(
                                          scale: 1.2,
                                          child: Checkbox(
                                            value: task.isDone,
                                            shape: const CircleBorder(),
                                            onChanged: (val) {
                                              updateTaskStatus(task, !task.isDone);
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: task.isDone
                                                    ? Colors.grey.shade500
                                                    : Colors.black87,
                                                decoration: task.isDone
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: getPriorityColor(task.priority),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        getPriorityIcon(task.priority),
                                                        size: 12,
                                                        color: task.priority == 'high'
                                                            ? Colors.red.shade700
                                                            : task.priority == 'medium'
                                                                ? Colors.orange.shade700
                                                                : Colors.green.shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        task.priority == 'high'
                                                            ? 'Tinggi'
                                                            : task.priority == 'medium'
                                                                ? 'Sedang'
                                                                : 'Rendah',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          color: task.priority == 'high'
                                                              ? Colors.red.shade700
                                                              : task.priority == 'medium'
                                                                  ? Colors.orange.shade700
                                                                  : Colors.green.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(Icons.calendar_today,
                                                    size: 14, color: Colors.grey.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  task.dueDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time,
                                                    size: 12, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Dibuat: ${formatDateTime(task.createdAt)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.edit, 
                                                  color: Colors.blue.shade600, size: 20),
                                              onPressed: () => showEditDialog(task),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.delete, 
                                                  color: Colors.red.shade600, size: 20),
                                              onPressed: () => _showDeleteConfirmation(task.id),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tugas'),
      ),
    );
  }

  void _showDeleteConfirmation(int taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Konfirmasi Hapus'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              deleteTask(taskId);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}