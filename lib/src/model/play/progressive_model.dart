class ProgressiveModel {
  String? type;
  String? codec;
  num? width;
  num? height;
  String? linkExpirationTime;
  String? link;
  String? createdTime;
  num? fps;
  num? size;
  String? md5;
  String? rendition;
  num? qualityInt;

  ProgressiveModel({
    this.type,
    this.codec,
    this.width,
    this.height,
    this.linkExpirationTime,
    this.link,
    this.createdTime,
    this.fps,
    this.size,
    this.md5,
    this.rendition,
    this.qualityInt
  });

  ProgressiveModel.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    codec = json['codec'];
    width = json['width'];
    height = json['height'];
    linkExpirationTime = json['link_expiration_time'];
    link = json['link'];
    createdTime = json['created_time'];
    fps = json['fps'];
    size = json['size'];
    md5 = json['md5'];
    rendition = json['rendition'];
    int lastIndex = rendition?.lastIndexOf("p") ?? 0;
    try{
    String qualitySubstring = rendition?.substring(0, lastIndex) ?? '';
     qualityInt = int.tryParse(qualitySubstring);
    }catch(e){
      print('string error');
      print(e);
      print(rendition);
    }
   
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['codec'] = codec;
    data['width'] = width;
    data['height'] = height;
    data['link_expiration_time'] = linkExpirationTime;
    data['link'] = link;
    data['created_time'] = createdTime;
    data['fps'] = fps;
    data['size'] = size;
    data['md5'] = md5;
    data['rendition'] = rendition;
    return data;
  }
}
