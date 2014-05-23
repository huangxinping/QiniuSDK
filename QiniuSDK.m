//
//  QiniuSDK.m
//  QiniuSample
//
//  Created by huangxp on 13-8-28.
//  Copyright (c) 2013年 hxp. All rights reserved.
//

#import "QiniuSDK.h"
#import "GTMBase64.h"

@interface QiniuSDK ()
@property (nonatomic, SM_PROPERTY_COPY) QiniuUploadCompletionBlock uploadCompletionBlock;
@property (nonatomic, SM_PROPERTY_COPY) QiniuDownloadCompletionBlock downloadCompletionBlock;
@end

SINGLETON_FOR_CLASS(QiniuSDK)
@implementation QiniuSDK
SINGLETON_FOR_FUNCTION(QiniuSDK)

- (void)dealloc {
	SM_RELEASE(_bucketName);
	SM_RELEASE(_accessKey);
	SM_RELEASE(_secretKey);
	SM_RELEASE(_uploadCompletionBlock);
	SM_RELEASE(_downloadCompletionBlock);
	SM_SUPER_DEALLOC();
}

#pragma mark – 上传
- (NSString *)marshal {
	time_t deadline;
	time(&deadline);
	deadline += 60 * 60 * 24 * 30; // token有效期为30天
	NSNumber *deadlineNumber = [NSNumber numberWithLongLong:deadline];
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	if (self.bucketName) {
		[dic setObject:self.bucketName forKey:@"scope"];
	}
//    if (self.callbackUrl)
//    {
//        [dic setObject:self.callbackUrl forKey:@"callbackUrl"];
//    }
//    if (self.callbackBody)
//    {
//        [dic setObject:self.callbackBody forKey:@"callbackBody"];
//    }
//    if (self.returnUrl)
//    {
//        [dic setObject:self.returnUrl forKey:@"returnUrl"];
//    }
//    if (self.returnBody)
//    {
//        [dic setObject:self.returnBody forKey:@"returnBody"];
//    }
//    if (self.endUser)
//    {
//        [dic setObject:self.endUser forKey:@"endUser"];
//    }
	[dic setObject:deadlineNumber forKey:@"deadline"];
	NSString *json = [dic JSONObject];
	return json;
}

- (NSString *)mergeToken {
	if (!self.bucketName ||
	    !self.secretKey ||
	    !self.accessKey ||
	    [self.bucketName isEmpty] ||
	    [self.secretKey isEmpty] ||
	    [self.accessKey isEmpty]) {
		return nil;
	}
    
	NSString *policy = [self marshal];
	NSData *policyData = [policy dataUsingEncoding:NSUTF8StringEncoding];
	NSString *encodedPolicy = [GTMBase64 stringByWebSafeEncodingData:policyData padded:TRUE];
	const char *encodedPolicyStr = [encodedPolicy cStringUsingEncoding:NSUTF8StringEncoding];
    
	char digestStr[CC_SHA1_DIGEST_LENGTH];
	bzero(digestStr, 0);
	const char *secretKeyStr = [_secretKey UTF8String];
	CCHmac(kCCHmacAlgSHA1, secretKeyStr, strlen(secretKeyStr), encodedPolicyStr, strlen(encodedPolicyStr), digestStr);
	NSString *encodedDigest = [GTMBase64 stringByWebSafeEncodingBytes:digestStr length:CC_SHA1_DIGEST_LENGTH padded:TRUE];
    
	NSString *token = [NSString stringWithFormat:@"%@:%@:%@",  _accessKey, encodedDigest, encodedPolicy];
	return token;
}

- (void)uploadWithFileData:(NSData *)data fileID:(NSString *)fileID {
	NSString *token = [self mergeToken];
	if (!token) {
		return;
	}
    
	[SMBlockRequestInstance makeRequest:REQUEST_POST urlBuffer:@"http://up.qiniu.com" useCache:NO timeOut:60 parametersBlock: ^NSDictionary *{
	    return @{ @"key": fileID,
	              @"token":token,
	              @"file":data };
	} startBlock:nil stopBlock: ^(id object) {
	    if ([object isKindOfClass:[NSString class]]) {
	        self.uploadCompletionBlock([object JSONValue], fileID);
		}
	} cancelRetryBlock:nil];
}

- (void)didUploadCompletionBlock:(QiniuUploadCompletionBlock)block {
	self.uploadCompletionBlock = block;
}

#pragma mark – 下载
- (NSString *)mergeDownloadUri:(NSString *)fileID {
	if (!self.bucketName ||
	    !self.secretKey ||
	    !self.accessKey ||
	    [self.bucketName isEmpty] ||
	    [self.secretKey isEmpty] ||
	    [self.accessKey isEmpty]) {
		return nil;
	}
	time_t deadline;
	time(&deadline);
	deadline += 60 * 60 * 24 * 30; // token有效期为30天
	NSNumber *deadlineNumber = [NSNumber numberWithLongLong:deadline];
	NSString *url = [NSString stringWithFormat:@"http://%@.qiniudn.com/%@?e=%@", _bucketName, fileID, deadlineNumber];
	char digestStr[CC_SHA1_DIGEST_LENGTH];
	bzero(digestStr, 0);
	const char *secretKeyStr = [_secretKey UTF8String];
	const char *sourceStr = [url UTF8String];
	CCHmac(kCCHmacAlgSHA1, secretKeyStr, strlen(secretKeyStr), sourceStr, strlen(sourceStr), digestStr);
	NSString *encodedDigest = [GTMBase64 stringByWebSafeEncodingBytes:digestStr length:CC_SHA1_DIGEST_LENGTH padded:TRUE];
	NSString *downloadToken = [NSString stringWithFormat:@"%@:%@", _accessKey, encodedDigest];
	NSString *downloadURL = [NSString stringWithFormat:@"http://%@.qiniudn.com/%@?e=%@&token=%@", _bucketName, fileID, deadlineNumber, downloadToken];
	return downloadURL;
}

- (void)downloadWithFileID:(NSString *)fileID {
	NSString *downloadURL = [self mergeDownloadUri:fileID];
	if (!downloadURL) {
		return;
	}
	SM_BLOCK_RETAIN_CIRCLE typeof(self) weakSelf = self;
    
	[SMBlockRequestInstance makeRequest:REQUEST_GET urlBuffer:downloadURL useCache:NO timeOut:60 parametersBlock:nil startBlock:nil stopBlock: ^(id object) {
	    if ([object isKindOfClass:[NSData class]]) {
	        weakSelf.downloadCompletionBlock(object, fileID);
		}
	} cancelRetryBlock:nil];
}

- (void)didDownloadCompletionBlock:(QiniuDownloadCompletionBlock)block {
	self.downloadCompletionBlock = block;
}

@end
