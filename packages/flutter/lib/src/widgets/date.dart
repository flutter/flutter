/// Signature for predicating dates for enabled date selections.
///
/// See [showDatePicker], which has a [SelectableDayPredicate] parameter used
/// to specify allowable days in the date picker.
typedef SelectableDayPredicate = bool Function(DateTime day);
