// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An example xcresult bundle json with invalid issues map.
const String kSampleResultJsonInvalidIssuesMap = r'''
{
  "_type" : {
    "_name" : "ActionsInvocationRecord"
  },
  "issues": []
}
''';

/// An example xcresult bundle json that contains warnings and errors that needs to be discarded per https://github.com/flutter/flutter/issues/95354.
const String kSampleResultJsonWithIssuesToBeDiscarded = r'''
{
  "issues" : {
    "_type" : {
      "_name" : "ResultIssueSummaries"
    },
    "errorSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "documentLocationInCreatingWorkspace" : {
            "_type" : {
              "_name" : "DocumentLocation"
            },
            "concreteTypeName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "DVTTextDocumentLocation"
            },
            "url" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "file:\/\/\/Users\/m\/Projects\/test_create\/ios\/Runner\/AppDelegate.m#CharacterRangeLen=0&CharacterRangeLoc=263&EndingColumnNumber=56&EndingLineNumber=7&LocationEncoding=1&StartingColumnNumber=56&StartingLineNumber=7"
            }
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Semantic Issue"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Use of undeclared identifier 'asdas'"
          }
        },
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Uncategorized"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Command PhaseScriptExecution failed with a nonzero exit code"
          }
        }
      ]
    },
    "warningSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Warning"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99."
          }
        }
      ]
    }
  }
}
''';

/// An example xcresult bundle json that contains some warning and some errors.
const String kSampleResultJsonWithIssues = r'''
{
  "issues" : {
    "_type" : {
      "_name" : "ResultIssueSummaries"
    },
    "errorSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "documentLocationInCreatingWorkspace" : {
            "_type" : {
              "_name" : "DocumentLocation"
            },
            "concreteTypeName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "DVTTextDocumentLocation"
            },
            "url" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "file:\/\/\/Users\/m\/Projects\/test_create\/ios\/Runner\/AppDelegate.m#CharacterRangeLen=0&CharacterRangeLoc=263&EndingColumnNumber=56&EndingLineNumber=7&LocationEncoding=1&StartingColumnNumber=56&StartingLineNumber=7"
            }
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Semantic Issue"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Use of undeclared identifier 'asdas'"
          }
        }
      ]
    },
    "warningSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Warning"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99."
          }
        }
      ]
    }
  }
}
''';

/// An example xcresult bundle json that contains some warning and some errors.
const String kSampleResultJsonWithIssuesAndInvalidUrl = r'''
{
  "issues" : {
    "_type" : {
      "_name" : "ResultIssueSummaries"
    },
    "errorSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "documentLocationInCreatingWorkspace" : {
            "_type" : {
              "_name" : "DocumentLocation"
            },
            "concreteTypeName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "DVTTextDocumentLocation"
            },
            "url" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "3:00"
            }
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Semantic Issue"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Use of undeclared identifier 'asdas'"
          }
        }
      ]
    },
    "warningSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Warning"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99."
          }
        }
      ]
    }
  }
}
''';

/// An example xcresult bundle json that contains no issues.
const String kSampleResultJsonNoIssues = r'''
{
  "issues" : {
    "_type" : {
      "_name" : "ResultIssueSummaries"
    }
  }
}
''';

/// An example xcresult bundle json with some provision profile issue.
const String kSampleResultJsonWithProvisionIssue = r'''
{
  "issues" : {
    "_type" : {
      "_name" : "ResultIssueSummaries"
    },
    "errorSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Semantic Issue"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Some Provisioning profile issue."
          }
        }
      ]
    }
  }
}
''';
