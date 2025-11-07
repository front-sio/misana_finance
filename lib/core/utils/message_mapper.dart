// lib/core/utils/message_mapper.dart
class MessageMapper {
  static String getAuthErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Tatizo la mtandao. Tafadhali angalia muunganisho wako wa intaneti.';
    }

    if (errorString.contains('timeout')) {
      return 'Ombi lilizokaa muda mrefu. Tafadhali jaribu tena.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Mkutano wako umepishwa. Tafadhali ingia tena.';
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Ukinzani wa ufahamu. Tafadhali wasiliana na msaada.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Huduma si inapatikana kwa sasa. Tafadhali jaribu tena baadaye.';
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Tatizo la seva. Tunakamatia kurekebeza hii.';
    }

    if (errorString.contains('invalid') || errorString.contains('credentials')) {
      return 'Taarifa si sahihi. Tafadhali angalia na jaribu tena.';
    }

    return 'Kitu kimekataa. Tafadhali jaribu tena.';
  }

  static String getSuccessMessage(String action) {
    switch (action) {
      case 'session_verified':
        return 'Karibu tena! Tunakuletea kituo chako...';
      case 'login_success':
        return 'Ingizo lilianza! Tunaongezeana...';
      case 'registration_success':
        return 'Akaunti iliundwa vizuri!';
      case 'verification_success':
        return 'Uthibitisho kumalizika!';
      case 'pot_created':
        return 'Mpango wa akiba umeundwa!';
      case 'pot_updated':
        return 'Mpango wa akiba umehariri!';
      case 'pot_deleted':
        return 'Mpango wa akiba umeondolewa!';
      default:
        return 'Imekamilika!';
    }
  }

  static String getPotsFriendlyError(dynamic error) {
    if (error == null) return 'Tatizo lisilojulikana limetokea.';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Tatizo la mtandao. Tafadhali angalia muunganisho wako wa intaneti na jaribu tena.';
    }

    if (errorString.contains('timeout')) {
      return 'Ombi lilizokaa muda mrefu. Tafadhali jaribu tena.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Mkutano wako umepishwa. Tafadhali ingia tena ili kuendelea.';
    }

    if (errorString.contains('account_not_found') || errorString.contains('akaunti')) {
      return 'Akaunti haijapatikana. Fungua au unganisha akaunti ya Selcom kisha jaribu tena.';
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Kuruhusu kuundwa mpango. Tafadhali wasiliana na msaada.';
    }

    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'Data iliyoingizwa si sahihi. Tafadhali angalia na jaribu tena.';
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Tatizo la seva. Tafadhali jaribu tena baadaye.';
    }

    if (errorString.contains('duplicate') || errorString.contains('already')) {
      return 'Mpango kwa jina hili haupo tayari. Tafadhali tumia jina lingine.';
    }

    return 'Hatuwezi kubakia mpango. Tafadhali jaribu tena.';
  }

  static String getAccountFriendlyError(dynamic error) {
    if (error == null) return 'Tatizo la akaunti lisilojulikana.';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Tatizo la mtandao. Hakikisha intaneti yako inaendelea.';
    }

    if (errorString.contains('timeout')) {
      return 'Muda umepita. Jaribu tena.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Hauruhusiwi. Ingia tena.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Akaunti haijapatikana. Fungua akaunti kwanza.';
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Kuruhusu kupita. Wasiliana na msaada.';
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Tatizo la seva. Jaribu baadaye.';
    }

    return 'Tatizo la akaunti. Jaribu tena.';
  }

  static String getPotsFriendlyMessage(String key, [Map<String, dynamic>? params]) {
    switch (key) {
      case 'pot_created':
        return 'Mpango wa akiba "${params?['name'] ?? ''}" umeundwa vizuri!';
      case 'pot_updated':
        return 'Mpango "${params?['name'] ?? ''}" umehariri!';
      case 'pot_deleted':
        return 'Mpango "${params?['name'] ?? ''}" umeondolewa.';
      case 'account_ensuring':
        return 'Inahakikisha akaunti yako...';
      case 'loading_pots':
        return 'Inapakia mipango yako...';
      default:
        return '';
    }
  }
}