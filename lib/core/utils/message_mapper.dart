class MessageMapper {
  static String getAuthErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection issue. Please check your internet and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Session expired. Please sign in again.';
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied. Please contact support.';
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server issue. We\'re working to fix this.';
    }
    
    if (errorString.contains('invalid') || errorString.contains('credentials')) {
      return 'Invalid credentials. Please check and try again.';
    }
    
    return 'Something went wrong. Please try again.';
  }
  
  static String getSuccessMessage(String action) {
    switch (action) {
      case 'session_verified':
        return 'Welcome back! Taking you to your dashboard...';
      case 'login_success':
        return 'Login successful! Redirecting...';
      case 'registration_success':
        return 'Account created successfully!';
      case 'verification_success':
        return 'Verification completed!';
      default:
        return 'Success!';
    }
  }
}