FROM php:7.4-apache

# Install PHP extensions for MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Copy the application source code from the learning-app-ecommerce directory
# Context is set to parent directory, so learning-app-ecommerce/ is at the root
COPY learning-app-ecommerce/ /var/www/html/

# Set proper ownership and permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80

# Docker build updated Wed Jul 23 15:44:56 EDT 2025
