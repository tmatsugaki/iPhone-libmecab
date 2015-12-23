//
//  FileUtil.m
//  Yardbird
//
//  Created by matsu on 10/11/12.
//  Copyright 2010 家事手伝い. All rights reserved.
//

#import <MobileCoreServices/UTType.h>
#import "FileUtil.h"
#import "NSString+TM.h"

@implementation FileUtil

+ (NSString *) localDocumentsDirectory {
    
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

// ドキュメントルートはドキュメントの親ディレクトリ
//+ (NSString *) cachedDocumentRoot {
//    
//    NSString *documentRoot = nil;
//    
//    if ([FileUtil fileExistsAtPath:kCachedDocumentPath] == NO) {
//        [FileUtil createDirectoryAtPath:kCachedDocumentPath];
//    }
//    if ([FileUtil fileExistsAtPath:kCachedDocumentPath]) {
//        documentRoot = kCachedDocumentPath;
//    }
//    return documentRoot;
//}

+ (BOOL) isEqualToPath:(NSString *)srcPath toPath:(NSString *)toPath {
	return [srcPath isEqualToString:toPath];
}

+ (long long) freeDiskSize {
    
    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:kDocumentPath error:nil];
    NSNumber *sizeObj = (NSNumber *) [dict valueForKey:@"NSFileSystemFreeSize"];
    return sizeObj.longLongValue;
}

//ファイル一覧の取得(1パスコンポーネントのアレイを返す)
+ (NSArray *)contentsOfDirectoryAtPath:(NSString *)path {
	NSError *error = nil;
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
}

