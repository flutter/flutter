part of sprites;

typedef void ImageMapCallback(ImageMap preloader);

class ImageMap {

  Map<String, Image> _images;

  int _totalNumImages = 0;
  int _numLoadedImages = 0;

  ImageMapCallback _callback;

  ImageMap(List<String> urls, ImageMapCallback this._callback) {
    _images = new Map();
    _totalNumImages = urls.length;
    urls.forEach(_addURL);
  }

  void _addURL(String url) {
    image_cache.load(url, (Image image) {
      // Store reference to image
      _images[url] = image;

      // Check if all images are loaded
      _numLoadedImages++;
      if (_numLoadedImages==_totalNumImages) {
        // Everything loaded, make callback
        _callback(this);
      }
    });
  }

  Image getImage(String url) => _images[url];

  Image operator [](String url) => _images[url];
}