import "dart:io";
import "dart:math" as math;
import "package:flutter/material.dart";
import "package:file_picker/file_picker.dart";
import "package:hive_flutter/hive_flutter.dart";
import "../models/book_model.dart";
import "../services/permission_service.dart";
import "../services/sound_service.dart";
import "reader_screen.dart";

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  static const Color _darkWood = Color(0xFF1E0E05);
  static const Color _shelfWoodHighlight = Color(0xFF8D4E24);
  static const Color _shelfWoodDark = Color(0xFF4A230D);
  static const Color _accentGold = Color(0xFFFFD59E);

  LocalBook? _selectedBook;

  final List<Color> _spinePalette = const [
    Color(0xFF6B1D1D),
    Color(0xFF1B3B2B),
    Color(0xFF1E2D4A),
    Color(0xFF4A3525),
    Color(0xFF3E1F47),
    Color(0xFF423B28),
    Color(0xFF5A2A18),
  ];

  Color _getBookColor(String title) {
    if (title.isEmpty) {
      return _spinePalette.first;
    }
    final int hash = title.codeUnits.fold(0, (prev, elem) => prev + elem);
    return _spinePalette[hash % _spinePalette.length];
  }

  Future<void> _pickAndAddBook() async {
    SoundService.playWoodTap();

    final hasPermission = await PermissionService.requestStoragePermission();
    if (!hasPermission) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Storage permission is required to import PDF files."),
          backgroundColor: Color(0xFF5D4037),
        ),
      );
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["pdf"],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;
      final box = Hive.box<LocalBook>("books");

      final alreadyExists = box.values.any((b) => b.filePath == path);
      if (alreadyExists) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This book is already on your bookshelf!"),
            backgroundColor: Color(0xFF5D4037),
          ),
        );
        return;
      }

      final cleanTitle = name
          .replaceAll(RegExp(r"\.[^.]+$"), "")
          .replaceAll(RegExp(r"[\-_]+"), " ")
          .trim();

      final newBook = LocalBook(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: cleanTitle.isEmpty ? "Untitled Book" : cleanTitle,
        author: "Unknown Author",
        filePath: path,
        format: "pdf",
        totalPages: 0,
        lastPage: 0,
        lastRead: DateTime.now(),
      );

      await box.add(newBook);
      SoundService.playBookOpenThud();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedBook = newBook;
      });
    }
  }

  Future<void> _confirmDeleteBook(LocalBook book) async {
    SoundService.playWoodTap();
    bool deleteFromStorage = false;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF23120A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD7A878), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.delete_forever,
                        color: Colors.redAccent, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Remove Book",
                        style: TextStyle(
                          color: _accentGold,
                          fontFamily: "serif",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to remove \"${book.title}\" from your bookshelf?",
                  style: const TextStyle(
                    color: Color(0xFFEDE0D4),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: deleteFromStorage,
                        activeColor: const Color(0xFFC62828),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD7A878)),
                        onChanged: (val) {
                          setDialogState(() {
                            deleteFromStorage = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Also delete file from device storage",
                          style:
                              TextStyle(color: Color(0xFFD7CCC8), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        SoundService.playWoodTap();
                        Navigator.pop(ctx, false);
                      },
                      child: const Text("Cancel",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Delete",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (shouldDelete == true) {
      SoundService.playEraserRub();

      if (deleteFromStorage) {
        try {
          final file = File(book.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      await book.delete();

      if (!mounted) {
        return;
      }
      setState(() {
        if (_selectedBook?.filePath == book.filePath) {
          _selectedBook = null;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("\"${book.title}\" has been removed from the bookshelf."),
          backgroundColor: const Color(0xFF3E2723),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openReader(LocalBook book) {
    SoundService.playBookOpenThud();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) =>
            ReaderScreen(book: book, initialMode: ReadingMode.curl3d),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen("books")) {
      return Scaffold(
        backgroundColor: _darkWood,
        body: FutureBuilder<Box<LocalBook>>(
          future: Hive.openBox<LocalBook>("books"),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD7A878)));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Bookshelf Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }
            return _buildMainLayout(snapshot.data!);
          },
        ),
      );
    }

    final box = Hive.box<LocalBook>("books");
    return _buildMainLayout(box);
  }

  Widget _buildMainLayout(Box<LocalBook> box) {
    return Scaffold(
      backgroundColor: _darkWood,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2E170A),
                  Color(0xFF1E0E05),
                  Color(0xFF120702),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeaderBar(),
                  Expanded(
                    child: ValueListenableBuilder<Box<LocalBook>>(
                      valueListenable: box.listenable(),
                      builder: (context, box, _) {
                        final books = box.values.toList();

                        if (books.isEmpty) {
                          return _buildEmptyState();
                        }

                        return _buildWoodenShelfRack(books);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM RIGHT DELETE BUTTON
          Positioned(
            bottom: 24,
            right: 20,
            child: _buildRightBottomDeleteButton(),
          ),

          // OPEN BOOK BUTTON (WHEN BOOK IS LIFTED)
          if (_selectedBook != null)
            Positioned(
              bottom: 24,
              left: 20,
              child: _buildOpenFloatingButton(_selectedBook!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xBB1E0E05),
        border:
            Border(bottom: BorderSide(color: Color(0x33D7A878), width: 1.5)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.shelves, color: Color(0xFFD7A878), size: 28),
              SizedBox(width: 10),
              Text(
                "AK Reader",
                style: TextStyle(
                  color: _accentGold,
                  fontFamily: "serif",
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                        color: Colors.black,
                        offset: Offset(0, 1.5),
                        blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D2E12),
              foregroundColor: _accentGold,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0x66D7A878)),
              ),
            ),
            onPressed: _pickAndAddBook,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              "Add Book",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book, color: Color(0xFFD7A878), size: 54),
          const SizedBox(height: 12),
          const Text(
            "Your Bookshelf is Empty",
            style: TextStyle(
              color: _accentGold,
              fontFamily: "serif",
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Tap \"Add Book\" to place PDF documents on this shelf",
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8D4E24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: _pickAndAddBook,
            icon: const Icon(Icons.add),
            label: const Text("Import PDF"),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodenShelfRack(List<LocalBook> books) {
    const int booksPerShelf = 4;
    final int shelfCount = (books.length / booksPerShelf).ceil();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: shelfCount,
      itemBuilder: (context, shelfIndex) {
        final int start = shelfIndex * booksPerShelf;
        final int end = math.min(start + booksPerShelf, books.length);
        final shelfBooks = books.sublist(start, end);

        return Container(
          margin: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 175,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.bottomLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: shelfBooks.map((book) {
                      final isSelected =
                          _selectedBook?.filePath == book.filePath;
                      return _buildStandingBookSpine(book, isSelected);
                    }).toList(),
                  ),
                ),
              ),
              _buildWoodenPlank(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandingBookSpine(LocalBook book, bool isSelected) {
    final Color spineColor = _getBookColor(book.title);
    const double spineWidth = 48.0;
    const double spineHeight = 158.0;

    return GestureDetector(
      onTap: () {
        SoundService.playWoodTap();
        setState(() {
          if (_selectedBook?.filePath == book.filePath) {
            _openReader(book);
          } else {
            _selectedBook = book;
          }
        });
      },
      onLongPress: () => _confirmDeleteBook(book),
      child: AnimatedSlide(
        offset: isSelected ? const Offset(0.0, -0.14) : Offset.zero,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: spineWidth,
            height: spineHeight,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  spineColor.withAlpha(200),
                  spineColor,
                  spineColor.withAlpha(240),
                  Colors.black.withAlpha(180),
                ],
                stops: const [0.0, 0.3, 0.8, 1.0],
              ),
              border: Border.all(
                color: isSelected ? _accentGold : Colors.white24,
                width: isSelected ? 2.4 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isSelected ? Colors.black.withAlpha(220) : Colors.black54,
                  blurRadius: isSelected ? 22 : 6,
                  offset: Offset(0, isSelected ? 12 : 3),
                  spreadRadius: isSelected ? 3 : 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 10,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isSelected ? _accentGold : const Color(0x88D7A878),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isSelected ? _accentGold : const Color(0x88D7A878),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? _accentGold
                            : Colors.white.withAlpha(230),
                        fontFamily: "serif",
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        shadows: const [
                          Shadow(
                              color: Colors.black87,
                              blurRadius: 4,
                              offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  child: Text(
                    book.totalPages > 0 ? "p.${book.lastPage + 1}" : "PDF",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
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

  Widget _buildWoodenPlank() {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _shelfWoodHighlight,
            _shelfWoodDark,
            Color(0xFF1F0B03),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        height: 1,
        color: const Color(0x33FFFFFF),
      ),
    );
  }

  Widget _buildRightBottomDeleteButton() {
    final bool hasSelection = _selectedBook != null;

    return FloatingActionButton.extended(
      heroTag: "shelf_delete_btn",
      backgroundColor:
          hasSelection ? const Color(0xFFC62828) : const Color(0x55331B10),
      foregroundColor: hasSelection ? Colors.white : Colors.white38,
      elevation: hasSelection ? 8 : 2,
      onPressed: hasSelection
          ? () => _confirmDeleteBook(_selectedBook!)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      "Please tap a book on the shelf to select it first."),
                  backgroundColor: Color(0xFF3E2723),
                  duration: Duration(seconds: 2),
                ),
              );
            },
      icon: const Icon(Icons.delete_forever, size: 22),
      label: Text(
        hasSelection ? "Delete Book" : "Delete",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildOpenFloatingButton(LocalBook book) {
    return FloatingActionButton.extended(
      heroTag: "shelf_open_btn",
      backgroundColor: const Color(0xFF8D4E24),
      foregroundColor: Colors.white,
      elevation: 8,
      onPressed: () => _openReader(book),
      icon: const Icon(Icons.menu_book, size: 20),
      label: const Text(
        "Open Book",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