//ファイルスペック一覧の取得
+ (NSArray *)fileSpecs:(NSString *)dir {

    DEBUG_LOG(@"%s ### dir:[%@]", __func__, dir);

    NSString *rootDir = nil;
    NSString *folderName = nil;

    if ([dir hasPrefix:kCachedDocumentPath]) {
        rootDir = kCachedDocumentRoot;
        folderName = @"Documents";
    } else if ([dir hasPrefix:kCachedWorkPath]) {
        rootDir = kCachedDocumentRoot;
        folderName = @"work";
    } else if ([dir hasPrefix:kCachedXMLPath]) {
        rootDir = kCachedDocumentRoot;
        folderName = @"xml";
    } else if ([dir hasPrefix:k_iCloudDocumentPath]) {
        rootDir = kCachedDocumentRoot;
        folderName = @"iCloud";
    } else if ([dir hasPrefix:kHinshiMasterUbiquityCotainerPath]) {
        rootDir = [kHinshiMasterUbiquityCotainerPath stringByDeletingLastPathComponent];
        folderName = [kHinshiMasterUbiquityCotainerPath lastPathComponent];
    } else {
        rootDir = kDocumentRoot;
        folderName = @"Documents";
    }
	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = nil;
	if ([dir isAbsolutePath])
	{// dir を Documents からの相対パスに変換する。
		path = dir;
		if ([[path lastPathComponent] isEqualToString:folderName]) {
			dir = @"";
		} else {
			NSRange range = [path length] ? [path rangeOfString:[folderName stringByAppendingString:@"/"]] : NSMakeRange(NSNotFound, 0);
			dir = [path substringFromIndex:range.location + range.length];
		}
		DEBUG_LOG(@"%s *** Absolute dir:[%@]", __func__, dir);
		DEBUG_LOG(@"%s *** Absolute path:[%@]", __func__, path);
	} else
	{// dir は Documents からの相対パスである。
		path = [rootDir stringByAppendingPathComponent:folderName];
		path = [path stringByAppendingPathComponent:dir]; 
		DEBUG_LOG(@"%s Relative dir:[%@]", __func__, dir);
		DEBUG_LOG(@"%s Relative path:[%@]", __func__, path);
	}
	NSError *error = nil;
	NSArray *array = [fileManager contentsOfDirectoryAtPath:path error:&error];
	NSMutableArray *a_files     = [[NSMutableArray alloc] init]; // Keys  :[path lastPathComponent]
	NSMutableArray *a_fileSpecs = [[NSMutableArray alloc] init]; // Values:FileSpec
	// ファイルを抽出して連想配列作成用アレイに格納する。
	for (NSString *fn in array) {
		path = [rootDir stringByAppendingPathComponent:folderName];
		path = [path stringByAppendingPathComponent:dir];
//		NSString *dirPath = path;
		path = [path stringByAppendingPathComponent:fn];
		error = nil;
		NSDictionary *attr = [fileManager attributesOfItemAtPath:path error:&error];
		NSString *fileType = (NSString *) [attr fileType];
		if ([fileType isEqualToString:NSFileTypeRegular])
		{// 【注意】普通のファイルである。
			FileSpec *a_fileSpec = [[FileSpec alloc] init];
			a_fileSpec.path             = path;
			a_fileSpec.dir              = [path stringByDeletingLastPathComponent]; // dirPath
			a_fileSpec.isSymbolicLink   = NO;
			a_fileSpec.fileName         = fn;
            a_fileSpec.extension        = [fn pathExtension];
			a_fileSpec.creationDate     = (NSDate *) [attr fileCreationDate];
			a_fileSpec.modificationDate = (NSDate *) [attr fileModificationDate];
			a_fileSpec.contentLength    = [attr fileSize];
			// シンボリックリンクのアレイを初期化する。
			a_fileSpec.symbols = [[NSMutableArray alloc] init];
			[a_fileSpecs addObject:a_fileSpec];
			[a_files addObject:a_fileSpec.fileName];
		}
	}
	NSDictionary *fileDic = [NSDictionary dictionaryWithObjects:a_fileSpecs forKeys:a_files];

	// シンボルを抽出してアレイに格納する。
	for (NSString *fn in array) {
		path = [rootDir stringByAppendingPathComponent:folderName];
		path = [path stringByAppendingPathComponent:dir];
		path = [path stringByAppendingPathComponent:fn];
		error = nil;
		NSDictionary *attr = [fileManager attributesOfItemAtPath:path error:&error];
		NSString *fileType = (NSString *) [attr fileType];
		if ([fileType isEqualToString:NSFileTypeSymbolicLink])
		{// シンボリックリンクである。
			error = nil;
			NSString *destPath = [fileManager destinationOfSymbolicLinkAtPath:path error:&error];
			FileSpec *fileSpec = [fileDic objectForKey:[destPath lastPathComponent]];
			if (fileSpec) {
				[fileSpec.symbols addObject:[path lastPathComponent]];
			}
		}
	}
	return a_fileSpecs;
}

