/// Словарь для маппинга латинских имён файлов на русские названия для UI.
/// Решает проблему с кириллицей в путях при сборке на GitHub Actions (Windows).
class AssetNames {
  AssetNames._();

  // ==========================================
  // КАРТИНКИ (Images)
  // ==========================================
  static const Map<String, String> imageToDisplayName = {
    'Bekas.jpg': 'Бекас',
    'belaya_kuropatka.jpg': 'Белая куропатка',
    'belohvostyj-orlan.jpg': 'Орлан-белохвост',
    'belokrylaya_krachka.jpg': 'Белокрылая крачка',
    'belyy_aist.jpg': 'Белый аист',
    'bolotnaya_sova.jpeg': 'Болотная сова',
    'bolshaya_belaya_tsaplya.jpg': 'Большая белая цапля',
    'bolshaya_sinitsa.jpg': 'Большая синица',
    'bolshaya_vyp.jpg': 'Большая выпь',
    'chechevitsa.jpg': 'Чечевица',
    'cheglok.jpg': 'Чеглок',
    'chernaya_krachka.jpg': 'Черная крачка',
    'chernozobaya_gagarka.jpeg': 'Чернозобая гагара',
    'chibis.jpg': 'Чибис',
    'chizh.jpeg': 'Чиж',
    'chomga.jpg': 'Чомга',
    'chyornyy_aist.jpeg': 'Чёрный аист',
    'chyornyy_korshun.jpg': 'Чёрный коршун',
    'chyornyy_strizh.jpg': 'Чёрный стриж',
    'dlinnohvostaya_neyasyt.jpeg': 'Длиннохвостая неясыть',
    'dlinnohvostyy_pomornik.jpeg': 'Длиннохвостый поморник',
    'filin.jpeg': 'Филин',
    'galka.jpg': 'Галка',
    'gluhar.jpg': 'Глухарь',
    'grach.jpg': 'Грач',
    'ivolga.jpg': 'Иволга',
    'kanyuk.jpg': 'Канюк',
    'klintuh.jpg': 'Клинтух',
    'klusha.jpeg': 'Клуша',
    'kolchataya_goritsa.jpg': 'Кольчатая горлица',
    'korolyok_zheltogolovyy.jpg': 'Королёк желтоголовый',
    'korostel.jpg': 'Коростель',
    'korotkohvostyy_pomornik.jpeg': 'Короткохвостый поморник',
    'kozodoy_obyknovennyy.jpg': 'Козодой обыкновенный',
    'krapivnik.jpeg': 'Крапивник',
    'krasnozobaya_gagarka.jpeg': 'Краснозобая гагара',
    'kvakva.jpeg': 'Кваква',
    'lesnoy_konyok.jpg': 'Лесной конёк',
    'lugovoy_chekan_samets.jpg': 'Луговой чекан (самец)',
    'lugovoy_chekan_samka_.jpg': 'Луговой чекан (самка)',
    'lysuha.jpg': 'Лысуха',
    'lyurik.jpg': 'Люрик',
    'malaya_krachka.jpeg': 'Малая крачка',
    'malaya_poganka.jpg': 'Малая поганка',
    'malaya_vyp.jpg': 'Малая выпь',
    'malyy_zuyok.jpg': 'Малый зуёк',
    'obyknovennaya_kukushka.jpg': 'Обыкновенная кукушка',
    'obyknovennaya_pustelga.jpg': 'Обыкновенная пустельга',
    'obyknovennyy_sverchok.jpg': 'Обыкновенный сверчок',
    'ovsyanka.jpg': 'Овсянка',
    'ozyornaya_chayka.jpeg': 'Озёрная чайка',
    'ozyornaya_chayka.jpg': 'Озёрная чайка',
    'penochka-tenkovka.jpg': 'Пеночка-теньковка',
    'penochka_treshchotka.jpg': 'Пеночка-трещотка',
    'penochka_vesnichka.jpg': 'Пеночка-весничка',
    'perepel.jpg': 'Перепел',
    'pevchiy_drozd.jpeg': 'Певчий дрозд',
    'polevoy_konyok.jpg': 'Полевой конёк',
    'popolzen.jpeg': 'Поползень',
    'rechnaya_krachka.jpg': 'Речная крачка',
    'rechnoy_sverchok.jpg': 'Речной сверчок',
    'ryabchik.jpg': 'Рябчик',
    'sapsan.jpg': 'Сапсан',
    'seraya_kuropatka.jpg': 'Серая куропатка',
    'seraya_neyasyt.jpg': 'Серая неясыть',
    'seraya-tsaplya.jpg': 'Серая цапля',
    'serebristaya_chayka.jpeg': 'Серебристая чайка',
    'serebristaya_chayka.jpg': 'Серебристая чайка',
    'shchegol.jpg': 'Щегол',
    'sizaya_chayka.jpg': 'Сизая чайка',
    'sizovoronka.jpg': 'Сизоворонка',
    'sizyy_golub.png': 'Сизый голубь',
    'skvorets.jpg': 'Скворец',
    'snegir.jpg': 'Снегирь',
    'solovey.jpg': 'Соловей',
    'splyushka.jpeg': 'Сплюшка',
    'sviristel.jpg': 'Свиристель',
    'teterev.png': 'Тетерев',
    'udod.jpg': 'Удод',
    'ushastaya_sova.jpeg': 'Ушастая сова',
    'valdshnep.png': 'Вальдшнеп',
    'varakushka.jpg': 'Варакушка',
    'voron.jpg': 'Ворон',
    'vyahir.jpeg': 'Вяхирь',
    'zaryanka.jpeg': 'Зарянка',
    'zhavoronok_polevoy.jpg': 'Жаворонок полевой',
    'zimorodok.jpg': 'Зимородок',
    'zyablik.jpg': 'Зяблик',
  };

