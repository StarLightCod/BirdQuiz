#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

print_header "🚀 Bird Quiz - Сборка для всех платформ"

if ! command -v flutter &> /dev/null; then
    print_error "Flutter не найден."
    exit 1
fi

print_success "Flutter найден: $(flutter --version | head -n 1)"

# Очистка и установка зависимостей
print_header "🧹 Очистка проекта"
flutter clean && flutter pub get
print_success "Проект очищен"

# Генерация иконок (исправленная команда)
print_header "🎨 Генерация иконок приложения"
if dart run flutter_launcher_icons; then
    print_success "Иконки сгенерированы"
else
    print_warning "Не удалось сгенерировать иконки. Проверьте настройки в pubspec.yaml"
fi

# Создание директории для результатов
BUILD_DIR="build_outputs"
mkdir -p "$BUILD_DIR"

# ============================================
# LINUX BUILD
# ============================================
print_header "🐧 Сборка для Linux"

if flutter build linux --release; then
    print_success "Linux сборка завершена успешно"
    
    LINUX_OUTPUT="$BUILD_DIR/linux"
    mkdir -p "$LINUX_OUTPUT"
    cp -r build/linux/x64/release/bundle/* "$LINUX_OUTPUT/"
    
    # Создание .desktop файла
    cat > "$LINUX_OUTPUT/bird-quiz.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Bird Quiz
Comment=Викторина по определению птиц
Exec=$LINUX_OUTPUT/bird_quiz
Icon=bird-quiz
Categories=Education;Game;
Terminal=false
EOF
    print_success ".desktop файл создан"
    
    # Создание DEB пакета
    print_header "📦 Создание DEB пакета"
    DEB_DIR=$(mktemp -d)
    mkdir -p "$DEB_DIR"/{DEBIAN,opt/bird-quiz,usr/share/applications,usr/share/pixmaps}
    
    cp -r "$LINUX_OUTPUT"/* "$DEB_DIR/opt/bird-quiz/"
    
    cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: bird-quiz
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Your Name <your.email@example.com>
Description: Bird Quiz - Викторина по определению птиц
 A quiz application for learning bird species
EOF
    
    cp "$LINUX_OUTPUT/bird-quiz.desktop" "$DEB_DIR/usr/share/applications/"
    if [ -f assets/images/icon.png ]; then
        cp assets/images/icon.png "$DEB_DIR/usr/share/pixmaps/bird-quiz.png"
    fi
    
    cd "$DEB_DIR"
    dpkg-deb --build . "$OLDPWD/$BUILD_DIR/bird-quiz_1.0.0_amd64.deb"
    cd - > /dev/null
    rm -rf "$DEB_DIR"
    
    if [ -f "$BUILD_DIR/bird-quiz_1.0.0_amd64.deb" ]; then
        print_success "DEB пакет создан: $BUILD_DIR/bird-quiz_1.0.0_amd64.deb"
    else
        print_error "Не удалось создать DEB пакет"
    fi
else
    print_error "Ошибка при сборке Linux. Убедитесь, что установлены зависимости:"
    echo "sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev"
fi

# ============================================
# ANDROID BUILD
# ============================================
print_header "📱 Сборка для Android"

if [ -d "$ANDROID_HOME" ] || [ -d "$HOME/Android/Sdk" ]; then
    if flutter build apk --release --split-per-abi; then
        print_success "Android APK собраны"
        
        ANDROID_OUTPUT="$BUILD_DIR/android"
        mkdir -p "$ANDROID_OUTPUT"
        cp build/app/outputs/flutter-apk/*.apk "$ANDROID_OUTPUT/"
        print_success "APK скопированы в $ANDROID_OUTPUT"
        ls -lh "$ANDROID_OUTPUT"/*.apk
    else
        print_error "Ошибка при сборке Android"
    fi
else
    print_warning "Android SDK не найден. Пропускаем."
fi

# ============================================
# WEB BUILD
# ============================================
print_header "🌐 Сборка для Web"

if flutter build web --release; then
    print_success "Web сборка завершена"
    
    WEB_OUTPUT="$BUILD_DIR/web"
    mkdir -p "$WEB_OUTPUT"
    cp -r build/web/* "$WEB_OUTPUT/"
    
    cd "$WEB_OUTPUT"
    zip -r "../bird-quiz-web.zip" .
    cd - > /dev/null
    print_success "Web архив: $BUILD_DIR/bird-quiz-web.zip"
else
    print_error "Ошибка при сборке Web"
fi

# ============================================
# ИТОГИ
# ============================================
print_header "📊 Итоги сборки"

echo -e "\n${GREEN}Собранные файлы:${NC}"
find "$BUILD_DIR" -type f \( -name "*.deb" -o -name "*.apk" -o -name "*.zip" -o -name "bird_quiz" \) -exec ls -lh {} \;

print_header "✅ Сборка завершена!"

echo -e "\n${YELLOW}Результаты в папке: $BUILD_DIR/${NC}"
echo -e "\n${GREEN}Для установки на Linux:${NC}"
echo "  deb: sudo dpkg -i $BUILD_DIR/bird-quiz_1.0.0_amd64.deb"
echo "  Direct: $BUILD_DIR/linux/bird_quiz"
echo -e "\n${GREEN}Для Android:${NC}"
echo "  Установите APK: $BUILD_DIR/android/"
echo -e "\n${GREEN}Для Web:${NC}"
echo "  Загрузите $BUILD_DIR/bird-quiz-web.zip или содержимое $BUILD_DIR/web/ на хостинг"