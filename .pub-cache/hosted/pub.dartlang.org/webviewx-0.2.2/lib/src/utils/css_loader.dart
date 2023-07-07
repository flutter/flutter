/// This is used to generate a css loading indicator
/// *ONLY FOR THE WEB VERSION*, for when the iframe is loading the page.
///
/// You can check out the default implementation below to see how it should
/// look like, or you can download a custom one from the internet.
class CssLoader {
  /// Full code of the loaded (css-only)
  final String style;

  /// Loader's className (where it is injected)
  final String loaderClassName;

  /// Constructor
  const CssLoader({
    this.style = '''
    .loader {
      position: absolute;
      top: calc(50% - 25px);
      left: calc(50% - 25px);
      width: 50px;
      height: 50px;
      background-color: #333;
      border-radius: 50%;  
      animation: loader 1s infinite ease-in-out;
    }
    @keyframes loader {
      0% {
      transform: scale(0);
      }
      100% {
      transform: scale(1);
      opacity: 0;
      }
    }
    ''',
    this.loaderClassName = 'loader',
  });

  /// Builds the html page used when *ONLY ON WEB*, when the page is loading
  String build() {
    return '''
<html>
  <head>
    <style>
      $style
    </style>
</head>
  <body>
    <div class="$loaderClassName"></div>
  </body>
</html>
    ''';
  }
}
