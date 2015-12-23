// $Id: iCloudStorage.h,v 1.1.1.1 2011-03-17 07:14:34 matsu Exp $
//
//  iCloudStorage.h
//  Music PlugIn
//
//  Created by matsu on 10/09/23.
//  Copyright 2010 Takuji Matsugaki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileRepresentation.h"
#import "FileSpec.h"

@protocol iCloudStorageDelegate
@required
// ノーティファイ
// iCloud ストレージ変更操作のノーティファイ（ローカルのみ）
- (void) iCloudManageNotify:(NSString *)fileName completion:(BOOL)completion;
- (void) iCloudUnmanageNotify:(NSString *)fileName completion:(BOOL)completion;
- (void) iCloudModifyNotify:(NSString *)fileName completion:(BOOL)completion;
- (void) iCloudDeleteNotify:(NSString *)fileName completion:(BOOL)completion;
// iCloud ストレージコンテンツ更新のノーティファイ（ローカル／リモート）
- (void) iCloudUpdatedNotify:(NSArray *)files;     // readyToGetList == YES の場合は一連の更新が完了して、リスト作成に適したことを通知する。
- (void) iCloudListReceivedNotify:(NSUInteger)numTunes;
// iCloud ストレージ変更結果（ファイル受信）のノーティファイ（リモートのみ）
- (void) iCloudSynchronizedNotify:(NSString *)fileName;
@end

@interface iCloudStorage : NSObject {
#if 0
//    NSMetadataQuery *_query;
    id _query;
    BOOL _inQuery;
    NSURL *_documentsDir;       // 
    NSMutableArray *_fileList;  // FileRepresentation のアレイ
    NSString *_currentPath;
    int _networkRequestCount;       
    NSTimer *_requestTimer;         // 
    CGFloat _downloadProgress;      // 
    NSString *_failureFile1;        // 
    NSString *_failureFile2;        // 未使用（_error2 を使用する）
//    NSTimer *_failureDetectTimer1;  // 未使用
//    NSTimer *_failureDetectTimer2;  // 未使用
    NSUInteger _downloadedCount;
    NSError *_error;
    NSError *_error1;               // 未使用（failureFile1 を使用する）
    NSError *_error2;               // 
    // Level1:長時間に渡って【アップロード済み】且つ【未ダウンロード】のファイルがあって、継続的に update がある致命的なケース。
    // 【対策】
    NSMutableArray *_corruptedLevel1Paths;
    // Level2:Level1 処理を実施したが、downloadFileIfNotAvailable で依然エラーが発生しているファイルがあるケース。
    NSMutableArray *_corruptedLevel2Paths;
#endif
}
@property (nonatomic, strong) id query;
@property (nonatomic, assign) BOOL inQuery;
@property (nonatomic, strong) NSURL *ubiquityDocumentURL;
@property (nonatomic, strong) NSMutableArray *fileList;
@property (nonatomic, strong) NSString *currentPath;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSError *error1;
@property (nonatomic, strong) NSError *error2;
@property (nonatomic, strong) NSMutableArray *corruptedLevel1Paths;
@property (nonatomic, strong) NSMutableArray *corruptedLevel2Paths;
@property (nonatomic, strong) NSTimer *requestTimer;
@property (nonatomic, assign) CGFloat downloadProgress;
@property (nonatomic, assign) NSUInteger downloadedCount;
@property (nonatomic, strong) NSString *failureFile1;
@property (nonatomic, strong) NSString *failureFile2;
@property (nonatomic, assign) NSInteger networkRequestCount;
@property (nonatomic, assign) id <iCloudStorageDelegate> delegate;

// 基本機能
+ (NSURL *) ubiquityContainerURL;
+ (NSURL *) ubiquityDocumentsURL;
+ (NSString *) sandboxContainerDocPath;

- (id) initWithURL:(NSURL *)ubiquityContainerURL;
- (NSString *) iCloudDocumentDirectory:(BOOL)sandbox;
- (NSURL *) sandboxURL:(NSString *)path;
- (NSString *) sandboxPath:(NSURL *)url;

// リスト要求
- (void) requestListing:(NSString *)path;
// 管理要求
- (void) moveFileToiCloud:(FileRepresentation *)fileToMove;
// 管理解除要求
- (void) moveFileToLocal:(FileRepresentation *)fileToMove;
// 更新要求
- (void) modifyFile:(FileRepresentation *)fileToModify data:(NSData *)data;
// 削除要求
- (void) deleteFile:(FileRepresentation *)fileToDelete;
// ファイルスペックの全ての iCloud拡張属性を取得する。
- (void) get_iCloudAttributes:(NSString *)path fileSpec:(FileSpec *)fileSpec;
// ダウンロード要求（オプション）
- (void) requestLoad:(NSString *)path;

// 状態クエリー
- (BOOL) is_iCloudStored:(NSURL *)file;
- (BOOL) is_iCloudDownloaded:(NSURL *)file;
- (BOOL) is_iCloudDownloading:(NSURL *)file;
//- (CGFloat) iCloudDownloadedPercent:(NSURL *)file;
- (BOOL) is_iCloudUploaded:(NSURL *)file;
- (BOOL) is_iCloudUploading:(NSURL *)file;
//- (CGFloat) iCloudUploadedPercent:(NSURL *)file;
- (NSNumber *) iCloudFileSize:(NSURL *)file;
- (NSDate *) iCloudFileCreationDate:(NSURL *)file;
- (NSDate *) iCloudFileModificationDate:(NSURL *)file;

- (void) level1FailureRecovery:(NSString *)path;
- (void) level2FailureRecovery:(NSString *)path;
@end
