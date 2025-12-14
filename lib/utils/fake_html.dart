// Bu dosya sadece Android/iOS derlemesi hata vermesin diye var.
// İçindeki kodlar mobilde asla çalışmayacak, sadece derleyiciyi kandıracak.

class Blob {
  Blob(List<dynamic> blobParts);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => "";
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({required String href});
  String? href;
  String? download;
  
  void click() {}
  void setAttribute(String name, String value) {}
}