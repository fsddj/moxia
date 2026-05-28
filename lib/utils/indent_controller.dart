import 'package:flutter/material.dart';

class IndentController extends TextEditingController {
  IndentController({String? text}) : super(text: text);

  static String addIndents(String text) {
    if (text.isEmpty) return text;
    final paragraphs = text.split('\n');
    return paragraphs.map((p) => '　　$p').join('\n');
  }

  static String stripIndents(String text) {
    return text.replaceAll(RegExp(r'^　　', multiLine: true), '');
  }
}
