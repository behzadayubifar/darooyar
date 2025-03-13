# راهنمای استقرار دارویار در لیارا

این راهنما مراحل استقرار سرور دارویار و NATS در لیارا را توضیح می‌دهد.

## پیش‌نیازها

1. نصب [Liara CLI](https://docs.liara.ir/cli/install)
2. ورود به حساب کاربری لیارا با دستور `liara login`

## گام 1: ایجاد شبکه در لیارا

ابتدا باید یک شبکه در لیارا ایجاد کنید تا برنامه‌ها بتوانند با یکدیگر ارتباط برقرار کنند:

```bash
liara network:create darooyar-network
```

## گام 2: استقرار NATS Server

1. وارد پوشه `liara-nats` شوید:

   ```bash
   cd liara-nats
   ```

2. یک دیسک برای ذخیره‌سازی داده‌های NATS ایجاد کنید:

   ```bash
   liara disk:create data --app nats-server --size 1
   ```

3. NATS را مستقر کنید:

   ```bash
   liara deploy
   ```

4. NATS را به شبکه متصل کنید:
   ```bash
   liara network:connect darooyar-network --app nats-server --alias nats-server
   ```

## گام 3: استقرار سرور دارویار

1. وارد پوشه `server` شوید:

   ```bash
   cd ../server
   ```

2. یک دیسک برای ذخیره‌سازی فایل‌ها ایجاد کنید:

   ```bash
   liara disk:create storage --app darooyar-server --size 1
   ```

3. متغیرهای محیطی مورد نیاز را تنظیم کنید:

   ```bash
   liara env:set OPENAI_API_KEY="YOUR_API_KEY" --app darooyar-server
   liara env:set JWT_SECRET="YOUR_SECRET_KEY" --app darooyar-server
   liara env:set DB_HOST="YOUR_DB_HOST" --app darooyar-server
   liara env:set DB_PORT="YOUR_DB_PORT" --app darooyar-server
   liara env:set DB_USER="YOUR_DB_USER" --app darooyar-server
   liara env:set DB_PASSWORD="YOUR_DB_PASSWORD" --app darooyar-server
   liara env:set DB_NAME="YOUR_DB_NAME" --app darooyar-server
   liara env:set NATS_URL="nats://nats-server:4222" --app darooyar-server
   ```

4. سرور دارویار را مستقر کنید:

   ```bash
   liara deploy
   ```

5. سرور دارویار را به شبکه متصل کنید:
   ```bash
   liara network:connect darooyar-network --app darooyar-server --alias darooyar-server
   ```

## گام 4: تست اتصال

برای تست اتصال به NATS، می‌توانید از دستور زیر استفاده کنید:

```bash
liara shell --app darooyar-server
cd /app
go run cmd/test_nats/main.go
```

## عیب‌یابی

اگر با مشکلی مواجه شدید، می‌توانید لاگ‌های برنامه‌ها را بررسی کنید:

```bash
liara logs --app nats-server
liara logs --app darooyar-server
```

## مانیتورینگ NATS

برای مشاهده وضعیت NATS، می‌توانید از پورت 8222 استفاده کنید. برای این کار، یک پروکسی ایجاد کنید:

```bash
liara proxy:create --app nats-server --port 8222
```

سپس می‌توانید با مراجعه به آدرس ارائه شده، وضعیت NATS را مشاهده کنید.
