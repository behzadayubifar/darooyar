FROM nats:latest

# پورت‌های مورد نیاز NATS
EXPOSE 4222 8222 6222

# راه‌اندازی NATS با JetStream برای ذخیره‌سازی پیام‌ها
CMD ["--jetstream", "--http_port", "8222"] 