  // ==========================================
  // АУДИО (Audio)
  // ==========================================
  static const Map<String, String> audioToDisplayName = {
    '4._Golosa_ptic_-_Konek_lesnoj_(SkySound.cc).mp3': 'Лесной конёк',
    'bekas.mp3': 'Бекас',
    'belokrylaya_krachka.mp3': 'Белокрылая крачка',
    'bolshaya_vyp.mp3': 'Большая выпь',
    'cheglok.mp3': 'Чеглок',
    'chibis.mp3': 'Чибис',
    'chirikanie_perepela.mp3': 'Перепел',
    'chomga-4.mp3': 'Чомга',
    'chyornaya_krachka.mp3': 'Чёрная крачка',
    'chyornyy_aist.mp3': 'Чёрный аист',
    'chyornyy_korshun.mp3': 'Чёрный коршун',
    'Dlinnohvo_staya_uralskaya_neyasyt_-_Ural_Owl_Strix_uralensis_(SkySound.cc).mp3': 'Длиннохвостая неясыть',
    'dlinnohvostyy_pomornik.mp3': 'Длиннохвостый поморник',
    'dlinnohvostyy_pomornik_nervnyy.mp3': 'Длиннохвостый поморник',
    'filin._evropa_aziya_amerika._golosa_ptits.mp3': 'Филин',
    'gagara-krasnozobaya02.mp3': 'Краснозобая гагара',
    'Galka.mp3': 'Галка',
    'Golosa_ptic_Evropy_-_Gagara_chernozobaya_(Rilds.com).mp3': 'Чернозобая гагара',
    'Golosa_ptic_-_Lugovoj_chekan_(SkySound.cc).mp3': 'Луговой чекан',
    'Golosa_ptic_-_Seraya_neyasyt_Strix_aluco_(SkySound.cc).mp3': 'Серая неясыть',
    'Golosa_ptic_-_Zaryanka_Malinovka_(SkySound.cc).mp3': 'Зарянка',
    '-golosa-ptits-bolshaya-belaya-tsaplya-golosa-ptits.mp3': 'Большая белая цапля',
    'grach-1.mp3': 'Грач',
    'kak_poyot_krapivnik_audio_troglodytes_troglodytes.mp3': 'Крапивник',
    'kanyuk.mp3': 'Канюк',
    'Klintuh.mp3': 'Клинтух',
    'klusha._golosa_ptits.mp3': 'Клуша',
    'korostel.mp3': 'Коростель',
    'korotkohvostyy_pomornik.mp3': 'Короткохвостый поморник',
    'krachka-rechnaya02.mp3': 'Речная крачка',
    'krik-perepela.mp3': 'Перепел (крик)',
    'Kuropatka_seraya_-_Kuropatka_seraya_(SkySound.cc).mp3': 'Серая куропатка',
    'lysuha.mp3': 'Лысуха',
    'lyurik._golosa_ptits.mp3': 'Люрик',
    'malaya_poganka.mp3': 'Малая поганка',
    'malaya_vyp.mp3': 'Малая выпь',
    'obyknovennaya_pustelga.mp3': 'Обыкновенная пустельга',
    'orlan-belohvost.mp3': 'Орлан-белохвост',
    'Ovsyanka_-_Penie_ptic_(TheMP3.Info).mp3': 'Овсянка',
    'ozyornaya_chayka.mp3': 'Озёрная чайка',
    'ozyornaya_chayka_1.mp3': 'Озёрная чайка',
    'Penie_ptic_-_bolotnaya_sova_(SkySound.cc).mp3': 'Болотная сова',
    'Penie_ptic_-_CHechevica_(SkySound.cc).mp3': 'Чечевица',
    'Penie_ptic_-_ZHeltogolovyj_korolek_(SkySound.cc).mp3': 'Королёк желтоголовый',
    'penochka-3-vesnichka.mp3': 'Пеночка-весничка',
    'penochka-tenkovka.mp3': 'Пеночка-теньковка',
    'penochka-treshchotka.mp3': 'Пеночка-трещотка',
    'pevchiy_drozd.mp3': 'Певчий дрозд',
    'pevchiy_drozd_1.mp3': 'Певчий дрозд',
    'polevoy_konyok.mp3': 'Полевой конёк',
    'popolzen.mp3': 'Поползень',
    'Pticy_Evropy_-_Golub_sizyj_(Bib.fm).mp3': 'Сизый голубь',
    'Pticy_Evropy_-_Kuropatka_belaya_(SkySound.cc).mp3': 'Белая куропатка',
    'Pticy_Evropy_-_Kvakva_(SkySound.cc).mp3': 'Кваква',
    'Rechnoj_sverchok_-_Rechnoj_sverchok_(SkySound.cc).mp3': 'Речной сверчок',
    'Ryabchik.mp3': 'Рябчик',
    'samets_gluharya.mp3': 'Глухарь (самец)',
    'samka_gluharya.mp3': 'Глухарь (самка)',
    'sapsan_falco_peregrinus_.mp3': 'Сапсан',
    'seraya_tsaplya.mp3': 'Серая цапля',
    '-serebristaya-chayka-golos-1.mp3': 'Серебристая чайка',
    'shchegol.mp3': 'Щегол',
    'sizaya_chayka.mp3': 'Сизая чайка',
    'sizovoronka.mp3': 'Сизоворонка',
    'sizovoronka_1.mp3': 'Сизоворонка',
    'solovey.mp3': 'Соловей',
    'Sova_splyushka_-_Otus_scops_(SkySound.cc).mp3': 'Сплюшка',
    'sverchok._golosa_ptits.mp3': 'Обыкновенный сверчок',
    'sviristel.mp3': 'Свиристель',
    'teterev_lyrurus_tetrix_.mp3': 'Тетерев',
    'udod-1.mp3': 'Удод',
    'Ushastaya_sova._-_Uhane._(SkySound.cc).mp3': 'Ушастая сова',
    'validshnep-2-samka.mp3': 'Вальдшнеп (самка)',
    'validshnep-5.mp3': 'Вальдшнеп',
    'varakushka._golosa_ptits.mp3': 'Варакушка',
    'vjahir-vorkuet.mp3': 'Вяхирь',
    'Vorona_seraya_Corvus_cornix_-_krik_vorony_(SkySound.cc).mp3': 'Серая ворона',
    'voron.mp3': 'Ворон',
    'zhavoronok_polevoy.mp3': 'Жаворонок полевой',
    'zimorodok.mp3': 'Зимородок',
    'zuek-malye02.mp3': 'Малый зуёк',
    'z_uki-prirody-sk_orec.mp3': 'Скворец',
    'zvuk-aista.mp3': 'Белый аист',
    '-zvuk-gluhoy-kukushki.mp3': 'Глухая кукушка',
    'zvuki-chernogo-strizha.mp3': 'Чёрный стриж',
    'zvuki-penija-gorlicy.mp3': 'Кольчатая горлица',
    'zvuki-prirody-bol-shaya-sinica.mp3': 'Большая синица',
    'Zvuki_prirody_-_Penie_ptic_-_Snegir_(SkySound.cc).mp3': 'Снегирь',
    'zvuk-kozodoja.mp3': 'Обыкновенный козодой',
    'zvuk-kukushki.mp3': 'Обыкновенная кукушка',
  };

  // ==========================================
  // МЕТОДЫ ПОИСКА
  // ==========================================

  /// Получить русское название картинки по имени файла
  static String getImageDisplayName(String fileName) {
    final name = fileName.split('/').last;
    return imageToDisplayName[name] ?? name.replaceAll(RegExp(r'[_\-]'), ' ');
  }

  /// Получить русское название аудио по имени файла
  static String getAudioDisplayName(String fileName) {
    final name = fileName.split('/').last;
    return audioToDisplayName[name] ?? name.replaceAll(RegExp(r'[_\-]'), ' ');
  }

  /// Получить имя файла картинки по русскому названию (обратный поиск)
  static String? getImageFileNameByDisplayName(String displayName) {
    for (var entry in imageToDisplayName.entries) {
      if (entry.value.toLowerCase() == displayName.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  /// Получить имя файла аудио по русскому названию
  static String? getAudioFileNameByDisplayName(String displayName) {
    for (var entry in audioToDisplayName.entries) {
      if (entry.value.toLowerCase() == displayName.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }
}