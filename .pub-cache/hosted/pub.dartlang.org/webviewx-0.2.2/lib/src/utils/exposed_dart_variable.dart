/// TODO
/// This will (maybe, eventually) be used in order to expose a Dart variable to JS at startup
/// The variable could then be used from the JS side.
///
/// Example:
///
/// On the Dart side:
/// window[MyVariable] = 5;
/// ...
/// ...
/// On the JS side:
/// console.log(MyVariable) // prints 5
///
/// Note: There should also (i think?) be a way to update that variable
/// i.e. to do window[MyVariable] = 6.
