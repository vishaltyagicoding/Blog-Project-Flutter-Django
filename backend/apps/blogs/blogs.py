from celery import shared_task
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags
import logging

logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=3)
def send_blog_notification_email(self, blog_post_id):
    """
    Send notification email when a new blog post is published
    """
    try:
        # Import inside the function to avoid circular imports
        from apps.blogs.models import BlogPost
        from apps.accounts.models import User
        
        # Get the blog post
        blog_post = BlogPost.objects.select_related('author').get(id=blog_post_id)
        
        # Get all subscribers or followers (customize based on your app)
        # Option 1: Send to all active users
        recipients = User.objects.filter(is_active=True, email_notifications=True)
        
        # Option 2: Send to specific followers/subscribers
        # recipients = blog_post.author.followers.filter(email_notifications=True)
        
        # Email subject
        subject = f"New Blog Post: {blog_post.title}"
        
        # Email content
        context = {
            'blog_post': blog_post,
            'author': blog_post.author,
            'title': blog_post.title,
            'excerpt': blog_post.content[:200] + '...' if len(blog_post.content) > 200 else blog_post.content,
            'url': f"{settings.SITE_URL}/blogs/{blog_post.id}/",
            'author_name': blog_post.author.get_full_name() or blog_post.author.email,
        }
        
        # Render HTML email
        html_message = render_to_string('emails/blog_notification.html', context)
        
        # Plain text version (fallback)
        plain_message = strip_tags(html_message)
        
        # From email
        from_email = settings.DEFAULT_FROM_EMAIL
        
        # Send emails in batches to avoid overwhelming the email server
        recipient_list = [user.email for user in recipients]
        
        # Option A: Send individual emails (more reliable but slower)
        success_count = 0
        fail_count = 0
        
        for recipient_email in recipient_list:
            try:
                send_mail(
                    subject=subject,
                    message=plain_message,
                    from_email=from_email,
                    recipient_list=[recipient_email],
                    html_message=html_message,
                    fail_silently=False,
                )
                success_count += 1
            except Exception as e:
                fail_count += 1
                logger.error(f"Failed to send email to {recipient_email}: {str(e)}")
        
        # Option B: Send to all at once (faster but may hit limits)
        # send_mail(
        #     subject=subject,
        #     message=plain_message,
        #     from_email=from_email,
        #     recipient_list=recipient_list,
        #     html_message=html_message,
        # )
        
        logger.info(f"Blog notification emails sent - Success: {success_count}, Failed: {fail_count}")
        
        return {
            'status': 'success',
            'blog_post_id': blog_post_id,
            'blog_title': blog_post.title,
            'recipients_count': len(recipient_list),
            'success_count': success_count,
            'fail_count': fail_count
        }
        
    except BlogPost.DoesNotExist:
        logger.error(f"Blog post with ID {blog_post_id} not found")
        return {
            'status': 'error',
            'message': f'Blog post with ID {blog_post_id} not found'
        }
        
    except Exception as e:
        logger.error(f"Error sending blog notification: {str(e)}")
        # Retry the task
        raise self.retry(exc=e, countdown=60)  # Retry after 60 seconds