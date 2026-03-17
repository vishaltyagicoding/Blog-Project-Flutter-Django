from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.core.cache import cache
from django.utils import timezone
from .models import BlogPost, Comment
from .serializers import BlogPostSerializer, CommentSerializer, BlogPostCreateUpdateSerializer
from .permissions import IsBlogOwner

class BlogPostViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsBlogOwner]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'content']
    ordering_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']
    
    def _get_cache_key(self, pk):
        """Generate cache key for current user"""
        return f'blog_post_{pk}'
    
    def _clear_cache(self, pk):
        """Clear cached tasks for current user"""
        cache_key = self._get_cache_key(pk)
        cache.delete(cache_key)
    
    def get_queryset(self):
        self.queryset = BlogPost.objects.filter(author=self.request.user).select_related('author').prefetch_related('comments')
        status_filter = self.request.query_params.get('status', None)
        priority_filter = self.request.query_params.get('priority', None)
        
        if status_filter:
            self.queryset = self.queryset.filter(status=status_filter)
        
        if priority_filter:
            self.queryset = self.queryset.filter(priority=priority_filter)
        
        return self.queryset
    
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return BlogPostCreateUpdateSerializer
        return BlogPostSerializer
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        blog = serializer.save(author=request.user)
        self._clear_cache(blog.id)

        sresponse_serializer = BlogPostSerializer(blog)
        return Response(sresponse_serializer.data, status=status.HTTP_201_CREATED)
    

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        blog = serializer.save()
        self._clear_cache(blog.id)

        sresponse_serializer = BlogPostSerializer(blog)
        return Response(sresponse_serializer.data, status=status.HTTP_200_OK)


    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        blog_id = instance.id
        self.perform_destroy(instance)
        self._clear_cache(blog_id)
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=True, methods=['post'])
    def add_comment(self, request, pk=None):
        blog_post = self.get_object()
        serializer = CommentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(blog=blog_post, author=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        blog_posts = self.get_queryset()
        data = {
            'total': blog_posts.count(),
            'published': blog_posts.filter(status='published').count(),
            'draft': blog_posts.filter(status='draft').count(),
            'archived': blog_posts.filter(status='archived').count(),
            'comments_count': Comment.objects.filter(blog__in=blog_posts).count(),
            'last_updated': blog_posts.latest('updated_at').updated_at if blog_posts.exists() else None,
        }
        return Response(data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        recent_posts = BlogPost.objects.filter(author=request.user, created_at__gte=timezone.now()-timezone.timedelta(days=7)).order_by('-created_at')
        serializer = self.get_serializer(recent_posts, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    

    @action(detail=False, methods=['get'])
    def search(self, request):
        query = request.query_params.get('q', None)
        if query:
            search_results = BlogPost.objects.filter(author=request.user, title__icontains=query).order_by('-created_at')
            serializer = self.get_serializer(search_results, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response({'detail': 'Query parameter "q" is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def filter_by_status(self, request):
        status_param = request.query_params.get('status', None)
        if status_param:
            filtered_posts = BlogPost.objects.filter(author=request.user, status=status_param).order_by('-created_at')
            serializer = self.get_serializer(filtered_posts, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response({'detail': 'Query parameter "status" is required'}, status=status.HTTP_400_BAD_REQUEST)
    

    @action(detail=False, methods=['get'])
    def filter_by_priority(self, request):
        priority_param = request.query_params.get('priority', None)
        if priority_param:
            filtered_posts = BlogPost.objects.filter(author=request.user, priority=priority_param).order_by('-created_at')
            serializer = self.get_serializer(filtered_posts, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response({'detail': 'Query parameter "priority" is required'}, status=status.HTTP_400_BAD_REQUEST)