//ファイルスペック一覧の取得
+ (NSArray *)dirFileSpecs:(NSString *)dir {

//    DEBUG_LOG(@"%s ### dir:[%@]", __func__, dir);
    
    NSString *rootDir = nil;
    NSString *folderName = nil;

    if ([dir hasPrefix:kCachedDocumentPath]) {
        rootDir = kCachedDocumentRoot;
        folderName = @"Documents";
    } else if ([dir hasPrefix:kCachedWorkPath]) {
        rootDir = kCachedDocumentRoot;
        folderName = @"work";
    } else if ([dir hasPrefix:kCachedXMLPath]) {
        rootDir = kCachedDocumentRoot;
        folderName = @"xml";
    } else if ([dir hasPrefix:k_iCloudDocumentPath]) {
        rootDir = kCachedDocumentRoot;
        folderName = @"iCloud";
    } else if ([dir hasPrefix:kHinshiMasterUbiquityCotainerPath]) {
        rootDir = [kHinshiMasterUbiquityCotainerPath stringByDeletingLastPathComponent];
        folderName = [kHinshiMasterUbiquityCotainerPath lastPathComponent];
    } else {
        rootDir = kDocumentRoot;
        folderName = @"Documents";
    }

	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = nil;
	if ([dir isAbsolutePath])
	{// dir を Documents からの相対パスに変換する。
		path = dir;
		if ([[path lastPathComponent] isEqualToString:folderName]) {
			dir = @"";
		} else {
			NSRange range = [path length] ? [path rangeOfString:[folderName stringByAppendingString:@"/"]] : NSMakeRange(NSNotFound, 0);
			dir = [path substringFromIndex:range.location + range.length];
		}
//		DEBUG_LOG(@"%s *** Absolute dir:[%@]", __func__, dir);
//		DEBUG_LOG(@"%s *** Absolute path:[%@]", __func__, path);
	} else
	{// dir は Documents からの相対パスである
		path = [rootDir stringByAppendingPathComponent:folderName];
		path = [path stringByAppendingPathComponent:dir]; 
//		DEBUG_LOG(@"%s Relative dir:[%@]", __func__, dir);
//		DEBUG_LOG(@"%s Relative path:[%@]", __func__, path);
	}
	
	NSError *error = nil;
	NSArray *array = [fileManager contentsOfDirectoryAtPath:path error:&error];
	NSMutableArray *a_files     = [[NSMutableArray alloc] init]; // Keys  :[path lastPathComponent]
	NSMutableArray *a_fileSpecs = [[NSMutableArray alloc] init]; // Values:FileSpec
	// ファイルを抽出して連想配列作成用アレイに格納する。
	for (NSString *fn in array) {
		path = [rootDir stringByAppendingPathComponent:folderName];
		path = [path stringByAppendingPathComponent:dir];
//		NSString *dirPath = path;
		path = [path stringByAppendingPathComponent:fn];
		error = nil;
		NSDictionary *attr = [fileManager attributesOfItemAtPath:path error:&error];
		NSString *fileType = (NSString *) [attr fileType];
		if ([fileType isEqualToString:NSFileTypeRegular]
         || [fileType isEqualToString:NSFileTypeSymbolicLink])
		{// 【注意】普通のファイルかシンボリックリンクである。
			FileSpec *a_fileSpec = [[FileSpec alloc] init];
			a_fileSpec.path             = path;
			a_fileSpec.dir              = [path stringByDeletingLastPathComponent]; // dirPath
			a_fileSpec.fileName         = fn;
            a_fileSpec.extension        = [fn pathExtension];
//			if ([a_fileSpec.fileName isEqualToString:@"進捗.opml"]) {
//				DEBUG_LOG(@"[%@]", attr);
//			}
			a_fileSpec.isDir            = NO;
			a_fileSpec.isSymbolicLink   = [fileType isEqualToString:NSFileTypeSymbolicLink];
			a_fileSpec.creationDate     = (NSDate *) [attr fileCreationDate];
			a_fileSpec.modificationDate = (NSDate *) [attr fileModificationDate];
			a_fileSpec.contentLength    = [attr fileSize];
			// シンボリックリンクのアレイを初期化する。
			a_fileSpec.symbols = [[NSMutableArray alloc] init];
			[a_fileSpecs addObject:a_fileSpec];
			[a_files addObject:a_fileSpec.fileName];
		} else if ([fileType isEqualToString:NSFileTypeDirectory])
		{// ディレクトリである。
			FileSpec *a_fileSpec = [[FileSpec alloc] init];
			a_fileSpec.path             = path;
			a_fileSpec.dir              = [path stringByDeletingLastPathComponent]; // dirPath
			a_fileSpec.fileName         = [fn stringByAppendingPathComponent:@""]; // @""; // 長さ0の場合はディレクトリ @""
            a_fileSpec.extension        = @"0";
			a_fileSpec.isDir            = YES;
			a_fileSpec.isSymbolicLink   = NO;
			a_fileSpec.creationDate     = (NSDate *) [attr fileCreationDate];
			a_fileSpec.modificationDate = (NSDate *) [attr fileModificationDate];
			a_fileSpec.contentLength    = 0;
			// シンボリックリンクのアレイを初期化する。
			a_fileSpec.symbols = [[NSMutableArray alloc] init];
			[a_fileSpecs addObject:a_fileSpec];
			[a_files addObject:a_fileSpec.fileName];
		}
	}
	NSDictionary *fileDic = [NSDictionary dictionaryWithObjects:a_fileSpecs forKeys:a_files];
	
	// シンボルを抽出してアレイに格納する。
	for (NSString *fn in array) {
		path = [rootDir stringByAppendingPathComponent:folderName];
		path = [path stringByAppendingPathComponent:dir];
		path = [path stringByAppendingPathComponent:fn];
		error = nil;
		NSDictionary *attr = [fileManager attributesOfItemAtPath:path error:&error];
		NSString *fileType = (NSString *) [attr fileType];
		if ([fileType isEqualToString:NSFileTypeSymbolicLink])
		{// シンボリックリンクである。
			error = nil;
			NSString *destPath = [fileManager destinationOfSymbolicLinkAtPath:path error:&error];
			FileSpec *fileSpec = [fileDic objectForKey:[destPath lastPathComponent]];
			if (fileSpec) {
				[fileSpec.symbols addObject:[path lastPathComponent]];
			}
		}
	}
	return a_fileSpecs;
}

