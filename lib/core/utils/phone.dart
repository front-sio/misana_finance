String normalizePhone(String phone, String countryCode) {
  phone = phone.trim();
  if (phone.startsWith('+')) phone = phone.substring(1);
  if (phone.startsWith('0')) phone = countryCode + phone.substring(1);
  return phone;
}