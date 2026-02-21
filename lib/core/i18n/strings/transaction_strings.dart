class TransactionStrings {
  static const Map<String, String> en = {
    'transactions': 'Career Contributions',
    'deposit': 'Career Investment',
    'withdraw': 'Career Return',
    'amount': 'Investment Amount',
    'fee': 'Processing Fee',
    'net_amount': 'Net Investment',
    'date': 'Date',
    'time': 'Time',
    'status': 'Status',
    'pending': 'Processing',
    'posted': 'Invested',
    'failed': 'Failed',
    'provider': 'Payment Provider',
    'reference': 'Reference Number',
    'transaction_details': 'Investment Details',
    'total_amount': 'Total Investment',
    'contribution_history': 'Contribution History',
    'investment_summary': 'Investment Summary',
    'career_growth': 'Career Growth',
    'return_on_investment': 'Return on Investment',
  };
  
  static const Map<String, String> sw = {
    'transactions': 'Michango ya Kazi',
    'deposit': 'Uwekezaji wa Kazi',
    'withdraw': 'Rejesho la Kazi',
    'amount': 'Kiasi cha Uwekezaji',
    'fee': 'Ada ya Usindikaji',
    'net_amount': 'Uwekezaji Halisi',
    'date': 'Tarehe',
    'time': 'Wakati',
    'status': 'Hali',
    'pending': 'Inasindikwa',
    'posted': 'Imewekezwa',
    'failed': 'Imeshindwa',
    'provider': 'Mtoa Huduma ya Malipo',
    'reference': 'Namba ya Rejeleo',
    'transaction_details': 'Maelezo ya Uwekezaji',
    'total_amount': 'Jumla ya Uwekezaji',
    'contribution_history': 'Historia ya Michango',
    'investment_summary': 'Muhtasari wa Uwekezaji',
    'career_growth': 'Ukuaji wa Kazi',
    'return_on_investment': 'Rejesho la Uwekezaji',
  };
  
  static String get(String key, String locale) {
    return locale == 'sw' ? (sw[key] ?? en[key] ?? key) : (en[key] ?? key);
  }
}
