// $Id: iCloudStorage.m,v 1.1.1.1 2011-03-17 07:14:34 matsu Exp $
//
//  iCloudStorage.m
//  Music PlugIn
//
//  Created by matsu on 10/09/23.
//  Copyright 2010 Takuji Matsugaki. All rights reserved.
//
#define ON_THE_FLY  1

#import "definitions.h"
#import "iCloudStorage.h"
#import "FileUtil.h"

@interface iCloudStorage ()
- (void) queryStartedCallback;
- (void) listReceivedCallback;
- (void) updatedCallback;
- (BOOL) downloadFileIfNotAvailable:(NSURL*)file;
- (void) createDirectories:(NSString *)dirPath;
- (void) createPseudoFiles;
- (void) syncToLocal;

- (void) requestCompleted:(NSString *)message;
- (void) requestTimerStart;
- (void) requestTimerFired:(NSTimer *)timer;
@end

@implementation iCloudStorage

@synthesize delegate;

- (id) initWithURL:(NSURL *)ubiquityContainerURL {
#if (ICLOUD_LOG == 1)
//	DEBUG_LOG(@"%s %@", __func__, [documentsDir absoluteString]);
#endif
    
    self = [super init];
    if (self != nil)
	{
        self.ubiquityDocumentURL = ubiquityContainerURL;
        self.fileList = [[[NSMutableArray alloc] init] autorelease];
#if (ICLOUD_ENABLD == 1)
        // オブザーバーを設定する。
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(queryStartedCallback)
                                   name:NSMetadataQueryDidStartGatheringNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(listReceivedCallback)
                                   name:NSMetadataQueryDidFinishGatheringNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(updatedCallback)
                                   name:NSMetadataQueryDidUpdateNotification
                                 object:nil];
#endif
//        self.error = [[[NSError alloc] initWithDomain:@"" code:0 userInfo:nil] autorelease];

#if 0
        [_error addObserver:self // オブザーバーはこのインスタンス
                 forKeyPath:@"iCloudError"
                    options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                     context:NULL];
#endif
        self.corruptedLevel1Paths = [[[NSMutableArray alloc] init] autorelease];
        self.corruptedLevel2Paths = [[[NSMutableArray alloc] init] autorelease];
    }
	return self;
}

#if 0
- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if ([keyPath isEqual:@"iCloudError"]) {
        DEBUG_LOG(@"%s Error Changed [%@]", __func__, _error);
//        [_error setObjectValue:[change objectForKey:NSKeyValueChangeNewKey]];
    }
    /*
     Be sure to call the superclass's implementation *if it implements it*.
     NSObject does not implement the method.
     */
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}
#endif

- (void) dealloc
{
#if (LOG || DEALLOC_LOG)
	DEBUG_LOG(@"%s", __func__);
#endif

    self.query = nil;
    self.ubiquityDocumentURL = nil;
    self.fileList = nil;
    self.currentPath = nil;
    self.error = nil;
    self.error1 = nil;
    self.error2 = nil;
    self.corruptedLevel1Paths = nil;
    self.corruptedLevel2Paths = nil;
    self.requestTimer = nil;

    [super dealloc];
    
#if (ICLOUD_ENABLD == 1)
    // オブザーバーを破棄する。
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:NSMetadataQueryDidStartGatheringNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:NSMetadataQueryDidFinishGatheringNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:NSMetadataQueryDidUpdateNotification
                                object:nil];
#endif
}

#pragma mark - Environment

// file://localhost/private/var/mobile/Library/Mobile%20Documents/iCloud~jp~mydns~rikki~HinshiMaster/
//
+ (NSURL *) ubiquityContainerURL {
    
#if (ICLOUD_LOG == 1)
	DEBUG_LOG(@"%s", __func__);
#endif
    
    NSURL *ubiquityContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:UbiquityContainerIdentifier];
    
    DEBUG_LOG(@"%s %@", __func__, ubiquityContainerURL);
    
    return ubiquityContainerURL;
}

// file://localhost/private/var/mobile/Library/Mobile%20Documents/iCloud~jp~mydns~rikki~HinshiMaster/Documents/
//
+ (NSURL *) ubiquityDocumentsURL {
    
#if (ICLOUD_LOG == 1)
	DEBUG_LOG(@"%s", __func__);
#endif
    
    NSURL *ubiquityContainerURL = [iCloudStorage ubiquityContainerURL];
    
    if (ubiquityContainerURL) {
        return [ubiquityContainerURL URLByAppendingPathComponent:@"Documents"];
    } else {
        return nil;
    }
}

// サンドボックスコンテナ（のルートディレクトリ）
+ (NSString *) sandboxContainerDocPath {
    
    NSString *sandboxContainerDocPath = nil;
    
#if (ICLOUD_FALLBACK_STORE_IN_CACHE == 1)
    // サンドボックスコンテナは、キャッシュに持つ。（こちらが望ましい。）
    // Inbox や iCloud から取得したファイルをここで操作する。
    // 【サンドボックスコンテナ】/var/mobile/Applications/XXXX-XXXX-XXXX-XXXX-XXXX/Library/Caches/iCloud/
    // 【ユビキティコンテナ】/private/var/mobile/Library/Mobile Documents/F42S2EFB55~org~dyndns~rikki~Yadrbirds/Documents/
    sandboxContainerDocPath = k_iCloudDocumentPath;
#else
    // 【デバッグ用】iCloud にダブルでバックアップされてしまうので、良くない！！
    sandboxContainerDocPath = [kDocumentPath stringByAppendingPathComponent:ICLOUD_FOLDER_NAME];
#endif
    return sandboxContainerDocPath;
}

