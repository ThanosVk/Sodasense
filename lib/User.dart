import 'package:hive/hive.dart';

//part 'User.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  late String username;

  @HiveField(1)
  late String email;

  @HiveField(2)
  late List<List> steps;

  @HiveField(3)
  late List<List> yesterday_steps;

  @HiveField(4)
  late List<List> daily_steps;

  @HiveField(5)
  late int target_steps;

  @HiveField(6)
  late List<List> daily_km;

  @HiveField(7)
  late int height;

  @HiveField(8)
  late String gender;

  @HiveField(9)
  late double steps_length;

  @HiveField(10)
  late List<List> coordinates;

  @HiveField(11)
  late List<List> altitude;

  @HiveField(12)
  late List<List> total_steps;

  @HiveField(13)
  late List<List> pressure;

  @HiveField(14)
  late List<List> acceleration;

  @HiveField(15)
  late List<List> gyroscope;

  @HiveField(16)
  late List<List> magnetometer;

  @HiveField(17)
  late List<List> proximity;

  @HiveField(18)
  late bool theme;
}
