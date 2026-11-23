class HttpUrls {
  HttpUrls._();

  static const String articles = '/articles/';
  static String articleById(int id) => '/articles/$id/';
}
