import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  var image = img.Image(width: 10, height: 10);
  image.clear(img.ColorUint8.rgb(100, 100, 100)); // gray
  print('Before: ${image.getPixel(0,0).r}');
  var contrasted = img.contrast(image, contrast: 1.5);
  print('After contrast 1.5: ${contrasted.getPixel(0,0).r}');
  var contrasted150 = img.contrast(image, contrast: 150);
  print('After contrast 150: ${contrasted150.getPixel(0,0).r}');
}
