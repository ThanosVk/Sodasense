import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDatabase {
  static final SqlDatabase instance = SqlDatabase._init();
  static Database? _database;

  SqlDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    //creation of coordinates table
    await db.execute(
        'CREATE TABLE coordinates (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, lat REAL, lng REAL, updated INTEGER)');

    //creation of altitude table
    await db.execute(
        'CREATE TABLE altitude (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, altitude REAL, updated INTEGER)');

    //creation of pressure table
    await db.execute(
        'CREATE TABLE pressure (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, pressure REAL, updated INTEGER)');

    //creation of acceleration table
    await db.execute(
        'CREATE TABLE acceleration (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, x REAL, y REAL, z REAL, updated INTEGER)');

    //creation of gyroscope table
    await db.execute(
        'CREATE TABLE gyroscope (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, x REAL, y REAL, z REAL, updated INTEGER)');

    //creation of magnetometer table
    await db.execute(
        'CREATE TABLE magnetometer (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, x REAL, y REAL, z REAL, updated INTEGER)');

    //creation of proximity table
    await db.execute(
        'CREATE TABLE proximity (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, dist TEXT, updated INTEGER)');

    //creation of daily steps table
    await db.execute(
        'CREATE TABLE daily_steps (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, steps INTEGER, updated INTEGER)');

    //creation of sensors table
    await db.execute(
        'CREATE TABLE sensors (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, pressure REAL, acc_x REAL, acc_y REAL, acc_z REAL,gyro_x REAL, gyro_y REAL, gyro_z REAL,magn_x REAL, magn_y REAL, magn_z REAL, dist TEXT,steps INTEGER, updated INTEGER)');
  }

  Future<List<Map<String, dynamic>>> select_steps_for_current_week() async {
    final db = await instance.database;

    final now = DateTime.now().toUtc();
    final startOfWeek = DateTime.utc(now.year, now.month, now.day - now.weekday + 1);
    final endOfWeek = startOfWeek.add(Duration(days: 6)).subtract(Duration(seconds: 1));

    final result = await db.rawQuery(
      'SELECT date, SUM(steps) as steps FROM daily_steps WHERE date >= ? AND date <= ? GROUP BY date',
      [startOfWeek.millisecondsSinceEpoch, endOfWeek.millisecondsSinceEpoch],
    );

    // Logging fetched data for debugging
    result.forEach((row) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(row['date'] as int, isUtc: true).toLocal();
      int steps = row['steps'] as int;
      print("Database fetched data - Date: ${date.toString()}, Steps: $steps");
    });

    return result;
  }

  Future insert_coor(int date, double lat, double lng, int updated) async {
    final db = await instance.database;

    await db.rawInsert(
        'INSERT INTO coordinates(date, lat, lng, updated) VALUES($date, $lat, $lng, $updated)');
  }

  Future insert_altitude(int date, double altitude, int updated) async {
    final db = await instance.database;

    await db.rawInsert(
        'INSERT INTO altitude(date, altitude, updated) VALUES($date, $altitude, $updated)');
  }

  Future insert_pressure(int date, double pressure, int updated) async {
    final db = await instance.database;

    await db.rawInsert(
        'INSERT INTO pressure(date, pressure, updated) VALUES($date, $pressure, $updated)');
  }

  Future insert_acc(int date, double x, double y, double z, int updated) async {
    final db = await instance.database;

    await db.rawInsert(
        'INSERT INTO acceleration(date, x, y, z, updated) VALUES($date, $x, $y, $z, $updated)');
  }

  Future insert_gyro(
      int date, double x, double y, double z, int updated) async {
    final db = await instance.database;

    await db.rawInsert(
        'INSERT INTO gyroscope(date, x, y, z, updated) VALUES($date, $x, $y, $z, $updated)');
  }

  Future insert_magn(
      int date, double x, double y, double z, int updated) async {
    final db = await instance.database;

    await db.rawInsert(
        'INSERT INTO magnetometer(date, x, y, z, updated) VALUES($date, $x, $y, $z, $updated)');
  }

  Future insert_prox(int date, String dist, int updated) async {
    final db = await instance.database;

    await db.rawInsert(
        'INSERT INTO proximity(date, dist, updated) VALUES($date, $dist, $updated)');
  }

  Future<void> insert_daily_steps(int date, int steps, int updated) async {
    final db = await instance.database;

    await db.rawInsert(
      'INSERT INTO daily_steps(date, steps, updated) VALUES(?, ?, ?)',
      [date, steps, updated],
    );

    print("Inserted steps: $steps on date: $date");
  }

  Future insert_sensors(
      int date,
      double pressure,
      double acc_x,
      double acc_y,
      double acc_z,
      double gyro_x,
      double gyro_y,
      double gyro_z,
      double magn_x,
      double magn_y,
      double magn_z,
      String dist,
      int steps,
      int updated) async {
    final db = await instance.database;

    await db.rawInsert(
        'INSERT INTO sensors(date, pressure, acc_x, acc_y, acc_z,gyro_x, gyro_y, gyro_z,magn_x, magn_y, magn_z, dist,steps, updated) VALUES($date, $pressure,$acc_x,$acc_y,$acc_z,$gyro_x,$gyro_y,$gyro_z,$magn_x,$magn_y,$magn_z,$dist,$steps,$updated)');
  }

  //For selecting the coordinates by number of points and by a specific date and after
  Future select_coor_first(int x, int dt_st) async {
    final db = await instance.database;

    final result = await db.rawQuery(
        'SELECT lat,lng FROM coordinates WHERE date > $dt_st ORDER BY id DESC LIMIT $x');

    // final result = await db.transaction((txn) async {
    //   await txn.rawQuery('SELECT lat,lng FROM coordinates ORDER BY id DESC LIMIT 1000');
    // });

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  //For counting the number of entries in db of the select_coor_first
  Future select_coor_first_count(int x, int dt_st) async {
    final db = await instance.database;

    // final result =  await db.rawQuery('SELECT lat,lng FROM coordinates WHERE date > $dt_st ORDER BY id DESC LIMIT $x');

    // final result = await db.transaction((txn) async {
    //   await txn.rawQuery('SELECT lat,lng FROM coordinates ORDER BY id DESC LIMIT 1000');
    // });

    int? count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM coordinates WHERE date > $dt_st ORDER BY id DESC LIMIT $x'));

    return count;
  }

  //For selecting the coordinates by number of points and by a specific date and after
  Future select_coor_second(int x, int dt_st) async {
    int z = dt_st + 86399000;

    final db = await instance.database;

    final result = await db.rawQuery(
        'SELECT lat,lng FROM coordinates WHERE (date > $dt_st AND date < $z) ORDER BY id DESC LIMIT 2000');

    // final result = await db.transaction((txn) async {
    //   await txn.rawQuery('SELECT lat,lng FROM coordinates ORDER BY id DESC LIMIT 1000');
    // });

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  //For counting the number of entries in db of the select_coor_second
  Future select_coor_second_count(int x, int dt_st) async {
    int z = dt_st + 86399000;

    final db = await instance.database;

    // final result =  await db.rawQuery('SELECT lat,lng FROM coordinates WHERE date > $dt_st ORDER BY id DESC LIMIT $x');

    // final result = await db.transaction((txn) async {
    //   await txn.rawQuery('SELECT lat,lng FROM coordinates ORDER BY id DESC LIMIT 1000');
    // });

    int? count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM coordinates WHERE (date > $dt_st AND date < $z) ORDER BY id DESC LIMIT 2000'));

    return count;
  }

  Future select_altitude() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT altitude FROM altitude');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future select_pressure() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT pressure FROM pressure');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future select_acc() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT x,y,z FROM acceleration');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future select_gyro() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT x,y,z FROM gyroscope');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future select_magn() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT x,y,z FROM magnetometer');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future select_prox() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT dist FROM proximity');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future select_daily_steps() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT steps FROM daily_steps');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future select_sensors() async {
    final db = await instance.database;

    final result = await db.rawQuery(
        'SELECT pressure, acc_x, acc_y, acc_z,gyro_x, gyro_y, gyro_z,magn_x, magn_y, magn_z, dist,steps, updated FROM sensors');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future sum_daily_steps() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT SUM(steps) FROM daily_steps');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));

    return result;
  }

  Future<List<Map<String, dynamic>>> select_total_steps_per_day() async {
    final db = await instance.database;

    // Get the current date and calculate the start of the current week
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1).millisecondsSinceEpoch;
    final endOfWeek = DateTime(now.year, now.month, now.day + (7 - now.weekday)).millisecondsSinceEpoch;

    // Fetch steps data between the start and end of the current week
    final result = await db.rawQuery(
        'SELECT date, SUM(steps) as steps FROM daily_steps WHERE date >= ? AND date <= ? GROUP BY date',
        [startOfWeek, endOfWeek]
    );

    return result;
  }

  // New Method to fetch steps for a specific date range
  Future<List<Map<String, dynamic>>> select_steps_for_date_range(int startOfDay, int endOfDay) async {
    final db = await instance.database;

    final result = await db.rawQuery(
        'SELECT SUM(steps) as steps FROM daily_steps WHERE date >= ? AND date <= ?',
        [startOfDay, endOfDay]
    );

    return result;
  }

  Future select_altitude_unupdated() async {
    final db = await instance.database;

    final result = await db
        .rawQuery('SELECT date,altitude FROM altitude WHERE updated = 0');

    await db.rawUpdate('UPDATE altitude SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future select_pressure_unupdated() async {
    final db = await instance.database;

    final result = await db
        .rawQuery('SELECT date,pressure FROM pressure WHERE updated = 0');

    // await db.rawUpdate('UPDATE pressure SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future select_acc_unupdated() async {
    final db = await instance.database;

    final result = await db
        .rawQuery('SELECT date,x,y,z FROM acceleration WHERE updated = 0');

    // await db.rawUpdate('UPDATE accelaration SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future select_gyro_unupdated() async {
    final db = await instance.database;

    final result =
    await db.rawQuery('SELECT date,x,y,z FROM gyroscope WHERE updated = 0');

    // await db.rawUpdate('UPDATE gyroscope SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future select_magn_unupdated() async {
    final db = await instance.database;

    final result = await db
        .rawQuery('SELECT date,x,y,z FROM magnetometer WHERE updated = 0');

    // await db.rawUpdate('UPDATE magnetometer SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future select_prox_unupdated() async {
    final db = await instance.database;

    final result =
    await db.rawQuery('SELECT date,dist FROM proximity WHERE updated = 0');

    // await db.rawUpdate('UPDATE proximity SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future select_daily_steps_unupdated() async {
    final db = await instance.database;

    final result = await db
        .rawQuery('SELECT date,steps FROM daily_steps WHERE updated = 0');

    await db.rawUpdate('UPDATE daily_steps SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future select_coor_unupdated() async {
    final db = await instance.database;

    final result = await db
        .rawQuery('SELECT date,lat,lng FROM coordinates WHERE updated = 0');

    await db.rawUpdate('UPDATE coordinates SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future select_sensors_unupdated() async {
    final db = await instance.database;

    final result = await db.rawQuery(
        'SELECT date, pressure,acc_x,acc_y,acc_z,gyro_x,gyro_y,gyro_z,magn_x,magn_y,magn_z,dist,steps FROM sensors WHERE updated = 0');

    await db.rawUpdate('UPDATE sensors SET updated = 1 WHERE updated = 0');

    return result;
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}