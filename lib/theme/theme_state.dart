import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class ThemeState extends GetxController {
  ThemeData themedata = ThemeData.light();
  bool isDarkMode = false;

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    isDarkMode = box.read('isDarkMode') ?? false;
  }

  void updateTheme(ThemeData themedata) {
    this.themedata = themedata;
    update();
    box.write('isDarkMode', isDarkMode);
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    updateTheme(isDarkMode ? ThemeData.dark() : ThemeData.light());
    box.write('isDarkMode', isDarkMode);
  }
}
