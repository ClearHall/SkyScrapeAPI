part of '../../data_types.dart';

class Gradebook {
  final List<GradebookSector> gradebookSectors;

  Gradebook(this.gradebookSectors);

  List<Class> getAllClasses() {
    return gradebookSectors.expand((element) => element.classes).toList();
  }

  List<Assignment> getAllAssignments() {
    return gradebookSectors
        .expand((element) => element.quickAssignments)
        .toList();
  }

  List<Term> getAllTerms() {
    return gradebookSectors.expand((element) => element.terms).toList();
  }

  @override
  String toString() {
    return 'Gradebook{gradebookSectors: $gradebookSectors}';
  }

  Gradebook.fromJson(Map<String, dynamic> json)
      : gradebookSectors =
            (json['c'] == null ? _getSectorList(json) : _fromCompressed(json));

  static List<GradebookSector> _getSectorList(Map<String, dynamic> json) {
    return (json['gradebookSectors'] ?? json['gS'])
        .map((value) => GradebookSector.fromJson(value))
        .toList()
        .cast<GradebookSector>();
  }

  /// 其实挺简单的！
  /// It loops through the encoded map and finds things such as student ID, course ID, and terms. The three most commonly repeated variables.
  /// By taking those variables out and associating a specific index of a separate designated set for them, we can eliminate many duplicates and save a lot of space.
  /// For example, compressing can turn {sID: 30012} into {sID: 0}, while in another location {0: 30012} is stored. If we have multiple elements with that same sID, it'll save a lot of space by eliminating the need to have 30012 over and over again.
  static List<GradebookSector> _fromCompressed(Map<String, dynamic> json) {
    for (Map sec in json['gS']) {
      for (int i = 0; i < sec['t'].length; i++)
        sec['t'][i] = json['c'][sec['t'][i]];
      for (Map classes in sec['c']) {
        for (Map grades in classes['g']) {
          grades['t'] = json['c'][grades['t']];
          if (grades.containsKey('cN')) {
            grades['cN'] = json['cID'][grades['cN']];
            if (grades.containsKey('sID'))
              grades['sID'] = json['s'][grades['sID']];
            else
              grades['sID'] = json['s'][0];
          }
        }
      }

      int tmp;
      for (Map qAssign in sec['qA']) {
        if (qAssign.containsKey('cID')) {
          tmp = qAssign['cID'];
        }
        qAssign['cID'] = json['cID'][tmp];
        if (qAssign.containsKey('sID'))
          qAssign['sID'] = json['s'][qAssign['sID']];
        else
          qAssign['sID'] = json['s'][0];
      }
    }
    json.remove('c');
    json.remove('cID');
    json.remove('s');
    return _getSectorList(json);
  }

  Map<String, dynamic> toJson() => {'gradebookSectors': gradebookSectors};

  Map<String, dynamic> toCompressedJson() {
    Map<String, dynamic> json = jsonDecode(jsonEncode(toJson()));
    List<Map> termCache = List<Map>();
    Set<String> studentID = Set();
    Set<String> courseID = Set();

    _simplifyMap(json);

    for (Map sec in json['gS']) {
      for (int i = 0; i < sec['t'].length; i++)
        sec['t'][i] = _checkTermElems(sec['t'][i], termCache);
      for (Map classes in sec['c']) {
        for (Map grades in classes['g']) {
          grades['t'] = _checkTermElems(grades['t'], termCache);
          if (grades.containsKey('cN') && grades.containsKey('sID')) {
            _singleSetAdd(courseID, grades, 'cN');
            _singleSetAdd(studentID, grades, 'sID');
            if (grades['sID'] == 0) grades.remove('sID');
          }
        }
      }

      int tmp;
      for (Map qAssign in sec['qA']) {
        if (qAssign.containsKey('cID') && qAssign.containsKey('sID')) {
          _singleSetAdd(courseID, qAssign, 'cID');
          if (tmp != qAssign['cID']) {
            tmp = qAssign['cID'];
          } else {
            qAssign.remove('cID');
          }
          _singleSetAdd(studentID, qAssign, 'sID');
          if (qAssign['sID'] == 0) qAssign.remove('sID');
        }
      }
    }

    json['s'] = studentID.toList();
    json['cID'] = courseID.toList();
    json['c'] = termCache;
    return json;
  }

  void _simplifyMap(Map<String, dynamic> a) {
    List<String> keys = a.keys.toList();
    for (int i = keys.length - 1; i >= 0; i--) {
      String simplified = simplify(keys[i]);
      a[simplified] = a[keys[i]];
      a.remove(keys[i]);
      _checkValue(a[simplified]);
    }
  }

  void _checkValue(x) {
    if (x is Map)
      _simplifyMap(x);
    else if (x is List)
      for (var v in x) {
        _checkValue(v);
      }
  }

