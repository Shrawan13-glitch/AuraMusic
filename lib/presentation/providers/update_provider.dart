import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/update_model.dart';
import '../../data/services/update_service.dart';

final updateServiceProvider = Provider((ref) => UpdateService());

final updateCheckProvider = FutureProvider<UpdateModel?>((ref) async {
  final service = ref.read(updateServiceProvider);
  return await service.checkForUpdate();
});