//ファイル・ディレクトリが存在するか
+ (BOOL)fileExistsAtPath:(NSString *)path {
	return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)fileExistsAtPath:(NSString *)path
			 isDirectory:(BOOL *)isDirectory {

	return [[NSFileManager defaultManager] fileExistsAtPath:path
												isDirectory:isDirectory];
}

//ファイル・ディレクトリのサイズ
+ (unsigned long long)fileSize:(NSString *)path {
	NSError *error = nil;
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path
																		  error:&error];
	return (unsigned long long) [attr fileSize];
}

//ファイル・ディレクトリの作成日時
+ (NSDate *)creationDate:(NSString *)path {
	NSError *error = nil;
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path
																		  error:&error];
	return (NSDate *) [attr fileCreationDate];
}

+ (BOOL)setCreationDate:(NSString *)path
				creDate:(NSDate *)creDate {
	NSError *error = nil;
	BOOL ret = NO;
	NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:path
																															   error:&error]];
//	DEBUG_LOG(@"%s %@", __func__, [attr objectForKey:NSFileCreationDate]);
	if (error == nil) {
		@try {
			DEBUG_LOG(@"%s %@ --> %@", __func__, [attr objectForKey:NSFileCreationDate], creDate);
			[attr setObject:creDate forKey:NSFileCreationDate];
			ret = [[NSFileManager defaultManager] setAttributes:attr
												   ofItemAtPath:path
														  error:&error];
		}
		@catch (NSException *exception) {
			DEBUG_LOG(@"!!! Failed %s %@", __func__, [attr objectForKey:NSFileCreationDate]);
		}
	}
	attr = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:path
																										  error:nil]];
	DEBUG_LOG(@"%s [%@]!!", __func__, [attr objectForKey:NSFileCreationDate]);
	return (ret && [[attr objectForKey:NSFileCreationDate] isEqualToDate:creDate]);
}

//ファイル・ディレクトリの修正日時
+ (NSDate *)modificationDate:(NSString *)path {
	NSError *error = nil;
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path
																		  error:&error];
	return (NSDate *) [attr fileModificationDate];
}

+ (BOOL)setModificationDate:(NSString *)path
					modDate:(NSDate *)modDate {
	NSError *error = nil;
	BOOL ret = NO;
	NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:path
																															   error:&error]];

