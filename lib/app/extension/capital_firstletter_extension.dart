extension NullableStringCasingExtension on String? {
  String capitalizeFirst() {
    if (this == null || this!.isEmpty) return '';
    return this![0].toUpperCase() + this!.substring(1);
  }
}
