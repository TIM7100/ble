//
//  NSString+Additions.m
//  MLIPhone
//
//  Created by yakehuang on 5/7/14.
//
//

#import "NSString+Additions.h"
#import "BaseDefinition.h"
#import <CommonCrypto/CommonDigest.h>
//#import "UserManager.h"

@implementation NSString (Additions)

/*
 URL 字符串 里面可能包含某些字符，比如‘$‘ ‘&’ ‘？’...等，这些字符在 URL 语法中是具有特殊语法含义的，
 比如 URL ：http://www.baidu.com/s?wd=%BD%AA%C3%C8%D1%BF&rsv_bp=0&rsv_spt=3&inputT=3512
 中 的 & 起到分割作用 等等，如果 你提供的URL 本身就含有 这些字符，就需要把这些字符 转化为 “%+ASCII” 形式，以免造成冲突
 */
+ (NSString *)urlEscape:(NSString *)unencodedString {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)unencodedString,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 kCFStringEncodingUTF8));
}

/*
 作用同上一个函数相反
 */
+ (NSString *)urlUnescape: (NSString *) input
{
	return (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                 (CFStringRef)input,
                                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                                 kCFStringEncodingUTF8));
}

// 把传入的参数按照get的方式打包到url后面。
+ (NSString *)addQueryStringToUrl:(NSString *)url params:(NSDictionary *)params
{
    if (nil == url) {
        return @"";
    }
#ifdef  DEBUG
//    NSString *localStr = [self getlocalURLTitle:url];
//    NSString *updateStr = [self getlocalURLTitle:[[ConfigManage sharedConfig] getURLStringWithAliasName:@"getIndex"]];
//    if (!localStr) {
//        
//    } else if (![localStr isEqualToString:updateStr] && [url rangeOfString:@"config"].length < 1) {
//        url = [url substringFromIndex:localStr.length];
//        url = [updateStr stringByAppendingString:url];
//    }
#endif
    
	NSMutableString *urlWithQuerystring = [[NSMutableString alloc] initWithString:url];

    
    
	// Convert the params into a query string
	if (params) {
		for(id key in params) {
			NSString *sKey = [key description];
			NSString *sVal = [[params objectForKey:key] description];
			//是否有？，必须处理这个
			if ([urlWithQuerystring rangeOfString:@"?"].location==NSNotFound) {
				[urlWithQuerystring appendFormat:@"?%@=%@", [NSString urlEscape:sKey], [NSString urlEscape:sVal]];
			} else {
				[urlWithQuerystring appendFormat:@"&%@=%@", [NSString urlEscape:sKey], [NSString urlEscape:sVal]];
			}
		}
	}
    
	return urlWithQuerystring;
}

// 返回md5加密后的字符串
- (NSString *)stringFromMD5
{
    if(self == nil || [self length] == 0)
        return nil;
    
    const char *value = [self UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    unsigned char x = strlen(value);
    CC_MD5(value,x, outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    return outputString;
}

- (BOOL)isEmpty
{
    if (!self || [self isEqualToString:@""]) {
        return YES;
    }
    return NO;
}

- (NSDictionary *)urlParam
{
    //去除空格
    NSMutableString *mStr = [self mutableCopy];
    CFStringTrimWhitespace((CFMutableStringRef)mStr);
    
    NSArray *tempArray = [self componentsSeparatedByString:@"?"];
    if (tempArray.count ==2) {
        NSArray *tempArray2 = [tempArray[1] componentsSeparatedByString:@"&"];
        NSMutableDictionary *mutableDic = [@{} mutableCopy];
        [tempArray2 enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
            NSArray *dicArray = [str componentsSeparatedByString:@"="];
            if (dicArray.count == 2) {
                mutableDic[dicArray[0]] = dicArray[1];
                MLDLog(@"%@",mutableDic);
            }
        }];
        return mutableDic;
    }
    return nil;
}

- (NSDictionary *)messageShortUrlParam
{
    NSMutableString *mStr = [self mutableCopy];
    CFStringTrimWhitespace((CFMutableStringRef)mStr);
    
    NSArray *tempArray = [self componentsSeparatedByString:@"?"];
    if (tempArray.count >=2) {
        NSArray *tempArray2 = [tempArray[1] componentsSeparatedByString:@"&"];
        NSMutableDictionary *mutableDic = [@{} mutableCopy];
        [tempArray2 enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
            NSArray *dicArray = [str componentsSeparatedByString:@"="];
            if (dicArray.count == 2) {
                if ([dicArray[0] isEqualToString:@"url"]) {
                    NSRange range = [mStr rangeOfString:dicArray[1]];
                    mutableDic[dicArray[0]] = [mStr substringFromIndex:range.location];
                    *stop = YES;
                } else {
                    mutableDic[dicArray[0]] = dicArray[1];
                }
                
                MLDLog(@"%@",mutableDic);
            }
        }];
        return mutableDic;
    }
    return nil;
}

+ (id)deserializeMessageJSON:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

@end
