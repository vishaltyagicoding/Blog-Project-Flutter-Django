from django.apps import AppConfig
import logging

logger = logging.getLogger(__name__)

class BlogsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.blogs'
    verbose_name = 'Blog Management'
    
    def ready(self):
        """
        Initialize app when Django starts.
        Import signals to ensure they are registered.
        """
        try:
            import apps.blogs.signals
            logger.debug("Blogs signals imported successfully")
        except ImportError as e:
            # Signals file might not exist yet - that's ok
            logger.debug(f"Signals not found for blogs app: {e}")
            