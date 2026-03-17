import '../config/api_config.dart';
import '../models/blog.dart';
import 'api_service.dart';

class BlogService {
  static Future<List<Blog>> getBlogs(
      {String? status, String? priority, String? search}) async {
    String url = ApiConfig.blogsEndpoint;
    List<String> params = [];

    if (status != null) params.add('status=$status');
    if (priority != null) params.add('priority=$priority');
    if (search != null && search.isNotEmpty) params.add('search=$search');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await ApiService.get(url);
    final results = response['results'] ?? response;
    return (results as List).map((json) => Blog.fromJson(json)).toList();
  }

  static Future<Blog> getBlog(int id) async {
    final response = await ApiService.get(ApiConfig.blogDetailEndpoint(id));
    return Blog.fromJson(response);
  }

  static Future<Blog> createBlog(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.blogsEndpoint, data);
    return Blog.fromJson(response);
  }

  static Future<Blog> updateBlog(int id, Map<String, dynamic> data) async {
    final response =
        await ApiService.put(ApiConfig.blogDetailEndpoint(id), data);
    return Blog.fromJson(response);
  }

  static Future<void> deleteBlog(int id) async {
    await ApiService.delete(ApiConfig.blogDetailEndpoint(id));
  }

  static Future<void> addComment(int blogId, String content) async {
    await ApiService.post(
        ApiConfig.blogCommentEndpoint(blogId), {'content': content});
  }

  static Future<BlogStatistics> getStatistics() async {
    final response = await ApiService.get(ApiConfig.blogStatisticsEndpoint);
    return BlogStatistics.fromJson(response);
  }
}
