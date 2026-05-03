String? titleFieldValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a title';
  }
  if (value.length > 50) {
    return 'Title cannot be longer than 50 characters';
  }
  return null;
}
