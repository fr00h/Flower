# Цветочный магазин

Итоговый проект по УП.04.01. Клиент на Flutter Web, сервер PocketBase.

## Запуск

1. Скачать PocketBase (https://pocketbase.io/docs/) и положить `pocketbase.exe` в папку `pocketbase`.

2. Запустить сервер:

```
cd pocketbase
pocketbase.exe serve --http 127.0.0.1:8090
```

3. Один раз создать администратора, коллекции и тестовые данные (Node.js 18+):

```
cd pocketbase
pocketbase.exe superuser upsert admin@flowers.ru flowers12345
node setup.mjs
```

Схему можно загрузить и без скрипта: `pocketbase/pb_schema.json`, Settings -> Import collections.

4. Запустить клиент:

```
cd flower_shop
flutter pub get
flutter run -d chrome --web-port 5000 --dart-define=API_URL=http://127.0.0.1:8090
```

## Учётные записи

Пароль у всех: flowers12345

- admin@flowers.ru - администратор
- florist@flowers.ru - флорист
- customer@flowers.ru - покупатель

## Тесты

```
cd flower_shop
flutter analyze
flutter test
```
