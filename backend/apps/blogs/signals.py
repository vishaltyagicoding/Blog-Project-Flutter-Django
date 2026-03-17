from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.core.cache import cache
from .models import BlogPost

@receiver(post_save, sender=BlogPost)
def clear_blog_cache_on_save(sender, instance, **kwargs):
    """Clear cache when blog post is created or updated"""
    cache_key = f'blog_post_{instance.id}'
    cache.delete(cache_key)

@receiver(post_delete, sender=BlogPost)
def clear_blog_cache_on_delete(sender, instance, **kwargs):
    """Clear cache when blog post is deleted"""
    cache_key = f'blog_post_{instance.id}'
    cache.delete(cache_key)