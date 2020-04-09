import 'dart:convert';

part 'data/district_search.dart';

part 'data/grades/academic_history.dart';

part 'data/grades/assignments.dart';

part 'data/grades/gradebook.dart';

part 'data/messages.dart';

part 'data/student_info.dart';

/// [Term] allow for the scrapers to sort through the grades and retrieve grades for certain terms.
///
/// [Term] is JSON compatible and can be converted to a JSON if needed.
class Term {
  /// TermCode is the identifier used to identify the term.
  String termCode;

  /// TermName is the name of the term used if needed for extra identification or display
  String termName;

  // Simple constructor to initialize the termCode and termName
  Term(this.termCode, this.termName);

  @override
  String toString() {
    return "$termCode : $termName";
  }

  Term.fromJson(Map<String, dynamic> json)
      : termCode = json['termCode'] ?? json['tC'],
        termName = json['termName'] ?? json['tN'];

  Map<String, dynamic> toJson() => {
    'tC': termCode,
    'tN': termName,
  };

  /// Compares the term codes only
  @override
  bool operator ==(other) {
    if (other is Term) {
      return (other).termCode == this.termCode;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => termCode.hashCode;
}

/// Account returned for internal API use when a parent account is parsed
class Child {
  final String dataID, name;

  Child(this.dataID, this.name);

  @override
  String toString() {
    return 'SkywardAccount{dataID: $dataID, name: $name}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Child &&
              runtimeType == other.runtimeType &&
              dataID == other.dataID;

  @override
  int get hashCode => dataID.hashCode;
}

enum ErrorCode {
  LoginError,
  RefreshTimeLessThanOne,
  UnderMaintenance,
  ExceededRefreshTimeLimit
}

/// SkyScrapeAPI Custom errors to locate errors and give proper causes.
///
/// **NOTE: THE WHOLE API WILL USE THIS EXCEPTION**
class SkywardError implements Exception {
  String cause;
  ErrorCode errorCode;

  SkywardError(this.cause);

  SkywardError.usingErrorCode(this.errorCode);

  String getErrorCode() {
    return errorCode.toString().split('.')[1];
  }

  String getErrorCodeMessage() {
    if (errorCode != null) {
      switch (errorCode) {
        case ErrorCode.LoginError:
          return 'An fatal unexpected error has occured while logging in!';
          break;
        case ErrorCode.RefreshTimeLessThanOne:
          return 'Refresh times cannot be set to a value less than 1!';
          break;
        case ErrorCode.UnderMaintenance:
          return 'Your district\'s Skyward seems like it\'s on maintenance';
          break;
        case ErrorCode.ExceededRefreshTimeLimit:
          return 'Refresh times were exceeded. An unexpected error has occured. Please report this to the developer!';
          break;
        default:
          return 'Could not retrieve an error message!';
      }
    } else {
      return null;
    }
  }

  @override
  String toString() {
    if (cause != null)
      return cause;
    else
      return getErrorCode();
  }
}
