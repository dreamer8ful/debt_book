import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currencyDisplayController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _customCurrencyCountryController = TextEditingController();
  final _customCurrencyCodeController = TextEditingController();
  final _customCurrencySymbolController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _enableLock = false;
  bool _lockStateInitialized = false;
  bool _currencyStateInitialized = false;
  bool _useCustomCurrency = false;

  static const _customCurrencyValue = '__custom_currency__';

  static Map<String, String> _currencyOption({
    required String label,
    required String code,
    required String symbol,
    required String country,
    required String currency,
  }) {
    return {
      'label': label,
      'code': code,
      'symbol': symbol,
      'country': country,
      'currency': currency,
    };
  }

  static final _currencyOptions = [
    _currencyOption(
      label: 'Algerian Dinar (DZD)',
      code: 'DZD',
      symbol: 'DZD ',
      country: 'Algeria',
      currency: 'Algerian Dinar',
    ),
    _currencyOption(
      label: 'Angolan Kwanza (Kz)',
      code: 'AOA',
      symbol: 'Kz ',
      country: 'Angola',
      currency: 'Angolan Kwanza',
    ),
    _currencyOption(
      label: 'West African CFA Franc (CFA)',
      code: 'XOF',
      symbol: 'CFA ',
      country:
          'Benin, Burkina Faso, Guinea-Bissau, Ivory Coast, Mali, Niger, Senegal, Togo',
      currency: 'West African CFA Franc',
    ),
    _currencyOption(
      label: 'Botswana Pula (P)',
      code: 'BWP',
      symbol: 'P ',
      country: 'Botswana',
      currency: 'Botswana Pula',
    ),
    _currencyOption(
      label: 'Burundian Franc (FBu)',
      code: 'BIF',
      symbol: 'FBu ',
      country: 'Burundi',
      currency: 'Burundian Franc',
    ),
    _currencyOption(
      label: 'Cabo Verde Escudo (CVE)',
      code: 'CVE',
      symbol: 'CVE ',
      country: 'Cabo Verde',
      currency: 'Cabo Verde Escudo',
    ),
    _currencyOption(
      label: 'Central African CFA Franc (FCFA)',
      code: 'XAF',
      symbol: 'FCFA ',
      country:
          'Cameroon, Central African Republic, Chad, Republic of the Congo, Equatorial Guinea, Gabon',
      currency: 'Central African CFA Franc',
    ),
    _currencyOption(
      label: 'Comorian Franc (CF)',
      code: 'KMF',
      symbol: 'CF ',
      country: 'Comoros',
      currency: 'Comorian Franc',
    ),
    _currencyOption(
      label: 'Congolese Franc (CDF)',
      code: 'CDF',
      symbol: 'CDF ',
      country: 'Democratic Republic of the Congo',
      currency: 'Congolese Franc',
    ),
    _currencyOption(
      label: 'Djiboutian Franc (Fdj)',
      code: 'DJF',
      symbol: 'Fdj ',
      country: 'Djibouti',
      currency: 'Djiboutian Franc',
    ),
    _currencyOption(
      label: 'Egyptian Pound (E£)',
      code: 'EGP',
      symbol: 'E£ ',
      country: 'Egypt',
      currency: 'Egyptian Pound',
    ),
    _currencyOption(
      label: 'Eritrean Nakfa (Nfk)',
      code: 'ERN',
      symbol: 'Nfk ',
      country: 'Eritrea',
      currency: 'Eritrean Nakfa',
    ),
    _currencyOption(
      label: 'Eswatini Lilangeni (E)',
      code: 'SZL',
      symbol: 'E ',
      country: 'Eswatini',
      currency: 'Lilangeni',
    ),
    _currencyOption(
      label: 'Ethiopian Birr (Br)',
      code: 'ETB',
      symbol: 'Br ',
      country: 'Ethiopia',
      currency: 'Ethiopian Birr',
    ),
    _currencyOption(
      label: 'Gambian Dalasi (D)',
      code: 'GMD',
      symbol: 'D ',
      country: 'Gambia',
      currency: 'Gambian Dalasi',
    ),
    _currencyOption(
      label: 'Ghanaian Cedi (GH₵)',
      code: 'GHS',
      symbol: 'GH₵ ',
      country: 'Ghana',
      currency: 'Ghanaian Cedi',
    ),
    _currencyOption(
      label: 'Guinean Franc (FG)',
      code: 'GNF',
      symbol: 'FG ',
      country: 'Guinea',
      currency: 'Guinean Franc',
    ),
    _currencyOption(
      label: 'Kenyan Shilling (KSh)',
      code: 'KES',
      symbol: 'KSh ',
      country: 'Kenya',
      currency: 'Kenyan Shilling',
    ),
    _currencyOption(
      label: 'Lesotho Loti (L)',
      code: 'LSL',
      symbol: 'L ',
      country: 'Lesotho',
      currency: 'Lesotho Loti',
    ),
    _currencyOption(
      label: 'Liberian Dollar (L\$)',
      code: 'LRD',
      symbol: 'L\$',
      country: 'Liberia',
      currency: 'Liberian Dollar',
    ),
    _currencyOption(
      label: 'Libyan Dinar (LYD)',
      code: 'LYD',
      symbol: 'LYD ',
      country: 'Libya',
      currency: 'Libyan Dinar',
    ),
    _currencyOption(
      label: 'Malagasy Ariary (Ar)',
      code: 'MGA',
      symbol: 'Ar ',
      country: 'Madagascar',
      currency: 'Malagasy Ariary',
    ),
    _currencyOption(
      label: 'Malawian Kwacha (MK)',
      code: 'MWK',
      symbol: 'MK ',
      country: 'Malawi',
      currency: 'Malawian Kwacha',
    ),
    _currencyOption(
      label: 'Mauritanian Ouguiya (MRU)',
      code: 'MRU',
      symbol: 'MRU ',
      country: 'Mauritania',
      currency: 'Mauritanian Ouguiya',
    ),
    _currencyOption(
      label: 'Mauritian Rupee (₨)',
      code: 'MUR',
      symbol: '₨',
      country: 'Mauritius',
      currency: 'Mauritian Rupee',
    ),
    _currencyOption(
      label: 'Moroccan Dirham (MAD)',
      code: 'MAD',
      symbol: 'MAD ',
      country: 'Morocco',
      currency: 'Moroccan Dirham',
    ),
    _currencyOption(
      label: 'Mozambican Metical (MT)',
      code: 'MZN',
      symbol: 'MT ',
      country: 'Mozambique',
      currency: 'Mozambican Metical',
    ),
    _currencyOption(
      label: 'Namibian Dollar (N\$)',
      code: 'NAD',
      symbol: 'N\$',
      country: 'Namibia',
      currency: 'Namibian Dollar',
    ),
    _currencyOption(
      label: 'Nigerian Naira (₦)',
      code: 'NGN',
      symbol: '₦',
      country: 'Nigeria',
      currency: 'Nigerian Naira',
    ),
    _currencyOption(
      label: 'Rwandan Franc (RF)',
      code: 'RWF',
      symbol: 'RF ',
      country: 'Rwanda',
      currency: 'Rwandan Franc',
    ),
    _currencyOption(
      label: 'Sao Tome and Principe Dobra (Db)',
      code: 'STN',
      symbol: 'Db ',
      country: 'Sao Tome and Principe',
      currency: 'Dobra',
    ),
    _currencyOption(
      label: 'Seychellois Rupee (₨)',
      code: 'SCR',
      symbol: '₨',
      country: 'Seychelles',
      currency: 'Seychellois Rupee',
    ),
    _currencyOption(
      label: 'Sierra Leonean Leone (Le)',
      code: 'SLE',
      symbol: 'Le ',
      country: 'Sierra Leone',
      currency: 'Sierra Leonean Leone',
    ),
    _currencyOption(
      label: 'Somali Shilling (Sh)',
      code: 'SOS',
      symbol: 'Sh ',
      country: 'Somalia',
      currency: 'Somali Shilling',
    ),
    _currencyOption(
      label: 'South African Rand (R)',
      code: 'ZAR',
      symbol: 'R',
      country: 'South Africa',
      currency: 'South African Rand',
    ),
    _currencyOption(
      label: 'South Sudanese Pound (SSP)',
      code: 'SSP',
      symbol: 'SSP ',
      country: 'South Sudan',
      currency: 'South Sudanese Pound',
    ),
    _currencyOption(
      label: 'Sudanese Pound (SDG)',
      code: 'SDG',
      symbol: 'SDG ',
      country: 'Sudan',
      currency: 'Sudanese Pound',
    ),
    _currencyOption(
      label: 'Tanzanian Shilling (TSh)',
      code: 'TZS',
      symbol: 'TSh ',
      country: 'Tanzania',
      currency: 'Tanzanian Shilling',
    ),
    _currencyOption(
      label: 'Tunisian Dinar (TND)',
      code: 'TND',
      symbol: 'TND ',
      country: 'Tunisia',
      currency: 'Tunisian Dinar',
    ),
    _currencyOption(
      label: 'Ugandan Shilling (USh)',
      code: 'UGX',
      symbol: 'USh ',
      country: 'Uganda',
      currency: 'Ugandan Shilling',
    ),
    _currencyOption(
      label: 'Zambian Kwacha (ZK)',
      code: 'ZMW',
      symbol: 'ZK ',
      country: 'Zambia',
      currency: 'Zambian Kwacha',
    ),
    _currencyOption(
      label: 'Zimbabwe Gold (ZiG)',
      code: 'ZWG',
      symbol: 'ZiG ',
      country: 'Zimbabwe',
      currency: 'Zimbabwe Gold',
    ),
    _currencyOption(
      label: 'Afghan Afghani (؋)',
      code: 'AFN',
      symbol: '؋',
      country: 'Afghanistan',
      currency: 'Afghan Afghani',
    ),
    _currencyOption(
      label: 'Armenian Dram (֏)',
      code: 'AMD',
      symbol: '֏',
      country: 'Armenia',
      currency: 'Armenian Dram',
    ),
    _currencyOption(
      label: 'Azerbaijani Manat (₼)',
      code: 'AZN',
      symbol: '₼',
      country: 'Azerbaijan',
      currency: 'Azerbaijani Manat',
    ),
    _currencyOption(
      label: 'Bahraini Dinar (BHD)',
      code: 'BHD',
      symbol: 'BHD ',
      country: 'Bahrain',
      currency: 'Bahraini Dinar',
    ),
    _currencyOption(
      label: 'Bangladeshi Taka (৳)',
      code: 'BDT',
      symbol: '৳',
      country: 'Bangladesh',
      currency: 'Bangladeshi Taka',
    ),
    _currencyOption(
      label: 'Bhutanese Ngultrum (Nu)',
      code: 'BTN',
      symbol: 'Nu ',
      country: 'Bhutan',
      currency: 'Bhutanese Ngultrum',
    ),
    _currencyOption(
      label: 'Brunei Dollar (B\$)',
      code: 'BND',
      symbol: 'B\$',
      country: 'Brunei',
      currency: 'Brunei Dollar',
    ),
    _currencyOption(
      label: 'Cambodian Riel (៛)',
      code: 'KHR',
      symbol: '៛',
      country: 'Cambodia',
      currency: 'Cambodian Riel',
    ),
    _currencyOption(
      label: 'Chinese Yuan (¥)',
      code: 'CNY',
      symbol: '¥',
      country: 'China',
      currency: 'Chinese Yuan',
    ),
    _currencyOption(
      label: 'Georgian Lari (₾)',
      code: 'GEL',
      symbol: '₾',
      country: 'Georgia',
      currency: 'Georgian Lari',
    ),
    _currencyOption(
      label: 'Hong Kong Dollar (HK\$)',
      code: 'HKD',
      symbol: 'HK\$',
      country: 'Hong Kong',
      currency: 'Hong Kong Dollar',
    ),
    _currencyOption(
      label: 'Indian Rupee (₹)',
      code: 'INR',
      symbol: '₹',
      country: 'India',
      currency: 'Indian Rupee',
    ),
    _currencyOption(
      label: 'Indonesian Rupiah (Rp)',
      code: 'IDR',
      symbol: 'Rp ',
      country: 'Indonesia',
      currency: 'Indonesian Rupiah',
    ),
    _currencyOption(
      label: 'Iranian Rial (IRR)',
      code: 'IRR',
      symbol: 'IRR ',
      country: 'Iran',
      currency: 'Iranian Rial',
    ),
    _currencyOption(
      label: 'Iraqi Dinar (IQD)',
      code: 'IQD',
      symbol: 'IQD ',
      country: 'Iraq',
      currency: 'Iraqi Dinar',
    ),
    _currencyOption(
      label: 'Israeli New Shekel (₪)',
      code: 'ILS',
      symbol: '₪',
      country: 'Israel, Palestine',
      currency: 'Israeli New Shekel',
    ),
    _currencyOption(
      label: 'Japanese Yen (¥)',
      code: 'JPY',
      symbol: '¥',
      country: 'Japan',
      currency: 'Japanese Yen',
    ),
    _currencyOption(
      label: 'Jordanian Dinar (JOD)',
      code: 'JOD',
      symbol: 'JOD ',
      country: 'Jordan',
      currency: 'Jordanian Dinar',
    ),
    _currencyOption(
      label: 'Kazakhstani Tenge (₸)',
      code: 'KZT',
      symbol: '₸',
      country: 'Kazakhstan',
      currency: 'Kazakhstani Tenge',
    ),
    _currencyOption(
      label: 'Kuwaiti Dinar (KWD)',
      code: 'KWD',
      symbol: 'KWD ',
      country: 'Kuwait',
      currency: 'Kuwaiti Dinar',
    ),
    _currencyOption(
      label: 'Kyrgyzstani Som (сом)',
      code: 'KGS',
      symbol: 'сом ',
      country: 'Kyrgyzstan',
      currency: 'Kyrgyzstani Som',
    ),
    _currencyOption(
      label: 'Lao Kip (₭)',
      code: 'LAK',
      symbol: '₭',
      country: 'Laos',
      currency: 'Lao Kip',
    ),
    _currencyOption(
      label: 'Lebanese Pound (L£)',
      code: 'LBP',
      symbol: 'L£ ',
      country: 'Lebanon',
      currency: 'Lebanese Pound',
    ),
    _currencyOption(
      label: 'Macanese Pataca (MOP\$)',
      code: 'MOP',
      symbol: 'MOP\$',
      country: 'Macau',
      currency: 'Macanese Pataca',
    ),
    _currencyOption(
      label: 'Malaysian Ringgit (RM)',
      code: 'MYR',
      symbol: 'RM ',
      country: 'Malaysia',
      currency: 'Malaysian Ringgit',
    ),
    _currencyOption(
      label: 'Maldivian Rufiyaa (Rf)',
      code: 'MVR',
      symbol: 'Rf ',
      country: 'Maldives',
      currency: 'Maldivian Rufiyaa',
    ),
    _currencyOption(
      label: 'Mongolian Togrog (₮)',
      code: 'MNT',
      symbol: '₮',
      country: 'Mongolia',
      currency: 'Mongolian Togrog',
    ),
    _currencyOption(
      label: 'Myanmar Kyat (K)',
      code: 'MMK',
      symbol: 'K ',
      country: 'Myanmar',
      currency: 'Myanmar Kyat',
    ),
    _currencyOption(
      label: 'Nepalese Rupee (₨)',
      code: 'NPR',
      symbol: '₨',
      country: 'Nepal',
      currency: 'Nepalese Rupee',
    ),
    _currencyOption(
      label: 'North Korean Won (₩)',
      code: 'KPW',
      symbol: '₩',
      country: 'North Korea',
      currency: 'North Korean Won',
    ),
    _currencyOption(
      label: 'Omani Rial (OMR)',
      code: 'OMR',
      symbol: 'OMR ',
      country: 'Oman',
      currency: 'Omani Rial',
    ),
    _currencyOption(
      label: 'Pakistani Rupee (₨)',
      code: 'PKR',
      symbol: '₨',
      country: 'Pakistan',
      currency: 'Pakistani Rupee',
    ),
    _currencyOption(
      label: 'Philippine Peso (₱)',
      code: 'PHP',
      symbol: '₱',
      country: 'Philippines',
      currency: 'Philippine Peso',
    ),
    _currencyOption(
      label: 'Qatari Riyal (QAR)',
      code: 'QAR',
      symbol: 'QAR ',
      country: 'Qatar',
      currency: 'Qatari Riyal',
    ),
    _currencyOption(
      label: 'Saudi Riyal (SAR)',
      code: 'SAR',
      symbol: 'SAR ',
      country: 'Saudi Arabia',
      currency: 'Saudi Riyal',
    ),
    _currencyOption(
      label: 'Singapore Dollar (S\$)',
      code: 'SGD',
      symbol: 'S\$',
      country: 'Singapore',
      currency: 'Singapore Dollar',
    ),
    _currencyOption(
      label: 'South Korean Won (₩)',
      code: 'KRW',
      symbol: '₩',
      country: 'South Korea',
      currency: 'South Korean Won',
    ),
    _currencyOption(
      label: 'Sri Lankan Rupee (₨)',
      code: 'LKR',
      symbol: '₨',
      country: 'Sri Lanka',
      currency: 'Sri Lankan Rupee',
    ),
    _currencyOption(
      label: 'Syrian Pound (SYP)',
      code: 'SYP',
      symbol: 'SYP ',
      country: 'Syria',
      currency: 'Syrian Pound',
    ),
    _currencyOption(
      label: 'New Taiwan Dollar (NT\$)',
      code: 'TWD',
      symbol: 'NT\$',
      country: 'Taiwan',
      currency: 'New Taiwan Dollar',
    ),
    _currencyOption(
      label: 'Tajikistani Somoni (SM)',
      code: 'TJS',
      symbol: 'SM ',
      country: 'Tajikistan',
      currency: 'Tajikistani Somoni',
    ),
    _currencyOption(
      label: 'Thai Baht (฿)',
      code: 'THB',
      symbol: '฿',
      country: 'Thailand',
      currency: 'Thai Baht',
    ),
    _currencyOption(
      label: 'Turkmenistani Manat (m)',
      code: 'TMT',
      symbol: 'm ',
      country: 'Turkmenistan',
      currency: 'Turkmenistani Manat',
    ),
    _currencyOption(
      label: 'UAE Dirham (AED)',
      code: 'AED',
      symbol: 'AED ',
      country: 'United Arab Emirates',
      currency: 'UAE Dirham',
    ),
    _currencyOption(
      label: 'Uzbekistani Som (soʻm)',
      code: 'UZS',
      symbol: 'soʻm ',
      country: 'Uzbekistan',
      currency: 'Uzbekistani Som',
    ),
    _currencyOption(
      label: 'Vietnamese Dong (₫)',
      code: 'VND',
      symbol: '₫',
      country: 'Vietnam',
      currency: 'Vietnamese Dong',
    ),
    _currencyOption(
      label: 'Yemeni Rial (YER)',
      code: 'YER',
      symbol: 'YER ',
      country: 'Yemen',
      currency: 'Yemeni Rial',
    ),
    _currencyOption(
      label: 'Albanian Lek (L)',
      code: 'ALL',
      symbol: 'L ',
      country: 'Albania',
      currency: 'Albanian Lek',
    ),
    _currencyOption(
      label: 'Bosnia and Herzegovina Convertible Mark (KM)',
      code: 'BAM',
      symbol: 'KM ',
      country: 'Bosnia and Herzegovina',
      currency: 'Convertible Mark',
    ),
    _currencyOption(
      label: 'Bulgarian Lev (лв)',
      code: 'BGN',
      symbol: 'лв ',
      country: 'Bulgaria',
      currency: 'Bulgarian Lev',
    ),
    _currencyOption(
      label: 'Czech Koruna (Kč)',
      code: 'CZK',
      symbol: 'Kč ',
      country: 'Czech Republic',
      currency: 'Czech Koruna',
    ),
    _currencyOption(
      label: 'Danish Krone (kr)',
      code: 'DKK',
      symbol: 'kr ',
      country: 'Denmark, Greenland, Faroe Islands',
      currency: 'Danish Krone',
    ),
    _currencyOption(
      label: 'Euro (€)',
      code: 'EUR',
      symbol: '€',
      country:
          'Andorra, Austria, Belgium, Croatia, Cyprus, Estonia, Finland, France, Germany, Greece, Ireland, Italy, Kosovo, Latvia, Lithuania, Luxembourg, Malta, Monaco, Montenegro, Netherlands, Portugal, San Marino, Slovakia, Slovenia, Spain, Vatican City',
      currency: 'Euro',
    ),
    _currencyOption(
      label: 'British Pound (£)',
      code: 'GBP',
      symbol: '£',
      country: 'United Kingdom',
      currency: 'British Pound',
    ),
    _currencyOption(
      label: 'Hungarian Forint (Ft)',
      code: 'HUF',
      symbol: 'Ft ',
      country: 'Hungary',
      currency: 'Hungarian Forint',
    ),
    _currencyOption(
      label: 'Icelandic Krona (kr)',
      code: 'ISK',
      symbol: 'kr ',
      country: 'Iceland',
      currency: 'Icelandic Krona',
    ),
    _currencyOption(
      label: 'Moldovan Leu (L)',
      code: 'MDL',
      symbol: 'L ',
      country: 'Moldova',
      currency: 'Moldovan Leu',
    ),
    _currencyOption(
      label: 'North Macedonian Denar (ден)',
      code: 'MKD',
      symbol: 'ден ',
      country: 'North Macedonia',
      currency: 'North Macedonian Denar',
    ),
    _currencyOption(
      label: 'Norwegian Krone (kr)',
      code: 'NOK',
      symbol: 'kr ',
      country: 'Norway',
      currency: 'Norwegian Krone',
    ),
    _currencyOption(
      label: 'Polish Zloty (zł)',
      code: 'PLN',
      symbol: 'zł ',
      country: 'Poland',
      currency: 'Polish Zloty',
    ),
    _currencyOption(
      label: 'Romanian Leu (lei)',
      code: 'RON',
      symbol: 'lei ',
      country: 'Romania',
      currency: 'Romanian Leu',
    ),
    _currencyOption(
      label: 'Serbian Dinar (дин)',
      code: 'RSD',
      symbol: 'дин ',
      country: 'Serbia',
      currency: 'Serbian Dinar',
    ),
    _currencyOption(
      label: 'Swedish Krona (kr)',
      code: 'SEK',
      symbol: 'kr ',
      country: 'Sweden',
      currency: 'Swedish Krona',
    ),
    _currencyOption(
      label: 'Swiss Franc (CHF)',
      code: 'CHF',
      symbol: 'CHF ',
      country: 'Switzerland, Liechtenstein',
      currency: 'Swiss Franc',
    ),
    _currencyOption(
      label: 'Ukrainian Hryvnia (₴)',
      code: 'UAH',
      symbol: '₴',
      country: 'Ukraine',
      currency: 'Ukrainian Hryvnia',
    ),
    _currencyOption(
      label: 'Belize Dollar (BZ\$)',
      code: 'BZD',
      symbol: 'BZ\$',
      country: 'Belize',
      currency: 'Belize Dollar',
    ),
    _currencyOption(
      label: 'Bermudian Dollar (BD\$)',
      code: 'BMD',
      symbol: 'BD\$',
      country: 'Bermuda',
      currency: 'Bermudian Dollar',
    ),
    _currencyOption(
      label: 'Bolivian Boliviano (Bs)',
      code: 'BOB',
      symbol: 'Bs ',
      country: 'Bolivia',
      currency: 'Bolivian Boliviano',
    ),
    _currencyOption(
      label: 'Brazilian Real (R\$)',
      code: 'BRL',
      symbol: 'R\$',
      country: 'Brazil',
      currency: 'Brazilian Real',
    ),
    _currencyOption(
      label: 'Canadian Dollar (C\$)',
      code: 'CAD',
      symbol: 'C\$',
      country: 'Canada',
      currency: 'Canadian Dollar',
    ),
    _currencyOption(
      label: 'Chilean Peso (CLP\$)',
      code: 'CLP',
      symbol: 'CLP\$',
      country: 'Chile',
      currency: 'Chilean Peso',
    ),
    _currencyOption(
      label: 'Colombian Peso (COL\$)',
      code: 'COP',
      symbol: 'COL\$',
      country: 'Colombia',
      currency: 'Colombian Peso',
    ),
    _currencyOption(
      label: 'Costa Rican Colon (₡)',
      code: 'CRC',
      symbol: '₡',
      country: 'Costa Rica',
      currency: 'Costa Rican Colon',
    ),
    _currencyOption(
      label: 'Cuban Peso (CUP)',
      code: 'CUP',
      symbol: 'CUP ',
      country: 'Cuba',
      currency: 'Cuban Peso',
    ),
    _currencyOption(
      label: 'Dominican Peso (RD\$)',
      code: 'DOP',
      symbol: 'RD\$',
      country: 'Dominican Republic',
      currency: 'Dominican Peso',
    ),
    _currencyOption(
      label: 'East Caribbean Dollar (EC\$)',
      code: 'XCD',
      symbol: 'EC\$',
      country:
          'Antigua and Barbuda, Dominica, Grenada, Saint Kitts and Nevis, Saint Lucia, Saint Vincent and the Grenadines',
      currency: 'East Caribbean Dollar',
    ),
    _currencyOption(
      label: 'Guatemalan Quetzal (Q)',
      code: 'GTQ',
      symbol: 'Q ',
      country: 'Guatemala',
      currency: 'Guatemalan Quetzal',
    ),
    _currencyOption(
      label: 'Guyanese Dollar (GY\$)',
      code: 'GYD',
      symbol: 'GY\$',
      country: 'Guyana',
      currency: 'Guyanese Dollar',
    ),
    _currencyOption(
      label: 'Haitian Gourde (G)',
      code: 'HTG',
      symbol: 'G ',
      country: 'Haiti',
      currency: 'Haitian Gourde',
    ),
    _currencyOption(
      label: 'Honduran Lempira (L)',
      code: 'HNL',
      symbol: 'L ',
      country: 'Honduras',
      currency: 'Honduran Lempira',
    ),
    _currencyOption(
      label: 'Jamaican Dollar (J\$)',
      code: 'JMD',
      symbol: 'J\$',
      country: 'Jamaica',
      currency: 'Jamaican Dollar',
    ),
    _currencyOption(
      label: 'Mexican Peso (MX\$)',
      code: 'MXN',
      symbol: 'MX\$',
      country: 'Mexico',
      currency: 'Mexican Peso',
    ),
    _currencyOption(
      label: 'Netherlands Antillean Guilder (ƒ)',
      code: 'ANG',
      symbol: 'ƒ ',
      country: 'Curacao, Sint Maarten',
      currency: 'Netherlands Antillean Guilder',
    ),
    _currencyOption(
      label: 'Nicaraguan Cordoba (C\$)',
      code: 'NIO',
      symbol: 'C\$ ',
      country: 'Nicaragua',
      currency: 'Nicaraguan Cordoba',
    ),
    _currencyOption(
      label: 'Panamanian Balboa (B/.)',
      code: 'PAB',
      symbol: 'B/. ',
      country: 'Panama',
      currency: 'Panamanian Balboa',
    ),
    _currencyOption(
      label: 'Paraguayan Guarani (₲)',
      code: 'PYG',
      symbol: '₲',
      country: 'Paraguay',
      currency: 'Paraguayan Guarani',
    ),
    _currencyOption(
      label: 'Peruvian Sol (S/)',
      code: 'PEN',
      symbol: 'S/ ',
      country: 'Peru',
      currency: 'Peruvian Sol',
    ),
    _currencyOption(
      label: 'Surinamese Dollar (Sr\$)',
      code: 'SRD',
      symbol: 'Sr\$ ',
      country: 'Suriname',
      currency: 'Surinamese Dollar',
    ),
    _currencyOption(
      label: 'Trinidad and Tobago Dollar (TT\$)',
      code: 'TTD',
      symbol: 'TT\$',
      country: 'Trinidad and Tobago',
      currency: 'Trinidad and Tobago Dollar',
    ),
    _currencyOption(
      label: 'US Dollar (\$)',
      code: 'USD',
      symbol: '\$',
      country:
          'United States, Ecuador, El Salvador, Micronesia, Marshall Islands, Palau, Timor-Leste, Zimbabwe',
      currency: 'US Dollar',
    ),
    _currencyOption(
      label: 'Uruguayan Peso (\$U)',
      code: 'UYU',
      symbol: '\$U ',
      country: 'Uruguay',
      currency: 'Uruguayan Peso',
    ),
    _currencyOption(
      label: 'Venezuelan Bolivar (Bs.)',
      code: 'VES',
      symbol: 'Bs. ',
      country: 'Venezuela',
      currency: 'Venezuelan Bolivar',
    ),
    _currencyOption(
      label: 'Argentine Peso (ARS\$)',
      code: 'ARS',
      symbol: 'ARS\$',
      country: 'Argentina',
      currency: 'Argentine Peso',
    ),
    _currencyOption(
      label: 'Australian Dollar (A\$)',
      code: 'AUD',
      symbol: 'A\$',
      country: 'Australia, Kiribati, Nauru, Tuvalu',
      currency: 'Australian Dollar',
    ),
    _currencyOption(
      label: 'Fijian Dollar (FJ\$)',
      code: 'FJD',
      symbol: 'FJ\$',
      country: 'Fiji',
      currency: 'Fijian Dollar',
    ),
    _currencyOption(
      label: 'New Zealand Dollar (NZ\$)',
      code: 'NZD',
      symbol: 'NZ\$',
      country: 'New Zealand, Cook Islands, Niue, Pitcairn Islands, Tokelau',
      currency: 'New Zealand Dollar',
    ),
    _currencyOption(
      label: 'Papua New Guinean Kina (K)',
      code: 'PGK',
      symbol: 'K ',
      country: 'Papua New Guinea',
      currency: 'Papua New Guinean Kina',
    ),
    _currencyOption(
      label: 'Samoan Tala (WS\$)',
      code: 'WST',
      symbol: 'WS\$ ',
      country: 'Samoa',
      currency: 'Samoan Tala',
    ),
    _currencyOption(
      label: 'Solomon Islands Dollar (SI\$)',
      code: 'SBD',
      symbol: 'SI\$',
      country: 'Solomon Islands',
      currency: 'Solomon Islands Dollar',
    ),
    _currencyOption(
      label: 'Tongan Paʻanga (T\$)',
      code: 'TOP',
      symbol: 'T\$ ',
      country: 'Tonga',
      currency: 'Tongan Paʻanga',
    ),
    _currencyOption(
      label: 'Vanuatu Vatu (VT)',
      code: 'VUV',
      symbol: 'VT ',
      country: 'Vanuatu',
      currency: 'Vanuatu Vatu',
    ),
    _currencyOption(
      label: 'CFP Franc (₣)',
      code: 'XPF',
      symbol: '₣ ',
      country: 'French Polynesia, New Caledonia, Wallis and Futuna',
      currency: 'CFP Franc',
    ),
    _currencyOption(
      label: 'Custom Currency',
      code: _customCurrencyValue,
      symbol: '',
      country: 'Custom',
      currency: 'Custom Currency',
    ),
  ];

  static final _dateFormats = [
    {'label': 'Day-Month-Year (28-06-2026)', 'pattern': 'dd-MM-yyyy'},
    {'label': 'Month-Day-Year (06-28-2026)', 'pattern': 'MM-dd-yyyy'},
    {'label': 'Year-Month-Day (2026-06-28)', 'pattern': 'yyyy-MM-dd'},
    {'label': 'Day/Month/Year (28/06/2026)', 'pattern': 'dd/MM/yyyy'},
    {'label': 'Month day, Year (Jun 28, 2026)', 'pattern': 'MMM d, yyyy'},
  ];

  @override
  void dispose() {
    _currencyDisplayController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customCurrencyCountryController.dispose();
    _customCurrencyCodeController.dispose();
    _customCurrencySymbolController.dispose();
    super.dispose();
  }

  bool _isKnownCurrencyCode(String code) {
    return _currencyOptions.any(
      (option) => option['code'] == code && code != _customCurrencyValue,
    );
  }

  Map<String, String>? _findCurrencyOption(String code) {
    for (final option in _currencyOptions) {
      if (option['code'] == code) {
        return option.map((key, value) => MapEntry(key, value));
      }
    }
    return null;
  }

  String _currentCurrencyLabel(AppSettingsProvider settings) {
    if (_useCustomCurrency) {
      final country = settings.currencyCountry.trim();
      final symbol = settings.currencySymbol.trim();
      final details = [
        if (country.isNotEmpty) country,
        settings.currencyCode,
        if (symbol.isNotEmpty) symbol,
      ];
      return details.isEmpty
          ? 'Custom Currency'
          : 'Custom Currency (${details.join(' · ')})';
    }

    final selected = _findCurrencyOption(settings.currencyCode);
    return selected?['label'] ?? settings.currencyCode;
  }

  List<Map<String, String>> _filterCurrencyOptions(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return _currencyOptions
          .map(
            (option) =>
                option.map((key, value) => MapEntry(key, value)),
          )
          .toList();
    }

    return _currencyOptions
        .map(
          (option) =>
              option.map((key, value) => MapEntry(key, value)),
        )
        .where((option) {
          final haystack = [
            option['label'],
            option['country'],
            option['currency'],
            option['code'],
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(normalizedQuery);
        })
        .toList();
  }

  Future<void> _selectCurrency(AppSettingsProvider settings) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final searchController = TextEditingController();
        var filteredOptions = _filterCurrencyOptions('');

        return StatefulBuilder(
          builder: (context, setModalState) {
            final screenHeight = MediaQuery.of(context).size.height;
            final sheetHeight = screenHeight > 700
                ? screenHeight * 0.68
                : screenHeight * 0.62;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: sheetHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Currency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search by country or currency name',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filteredOptions = _filterCurrencyOptions(value);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredOptions.isEmpty
                            ? const Center(child: Text('No currencies found'))
                            : ListView.separated(
                                itemCount: filteredOptions.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final option = filteredOptions[index];
                                  final isCustom =
                                      option['code'] == _customCurrencyValue;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(option['label'] ?? ''),
                                    subtitle: Text(
                                      isCustom
                                          ? 'Enter your own country, code and symbol'
                                          : '${option['country']} • ${option['code']}',
                                    ),
                                    trailing: isCustom
                                        ? const Icon(Icons.edit_outlined)
                                        : null,
                                    onTap: () =>
                                        Navigator.of(context).pop(option),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    if (result['code'] == _customCurrencyValue) {
      setState(() {
        _useCustomCurrency = true;
        _customCurrencyCountryController.text =
            _isKnownCurrencyCode(settings.currencyCode)
            ? ''
            : settings.currencyCountry.trim();
        _customCurrencyCodeController.text =
            _isKnownCurrencyCode(settings.currencyCode)
            ? ''
            : settings.currencyCode;
        _customCurrencySymbolController.text =
            _isKnownCurrencyCode(settings.currencyCode)
            ? ''
            : settings.currencySymbol.trim();
      });
      return;
    }

    setState(() {
      _useCustomCurrency = false;
    });
    await context.read<AppSettingsProvider>().setCurrency(
      country: result['country'] ?? '',
      code: result['code'] ?? '',
      symbol: result['symbol'] ?? '',
    );
  }

  Future<void> _saveCustomCurrency() async {
    final code = _customCurrencyCodeController.text.trim().toUpperCase();
    final symbol = _customCurrencySymbolController.text.trim();
    final country = _customCurrencyCountryController.text.trim();

    if (country.isEmpty || code.isEmpty || symbol.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter country, currency code and symbol'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    await context.read<AppSettingsProvider>().setCurrency(
      country: country,
      code: code,
      symbol: symbol,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Custom currency saved')));
  }

  Future<void> _savePasswordSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final settings = context.read<AppSettingsProvider>();

    if (!_enableLock) {
      await settings.clearPassword();
      if (!mounted) return;
      setState(() {
        _enableLock = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('App lock disabled')));
      return;
    }

    await settings.setPassword(_passwordController.text.trim());
    if (!mounted) return;
    setState(() {
      _enableLock = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password saved. App locked.')),
    );
  }

  Future<void> _backupDatabase(String providerName) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final suggestedName =
          'debt_book_${providerName.toLowerCase()}_$timestamp.db';

      final directoryPath = await getDirectoryPath(
        confirmButtonText: 'Choose Folder',
      );

      if (directoryPath == null || directoryPath.isEmpty) {
        return;
      }

      final targetPath = p.join(directoryPath, suggestedName);
      final savedPath = await DatabaseHelper.instance.backupDatabaseToFile(
        targetPath,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$providerName backup saved to $savedPath')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$providerName backup failed: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _restoreDatabase(String providerName) async {
    final messenger = ScaffoldMessenger.of(context);
    final debtProvider = context.read<DebtProvider>();
    try {
      final typeGroup = XTypeGroup(
        label: 'Database backups',
        extensions: const ['db'],
      );
      final source = await openFile(
        acceptedTypeGroups: [typeGroup],
        confirmButtonText: 'Select Backup',
      );

      final sourcePath = source?.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        return;
      }

      await DatabaseHelper.instance.restoreDatabaseFromFile(sourcePath);
      await debtProvider.loadAllData();

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$providerName backup restored successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$providerName restore failed: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    if (settings.initialized && !_lockStateInitialized) {
      _enableLock = settings.lockEnabled;
      _lockStateInitialized = true;
    }
    if (settings.initialized && !_currencyStateInitialized) {
      _useCustomCurrency = !_isKnownCurrencyCode(settings.currencyCode);
      if (_useCustomCurrency) {
        _customCurrencyCountryController.text = settings.currencyCountry;
        _customCurrencyCodeController.text = settings.currencyCode;
        _customCurrencySymbolController.text = settings.currencySymbol.trim();
      }
      _currencyStateInitialized = true;
    }
    _currencyDisplayController.text = _currentCurrencyLabel(settings);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Localization'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _currencyDisplayController,
                    readOnly: true,
                    onTap: () => _selectCurrency(settings),
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      hintText: 'Search by country or currency name',
                      prefixIcon: Icon(Icons.payments_outlined, size: 20),
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                  if (_useCustomCurrency) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customCurrencyCountryController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Country Name',
                        hintText: 'e.g. Nepal',
                        prefixIcon: Icon(Icons.public_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customCurrencyCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Custom Currency Code',
                        hintText: 'e.g. NPR',
                        prefixIcon: Icon(Icons.tag_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customCurrencySymbolController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Currency Symbol',
                        hintText: 'e.g. Rs',
                        prefixIcon: Icon(
                          Icons.alternate_email_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _saveCustomCurrency,
                        child: const Text('Save Custom Currency'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Date Format',
                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                    ),
                    initialValue: settings.dateFormatPattern,
                    items: _dateFormats
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt['pattern'] as String,
                            child: Text(opt['label'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      context.read<AppSettingsProvider>().setDateFormat(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Security'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Enable App Lock',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Require password to open app'),
                      value: _enableLock,
                      onChanged: (value) async {
                        setState(() => _enableLock = value);
                        if (!value && settings.hasPassword) {
                          await context
                              .read<AppSettingsProvider>()
                              .clearPassword();
                        }
                      },
                    ),
                    if (_enableLock) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.lock_outline, size: 20),
                        ),
                        validator: (v) =>
                            _enableLock && (v == null || v.isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
                        ),
                        validator: (v) =>
                            _enableLock && v != _passwordController.text
                            ? 'No match'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _savePasswordSettings,
                          child: Text(
                            settings.hasPassword
                                ? 'Update Password'
                                : 'Save Password',
                          ),
                        ),
                      ),
                      if (settings.hasPassword) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                context.read<AppSettingsProvider>().lockApp(),
                            child: const Text('Lock App Now'),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Backup & Restore'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _cloudProviderRow(
                    'Google Drive',
                    Icons.cloud_outlined,
                    Colors.blue,
                    () => _backupDatabase('Google Drive'),
                    () => _restoreDatabase('Google Drive'),
                  ),
                  const Divider(height: 32),
                  _cloudProviderRow(
                    'OneDrive',
                    Icons.cloud_done_outlined,
                    Colors.indigo,
                    () => _backupDatabase('OneDrive'),
                    () => _restoreDatabase('OneDrive'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _cloudProviderRow(
    String title,
    IconData icon,
    Color color,
    VoidCallback onBackup,
    VoidCallback onRestore,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBackup,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Backup'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                label: const Text('Restore'),
              ),
            ),
          ],
        ),
      ],
    );
  }
} // class
