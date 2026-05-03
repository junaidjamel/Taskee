String? descriptionFieldValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a description';
  }
  if (value.length > 200) {
    return 'Description cannot be longer than 200 characters';
  }
  return null;
}
