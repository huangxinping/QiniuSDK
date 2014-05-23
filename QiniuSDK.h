//
//  QiniuSDK.h
//  QiniuSample
//
//  Created by huangxp on 13-8-28.
//  Copyright (c) 2013年 hxp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^QiniuUploadCompletionBlock)(NSDictionary *dictionary,NSString *fileID);
typedef void (^QiniuDownloadCompletionBlock)(NSData *data,NSString *fileID);

@interface QiniuSDK : NSObject

// 空间名称
@property(nonatomic,SM_PROPERTY_RETAIN)NSString *bucketName;

// 通道key
@property(nonatomic,SM_PROPERTY_RETAIN)NSString *accessKey;

// 密钥key
@property(nonatomic,SM_PROPERTY_RETAIN)NSString *secretKey;

SINGLETON_FOR_HEADER(QiniuSDK)

#pragma mark – 下载模块

// 私有资源根据fileID、bucketName、accessKey、secretKey合成下载链接
- (NSString*)mergeDownloadUri:(NSString*)fileID;

// 下载资源
- (void)downloadWithFileID:(NSString*)fileID;

// 设置下载完成block
- (void)didDownloadCompletionBlock:(QiniuDownloadCompletionBlock)block;

#pragma mark – 上传模块
- (void)uploadWithFileData:(NSData*)data fileID:(NSString*)fileID;

// 设置上传完成block
- (void)didUploadCompletionBlock:(QiniuUploadCompletionBlock)block; 

@end
