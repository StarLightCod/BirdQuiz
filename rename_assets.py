#!/usr/bin/env python3
import os
import re
from pathlib import Path

def transliterate(text):
    """Транслитерация кириллицы в латиницу"""
    mapping = {
        'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
        'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
        'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
        'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
        'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
        'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D', 'Е': 'E', 'Ё': 'Yo',
        'Ж': 'Zh', 'З': 'Z', 'И': 'I', 'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M',
        'Н': 'N', 'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U',
        'Ф': 'F', 'Х': 'H', 'Ц': 'Ts', 'Ч': 'Ch', 'Ш': 'Sh', 'Щ': 'Shch',
        'Ъ': '', 'Ы': 'Y', 'Ь': '', 'Э': 'E', 'Ю': 'Yu', 'Я': 'Ya'
    }
    
    result = ''.join(mapping.get(c, c) for c in text)
    # Заменяем пробелы на дефисы, убираем спецсимволы
    result = re.sub(r'[^a-zA-Z0-9._-]', '_', result)
    result = re.sub(r'_+', '_', result)
    return result.lower()

def rename_files_in_dir(directory):
    for filepath in Path(directory).rglob('*'):
        if filepath.is_file():
            filename = filepath.name
            if any(ord(c) > 127 for c in filename):  # Есть кириллица
                name, ext = os.path.splitext(filename)
                new_name = transliterate(name) + ext
                new_path = filepath.parent / new_name
                
                if filepath != new_path:
                    print(f"Renaming: {filename} -> {new_name}")
                    filepath.rename(new_path)

# Использование
rename_files_in_dir('assets/images')
rename_files_in_dir('assets/audio')
print("Done!")
