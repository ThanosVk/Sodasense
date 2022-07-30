import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class SqlDatabase{

  static final SqlDatabase instance = SqlDatabase._init();

  static Database? _database;

  SqlDatabase._init();


  //Database database = await openDatabase(path,version: 1,onCreate: _createDB);

  Future<Database> get database async{
    if(_database != null) return _database!;


    _database = await  _initDB('db.db');
    return _database!;
  }

  Future<Database> _initDB(String  filePath) async{

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);

  }

  Future _createDB(Database db, int version) async {

    //creation of coordinates table
    await db.execute(
    'CREATE TABLE coordinates (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, lat REAL, lng REAL, updated INTEGER)'
    );

    //creation of altitude table
    await db.execute(
        'CREATE TABLE altitude (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, altitude REAL, updated INTEGER)'
    );

    //creation of pressure table
    await db.execute(
        'CREATE TABLE pressure (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, pressure REAL, updated INTEGER)'
    );

    //creation of acceleration table
    await db.execute(
        'CREATE TABLE acceleration (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, x REAL, y REAL, z REAL, updated INTEGER)'
    );

    //creation of gyroscope table
    await db.execute(
        'CREATE TABLE gyroscope (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, x REAL, y REAL, z REAL, updated INTEGER)'
    );

    //creation of magnetometer table
    await db.execute(
        'CREATE TABLE magnetometer (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, x REAL, y REAL, z REAL, updated INTEGER)'
    );

    //creation of proximity table
    await db.execute(
        'CREATE TABLE proximity (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, dist TEXT, updated INTEGER)'
    );

    //creation of daily steps table
    await db.execute(
        'CREATE TABLE daily_steps (id INTEGER PRIMARY KEY AUTOINCREMENT, date INTEGER, steps INTEGER, updated INTEGER)'
    );

  }

  Future insert_coor(int date, double lat, double lng, int updated) async{
    final db = await instance.database;

    await db.rawInsert('INSERT INTO coordinates(date, lat, lng, updated) VALUES($date, $lat, $lng, $updated)');

  }

  Future insert_altitude(int date, double altitude, int updated) async{
    final db = await instance.database;

    await db.rawInsert('INSERT INTO altitude(date, altitude, updated) VALUES($date, $altitude, $updated)');

  }

  Future insert_pressure(int date, double pressure, int updated) async{
    final db = await instance.database;

    await db.rawInsert('INSERT INTO pressure(date, pressure, updated) VALUES($date, $pressure, $updated)');

  }

  Future insert_acc(int date, double x, double y, double z, int updated) async{
    final db = await instance.database;

    await db.rawInsert('INSERT INTO acceleration(date, x, y, z, updated) VALUES($date, $x, $y, $z, $updated)');

  }

  Future insert_gyro(int date, double x, double y, double z, int updated) async{
    final db = await instance.database;

    await db.rawInsert('INSERT INTO gyroscope(date, x, y, z, updated) VALUES($date, $x, $y, $z, $updated)');

  }

  Future insert_magn(int date, double x, double y, double z, int updated) async{
    final db = await instance.database;

    await db.rawInsert('INSERT INTO magnetometer(date, x, y, z, updated) VALUES($date, $x, $y, $z, $updated)');

  }

  Future insert_prox(int date, String dist, int updated) async{
    final db = await instance.database;
    
    await db.rawInsert('INSERT INTO proximity(date, dist, updated) VALUES($date, $dist, $updated)');

  }

  Future insert_daily_steps(int date, int steps, int updated) async{
    final db = await instance.database;

    await db.rawInsert('INSERT INTO daily_steps(date, steps, updated) VALUES($date, $steps, $updated)');

  }

  //For selecting the coordinates by number of points and by a specific date and after
  Future select_coor_first(int x, int dt_st) async{
    
    final db = await instance.database;

    final result =  await db.rawQuery('SELECT lat,lng FROM coordinates WHERE date > $dt_st ORDER BY id DESC LIMIT $x');

    // final result = await db.transaction((txn) async {
    //   await txn.rawQuery('SELECT lat,lng FROM coordinates ORDER BY id DESC LIMIT 1000');
    // });

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


   return result;
  }

  //For counting the number of entries in db of the select_coor_first
  Future select_coor_first_count(int x, int dt_st) async{

    final db = await instance.database;

    // final result =  await db.rawQuery('SELECT lat,lng FROM coordinates WHERE date > $dt_st ORDER BY id DESC LIMIT $x');

    // final result = await db.transaction((txn) async {
    //   await txn.rawQuery('SELECT lat,lng FROM coordinates ORDER BY id DESC LIMIT 1000');
    // });

    int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates WHERE date > $dt_st ORDER BY id DESC LIMIT $x'));


    return count;
  }

  //For selecting the coordinates by number of points and by a specific date and after
  Future select_coor_second(int x, int dt_st) async{

    int z = dt_st + 86399000;

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT lat,lng FROM coordinates WHERE (date > $dt_st AND date < $z) ORDER BY id DESC LIMIT 2000');

    // final result = await db.transaction((txn) async {
    //   await txn.rawQuery('SELECT lat,lng FROM coordinates ORDER BY id DESC LIMIT 1000');
    // });

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  //For counting the number of entries in db of the select_coor_first
  Future select_coor_second_count(int x, int dt_st) async{

    int z = dt_st + 86399000;

    final db = await instance.database;

    // final result =  await db.rawQuery('SELECT lat,lng FROM coordinates WHERE date > $dt_st ORDER BY id DESC LIMIT $x');

    // final result = await db.transaction((txn) async {
    //   await txn.rawQuery('SELECT lat,lng FROM coordinates ORDER BY id DESC LIMIT 1000');
    // });

    int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates WHERE (date > $dt_st AND date < $z) ORDER BY id DESC LIMIT 2000'));


    return count;
  }

  Future select_altitude() async{

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT altitude FROM altitude');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  Future select_pressure() async{

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT pressure FROM pressure');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  Future select_acc() async{

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT x,y,z FROM acceleration');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  Future select_gyro() async{

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT x,y,z FROM gyroscope');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  Future select_magn() async{

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT x,y,z FROM magnetometer');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  Future select_prox() async{

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT dist FROM proximity');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  Future select_daily_steps() async{

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT steps FROM daily_steps');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  Future sum_daily_steps() async{

    final db = await instance.database;

    final result =  await db.rawQuery('SELECT SUM(steps) FROM daily_steps');

    //int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM coordinates'));


    return result;
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }



}