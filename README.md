QiniuSDK
========

七牛SDK，个人专用，需要链接底层库，请勿下载。


使用方法：

API key
-----------
* NSString *QiniuAccessKey = @"DTGpvlJkMBNhxOGLst3fNEVOjcAYmgjybbD1pdDt";
* NSString *QiniuSecretKey = @"xvTxqs8bSYFUNFpD6kU5Yt9H1vaX8cu_eS3wij8U";
* NSString *QiniuBucketName = @"meijia";


代码
------------
	[QiniuSDK sharedInstance].bucketName = QiniuBucketName;
	[QiniuSDK sharedInstance].secretKey = QiniuSecretKey;
	[QiniuSDK sharedInstance].accessKey = QiniuAccessKey;
	
	[[QiniuSDK sharedInstance] uploadWithFileData:fontData fileID:fileName];
	[[QiniuSDK sharedInstance] didUploadCompletionBlock: ^(NSDictionary 	*dictionary, NSString *fileID) {

	}];