  void _singleSetAdd(Set<String> set, Map grades, String id) {
    set.add(grades[id]);
    grades[id] = set.toList().indexOf(grades[id]);
  }

  int _checkTermElems(var grades, List<Map> termCache) {
    bool Function(Map) functionCheck = (element) =>
        element['tC'] == grades['tC'] && element['tN'] == grades['tN'];
    if (termCache.where(functionCheck).length == 0) termCache.add(grades);
    return termCache.indexWhere(functionCheck);
  }
}

class GradebookSector {
  String name;
  List<Class> classes;
  List<Term> terms;
  List<Assignment> quickAssignments;

  GradebookSector() {
    classes = List();
    terms = List();
    quickAssignments = List();
  }

  /// This compares assignment's assignment ID!
  /// This is useful if you are trying to find the term of an assignment in semesters.
  String getAssignmentTerm(Assignment a) {
    for (Assignment b in quickAssignments) {
      if (a.assignmentID == b.assignmentID) return b.attributes['term'];
    }
    return null;
  }

  @override
  String toString() {
    return 'Gradebook{terms: $terms, classes: $classes, quickAssignments: $quickAssignments, name: $name}';
  }

  GradebookSector.fromJson(Map<String, dynamic> json)
      : classes = (json['c'] ?? json['classes'])
      .map((value) => Class.fromJson(value))
      .toList()
      .cast<Class>(),
        terms = (json['t'] ?? json['terms'])
            .map((value) => Term.fromJson(value))
            .toList()
            .cast<Term>(),
        quickAssignments = (json['qA'] ?? json['quickAssignments'])
            .map((value) => Assignment.fromJson(value))
            .toList()
            .cast<Assignment>(),
        name = json['n'] ?? json['name'];

  Map<String, dynamic> toJson() =>
      {
        'terms': terms,
        'classes': classes,
        'quickAssignments': quickAssignments,
        'name': name
      };
}

class Class {
  String teacherName;
  String timePeriod;
  String courseName;

  List<GradebookNode> grades;

  Class(this.teacherName, this.courseName, this.timePeriod, {this.grades}) {
    grades = List<GradebookNode>();
  }

  GradebookNode retrieveNodeByTerm(Term term) {
    for (GradebookNode node in grades) {
      if (node.term == term) return node;
    }
    return null;
  }

  @override
  String toString() {
    return 'Class{teacherName: $teacherName, timePeriod: $timePeriod, courseName: $courseName, grades: $grades}';
  }

  Class.fromJson(Map<String, dynamic> json)
      : teacherName = (json['tN'] ?? json['teacherName']),
        timePeriod = (json['tP'] ?? json['timePeriod']),
        courseName = (json['cN'] ?? json['courseName']),
        grades = (json['g'] ?? json['grades'])
            .map((value) => value.length == 2
                ? FixedGrade.fromJson(value)
                : Grade.fromJson(value))
            .toList()
            .cast<GradebookNode>();

  Map<String, dynamic> toJson() =>
      {
        'teacherName': teacherName,
        'timePeriod': timePeriod,
        'courseName': courseName,
        'grades': grades
      };
}

/// [GradebookNode] is a root that helps distinguish the difference between grades and teacher information
///
/// There are only two children of [GradebookNode]
/// * [FixedGrade]
/// * [Grade]
abstract class GradebookNode {
  Term term;
  String grade;
  bool containsMoreData;

  GradebookNode(this.term, this.grade, this.containsMoreData);

  GradebookNode.fromJson(Map<String, dynamic> json, this.containsMoreData)
      : term = Term.fromJson((json['t'] ?? json['term'])),
        grade = (json['g'] ?? json['grade']);

  Map<String, dynamic> toJson() => {'grade': grade, 'term': term.toJson()};
}

class FixedGrade extends GradebookNode {
  FixedGrade(String grade, Term term) : super(term, grade, false);

  bool isGradeBehavior() {
    return int.tryParse(grade) == null;
  }

  @override
  String toString() {
    return 'FixedGrade{grade: $grade}';
  }

  FixedGrade.fromJson(Map<String, dynamic> json) : super.fromJson(json, false);
}

/// [Grade] is most likely a clickable numbered grade part of a specific term
class Grade extends GradebookNode {
  String courseNumber;
  String studentID;

  /// Identification for which term [Grade] is in.
  Grade(this.courseNumber, Term term, String grade, this.studentID)
      : super(term, grade, true);

  @override
  String toString() {
    return 'Grade{courseNumber: $courseNumber, grade: $grade, studentID: $studentID}';
  }

  Grade.fromJson(Map<String, dynamic> json)
      : courseNumber = (json['cN'] ?? json['courseNumber']),
        studentID = (json['sID'] ?? json['studentID']),
        super.fromJson(json, true);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'courseNumber': courseNumber,
      'studentID': studentID,
    });
}
