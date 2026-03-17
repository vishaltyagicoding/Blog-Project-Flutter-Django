import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/blog_provider.dart';
import '../widgets/blog_card.dart';
import '../widgets/empty_error_view.dart';
import 'blog_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _BlogsTab(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlogProvider>().loadBlogs();
      context.read<BlogProvider>().loadStatistics();
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Blogs' : 'Profile'),
        centerTitle: false,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Blog',
              onPressed: () => _openBlogForm(context),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article),
              label: 'Blogs'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  void _openBlogForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _BlogFormSheet(),
    );
  }
}

// ── Blogs Tab ──────────────────────────────────────────────────────────────────

class _BlogsTab extends StatelessWidget {
  const _BlogsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<BlogProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _StatsBar(provider: provider),
            _SearchBar(provider: provider),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? ErrorView(
                          error: provider.error!,
                          onRetry: () => provider.loadBlogs())
                      : provider.blogs.isEmpty
                          ? const EmptyView(
                              message: 'No blogs yet',
                              hint: 'Tap + to create your first blog',
                            )
                          : RefreshIndicator(
                              onRefresh: () => provider.loadBlogs(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: provider.blogs.length,
                                itemBuilder: (context, i) => BlogCard(
                                  blog: provider.blogs[i],
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => BlogScreen(
                                            blog: provider.blogs[i])),
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsBar extends StatelessWidget {
  final BlogProvider provider;
  const _StatsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.statistics?.total ?? 0;
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, size: 18),
          const SizedBox(width: 8),
          Text('$total blog${total == 1 ? '' : 's'} total',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final BlogProvider provider;
  const _SearchBar({required this.provider});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search blogs...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.provider.loadBlogs();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (v) {
          setState(() {});
          widget.provider.loadBlogs(search: v);
        },
      ),
    );
  }
}

// ── Blog Create Form ───────────────────────────────────────────────────────────

class _BlogFormSheet extends StatefulWidget {
  const _BlogFormSheet();

  @override
  State<_BlogFormSheet> createState() => _BlogFormSheetState();
}

class _BlogFormSheetState extends State<_BlogFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _status = 'draft';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<BlogProvider>();
    final success = await provider.createBlog({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'status': _status,
    });
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('New Blog', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                  labelText: 'Content', border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                  labelText: 'Status', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'published', child: Text('Published')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            Consumer<BlogProvider>(
              builder: (_, provider, __) => ElevatedButton(
                onPressed: provider.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