//	DEBUG_LOG(@"%s %@", __func__, [attr objectForKey:NSFileModificationDate]);
	if (error == nil) {
		@try {
			DEBUG_LOG(@"%s %@ --> %@", __func__, [attr objectForKey:NSFileModificationDate], modDate);
			[attr setObject:modDate forKey:NSFileModificationDate];
			ret = [[NSFileManager defaultManager] setAttributes:attr
												   ofItemAtPath:path
														  error:nil];
		}
		@catch (NSException *exception) {
			DEBUG_LOG(@"!!! Failed %s %@", __func__, [attr objectForKey:NSFileModificationDate]);
		}
	}
	attr = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:path
																										  error:nil]];
	DEBUG_LOG(@"%s [%@]!!", __func__, [attr objectForKey:NSFileModificationDate]);
	return (ret && [[attr objectForKey:NSFileModificationDate] isEqualToDate:modDate]);
}

//ディレクトリの生成
+ (BOOL)createDirectoryAtPath:(NSString *)path {
	
	// 以下の場合は例外を発生させる。
	NSAssert(! [path isEqualToString:kDocumentPath], @"DocumentPath is not permitted");
//	NSAssert(! [path isEqualToString:kCachedDocumentPath], @"");
	NSAssert(! [path isEqualToString:kMainBundlePath], @"MainBundle is not permitted");
	
    if ([FileUtil fileExistsAtPath:path]) return YES;
	NSError *error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:path
							  withIntermediateDirectories:NO
											   attributes:nil
													error:&error];
	return (error == nil);
}

//ディレクトリの生成
+ (BOOL)createDirectoryAtPath:(NSString *)path
  withIntermediateDirectories:(BOOL)withIntermediateDirectories
				   attributes:(NSDictionary *)attributes {

	// 以下の場合は例外を発生させる。
	NSAssert(! [path isEqualToString:kDocumentPath], @"DocumentPath is not permitted");
//	NSAssert(! [path isEqualToString:kCachedDocumentPath], @"");
	NSAssert(! [path isEqualToString:kMainBundlePath], @"MainBundle is not permitted");
    
	if ([FileUtil fileExistsAtPath:path]) return YES;
	NSError *error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:path
							  withIntermediateDirectories:withIntermediateDirectories
											   attributes:attributes
													error:&error];
	return (error == nil);
}

//ファイルの生成
+ (BOOL)createFileAtPath:(NSString *)path {

    if ([FileUtil fileExistsAtPath:path]) return YES;
	NSError *error = nil;
	[[NSFileManager defaultManager] createFileAtPath:path
											contents:NO
										  attributes:nil];
	return (error == nil);
}

//ファイルの生成
+ (BOOL)createFileAtPath:(NSString *)path
				contents:(NSData *)contents
			  attributes:(NSDictionary *)attributes {
	
    if ([FileUtil fileExistsAtPath:path]) return YES;
	NSError *error = nil;
	[[NSFileManager defaultManager] createFileAtPath:path
											contents:contents
										  attributes:attributes];
	return (error == nil);
}

//シンボリックリンクの生成
// path/destPath ともに絶対パス
+ (BOOL)createSymbolicLinkAtPath:(NSString *)path
             withDestinationPath:(NSString *)destPath {
	
	NSError *error = nil;
	[[NSFileManager defaultManager] createSymbolicLinkAtPath:path
										 withDestinationPath:destPath
													   error:&error];
    DEBUG_LOG(@"%s %@", __func__, error);
	return (error == nil);
}

// シンボリックリンク作成するディレクトリに移動して、相対パスでシンボリックリンクを作成するイメージ。
// path/destPath ともに絶対パス
+ (BOOL) createRelativeSymbolicLinkAtPath:(NSString *)path
                      withDestinationPath:(NSString *)destPath {
    
    NSString *curDirSave = [FileUtil currentDirectoryPath];
    NSString *cwd = nil;
    BOOL result = NO;
    
    if ([FileUtil isDirectory:path]) {
        cwd = path;
    } else
    {// ファイルなら最後のコンポーネントの上がディレクトリ
        cwd = [path stringByDeletingLastPathComponent];
    }
    result = [FileUtil changeCurrentDirectoryPath:cwd];
    if (result)
    {// 作成先は間違いの無い絶対パスで指定する。
        result = [FileUtil createSymbolicLinkAtPath:path
                                withDestinationPath:destPath];
        if (result) {
            result = [FileUtil changeCurrentDirectoryPath:curDirSave];
        }
    }
    return result;
}