- (NSString *) iCloudDocumentDirectory:(BOOL)sandbox {
    
    NSString *documentDirectory = nil;
    
    if (sandbox) {
        documentDirectory = [iCloudStorage sandboxContainerDocPath];
    } else {
        documentDirectory = [_ubiquityDocumentURL path];
    }
    return documentDirectory;
}

// サンドボックス・コンテナのパスから、対応する iCloud管理ファイルの URL を取得する。
- (NSURL *) sandboxURL:(NSString *)path {

    NSURL *url = nil;
    NSString *sandboxDocFolder = [iCloudStorage sandboxContainerDocPath];

    if (sandboxDocFolder) {
        if ([path length] > [sandboxDocFolder length] + 1) {
            NSString *relativePath = [path substringFromIndex:[sandboxDocFolder length] + 1];
            NSString *ubiquityDocFolder = [_ubiquityDocumentURL relativePath];
            NSString *adminPath = [NSString stringWithFormat:@"%@/%@", ubiquityDocFolder, relativePath];
            BOOL isDirectory = NO;
            
            (void) [FileUtil fileExistsAtPath:path isDirectory:&isDirectory];
            url = [NSURL fileURLWithPath:adminPath
                             isDirectory:isDirectory];
        }
    }
    return url;
}

// iCloud管理ファイルの URL から、対応する サンドボックス・コンテナのパスを取得する。
- (NSString *) sandboxPath:(NSURL *)url {

    NSString *path = nil;
    NSString *sandboxDocFolder = [iCloudStorage sandboxContainerDocPath];
    NSString *ubiquityDocFolder = [_ubiquityDocumentURL relativePath];
    if ([[url relativePath] length] > [ubiquityDocFolder length] + 1) {
        NSString *relativePath = [[url relativePath] substringFromIndex:[ubiquityDocFolder length] + 1];
        path = [NSString stringWithFormat:@"%@/%@", sandboxDocFolder, relativePath];
    }
    return path;
}

#pragma mark - Top Level Functions

// 【注意】initWithURL で NSMetadataQueryDidUpdateNotification が来る訳ではない！！
//       NSMetadataQueryDidUpdateNotification は startQuery の結果発生する。
// リクエスト①
- (void) requestListing:(NSString *)fileName {

    self.inQuery = YES;
    // 全ての起点はリスト要求？
    _downloadProgress = 0.0;
    self.error = nil;
    self.error1 = nil;
    self.error2 = nil;

#if (ICLOUD_ENABLD == 1)
    // ステータスバーのインジケータのアニメーションは NSMetadataQueryDidStartGatheringNotification のコールバックにて開始。

    self.query = [[[NSMetadataQuery alloc] init] autorelease];
    // iCloud コンテナの Documents 配下のディレクトリを取得する。
    [_query setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, nil]];
    
    if (fileName == nil)
    {// ls -R / と同意
        [_query setPredicate:[NSPredicate predicateWithFormat:@"%K like '*.*'", NSMetadataItemFSNameKey]];
    } else
    {// ls /to_path と同意（今の所、未使用）
//        [_query setPredicate:[NSPredicate predicateWithFormat:@"%K like \"%@*\"", NSMetadataItemURLKey, [self sandboxURL:path]]];
        [_query setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", NSMetadataItemFSNameKey, [fileName lastPathComponent]]];
    }
//    [_query setPredicate:[NSPredicate predicateWithFormat:@"%K like '*.*'", NSMetadataItemPathKey]];
    [_query startQuery];
#endif
}

