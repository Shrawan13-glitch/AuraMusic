class UpdateModel {
  final String latestVersion;
  final String downloadUrl;
  final List<String> notes;

  UpdateModel({
    required this.latestVersion,
    required this.downloadUrl,
    required this.notes,
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    final update = json['update'];
    return UpdateModel(
      latestVersion: update['latestVersion'],
      downloadUrl: update['downloadUrl'],
      notes: List<String>.from(update['notes']),
    );
  }
}
