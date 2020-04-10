part of '../../data_types.dart';

class DetailedGradingPeriod {
  Map<List<CategoryHeader>, List<Assignment>> assignments = Map();
  Map<String, String> attributes = Map();

  DetailedGradingPeriod();

  DetailedGradingPeriod.define(this.assignments, this.attributes);

  @override
  String toString() {
    return 'DetailedGradingPeriod{assignments: $assignments, attributes: $attributes}';
  }
}

/// [AssignmentNode] is the parent of multiple child types that allow for more categorization
abstract class AssignmentNode {
  String name;

  /// All the attributes like grades, post values, and more.
  /// **NOTE: THIS MAP IS NOT SAFE TO MODIFY IN YOUR CODE. DO IT WITH CAUTION**
  Map<String, String> attributes;

  AssignmentNode(this.name, this.attributes);

  @override
  String toString() {
    return "";
  }

  bool operator ==(other) {
    if (this is Assignment && other is Assignment) {
      return (this as Assignment).assignmentID == other.assignmentID;
    } else if (other is AssignmentNode) {
      return name == other.name;
    } else {
      return false;
    }
  }

  /// Attempts to get the assignment name
  String getAssignment() {
    return attributes[attributes.keys.toList()[1]];
  }

  /// Attempts to get a decimal grade if there is one.
  /// If there is no decimal grade in the map, then it'll attempt to find and return the integer grade by calling [getIntGrade()]
  /// Read [getIntGrade()] documentation to see what it returns.
  String getDecimal() {
    for (String a in attributes.values) {
      if (double.tryParse(a) != null && a.contains('.')) {
        return a;
      }
    }
    return getIntGrade();
  }

  /// Attempts to find an integer grade in the map.
  /// If one is not found, it'll return null.
  /// **NOTE: REMEMBER TO CHECK FOR THIS NULL IN YOUR CODE**
  String getIntGrade() {
    for (String val in attributes.values) {
      if (int.tryParse(val) != null) {
        return val;
      }
    }
    return null;
  }
}

/// [Assignment] is an assignment scraped from the API
///
/// [Assignment] is really hard to make, so custom declarations of Assignments is highly discouraged.
class Assignment extends AssignmentNode {
  /// Post required attributes. Do not worry about this value if you do not plan to modify [Assignment]
  String studentID;
  String assignmentID;
  String courseID;

  Assignment(this.studentID, this.assignmentID, this.courseID, String name,
      Map<String, String> attributes)
      : super(name, attributes);

  @override
  bool operator ==(other) {
    if (other is Assignment) return assignmentID == other.assignmentID;
    return false;
  }

  @override
  String toString() {
    return 'Assignment{studentID: $studentID, assignmentID: $assignmentID, courseID: $courseID, assignmentName: $name, attributes: $attributes}';
  }

  Assignment.fromJson(Map<String, dynamic> json)
      : studentID = (json['sID'] ?? json['studentID']),
        assignmentID = (json['aID'] ?? json['assignmentID']),
        courseID = (json['cID'] ?? json['courseID']),
        super(
          (json['n'] ?? json['name']),
          (json['attributes'] ?? _recoverAttr(json['a']))
              .cast<String, String>());

  static Map _recoverAttr(Map attr) {
    if (attr.containsKey('g') && attr.containsKey('t')) {
      attr['term'] = attr['t'];
      attr['grade'] = attr['g'];
      attr.remove('g');
      attr.remove('t');
    }
    return attr;
  }

  Map<String, dynamic> toJson() => {
    'studentID': studentID,
    'assignmentID': assignmentID,
    'courseID': courseID,
    'name': name,
    'attributes': attributes
      };
}

/// [CategoryHeader] is an category scraped from the API
///
/// [CategoryHeader] marks the beginning of a new Category, so it contains weight information and juicy stuff that allows you to distinguish assignments from categories
class CategoryHeader extends AssignmentNode {
  String weight;

  CategoryHeader(String name, this.weight, Map<String, String> attributes)
      : super(name, attributes);

  @override
  String toString() {
    return 'CategoryHeader{catName: $name,weight: $weight}';
  }
}

/// [AssignmentProperty] contains the attribute name and the value that the attribute holds
/// [infoName] and [info] are both paired together to declare a specific value. For example, "Due Date" and "9/3/19"
class AssignmentProperty {
  String infoName;
  String info;

  AssignmentProperty(this.infoName, this.info);

  String getDebug() {
    return infoName + ':' + info;
  }

  @override
  String toString() {
    return infoName +
        (!infoName.endsWith(":") ? ":" : "") +
        ' ' +
        (info != null ? info : "");
  }
}
