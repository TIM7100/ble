//
//  NSString+Additions.h
//  MLIPhone
//
//  Created by yakehuang on 5/7/14.
//
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

+ (NSString *)urlEscape:(NSString *)unencodedString;
+ (NSString *)urlUnescape: (NSString *) input;
+ (NSString *)addQueryStringToUrl:(NSString *)url params:(NSDictionary *)params;

- (NSString *)stringFromMD5;

//判空
- (BOOL)isEmpty;

//获取连接参数
- (NSDictionary *)urlParam;

//针对短信跳转的短链接获取参数
- (NSDictionary *)messageShortUrlParam;

//json解析
+ (id)deserializeMessageJSON:(NSString *)messageJSON;


@end