// ローカルのディレクトリ（サンドボックス・コンテナ）にあるファイルをユビキティー・コンテナへ移動させる。
// 【注意】ディレクトリ作成は1度で正常終了するがローカルに反映されない、2度目のエラーで表示され管理対象になる。
// 【注意】0バイトのファイル作成は1度で成功しローカルに反映されるが、リモートのイベントが発生しない。
// 【注意】0バイトのファイルリネームは1度で成功しローカルに反映されるが、リモートのイベントが発生しない。
// 【考察】ディレクトリ作成には1バイト以上のダミーファイルが必要？　0バイトのファイルはローカルイベント発生するだけ？
- (void) moveFileToiCloud:(FileRepresentation *)fileToMove {
    
    NSURL *sourceURL = fileToMove.url;
    NSURL *destinationAdminURL = [self sandboxURL:[sourceURL path]];
    
    // アップロードリクエストを発行した。
    fileToMove.request = kFileReplUploadReuested;

    dispatch_queue_t q_default;
    q_default = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(q_default, ^(void) {

        NSFileManager *fileManager = [[NSFileManager alloc] init];
//        NSError *error = nil;
//        DEBUG_LOG(@"sourceURL     :%@", sourceURL);
//        DEBUG_LOG(@"destinationURL:%@", destinationURL);
        NSError *error = nil;
        BOOL success = [fileManager setUbiquitous:YES
                                        itemAtURL:sourceURL
                                   destinationURL:destinationAdminURL
                                            error:&error];
        if (error) {
            self.error = error;
//            DEBUG_LOG(@"%s iCloud Error:%@", __func__, error);
        } else {
            // リクエスト完了の監視を開始する。
            [self requestTimerStart];
        }

        dispatch_queue_t q_main = dispatch_get_main_queue();
        dispatch_async(q_main, ^(void) {
            NSString *fileName = fileToMove.fileName;

            if (success) {
                FileRepresentation *completedFileRepresentation =
                [[FileRepresentation alloc] initWithFileName:fileToMove.fileName
                                                         url:destinationAdminURL];
                [_fileList removeObject:fileToMove];
                [_fileList addObject:completedFileRepresentation];
            }
            [delegate iCloudManageNotify:[fileName copy]
                              completion:success];
            // リクエスト完了
            [self requestCompleted:@"moveFileToiCloud"];
        });
    });
}

// ユビキティー・コンテナのファイルをローカル（サンドボックス・コンテナ）に移動させる。
- (void) moveFileToLocal:(FileRepresentation *)fileToMove {
    
    NSURL *sourceURL = fileToMove.url;
    NSURL *destinationURL = [NSURL fileURLWithPath:[self sandboxPath:fileToMove.url]
                                       isDirectory:NO];

    dispatch_queue_t q_default;
    q_default = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(q_default, ^(void) {

#if 1
        // 事前に消す。
        [FileUtil removeItemAtPath:[destinationURL path]];
#endif
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        BOOL success = [fileManager setUbiquitous:NO
                                        itemAtURL:sourceURL
                                   destinationURL:destinationURL
                                            error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        } else {
            // リクエスト完了の監視を開始する。
            [self requestTimerStart];
        }
        dispatch_queue_t q_main = dispatch_get_main_queue();
        dispatch_async(q_main, ^(void) {
            NSString *fileName = fileToMove.fileName;
            if (success) {
                FileRepresentation *completedFileRepresentation =
                [[FileRepresentation alloc] initWithFileName:fileToMove.fileName
                                                         url:destinationURL];
                // アップロードが正常に完了した。
                fileToMove.request = kFileReplReuestNone;

                [_fileList removeObject:fileToMove];
                [_fileList addObject:completedFileRepresentation];
            } else {
                // アップロードが異常終了した。
            }
            [delegate iCloudUnmanageNotify:[fileName copy]
                                completion:success];
            // リクエスト完了
            [self requestCompleted:@"moveFileToLocal"];
        });
    });
}

// data はリテインカウントをインクリメントしているのが前提。
- (void) modifyFile:(FileRepresentation *)fileToUpdate
               data:(NSData *)data {
    
    NSURL *fileURL = fileToUpdate.url;
//    DEBUG_LOG(@"%s %@", __func__, [fileURL absoluteString]);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        NSError *error = nil;
        [fileCoordinator coordinateWritingItemAtURL:fileURL
                                            options:NSFileCoordinatorWritingForMerging // NSFileCoordinatorWritingForMerging, NSFileCoordinatorWritingForReplacing ではダメ！！
                                              error:&error
                                         byAccessor:^(NSURL *modifyingURL) {
//                                             NSError *err = nil;
                                             [data writeToURL:modifyingURL
                                                       atomically:YES];
                                         }];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        } else {
            // リクエスト完了の監視を開始する。
//            [self requestTimerStart];
        }
    });
    for (int i = 0; i < [_fileList count]; i++) {
        FileRepresentation *fileRepl = [_fileList objectAtIndex:i];
        if ([fileRepl.url isEqual:fileURL]) {
            NSString *fileName = fileRepl.fileName;
            
            [delegate iCloudModifyNotify:[fileName copy]
                              completion:YES];
            break;
        }
    }
}

- (void) deleteFile:(FileRepresentation *)fileToDelete {

    // リクエスト完了の監視を開始する。
    [self requestTimerStart];

    NSURL *fileURL = fileToDelete.url;
//    DEBUG_LOG(@"%s %@", __func__, [fileURL absoluteString]);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {

        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        NSError *error = nil;
        [fileCoordinator coordinateWritingItemAtURL:fileURL
                                            options:NSFileCoordinatorWritingForDeleting
                                              error:&error
                                         byAccessor:^(NSURL *writingURL) {
                                             NSError *err = nil;
                                                  NSFileManager *fileManager = [[NSFileManager alloc] init];
                                                  [fileManager removeItemAtURL:writingURL
                                                                         error:&err];
                                              }];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        // リクエスト完了
        [self requestCompleted:@"deleteFile"];
    });
    for (int i = 0; i < [_fileList count]; i++) {
        FileRepresentation *fileRepl = [_fileList objectAtIndex:i];
        if ([fileRepl.url isEqual:fileURL]) {
            NSString *fileName = fileRepl.fileName;

            [delegate iCloudDeleteNotify:[fileName copy]
                              completion:YES];
            break;
        }
    }
}

