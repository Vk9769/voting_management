import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MaterialApp(
    home: AgentNewsPage(),
    debugShowCheckedModeBanner: false,
  ));
}

// ----------------- Main News Page -----------------
class AgentNewsPage extends StatefulWidget {
  const AgentNewsPage({super.key});

  @override
  State<AgentNewsPage> createState() => _AgentNewsPageState();
}

class _AgentNewsPageState extends State<AgentNewsPage>
    with SingleTickerProviderStateMixin {
  final List<News> newsList = [];
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  void _postNews() {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;

    final newNews = News(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      timestamp: DateTime.now(),
      images: List<File>.from(_selectedImages),
    );

    setState(() {
      newsList.insert(0, newNews);
      _selectedImages.clear();
    });

    _titleCtrl.clear();
    _descCtrl.clear();
  }

  String formatDate(DateTime dt) => DateFormat('dd MMM yyyy, HH:mm').format(dt);

  void _toggleLike(News news) {
    setState(() {
      news.isLiked = !news.isLiked;
      news.isLiked ? news.likes++ : news.likes--;
    });
  }

  void _openComments(News news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommentsPage(news: news)),
    );
  }

  // ----------------- Edit News -----------------
  void _editNews(News news) {
    final titleCtrl = TextEditingController(text: news.title);
    final descCtrl = TextEditingController(text: news.description);
    List<File> images = List<File>.from(news.images);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Edit News'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(hintText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  // Add Images Button
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final List<XFile>? newImages = await _picker.pickMultiImage();
                          if (newImages != null && newImages.isNotEmpty) {
                            setDialogState(() {
                              images.addAll(newImages.map((e) => File(e.path)));
                            });
                          }
                        },
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Images'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (images.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final img = images[index];
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(img),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: InkWell(
                                  onTap: () {
                                    setDialogState(() => images.removeAt(index));
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    news.title = titleCtrl.text.trim();
                    news.description = descCtrl.text.trim();
                    news.images.clear();
                    news.images.addAll(images);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteNews(News news) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete News'),
        content: const Text('Are you sure you want to delete this news?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                newsList.remove(news);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Daily News'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // --- Post News Panel ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'News Title',
                    prefixIcon: const Icon(Icons.edit_note),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  decoration: InputDecoration(
                    hintText: 'News Description',
                    prefixIcon: const Icon(Icons.description),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        final img = _selectedImages[index];
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(img),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedImages.removeAt(index)),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image, color: Colors.blueAccent),
                      tooltip: 'Pick Images',
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _postNews,
                      icon: const Icon(Icons.send),
                      label: const Text('Post News'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // --- News List ---
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: ListView.builder(
                key: ValueKey(newsList.length),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  final news = newsList[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images slider
                        if (news.images.isNotEmpty)
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: news.images.length,
                              itemBuilder: (context, imgIndex) {
                                return Container(
                                  margin: const EdgeInsets.all(6),
                                  width: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(news.images[imgIndex]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          title: Text(
                            news.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                news.description,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatDate(news.timestamp),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                            child: const Icon(Icons.campaign,
                                color: Colors.blueAccent),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  news.isLiked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () => _toggleLike(news),
                              ),
                              Text('${news.likes}'),
                              IconButton(
                                icon: const Icon(Icons.comment_outlined,
                                    color: Colors.grey),
                                onPressed: () => _openComments(news),
                              ),
                              Text('${news.comments.length}'),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () => _editNews(news),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteNews(news),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Comments Page -----------------
class CommentsPage extends StatefulWidget {
  final News news;
  const CommentsPage({super.key, required this.news});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentCtrl = TextEditingController();

  void _addComment() {
    if (_commentCtrl.text.trim().isEmpty) return;

    setState(() {
      widget.news.comments.add(Comment(
        username: 'User${widget.news.comments.length + 1}',
        text: _commentCtrl.text.trim(),
      ));
      _commentCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text('Comments'), backgroundColor: Colors.blueAccent),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.news.comments.length,
              itemBuilder: (context, index) {
                final comment = widget.news.comments[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(comment.username[0])),
                  title: Text(comment.username,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(comment.text),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Models -----------------
class News {
  String title;
  String description;
  final DateTime timestamp;
  final List<File> images;
  int likes;
  bool isLiked;
  final List<Comment> comments;

  News({
    required this.title,
    required this.description,
    required this.timestamp,
    this.images = const [],
    this.likes = 0,
    this.isLiked = false,
    List<Comment>? comments,
  }) : comments = comments ?? [];
}

class Comment {
  final String username;
  final String text;

  Comment({required this.username, required this.text});
}
