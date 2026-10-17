import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:permission_handler/permission_handler.dart";
import "../models/book_model.dart";
import "../services/permission_service.dart";
import "bookshelf_screen.dart";
import "reader_screen.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyPermissionStatus();
    }
  }

  Future<void> _verifyPermissionStatus() async {
    final granted = await PermissionService.checkPermissionDirect();
    if (mounted) {
      setState(() => _hasPermission = granted);
    }
  }

  Future<void> _checkInitialPermission() async {
    final granted = await PermissionService.checkPermissionDirect();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (!granted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog({VoidCallback? onGrantedAction}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1508),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD59E), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.folder_shared, color: Color(0xFFFFD59E), size: 24),
            SizedBox(width: 8),
            Text(
              "Storage Access",
              style: TextStyle(
                color: Color(0xFFFFD59E),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "AK Reader needs storage access to find and read books from your device. Please grant permission to load and read your library.",
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Deny", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD59E),
              foregroundColor: const Color(0xFF1E1008),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await PermissionService.requestStoragePermission();
              if (mounted) {
                setState(() => _hasPermission = res);
                if (res && onGrantedAction != null) {
                  onGrantedAction();
                } else if (!res) {
                  await openAppSettings();
                }
              }
            },
            child: const Text(
              "Allow Access",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _runGatedAction(VoidCallback action) {
    if (_hasPermission) {
      action();
    } else {
      _showPermissionDialog(onGrantedAction: action);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkWood = Color(0xFF1E1008);
    const lightBrown = Color(0xFFD7A878);
    const accentGold = Color(0xFFFFD59E);

    return Scaffold(
      backgroundColor: darkWood,
      appBar: AppBar(
        backgroundColor: const Color(0xFF23120A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: lightBrown, size: 24),
            SizedBox(width: 8),
            Text(
              "AK Reader Library",
              style: TextStyle(
                color: accentGold,
                fontFamily: "serif",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shelves, color: accentGold),
            tooltip: "Bookshelf View",
            onPressed: () => _runGatedAction(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookshelfScreen()),
              );
            }),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A1508),
              Color(0xFF1E1008),
              Color(0xFF130904),
            ],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<Box<LocalBook>>(
            valueListenable: Hive.isBoxOpen("books")
                ? Hive.box<LocalBook>("books").listenable()
                : ValueNotifier<Box<LocalBook>>(Hive.box<LocalBook>("books")),
            builder: (context, box, _) {
              final books = box.values.toList();
              final totalBooks = books.length;
              final readBooks = books.where((b) => b.lastPage > 0).length;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Permission Warning Banner if Denied
                  if (!_hasPermission)
                    GestureDetector(
                      onTap: () => _showPermissionDialog(),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFB74D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFFFFB74D), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Storage permission not granted. Tap to allow.",
                                style: TextStyle(color: Color(0xFFFFD59E), fontSize: 11),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Color(0xFFFFB74D), size: 18),
                          ],
                        ),
                      ),
                    ),

                  // Reading Statistics Card
                  GestureDetector(
                    onTap: () => _runGatedAction(() {}),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xDD2A1810),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: lightBrown.withAlpha(140), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Reading Statistics",
                            style: TextStyle(
                              color: accentGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: "serif",
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem("Total Books", "$totalBooks", lightBrown),
                              _buildStatItem("In Progress", "$readBooks", accentGold),
                              _buildStatItem(
                                "Finished",
                                "${books.where((b) => b.lastPage >= b.totalPages - 1 && b.totalPages > 1).length}",
                                Colors.greenAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Books Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Books",
                        style: TextStyle(
                          color: accentGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: "serif",
                        ),
                      ),
                      TextButton(
                        onPressed: () => _runGatedAction(() {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BookshelfScreen()),
                          );
                        }),
                        child: const Text("View All", style: TextStyle(color: lightBrown)),
                      ),
                    ],
                  ),

                  if (books.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.book_outlined, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text(
                            "No books loaded yet.",
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E2010),
                              foregroundColor: accentGold,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text("Open Bookshelf"),
                            onPressed: () => _runGatedAction(() {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BookshelfScreen()),
                              );
                            }),
                          ),
                        ],
                      ),
                    )
                  else
                    ...books.take(4).map(
                          (book) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xBB2A1810),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0x33C5A059)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.menu_book, color: lightBrown),
                              title: Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: accentGold, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                "Page ${book.lastPage + 1} of ${book.totalPages}",
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: lightBrown),
                              onTap: () => _runGatedAction(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReaderScreen(book: book),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3E2010),
        foregroundColor: accentGold,
        onPressed: () => _runGatedAction(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookshelfScreen()),
          );
        }),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
