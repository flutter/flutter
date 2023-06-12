These directories hold data used for date formatting when you read the data
from JSON files on disk or over the network. There are two directories

  patterns - Holds the mapping form skeletons to a locale-specific format. The
data is exactly equivalent to that in date_time_patterns.dart and is generated
from it using the tools/generate_locale_data_files.dart program.
 
  symbols - Holds the symbols used for formatting in a particular locale. This
includes things like the names of weekdays and months. The data is the same as
that in date_symbol_data_locale.dart and is generated from it using the 
tools/generate_locale_data_files.dart program.

There is also a localeList.dart file that lists all of the 
locales in these directories and which is sourced by other files in order to 
have a list of the available locales.
 
