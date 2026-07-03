class BirdSpecies {
  final String order;
  final String family;
  final String russianName;
  final String latinName;
  final String englishName;
  final String status;
  final String iucnStatus;
  final String redBookRussia;

  BirdSpecies({
    required this.order,
    required this.family,
    required this.russianName,
    required this.latinName,
    required this.englishName,
    this.status = '',
    this.iucnStatus = '',
    this.redBookRussia = '',
  });

  factory BirdSpecies.fromJson(Map<String, dynamic> json) {
    return BirdSpecies(
      order: json['order'] ?? '',
      family: json['family'] ?? '',
      russianName: json['russianName'] ?? '',
      latinName: json['latinName'] ?? '',
      englishName: json['englishName'] ?? '',
      status: json['status'] ?? '',
      iucnStatus: json['iucnStatus'] ?? '',
      redBookRussia: json['redBookRussia'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'family': family,
      'russianName': russianName,
      'latinName': latinName,
      'englishName': englishName,
      'status': status,
      'iucnStatus': iucnStatus,
      'redBookRussia': redBookRussia,
    };
  }

  String get shortLatinName {
    final parts = latinName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return latinName;
  }

  bool get hasStatus => status.isNotEmpty && status != '-';
  bool get isRedBook => redBookRussia.isNotEmpty && redBookRussia != '-';
  bool get hasIucnStatus => iucnStatus.isNotEmpty && iucnStatus != '-';
}