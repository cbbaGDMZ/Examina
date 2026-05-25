import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  var image = img.Image(width: 100, height: 100, numChannels: 3);
  image.clear(img.ColorUint8.rgb(100, 200, 50));
  var gray = img.grayscale(image);
  var jpgBytes = img.encodeJpg(gray);
  File('test_gray.jpg').writeAsBytesSync(jpgBytes);
  print('Done.');
}
