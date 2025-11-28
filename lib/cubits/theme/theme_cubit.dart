import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  // static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(const ThemeState(isDarkMode: false));

  Future<void> loadTheme() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // final isDark = prefs.getBool(_themeKey) ?? false;
      emit(state.copyWith(isDarkMode: true));
    } catch (e) {
      // print('Error loading theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    // try {
    //   final prefs = await SharedPreferences.getInstance();
    //   final newValue = !state.isDarkMode;
    //   await prefs.setBool(_themeKey, newValue);
    //   emit(state.copyWith(isDarkMode: newValue));
    // } catch (e) {
    //   print('Error toggling theme: $e');
    // }
  }
}
