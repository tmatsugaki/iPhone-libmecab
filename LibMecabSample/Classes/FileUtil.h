//
//  FileUtil.h
//  Yardbird
//
//  Created by matsu on 10/11/12.
//  Copyright 2010 家事手伝い. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "definitions.h"
#import "FileSpec.h"

//enum {
//    kDocumentPlaceDefault,
//    kDocumentPlaceCached,
//    kDocumentPlace_iCloud
//};

@interface FileUtil : NSObject {

}

+ (NSString *) localDocumentsDirectory;
//+ (NSString *) cachedDocumentRoot;

+ (BOOL) isEqualToPath:(NSString *)srcPath toPath:(NSString *)toPath;
/*
 * ファイル・ディレクトリ
 */
// ディスクの空き容量を取得する。
+ (long long) freeDiskSize;

//ファイル・ディレクトリ一覧の取得
+ (NSArray *) contentsOfDirectoryAtPath:(NSString *)path;
//ファイルスペック一覧の取得
+ (NSArray *) fileSpecs:(NSString *)dir;
+ (NSArray *) dirFileSpecs:(NSString *)dir;
//ファイル・ディレクトリが存在するか
+ (BOOL) fileExistsAtPath:(NSString *)path;
+ (BOOL) fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory;
//ファイルのサイズ
+ (unsigned long long) fileSize:(NSString *)path;
//ファイル・ディレクトリの作成日時
+ (NSDate *) creationDate:(NSString *)path;
+ (BOOL) setCreationDate:(NSString *)path creDate:(NSDate *)creDate;
//ファイル・ディレクトリの修正日時
+ (NSDate *) modificationDate:(NSString *)path;
+ (BOOL) setModificationDate:(NSString *)path modDate:(NSDate *)modDate;
//ディレクトリの生成
+ (BOOL) createDirectoryAtPath:(NSString *)path;
+ (BOOL) createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)withIntermediateDirectories attributes:(NSDictionary *)attributes;
//ファイルの生成
+ (BOOL) createFileAtPath:(NSString *)path;
+ (BOOL) createFileAtPath:(NSString *)path contents:(NSData *)contents attributes:(NSDictionary *)attributes;
//シンボリックリンクの生成
+ (BOOL) createSymbolicLinkAtPath:(NSString *)path withDestinationPath:(NSString *)destPath;
+ (BOOL) createRelativeSymbolicLinkAtPath:(NSString *)path withDestinationPath:(NSString *)destPath;
//ファイル・ディレクトリの削除
+ (BOOL) removeItemAtPath:(NSString *)path;
+ (BOOL) forceRemoveItemAtPath:(NSString *)path;
//ファイル・ディレクトリのリネーム
+ (BOOL) moveItemAtPath:(NSString *)srcPath toPath:(NSString *)toPath;
//ファイル・ディレクトリの複製を作成する
+ (BOOL) copyItemAtPath:(NSString *)srcPath toPath:(NSString *)toPath;
+ (BOOL) copyItemAtPathHier:(NSString *)srcPath toPath:(NSString *)toPath;
//ディレクトリであるか
+ (BOOL) isDirectory:(NSString *)path;
//ファイルであるか
+ (BOOL) isFile:(NSString *)path;
//シンボリックリンクであるか
+ (BOOL) isSymbolicLink:(NSString *)path;
+ (BOOL) isBrokenSymbolicLink:(NSString *)path;
//シンボリックリンクの実体
+ (NSString *) destinationOfSymbolicLinkAtPath:(NSString *)path;
//ファイルの拡張子の取得
//+ (NSString *) extension:(NSString *)path;
//ライトファイルハンドルの生成
+ (NSFileHandle *) fileHandleForWritingAtPath:(NSString *)path;
//リードファイルハンドルの生成
+ (NSFileHandle *) fileHandleForReadingAtPath:(NSString *)path;
//データ→ファイル
+ (BOOL) writeToFile:(NSData *)data path:(NSString *)path;
//データ→ファイル(追加)
+ (BOOL) appendToFile:(NSData *)data path:(NSString *)path;
//ファイル→データ
+ (NSData *) contentsAtPath:(NSString *)path;
//ファイル→データ(部分)
+ (NSData *) contentsAtPath:(NSString *)path offset:(unsigned long long)offset length:(unsigned long long)length;
// カレントワーキングディレクトリを取得する。
+ (NSString *) currentDirectoryPath;
// カレントワーキングディレクトリを設定する。
+ (BOOL) changeCurrentDirectoryPath:(NSString *)path;
/*
 * リソース
 */
//リソースがが存在するか
+ (BOOL) resourceExists:(NSString *)resName;
//リソース→データ
+ (NSData *) resourceContents:(NSString *)resName;
//リソース→データ(部分)
+ (NSData *) resourceContents:(NSString *)resName offset:(unsigned long long)offset length:(unsigned long long)length;
//リソース→ファイル
+ (BOOL) resourceToFileAtPath:(NSString *)resName toPath:(NSString *)toPath;
//ファイル→リソース
+ (BOOL) fileToResourceAtPath:(NSString *)fromPath resName:(NSString *)resName;
//リソース削除
+ (BOOL) removeResource:(NSString *)resName;
// テキストを表示する HTML の生成
@end
