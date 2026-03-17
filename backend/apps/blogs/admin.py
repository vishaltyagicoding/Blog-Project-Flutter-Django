from django.contrib import admin
from django.utils.html import format_html
from .models import BlogPost, Comment

class BlogCommentInline(admin.TabularInline):
    model = Comment
    extra = 0
    readonly_fields = ['author', 'content', 'created_at']
    fields = ['author', 'content', 'created_at']
    can_delete = False
    show_change_link = False

@admin.register(BlogPost)
class BlogPostAdmin(admin.ModelAdmin):
    list_display = ['title', 'author', 'created_at', 'status_badge']
    list_filter = ['status', 'created_at']
    search_fields = ['title', 'content', 'author__username']
    ordering = ['-created_at']

    fieldsets = (
        ("Post Info", {'fields': ('title', 'content', 'author')}),
        ('Publication Info', {'fields': ('status',)}),
        ('Timestamps', {'fields': ('created_at',)}),
    )

    readonly_fields = ['created_at']

    inlines = [BlogCommentInline]
    
    def status_badge(self, obj):
        colors = {
            'draft': 'orange',
            'published': 'green',
        }
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            colors.get(obj.status, 'gray'),
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'

@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ['blog', 'author', 'created_at']
    list_filter = ['created_at']
    search_fields = ['content', 'author__username', 'blog__title']
    ordering = ['-created_at']

    def content_preview(self, obj):
        return (obj.content[:75] + '...') if len(obj.content) > 75 else obj.content
    content_preview.short_description = 'Content Preview'