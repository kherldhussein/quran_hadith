import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_hadith/controller/base_controller.dart';

class HomeController extends BaseController {
  static HomeController get to => Get.find();
  final searchFocusNode = FocusNode();
}