// ファイルスペックの全ての iCloud拡張属性を取得する。
- (void) get_iCloudAttributes:(NSString *)path
                     fileSpec:(FileSpec *)fileSpec {

    fileSpec.is_Sandbox = [path hasPrefix:[iCloudStorage sandboxContainerDocPath]];

    if (fileSpec.is_Sandbox) {
        NSURL *adminUrl  = [self sandboxURL:path];
        
        if (adminUrl) {
            fileSpec.is_iCloudStored = [self is_iCloudStored:adminUrl];

            if (fileSpec.is_iCloudStored)
            {
                fileSpec.is_iCloudDownloaded  = [self is_iCloudDownloaded:adminUrl];
                fileSpec.is_iCloudUploaded    = [self is_iCloudUploaded:adminUrl];
                fileSpec.is_iCloudDownloading = [self is_iCloudDownloading:adminUrl];
                fileSpec.is_iCloudUploading   = [self is_iCloudUploading:adminUrl];
                if (fileSpec.is_iCloudDownloading) {
//                    fileSpec.iCloudPercent    = [self iCloudDownloadedPercent:adminUrl];
                    fileSpec.iCloudPercent    = 0.0;
                } else if (fileSpec.is_iCloudDownloading) {
//                    fileSpec.iCloudPercent    = [self iCloudUploadedPercent:adminUrl];
                    fileSpec.iCloudPercent    = 0.0;
                }
                fileSpec.iCloudContentLength    = [self iCloudFileSize:adminUrl].longLongValue;
                fileSpec.iCloudCreationDate     = [self iCloudFileCreationDate:adminUrl];
                fileSpec.iCloudModificationDate = [self iCloudFileModificationDate:adminUrl];
            } else {
                fileSpec.is_iCloudDownloaded    = NO;
                fileSpec.is_iCloudUploaded      = NO;
                fileSpec.is_iCloudDownloading   = NO;
                fileSpec.is_iCloudUploading     = NO;
                fileSpec.iCloudPercent          = 0.0;
                fileSpec.iCloudContentLength    = 0;
                fileSpec.iCloudCreationDate     = nil;
                fileSpec.iCloudModificationDate = nil;
            }
        }
    }
}

// 直接 iCloud のエージェントファイルを指定してダウンロードする。
- (void) requestLoad:(NSString *)path {
    
    for (FileRepresentation *fileToGet in _fileList) {
        DEBUG_LOG(@"1.%@", [fileToGet.url relativePath]);
        DEBUG_LOG(@"2.%@", path);
        
        if ([[self sandboxPath:fileToGet.url] isEqualToString:path]) {
            fileToGet.request = kFileReplDownloadReuested;
            [self downloadFileIfNotAvailable:fileToGet.url];
            break;
        }
    }
}

#pragma mark - Callbacks

// クエリーが開始したので、リクエスト完了の監視を開始する。
- (void) queryStartedCallback {

    [self requestTimerStart];
}

// ファイルリストを作成する。
- (void) listReceivedCallback {

    [_fileList removeAllObjects];

#if (ICLOUD_ENABLD == 1)
    NSArray *queryResults = [_query results];

#if (ICLOUD_LOG == 1)
    DEBUG_LOG(@"%s %lu records received.", __func__, (unsigned long)[queryResults count]);
#endif
    if ([queryResults count]) {
        for (NSMetadataItem *result in queryResults) {
            NSString *fileName = [result valueForAttribute:NSMetadataItemFSNameKey];
            
            [_fileList addObject:[[FileRepresentation alloc] initWithFileName:fileName
                                                                           url:[result valueForAttribute:NSMetadataItemURLKey]]];
        }
        [self syncToLocal];
    }
    // 孤児のファイルを消す。
    // 【注意】無い筈のファイルをせがんでプログレスが継続するアノ現象は、孤児のファイルが原因！！
    if ([self removeOrphanFiles]) {
        [delegate iCloudDeleteNotify:kLibXMLName completion:YES];
    }

    [delegate iCloudListReceivedNotify:[queryResults count]];
    // リクエスト完了
    [self requestCompleted:@"requestListing"];
#endif
    _inQuery = NO;
}