//ファイル・ディレクトリの削除
+ (BOOL)removeItemAtPath:(NSString *)path {
	
	// 以下の場合は例外を発生させる。
	NSAssert(! [path isEqualToString:kDocumentPath], @"DocumentPath is not permitted");
//	NSAssert(! [path isEqualToString:kCachedDocumentPath], @"");
	NSAssert(! [path isEqualToString:kMainBundlePath], @"MainBundle is not permitted");

    if ([FileUtil fileExistsAtPath:path] == NO && [FileUtil isSymbolicLink:path] == NO) return YES;

	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:path error:&error];
	return (error == nil);
}

//ファイル・ディレクトリの強制削除
+ (BOOL)forceRemoveItemAtPath:(NSString *)path {
	
	// 以下の場合は例外を発生させる。
	NSAssert(! [path isEqualToString:kDocumentPath], @"DocumentPath is not permitted");
//	NSAssert(! [path isEqualToString:kCachedDocumentPath], @"");
	NSAssert(! [path isEqualToString:kMainBundlePath], @"MainBundle is not permitted");
	
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:path error:&error];
	return (error == nil);
}

//ファイル・ディレクトリのリネーム
+ (BOOL)moveItemAtPath:(NSString *)srcPath
				toPath:(NSString *)toPath {
	
    if (! [FileUtil fileExistsAtPath:srcPath]) return NO;

	BOOL ret = YES;
	if ([FileUtil fileExistsAtPath:toPath]) {
		ret = [FileUtil removeItemAtPath:toPath];
	}
	if (ret) {
        NSString *toParentDir = [toPath stringByDeletingLastPathComponent];
        if ([FileUtil fileExistsAtPath:toParentDir] == NO) {
            ret = [FileUtil createDirectoryAtPath:toParentDir
                      withIntermediateDirectories:YES
                                       attributes:nil];
        }
    }
	if (ret) {
		NSError *error = nil;
		[[NSFileManager defaultManager] moveItemAtPath:srcPath toPath:toPath error:&error];
		ret = (error == nil);
	}
	return ret;
}

