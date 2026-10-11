import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "../models/book_model.dart";
import "bookshelf_screen.dart";
import "reader_screen.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              "Library Overview",
              style: TextStyle(
                color: accentGold,
                fontFamily: "serif",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
            valueListenable: Hive.box<LocalBook>("books").listenable(),
            builder: (context, box, _) {
              final books = box.values.toList();
              final totalBooks = books.length;
              final readBooks = books.where((b) => b.lastPage > 0).length;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Stats Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xDD2A1810),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: lightBrown.withAlpha(140), width: 1.2),
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
                            _buildStatItem("Books in Shelf", "$totalBooks",
                                Icons.menu_book),
                            _buildStatItem("Active Reads", "$readBooks",
                                Icons.chrome_reader_mode),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Open Bookshelf Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D4E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => const BookshelfScreen()),
                      );
                    },
                    icon: const Icon(Icons.shelves),
                    label: const Text(
                      "Go to Wooden Bookshelf",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Recent Documents",
                    style: TextStyle(
                      color: accentGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: "serif",
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (books.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          "No books yet. Go to Bookshelf to import PDFs.",
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...books.take(5).map((book) {
                      return Card(
                        color: const Color(0xCC2A1810),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: lightBrown.withAlpha(100)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf,
                              color: lightBrown),
                          title: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Page: ${book.lastPage + 1} of ${book.totalPages > 0 ? book.totalPages : 0}",
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: lightBrown, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => ReaderScreen(book: book)),
                            );
                          },
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD59E), size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}
