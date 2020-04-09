part of '../../data_types.dart';

/// [SchoolYear] is usually returned in a List from [SkywardAPICore.getHistory()]
///
/// SchoolYear provides information about the school year and is JSON Compatible so it can be saved or returned from a server
/// The [description] of the [SchoolYear] is just the name of the [SchoolYear] under Skyward. [terms] are also taken just in case your district has changed terms in its skyward history.
/// [classes] is a list of [HistoricalClass], for more information, read up on [HistoricalClass] documentation.
class SchoolYear {
  String description;
  List<Term> terms;

  //First String represents class, in each class theres a map of the term and then the grade of that term.
  List<HistoricalClass> classes;

  /// This is an extra attribute you can use in your application just in case you need it.
  bool isEnabled = true;

  SchoolYear();

  SchoolYear.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        terms = json['terms']
            .map((value) => Term.fromJson(value))
            .toList()
            .cast<Term>(),
        classes = json['classes']
            .map((value) => HistoricalClass.fromJson(value))
            .toList()
            .cast<HistoricalClass>(),
        isEnabled = json['isEnabled'];

  Map<String, dynamic> toJson() => {
        'description': description,
        'terms': terms,
        'classes': classes,
        'isEnabled': isEnabled
      };

  @override
  String toString() {
    return 'SchoolYear{description: $description, classes: $classes}';
  }

  @override
  bool operator ==(other) {
    return classes.length == other.classes.length;
  }

  @override
  int get hashCode => description.hashCode;
}

/// [HistoricalClass] is a rich information class that holds settings and information about your classes.
///
/// **Some Things to Note**
/// * [classLevel] is set by the developer or user, not automatically retrieved.
/// * [credits] is set by the developer or user, not automatically retrieved.
class HistoricalClass {
  String name;
  List<String> grades;
  double credits;
  ClassLevel classLevel;

  HistoricalClass(this.name);

  HistoricalClass.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        grades = json['grades'].toList().cast<String>(),
        credits = json['credits'],
        classLevel = _getClassLevelFromText(json['classLevel']);

  Map<String, dynamic> toJson() => {
        'name': name,
        'grades': grades,
        'credits': credits,
        'classLevel': classLevel.toString(),
      };

  static ClassLevel _getClassLevelFromText(String txt) {
    try {
      return ClassLevel.values.firstWhere((e) => e.toString() == txt);
    } catch (e) {
      return ClassLevel.Regular;
    }
  }

  @override
  String toString() {
    return 'GPACalculatorClass{name: $name, grades: $grades, credits: $credits, classLevel: $classLevel}';
  }

  @override
  bool operator ==(other) {
    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Just ClassLevels, nothing special.
enum ClassLevel { Regular, PreAP, AP, None }