//ファイル・ディレクトリの複製を作成する
+ (BOOL)copyItemAtPath:(NSString *)srcPath
				toPath:(NSString *)toPath {
    
	NSURL *srcURL = [NSURL fileURLWithPath:srcPath];
	NSURL *toURL = [NSURL fileURLWithPath:toPath];
	
	DEBUG_LOG(@"%s src:[%@]", __func__, [srcURL path]);
	DEBUG_LOG(@"%s  to:[%@]", __func__, [toURL path]);

    if ([srcPath isEqualToString:toPath]) return YES;
    if (! [FileUtil fileExistsAtPath:srcPath]) return NO;

	BOOL ret = YES;
	if ([FileUtil fileExistsAtPath:toPath]) {
		ret = [FileUtil removeItemAtPath:toPath];
	}
	if (ret) {
        NSString *toParentDir = [toPath stringByDeletingLastPathComponent];
        if ([FileUtil fileExistsAtPath:toParentDir] == NO) {
            ret = [FileUtil createDirectoryAtPath:toParentDir
                      withIntermediateDirectories:YES
                                       attributes:nil];
        }
    }
	if (ret) {
		NSError *error = nil;
		[[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:toPath error:&error];
		ret = (error == nil);
        DEBUG_LOG(@"%s  error:[%@]", __func__, error);
	}
	return ret;
}

//ファイル・ディレクトリの階層を辿って複製する
+ (BOOL)copyItemAtPathHier:(NSString *)srcPath
					toPath:(NSString *)toPath {
	
	BOOL ret = YES;

//	DEBUG_LOG(@"%s \n\t\t[%@]\n\t\t[%@]", __func__, srcPath, toPath);

	NSURL *srcURL = [NSURL fileURLWithPath:srcPath];
	NSURL *toURL = [NSURL fileURLWithPath:toPath];
	
	DEBUG_LOG(@"%s src:[%@]", __func__, [srcURL path]);
	DEBUG_LOG(@"%s  to:[%@]", __func__, [toURL path]);

	if ([FileUtil isDirectory:srcPath]) {
		NSArray *items = [FileUtil contentsOfDirectoryAtPath:srcPath];
		for (NSString *item in items) {
			NSString *newSrcPath = [srcPath stringByAppendingPathComponent:item];
			NSString *newToPath = [toPath stringByAppendingPathComponent:item];

			if ([FileUtil fileExistsAtPath:newSrcPath] == NO) {
				ret = NO;
				break;
			}
			if ([newSrcPath isEqualToString:newToPath]) {
				ret = YES;
				break;
			}
			ret = YES;
			if ([FileUtil fileExistsAtPath:newToPath])
			{// ディレクトリ／ファイルに関わらず複製先を削除する。
				ret = [FileUtil removeItemAtPath:newToPath];
			}
			// 複製先の親ディレクトリがない場合は、作成する。
			if (ret) {
				NSString *newToPathParentDir = [newToPath stringByDeletingLastPathComponent];
				if ([FileUtil fileExistsAtPath:newToPathParentDir] == NO) {
					ret = [FileUtil createDirectoryAtPath:newToPathParentDir
							  withIntermediateDirectories:YES
											   attributes:nil];
				}
			}
			// ターゲットのディレクトリまたはファイルを複製する。
			if (ret) {
				if ([FileUtil isDirectory:newSrcPath]) {
					ret = [FileUtil copyItemAtPathHier:newSrcPath toPath:newToPath];
				} else {
					ret = [FileUtil copyItemAtPath:newSrcPath toPath:newToPath];
				}
			}
		}
	} else {
		if ([FileUtil fileExistsAtPath:srcPath] == NO) {
			ret = NO;
		} else {
			if ([srcPath isEqualToString:toPath]) {
				ret = YES;
			} else {
				if ([FileUtil fileExistsAtPath:toPath])
				{// ディレクトリ／ファイルに関わらず複製先を削除する。
					ret = [FileUtil removeItemAtPath:toPath];
				}
				if (ret) {
					ret = [FileUtil copyItemAtPath:srcPath toPath:toPath];
				}
			}
		}
	}
	return ret;
}

+ (BOOL) isDirectory:(NSString *)path {
	
	NSError *error = nil;
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path
																		  error:&error];
	NSString *fileType = (NSString *) [attr fileType];
	
	return error == nil ? [fileType isEqualToString:NSFileTypeDirectory] : NO;
}

+ (BOOL) isFile:(NSString *)path {
	
	NSError *error = nil;
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path
																		  error:&error];
	NSString *fileType = (NSString *) [attr fileType];
	
	return error == nil ? [fileType isEqualToString:NSFileTypeRegular] : NO;
}

+ (BOOL) isSymbolicLink:(NSString *)path {

	NSError *error = nil;
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path
													   error:&error];
	NSString *fileType = (NSString *) [attr fileType];

	return error == nil ? [fileType isEqualToString:NSFileTypeSymbolicLink] : NO;
}

+ (BOOL) isBrokenSymbolicLink:(NSString *)path {
	
	NSError *error = nil;
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path
																		  error:&error];
	NSString *fileType = (NSString *) [attr fileType];
	
	return (error && [fileType isEqualToString:NSFileTypeSymbolicLink]);
}

+ (NSString *) destinationOfSymbolicLinkAtPath:(NSString *)path {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	return [fileManager destinationOfSymbolicLinkAtPath:path error:&error];
}

