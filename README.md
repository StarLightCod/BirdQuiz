# 🐦 Bird Quiz — Викторина по определению птиц

[![Build Windows](https://github.com/StarLightCod/BirdQuiz/actions/workflows/build-windows.yml/badge.svg)](https://github.com/StarLightCod/BirdQuiz/actions/workflows/build-windows.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-orange)]()

Интерактивное приложение для изучения птиц России. Помогает готовиться к **биологическим олимпиадам**, **ЕГЭ по биологии** и **вступительным экзаменам в вузы** (биофак, экология, зоология).

![Скриншот приложения](screenshots/main.png)

##  Возможности

- 📚 **Каталог из 789 видов птиц России** с русскими и латинскими названиями
-  **Голоса птиц** из базы Xeno-canto (предпрослушивание перед скачиванием)
- 📷 **Фотографии** из iNaturalist с зумом и навигацией
- 🎯 **Три режима викторины**: по фото, по звуку, комплексный
-  **4 уровня сложности**: от простого до эксперта
- 🛠️ **Конструктор карточек** — загружайте свои фото и звуки
- 💻 **Кроссплатформенность**: Linux и Windows
- 🌙 **Тёмная тема** и настройка интерфейса

##  Для кого это приложение?

- 🏆 **Школьники**, готовящиеся к олимпиадам по биологии и экологии
- 🎓 **Абитуриенты** биофаков, экологических и зоологических специальностей
- ‍🏫 **Преподаватели** биологии для использования на уроках
- 🐦 **Орнитологи-любители** и натуралисты

## 📥 Установка

### Windows

1. Скачайте архив **BirdQuiz-Windows.zip** из раздела [Releases](https://github.com/StarLightCod/BirdQuiz/releases) или со страницы [Actions](https://github.com/StarLightCod/BirdQuiz/actions)
2. Распакуйте архив в любую папку (например, `C:\Programs\BirdQuiz\`)
3. Запустите файл **bird_quiz.exe**

> ⚠️ **Важно:** Передавайте и запускайте **всю папку целиком**, а не только exe-файл. Приложение требует папку `data` для работы.

### Linux

**Для Debian/Ubuntu/Mint:**
```bash
# Скачайте .deb пакет из раздела Releases
sudo dpkg -i bird-quiz_1.0.0_amd64.deb