// NSMetadataQueryDidFinishGatheringNotification の後に、
// NSMetadataQueryDidUpdateNotification はプログレス表示用に複数回発生する。
- (void) updatedCallback {

#if (ICLOUD_LOG == 1)
    DEBUG_LOG(@"iCloud 更新イベント!!");
#endif

    NSArray *queryResults = [_query results];
    BOOL readyToGetList = ([queryResults count] > 0);
    NSMutableArray *files = [[NSMutableArray alloc] init];
    NSUInteger compCount = 0;
    
    if (readyToGetList)
    {
        for (NSMetadataItem *result in queryResults) {
            NSURL *url = [result valueForAttribute:NSMetadataItemURLKey];

            [files addObject:[[url path] lastPathComponent]];

            if ([self is_iCloudUploaded:url])
            {// 過渡状態のファイルがある。
                if ([self is_iCloudDownloading:url]) {
                    DEBUG_LOG(@"%s [%@] のダウンロード中", __func__, url);
                } else {
                    compCount++;
                    DEBUG_LOG(@"%s [%@] のダウンロード完了", __func__, url);
                }
            }
        }
    }
    if (_inQuery == NO)
    {// 【例外】クエリーがないので、リスト要求する。
        [delegate iCloudUpdatedNotify:files];
    }
    if (compCount && [queryResults count]) {
        [delegate iCloudDownloadCompNotify];
    }
    [files release];

    if ([_requestTimer isValid] == NO)
    {// リクエスト監視タイマーが有効でない場合は、ステータスバーのインジケータを用いて
     // アップデートがあったことを知らせる。
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

#pragma mark - Utils

// ユーザーの指示で全リスト取得した際に実行する。
// dirPath には、ローカル（サンドボックス・コンテナ）のパスを指定する。
- (void) createDirectories:(NSString *)dirPath {
    
    DEBUG_LOG(@"%s %@", __func__, dirPath);
    
    NSString *srcRoot = [_ubiquityDocumentURL relativePath];
    NSString *dstRoot = [self iCloudDocumentDirectory:YES];
    
    if ([FileUtil isDirectory:dirPath]) {
        NSArray *files = [FileUtil dirFileSpecs:dirPath];
        
        for (FileSpec *file in files) {
            // 
            [self get_iCloudAttributes:file.path fileSpec:file];
            
            NSString *relativePath = [file.path substringFromIndex:[srcRoot length] + 1];
            
            if ([FileUtil isDirectory:file.path])
            {// ディレクトリなので、末尾再帰で自身を呼び出す。
                NSString *dstDir = [NSString stringWithFormat:@"%@/%@", dstRoot, relativePath];
                
                if ([FileUtil fileExistsAtPath:dstDir] == NO)
                {// 親ディレクトリがない場合は作成する。
                    [FileUtil createDirectoryAtPath:dstDir
                        withIntermediateDirectories:YES
                                         attributes:nil];
                }
                [self createDirectories:file.path];
            }
        }
    }
}

// サンドボックス・コンテナに iCloud の骨子を作成する。以下を実施する。
// 1.ロードされていないファイルはシンボリックリンクでファイルを再現する。
- (void) createPseudoFiles {
    
    for (FileRepresentation *fileToGet in _fileList) {
        NSString *srcPath = [fileToGet.url path];
        // サンドボックス・コンテナ書類のルートパス
        NSString *local_iCloudDirPath = [self iCloudDocumentDirectory:YES];
        NSString *ubiquityDocFolder = [_ubiquityDocumentURL relativePath];
        // iCloud 管理ディレクトリ（ユビキティー・コンテナ）からの相対パス
        NSString *relativePath = [srcPath substringFromIndex:[ubiquityDocFolder length] + 1];
        NSString *dstPath = [NSString stringWithFormat:@"%@/%@", local_iCloudDirPath, relativePath];
        
        if ([self is_iCloudDownloaded:fileToGet.url] == NO)
        {// 未ダウンロードのファイルは、サンドボックス・コンテナに
            // シンボリックリンクを作成する。
            if ([FileUtil fileExistsAtPath:dstPath] == NO) {
                NSString *symPath = [NSString stringWithFormat:@"%@/%@", ubiquityDocFolder, relativePath];
                BOOL success = YES;
                
                if ([FileUtil isSymbolicLink:dstPath]) {
                    success = [FileUtil removeItemAtPath:dstPath];
                }
                if (success) {
                    [FileUtil createSymbolicLinkAtPath:dstPath
                                   withDestinationPath:symPath];
                }
            }
        }
    }
}

// iCloud 上のファイルが更新されたので、ローカルへのダウンロードを促す。
- (void) syncToLocal {

    // 取得したファイルをローカルに反映する。
    for (FileRepresentation *fileToGet in _fileList) {
        // 法要チェッカーはこちら。
        // ダウンロード可能なファイルは全てダウンロードする。
        [self downloadFileIfNotAvailable:fileToGet.url];

        NSString *srcPath = [fileToGet.url path];
        // サンドボックス・コンテナ書類のルートパス
        NSString *local_iCloudDirPath = [self iCloudDocumentDirectory:YES];
        NSString *ubiquityDocFolder = [_ubiquityDocumentURL relativePath];
        // iCloud 管理ディレクトリ（ユビキティー・コンテナ）からの相対パス
        NSString *relativePath = [srcPath substringFromIndex:[ubiquityDocFolder length] + 1];
        NSString *dstPath = [NSString stringWithFormat:@"%@/%@", local_iCloudDirPath, relativePath];
        
        if ([self is_iCloudDownloaded:fileToGet.url])
        {// ダウンロード済みのファイルである。
            NSDate *srcModDate = [FileUtil modificationDate:srcPath];
            NSDate *dstModDate = [FileUtil modificationDate:dstPath];
            BOOL success = YES;
            NSString *dstParentDir = [dstPath stringByDeletingLastPathComponent];
            
            // ダウンロードリクエストが完了した。
            fileToGet.request = kFileReplReuestNone;
            
            if ([FileUtil fileExistsAtPath:dstParentDir] == NO)
            {// 親ディレクトリがない場合は作成する。
                success = [FileUtil createDirectoryAtPath:dstParentDir
                              withIntermediateDirectories:YES
                                               attributes:nil];
            }
            if (success) {
                if ([FileUtil fileExistsAtPath:dstPath] && [FileUtil isSymbolicLink:dstPath])
                {// アップロード中またはダウンロード中であった。
                    NSString *linkedPath = [FileUtil destinationOfSymbolicLinkAtPath:dstPath];
                    
                    if ([FileUtil isFile:srcPath])
                    {// シンボリックリンク先のファイルをコピーする。
                        // 【注意】既存ファイルを削除してコピーするので、ダウンロード中だった際に
                        //       作成されたシンボリックリンクを削除しファイルをコピーする。
                        if (linkedPath) {
                            [FileUtil copyItemAtPath:linkedPath toPath:dstPath];
                            // 【未使用】同期したファイルを通知（同期中なので、大したことはできない！！）
                            [delegate iCloudSynchronizedNotify:[[dstPath lastPathComponent] copy]];
                        }
                    } else if ([FileUtil isDirectory:srcPath])
                    {// ユーザーによるリスト取得の際のディレクトリ作成のサブセット
                        // 必要に応じて逐次ディレクトリを作成する。
                        if ([FileUtil removeItemAtPath:dstPath]) {
                            [FileUtil createDirectoryAtPath:dstPath
                                withIntermediateDirectories:YES
                                                 attributes:nil];
                        }
                    }
                } else
                {
                    // srcModDate > dstModDate
                    NSComparisonResult result = [srcModDate compare:dstModDate];
                    // 【注意】古いファイルを自動的に上書きする。
                    // 法要チェッカーはこちら。
                    if (dstModDate == nil || result == NSOrderedDescending)
                    {// ダウンロード済みの新しいファイルは、サンドボックス・コンテナにコピーする。
                        if ([FileUtil isFile:srcPath])
                        {// ファイルをコピーする。
                            [FileUtil copyItemAtPath:srcPath toPath:dstPath];
                            [delegate iCloudSynchronizedNotify:[[dstPath lastPathComponent] copy]];
                        } else if ([FileUtil isDirectory:srcPath])
                        {// 【注意】空のディレクトリの削除イベントは発生しないので、このパスはない？
                            [FileUtil createDirectoryAtPath:dstPath
                                withIntermediateDirectories:YES
                                                 attributes:nil];
                        }
                    }
                }
            }
        } else {
//            DEBUG_LOG(@"***[Not Downloaded]: %@", fileToGet.fileName);
            // 未ダウンロードのファイルは、サンドボックス・コンテナに
            // シンボリックリンクを作成する。
            if ([FileUtil fileExistsAtPath:dstPath] == NO) {
                NSString *symPath = [NSString stringWithFormat:@"%@/%@", ubiquityDocFolder, relativePath];
                BOOL success = YES;
                
                if ([FileUtil isSymbolicLink:dstPath]) {
                    success = [FileUtil removeItemAtPath:dstPath];
                }
                if (success) {
                    [FileUtil createSymbolicLinkAtPath:dstPath
                                   withDestinationPath:symPath];
                }
            }
        }
    }
}

- (BOOL) removeOrphanFiles {

    BOOL removed = NO;
//    NSString *iCloudAdminFolder = [_documentsDir relativePath];
    // iCloud 管理ディレクトリ（ユビキティー・コンテナ）からの相対パス
    // サンドボックス・コンテナ書類のルートパス
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:k_iCloudDocumentPath error:nil];

    for (NSString *fileName in fileNames) {
        NSString *extension = [[fileName pathExtension] lowercaseString];

        if ([extension isEqualToString:@"xml"]) {
            NSString *path = [NSString stringWithFormat:@"%@/%@", k_iCloudDocumentPath, fileName];
            NSURL *adminUrl = [self sandboxURL:path];

            // ユビタスか否かは iCloud 管理ディレクトリ（ユビキティー・コンテナ）を見ないと分からん。
            if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:adminUrl] == NO)
            {// 孤児なので削除する。
                NSLog(@"孤児「%@」を削除！！", fileName);
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                removed = YES;
            }
//            DEBUG_LOG(@"%@[%d]", fileName, [[NSFileManager defaultManager] isUbiquitousItemAtURL:adminUrl]);
        }
    }
    return removed;
}

