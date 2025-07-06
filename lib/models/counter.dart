import 'package:flutter/material.dart';

class Counter {
  String name;
  int value;
  Color color;

  Counter({required this.name, this.value = 0, required this.color});

  factory Counter.fromJson(Map<String, dynamic> json) {
    return Counter(
      name: json['name'],
      value: json['value'],
      color: Color(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value, 'color': color.value};
  }
}
