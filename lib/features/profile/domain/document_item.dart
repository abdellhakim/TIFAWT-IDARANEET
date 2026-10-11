import '../../../shared/models/profile_enums.dart';

/// Papers usually requested by training centres and programmes.
enum DocumentType with Labelled {
  cin('البطاقة الوطنية', "Carte d'identité"),
  residence('شهادة السكنى', 'Certificat de résidence'),
  schoolCertificate('شهادة المستوى', 'Attestation scolaire'),
  birthCertificate('عقد الازدياد', "Extrait d'acte de naissance"),
  photos('تصاور', "Photos d'identité"),
  cv('السيرة الذاتية', 'CV');

  const DocumentType(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

class DocumentItem {
  const DocumentItem(this.type, {this.ready = false});
  final DocumentType type;
  final bool ready;

  Map<String, dynamic> toJson() => {'code': type.name, 'ready': ready};

  factory DocumentItem.fromJson(Map<dynamic, dynamic> json) => DocumentItem(
    enumByName(DocumentType.values, json['code'], DocumentType.cin),
    ready: (json['ready'] as bool?) ?? false,
  );
}
