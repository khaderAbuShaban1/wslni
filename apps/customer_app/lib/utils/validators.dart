String? requiredField(String? value) {
  if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'البريد مطلوب';
  if (!value.contains('@')) return 'أدخل بريد صحيح';
  return null;
}
