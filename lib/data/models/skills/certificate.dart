class Certificate {
  final int id;
  final String title;
  final List<int> required;
  final String icon;

  Certificate({
    required this.id,
    required this.title,
    required this.required,
    required this.icon,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'],
      title: json['title'],
      required: json['required'],
      icon: json['icon'],
    );
  }
}
