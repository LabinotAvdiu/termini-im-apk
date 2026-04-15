class Validators {
  static String? email(String? value, {
    String requiredMessage = "L'email est requis",
    String invalidMessage = 'Email invalide',
  }) {
    if (value == null || value.trim().isEmpty) return requiredMessage;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return invalidMessage;
    return null;
  }

  static String? password(String? value, {
    String requiredMessage = 'Le mot de passe est requis',
    String tooShortMessage = 'Le mot de passe doit contenir au moins 8 caractères',
    String needsUpperMessage = 'Doit contenir au moins une majuscule',
    String needsLowerMessage = 'Doit contenir au moins une minuscule',
    String needsNumberMessage = 'Doit contenir au moins un chiffre',
    int minLength = 8,
  }) {
    if (value == null || value.isEmpty) return requiredMessage;
    if (value.length < minLength) return tooShortMessage;
    if (!value.contains(RegExp(r'[A-Z]'))) return needsUpperMessage;
    if (!value.contains(RegExp(r'[a-z]'))) return needsLowerMessage;
    if (!value.contains(RegExp(r'[0-9]'))) return needsNumberMessage;
    return null;
  }

  static String? required(String? value, {
    String message = 'Ce champ est requis',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? confirmPassword(String? value, String? password, {
    String message = 'Les mots de passe ne correspondent pas',
  }) {
    if (value != password) return message;
    return null;
  }
}
