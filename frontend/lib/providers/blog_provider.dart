import 'package:flutter/foundation.dart';
import '../models/blog.dart';
import '../services/blog_service.dart';

class BlogProvider with ChangeNotifier {
  List<Blog> _blogs = [];
  BlogStatistics? _statistics;
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;
  String? _priorityFilter;

  List<Blog> get blogs => _blogs;
  BlogStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String? get priorityFilter => _priorityFilter;

  Future<void> loadBlogs({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _blogs = await BlogService.getBlogs(
        status: _statusFilter,
        priority: _priorityFilter,
        search: search,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStatistics() async {
    try {
      _statistics = await BlogService.getStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createBlog(Map<String, dynamic> data) async {
    try {
      final task = await BlogService.createBlog(data);
      _blogs.insert(0, task);
      // Reload statistics after creation
      await loadStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBlog(int id, Map<String, dynamic> data) async {
    try {
      final updatedTask = await BlogService.updateBlog(id, data);
      final index = _blogs.indexWhere((t) => t.id == id);
      if (index != -1) {
        _blogs[index] = updatedTask;
        // Reload statistics after update (status/priority might have changed)
        await loadStatistics();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBlog(int id) async {
    try {
      await BlogService.deleteBlog(id);
      _blogs.removeWhere((t) => t.id == id);
      // Reload statistics after deletion
      await loadStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadBlogs();
  }

  void setPriorityFilter(String? priority) {
    _priorityFilter = priority;
    loadBlogs();
  }

  void clearFilters() {
    _statusFilter = null;
    _priorityFilter = null;
    loadBlogs();
  }

  Future<Blog?> getBlog(int id) async {
    try {
      return await BlogService.getBlog(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> addComment(int blogId, String content) async {
    await BlogService.addComment(blogId, content);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