- (BOOL) downloadFileIfNotAvailable:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
#if (ICLOUD_LOG == 1)
    DEBUG_LOG(@"%s %@", __func__, [file path]);
#endif

    NSNumber *isIniCloud = nil;
    BOOL result = YES; // 【注意】Return YES as long as an explicit download was not started.
    
    NSError *error = nil;
    if ([file getResourceValue:&isIniCloud
                        forKey:NSURLIsUbiquitousItemKey
                         error:&error]) {
        // If the item is in iCloud, see its progress of downloading.
        if (error == nil) {
            if ([isIniCloud boolValue]) {
#if 1
                NSNumber *isDownloaded = nil;
                
                if ([file getResourceValue:&isDownloaded
                                    forKey:NSURLUbiquitousItemIsDownloadedKey
                                     error:&error]) {
                    if (error == nil && [isDownloaded boolValue] == NO) {
                        // Download the file.
                        [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:file error:&error];
                        if (error == nil) {
                            result = NO;
                        }
                    }
                }
#else
                NSNumber *downloadedPercentage = nil;
                NSNumber *isDownloaded = nil;
                BOOL downloadCompleted = NO;
                
                [file getResourceValue:&downloadedPercentage
                                forKey:NSMetadataUbiquitousItemPercentDownloadedKey
                                 error:&error];
                if (error == nil && [downloadedPercentage floatValue] == 100.0) {
                    downloadCompleted = YES;
                }
                if (downloadCompleted == NO) {
                    [file getResourceValue:&isDownloaded
                                    forKey:NSMetadataUbiquitousItemIsDownloadedKey
                                     error:&error];
                    if (error == nil && [isDownloaded boolValue] == YES) {
                        downloadCompleted = YES;
                    }
                }
                if (downloadCompleted == NO) {
                    // Download the file.
                    [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:file error:&error];
                    if (error == nil) {
                        result = NO;
                    }
                }
#endif
            }
        }
    }
    if (error) {
        self.error = error;
        self.error2 = error;
        DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        
        NSString *path = [file path];
        if ([_corruptedLevel2Paths containsObject:path] == NO) {
            [_corruptedLevel2Paths addObject:path];
        }
    }
    // Return YES as long as an explicit download was not started.
    return result;