/*
+ (NSString *) extension:(NSString *)path {
	
	NSString *ext = nil;
	NSArray *tokens = [path componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
	if ([tokens count] > 1) {
		ext = [tokens objectAtIndex:[tokens count]-1];
	}
	return ext;
}
*/

//ライトファイルハンドルの取得
+ (NSFileHandle *)fileHandleForWritingAtPath:(NSString *)path {

	return ([NSFileHandle fileHandleForWritingAtPath:path]);
}

//リードファイルハンドルの取得
+ (NSFileHandle *)fileHandleForReadingAtPath:(NSString *)path {

	return ([NSFileHandle fileHandleForReadingAtPath:path]);
}

//データ→ファイル
+ (BOOL)writeToFile:(NSData *)data
			 path:(NSString *)path {

	return ([data writeToFile:path atomically:YES]);
}

//データ→ファイル(追加)
+ (BOOL)appendToFile:(NSData *)data
				path:(NSString *)path {

    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (fh) {
        @try {
            [fh seekToEndOfFile];
            [fh writeData:data];   
            [fh closeFile];   
            return YES;
		}
		@catch(id error) {
		}
    }
    return NO;
}

//ファイル→データ
+ (NSData *)contentsAtPath:(NSString *)path {

	return [[NSData alloc] initWithContentsOfFile:path];
//	return [[[[NSFileManager defaultManager] contentsAtPath:path] retain] autorelease];
}

//ファイル→データ(部分)
+ (NSData *)contentsAtPath:(NSString *)path
					offset:(unsigned long long)offset 
					length:(unsigned long long)length {

    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = nil;
    if (fh) {
        @try {
            [fh seekToFileOffset:offset];
            data = [fh readDataOfLength:length];
            [fh closeFile];   
		}
		@catch(id error) {
		}
    }
    return [data copy];
}

+ (NSString *) currentDirectoryPath {
    return [[NSFileManager defaultManager] currentDirectoryPath];
}

+ (BOOL) changeCurrentDirectoryPath:(NSString *)path {
    return [[NSFileManager defaultManager] changeCurrentDirectoryPath:path];
}

//リソースがあるか否か
+ (BOOL)resourceExists:(NSString *)resName {
	
    return ([FileUtil fileExistsAtPath:[kDocumentPath stringByAppendingPathComponent:resName]]);
}

//リソース→データ
+ (NSData *)resourceContents:(NSString *)resName {
    NSString *path = [[NSBundle mainBundle] pathForResource:resName ofType:@""];
    return [NSData dataWithContentsOfFile:path];
}

//リソース→データ(部分)
+ (NSData *)resourceContents:(NSString *)resName
					  offset:(unsigned long long)offset 
					  length:(unsigned long long)length {

    NSString *path = [[NSBundle mainBundle] pathForResource:resName ofType:@""];
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = nil;
    if (fh) {
        @try {
            [fh seekToFileOffset:offset];
            data = [fh readDataOfLength:length];
            [fh closeFile];   
		}
		@catch(id error) {
		}
    }
    return data;
}

//リソース→ファイル
+ (BOOL)resourceToFileAtPath:(NSString *)resName
					  toPath:(NSString *)toPath {

    NSString *fromPath = [[NSBundle mainBundle] pathForResource:resName ofType:@""];
	NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:fromPath
											toPath:toPath
											 error:&error];
    return (error == nil);
}

//ファイル→リソース
+ (BOOL)fileToResourceAtPath:(NSString *)fromPath
					 resName:(NSString *)resName {
	
    NSString *toPath = [kDocumentPath stringByAppendingPathComponent:resName];
	NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:fromPath
											toPath:toPath
											 error:&error];
    return (error == nil);
}

//リソースを削除する
+ (BOOL)removeResource:(NSString *)resName {
	
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:[kDocumentPath stringByAppendingPathComponent:resName]
											   error:&error];
    return (error == nil);
}

@end
