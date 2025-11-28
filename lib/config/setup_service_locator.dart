import 'package:get_it/get_it.dart';
import 'package:kstudio/cubits/home/home_cubit.dart';
import 'package:kstudio/cubits/theme/theme_cubit.dart';
import 'package:kstudio/services/firestore_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerSingleton<FirestoreService>(FirestoreService());

  // Cubits
  getIt.registerSingleton<ThemeCubit>(ThemeCubit());
  getIt.registerSingleton<HomeCubit>(HomeCubit(getIt<FirestoreService>()));
}