#else
    return NO;
#endif
}

#pragma mark - Probe Status

- (BOOL) is_iCloudStored:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//    DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    NSNumber *isIniCloud = nil;
    
    NSError *error = nil;
    if ([file getResourceValue:&isIniCloud
                        forKey:NSURLIsUbiquitousItemKey
                         error:&error]) {
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        return ([isIniCloud boolValue]);
    } else {
        return NO;
    }
#else
    return NO;
#endif
}

- (BOOL) is_iCloudDownloaded:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//    DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    
    if (result) {
        // If the item is in iCloud, see if it is downloaded.
        NSNumber *isDownloaded = nil;
        
        NSError *error = nil;
        result = [file getResourceValue:&isDownloaded
                                 forKey:NSURLUbiquitousItemIsDownloadedKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (result) {
            result = [isDownloaded boolValue];
        }
    }
    return result;
#else
    return NO;
#endif
}

- (BOOL) is_iCloudDownloading:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//    DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    
    if (result) {
        // If the item is in iCloud, see if it is downloading.
        NSNumber *isDownloading = nil;
        
        NSError *error = nil;
        result = [file getResourceValue:&isDownloading
                                 forKey:NSURLUbiquitousItemIsDownloadingKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (result) {
            result = [isDownloading boolValue];
        }
    }
    return result;
#else
    return NO;
#endif
}

/* Deprecated in iOS 6.0
- (CGFloat) iCloudDownloadedPercent:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//    DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    CGFloat value = 0.0;
    
    if (result) {
        // If the item is in iCloud, get percent downloaded.
        NSNumber *percentDownloaded = nil;
        
        NSError *error = nil;
        result = [file getResourceValue:&percentDownloaded
                                 forKey:NSURLUbiquitousItemPercentDownloadedKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (result) {
            value = [percentDownloaded floatValue];
        }
    }
    return value;
#else
    return 0.0;
#endif
}
*/

- (BOOL) is_iCloudUploaded:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//    DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    
    if (result) {
        // If the item is in iCloud, see if it is uploaded.
        NSNumber *isUploaded = nil;
        
        NSError *error = nil;
        result = [file getResourceValue:&isUploaded
                                 forKey:NSURLUbiquitousItemIsUploadedKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (result) {
            result = [isUploaded boolValue];
        }
    }
    return result;
#else
    return NO;
#endif
}

- (BOOL) is_iCloudUploading:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//    DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    
    if (result) {
        // If the item is in iCloud, see if it is uploading.
        NSNumber *isUploading = nil;
        
        NSError *error = nil;
        result = [file getResourceValue:&isUploading
                                 forKey:NSURLUbiquitousItemIsUploadingKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (result) {
            result = [isUploading boolValue];
        }
    }
    return result;
#else
    return NO;
#endif
}

/* Deprecated in iOS 6.0
- (CGFloat) iCloudUploadedPercent:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//    DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    CGFloat value = 0.0;
    
    if (result) {
        // If the item is in iCloud, get percent downloaded.
        NSNumber *percentUploaded = nil;
        
        NSError *error = nil;
        result = [file getResourceValue:&percentUploaded
                                 forKey:NSURLUbiquitousItemPercentUploadedKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (result) {
            value = [percentUploaded floatValue];
        }
    }
    return value;
#else
    return 0.0;
#endif
}
*/

