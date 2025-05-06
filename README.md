# Proviante Notes

## Описание

Простое кроссплатформенное приложение для создания и управления заметками, созданное с помощью Flutter.

## Основные возможности (Features)

*   **Создание, редактирование и удаление заметок:** Базовый функционал для работы с заметками.
*   **Темная тема:** Поддержка светлой и темной тем оформления.
*   **Поиск по заметкам:** Быстрый поиск заметок по их содержимому или заголовку.
*   **Сортировка:** Возможность сортировки заметок (например, по дате создания или изменения).
*   **Кроссплатформенность:** Поддержка Android, iOS, Web, Windows и macOS.
*   **Тесты:** Наличие юнит-тестов, виджет-тестов и golden-тестов для обеспечения качества кода.
*   **Сплэш-скрин:** Кастомный экран загрузки при запуске приложения.
*   **Кастомная иконка приложения:** Уникальная иконка приложения для всех платформ.
*   **Кастомные анимации:** Плавные анимации переходов между экранами и анимированные элементы интерфейса (кнопки, возможно, списки).
*   **Локализация:** Поддержка нескольких языков (английский, русский).

## Скриншоты (Screenshots)

*(Рекомендуется добавить сюда скриншоты приложения, включая темную тему)*

```
![IMG_7022](https://github.com/user-attachments/assets/c49c4d4e-681b-4feb-9959-3b16f122527e)
![IMG_7023](https://github.com/user-attachments/assets/761e90ff-0ffb-4633-b034-9f8cbfd854c1)
![IMG_7024](https://github.com/user-attachments/assets/b3af1c79-e7c4-43a7-b58d-cfa447bcc1ae)
![IMG_7025](https://github.com/user-attachments/assets/2ed2674d-9367-4cb8-98b7-0fe47bfc97ad)
![IMG_7026](https://github.com/user-attachments/assets/08817e22-122b-4043-be18-7fd4ca5094f7)
![IMG_7027](https://github.com/user-attachments/assets/7410aee5-dccd-4012-a370-b56406a9fc69)
![IMG_7028](https://github.com/user-attachments/assets/417e45bd-26ef-40c2-b2a3-da39dfafac02)
![IMG_7029](https://github.com/user-attachments/assets/8fec2238-836b-44dd-b777-d715ab6b78ad)
![IMG_7030](https://github.com/user-attachments/assets/8f301b35-a015-41ee-b76a-a073571243c6)
![IMG_7031](https://github.com/user-attachments/assets/b7bddd82-a3bf-4fa0-be3a-10286ea16058)
...
```

## Технологии (Technologies Used)

*   **Фреймворк:** Flutter
*   **Язык:** Dart
*   **Управление состоянием:** flutter_bloc
*   **База данных:** Isar (локальная NoSQL БД)
*   **Внедрение зависимостей (DI):** get_it / injectable
*   **Локализация:** easy_localization
*   **Анимации:** flutter_animate, animations
*   **Тестирование:** flutter_test, mockito, golden_toolkit
*   **Генерация иконок/сплэша:** flutter_launcher_icons, flutter_native_splash
*   **Шрифты:** google_fonts
*   **Прочее:** equatable, path_provider, intl, shared_preferences

## Архитектура (Architecture)

Проект придерживается принципов **Clean Architecture**, разделяя логику на слои:

*   **Data:** Источники данных (локальная БД Isar), репозитории.
*   **Domain:** Сущности (Entities), интерфейсы репозиториев, Use Cases (хотя в данном проекте могут быть неявно выражены в BLoC).
*   **Presentation:** UI (экраны, виджеты), управление состоянием (BLoC).

Внедрение зависимостей осуществляется с помощью `get_it` и `injectable`. Управление состоянием построено на `flutter_bloc`.

## Запуск проекта (Getting Started / Installation)

1.  **Убедитесь, что у вас установлен Flutter SDK.** Инструкции по установке: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2.  **Клонируйте репозиторий:**
    ```bash
    git clone <URL репозитория>
    cd proviante_notes
    ```
3.  **Установите зависимости:**
    ```bash
    flutter pub get
    ```
4.  **Запустите генерацию кода** (необходимо для Isar и Injectable):
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
    *Примечание: Эту команду нужно выполнять после изменений в моделях Isar или конфигурации Injectable.*
5.  **Запустите приложение:**
    ```bash
    flutter run
    ```
    Выберите целевое устройство (эмулятор, реальное устройство или десктоп/веб).

## Тестирование (Running Tests)

Для запуска всех тестов выполните команду:

```bash
flutter test
```

Для обновления golden-файлов (если виджет-тесты используют `golden_toolkit`):

```bash
flutter test --update-goldens
