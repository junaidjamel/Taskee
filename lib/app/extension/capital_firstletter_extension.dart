extension NullableStringCasingExtension on String? {
  String capitalizeFirst() {
    if (this == null || this!.isEmpty) return '';
    return this![0].toUpperCase() + this!.substring(1);
  }
}



  /* Capitalizes the first letter of the string.
     Returns an empty string if null or empty.


     Use it like 👇
     'junaid'.capitalizeFirst();

*/