- (NSNumber *) iCloudFileSize:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//  DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    NSNumber *size = nil;
    
    if (result) {        
        NSError *error = nil;
        result = [file getResourceValue:&size
                                 forKey:NSURLFileSizeKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (! result) {
            size = nil;
        }
    }
    return size;
#else
    return nil;
#endif
}

- (NSDate *) iCloudFileCreationDate:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//  DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    NSDate *date = nil;
    
    if (result) {        
        NSError *error = nil;
        result = [file getResourceValue:&date
                                 forKey:NSURLCreationDateKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (! result) {
            date = nil;
        }
    }
    return date;
#else
    return nil;
#endif
}

- (NSDate *) iCloudFileModificationDate:(NSURL *)file {
    
#if (ICLOUD_ENABLD == 1)
    
//  DEBUG_LOG(@"%s %@", __func__, [file path]);
    
    BOOL result = [self is_iCloudStored:file];
    NSDate *date = nil;
    
    if (result) {        
        NSError *error = nil;
        result = [file getResourceValue:&date
                                 forKey:NSURLContentModificationDateKey
                                  error:&error];
        if (error) {
            self.error = error;
            DEBUG_LOG(@"%s iCloud Error Line(%d):%@", __func__, __LINE__, error);
        }
        if (! result) {
            date = nil;
        }
    }
    return date;
#else
    return nil;
#endif
}

#pragma mark - Request Timer

// リクエスト完了時の処理
- (void) requestCompleted:(NSString *)message {
    
#if (ICLOUD_LOG == 1)
    DEBUG_LOG(@"リクエスト完了[%@]", message);
#endif

    if ([NSThread isMainThread] == NO)
    {// NSTimer をメインスレッドでインストールしたので、invalidate はメインスレッドで実行する。
        [self performSelectorOnMainThread:@selector(requestCompleted:)
                               withObject:message
                            waitUntilDone:YES];  // 同期する。
    } else {
        if ([_requestTimer isValid]) {
            [_requestTimer invalidate];
        }
        self.requestTimer = nil;
        
        _networkRequestCount--;
#if (ICLOUD_LOG == 1)
        DEBUG_LOG(@"リクエスト数--:%ld", (long)_networkRequestCount);
#endif
        if (_networkRequestCount <= 0) {
            // ステータスバーのインジケータのアニメーションを停止。
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            _networkRequestCount = 0;
        }
    }
}

// 30秒のタイマーを生成し、リクエストの完了を監視する。
// 【注意】timerWithTimeInterval の target で指定した親方（iCloud）は任意のタイミングで生成
//       廃棄される。よって、iCloud の生成・廃棄のシーンに際しては、予め NSTimer を
//       invalidate して nil にすること。cf.setupByPreferences
- (void) requestTimerStart {

#if (ICLOUD_LOG == 1)
    DEBUG_LOG(@"%s", __func__);
#endif

    if ([NSThread isMainThread] == NO)
    {// timerWithTimeInterval はスレッドセーフでないので、メインスレッドで実行させる。
        [self performSelectorOnMainThread:@selector(requestTimerStart)
                               withObject:nil
                            waitUntilDone:YES]; // 同期する。
    } else {
        if ([_requestTimer isValid]) {
            [_requestTimer invalidate];
        }
        self.requestTimer = [NSTimer timerWithTimeInterval:30.0
                                                    target:self
                                                  selector:@selector(requestTimerFired:)
                                                  userInfo:nil
                                                   repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_requestTimer
                                     forMode:NSDefaultRunLoopMode];
        // ステータスバーのインジケータのアニメーションを開始。
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        _networkRequestCount++;

#if (ICLOUD_LOG == 1)
        DEBUG_LOG(@"リクエスト数++:%ld", (long)_networkRequestCount);
#endif
    }
}

// リクエストがタイムアウトした場合の処理
// 【注意】timerWithTimeInterval の target で指定した親方（iCloud）は任意のタイミングで生成
//       廃棄される。よって、iCloud の生成・廃棄のシーンに際しては、予め NSTimer を
//       invalidate して nil にすること。cf.setupByPreferences
- (void) requestTimerFired:(NSTimer *)timer {

    DEBUG_LOG(@"%s", __func__);

    if ([NSThread isMainThread] == NO)
    {// NSTimer をメインスレッドでインストールしたので、invalidate はメインスレッドで実行する。
        [self performSelectorOnMainThread:@selector(requestTimerFired:)
                               withObject:timer
                            waitUntilDone:YES]; // 同期する。
    } else {
        if (timer == _requestTimer)
        {
            DEBUG_LOG(@"リクエスト異常終了[タイムアウト]");
            DEBUG_LOG(@"%s %@", __func__, ((NSMetadataQuery *) _query).predicate);

            _networkRequestCount = 0;
            // ステータスバーのインジケータのアニメーションを停止。
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

            // クエリー実行中であれば、クエリーを停止する。
            if ([_query isGathering]) {
                [_query stopQuery];
            }
            if ([_requestTimer isValid]) {
                [_requestTimer invalidate];
            }
            self.requestTimer = nil;
        }
    }
}
@end
