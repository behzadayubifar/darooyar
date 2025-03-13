FROM golang:1.22 AS builder

WORKDIR /app

# کپی فایل‌های go.mod و go.sum
COPY go.mod go.sum ./

# دانلود وابستگی‌ها
RUN go mod download

# کپی کد منبع
COPY . .

# ساخت برنامه
RUN CGO_ENABLED=0 GOOS=linux go build -o darooyar-server main.go

# مرحله نهایی
FROM alpine:latest

WORKDIR /app

# نصب پکیج‌های مورد نیاز
RUN apk --no-cache add ca-certificates tzdata

# کپی فایل اجرایی از مرحله قبل
COPY --from=builder /app/darooyar-server .

# کپی فایل‌های مورد نیاز
COPY --from=builder /app/.env.example ./.env
COPY --from=builder /app/storage ./storage
COPY --from=builder /app/db/migrations ./db/migrations

# ایجاد کاربر غیر root
RUN adduser -D -g '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# پورت مورد نیاز
EXPOSE 8080

# اجرای برنامه
CMD ["./darooyar-server"] 