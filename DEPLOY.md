# Развертывание "Бабушкины вкусности и рукоделие"

## Требования
- VPS с Ubuntu 22.04/24.04
- Домен, указывающий на публичный IP сервера (A/AAAA записи для example.com и www.example.com)
- Открытые порты: 22 (SSH), 80/443 (HTTP/HTTPS), опционально порт VPN/бастион

## Подготовка сервера
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```
Перелогиньтесь после добавления пользователя в группу docker.

## Клонирование и подготовка
```bash
git clone https://example.com/babushka.git
cd babushka
cp .env.example .env
```

Сгенерируйте секреты:
```bash
openssl rand -hex 32 # NEXTAUTH_SECRET
openssl rand -hex 32 # для паролей/других секретов
```
Заполните `.env` (OAuth, SMTP, бонусы, MinIO, Telegram уведомления).

## Миграции и запуск
```bash
docker compose pull
docker compose build
docker compose up -d
```
Приложение доступно на 443/80, Caddy автоматически выпустит сертификаты Let's Encrypt. Postgres не публикуется наружу.

Для применения миграций при обновлении (выполняется в командной строке web-контейнера):
```bash
docker compose exec web npx prisma migrate deploy
```

## Обновление приложения
```bash
git pull
docker compose build web
docker compose up -d web
```

## Бэкап базы данных
Пример скрипта `scripts/pg-backup.sh`:
```bash
#!/bin/bash
set -euo pipefail
BACKUP_DIR=${1:-/var/backups}
mkdir -p "$BACKUP_DIR"
ts=$(date +"%Y%m%d-%H%M%S")
docker compose exec -T postgres pg_dump -U postgres babushka > "$BACKUP_DIR/babushka-$ts.sql"
```
Сделайте исполняемым и добавьте cron (`crontab -e`):
```
0 3 * * * /bin/bash /path/to/repo/scripts/pg-backup.sh /var/backups
```

## UFW
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80,443/tcp
sudo ufw enable
```

## Примечания
- Для dev окружения MinIO необязателен — изображения можно хранить в `public/uploads`.
- При первом запуске выполните `npm run db:seed` (или `docker compose exec web npm run db:seed`) для создания администратора и демо-данных.
