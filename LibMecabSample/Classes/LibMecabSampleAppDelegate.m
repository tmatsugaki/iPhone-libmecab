//
//  LibMecabSampleAppDelegate.m
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "definitions.h"
#import "LibMecabSampleAppDelegate.h"
#import "LibMecabSampleViewController.h"

@implementation LibMecabSampleAppDelegate

@synthesize window=_window;
@synthesize viewController=_viewController;
@synthesize iCloudStorage=_iCloudStorage;
@synthesize ubiquityContainerURL=_ubiquityContainerURL;
@synthesize listingCountByUpdate=_listingCountByUpdate;
@synthesize use_iCloud=_use_iCloud;

NSString * const iCloudListingNotification                  = @"iCloudListing";
NSString * const iCloudSyncNotification                     = @"iCloudSync";
NSString * const iCloudDeletedNotification                  = @"iCloudDeleted";

#pragma mark - Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.

    // Add the view controller's view to the window and display.
    [self.window addSubview:_viewController.view];
    [self.window makeKeyAndVisible];

    // 罫線を突き抜けさせる。
    [[UITableViewCell appearance] setSeparatorInset:UIEdgeInsetsZero];

    [self createDocumentFolder];
    [self create_iCloudFolder];
    [self createXMLFolder];
    [self createWorkFolder];
    [self init_iCloud];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark - Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

#pragma mark - 使い捨て（キャッシュ）ファイル用のディレクトリ

/*
 * キャッシュには Documents, xml, iCloud, work のフォルダを作成する。
 */
// キャッシュドキュメントの基底パスを返す。
// kCachedDocumentRoot（tmp/Documents）が無ければ作成する。
- (NSString *) cachedDocumentFolderPath {
    return [kCachedDocumentPath stringByAppendingPathComponent:LOCAL_CACHE_FOLDER_NAME];
}

// キャッシュディレクトリ(Library/Caches/Documents/)を構築する。
- (BOOL) createDocumentFolder {
    
#if (LOG == ON)
    DEBUG_LOG(@"%s", __func__);
#endif
    NSString *toPath = kCachedDocumentPath;
    //
    BOOL ret = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:toPath] == NO) {
        ret = [[NSFileManager defaultManager] createDirectoryAtPath:toPath
                                        withIntermediateDirectories:YES
                                                         attributes:nil
                                                              error:nil];
    }
    return ret;
}

// キャッシュディレクトリ(Library/Caches/xml/)を構築する。
- (BOOL) createXMLFolder {
    
#if (LOG == ON)
    DEBUG_LOG(@"%s", __func__);
#endif
    NSString *toPath = kCachedXMLPath;
    //
    BOOL ret = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:toPath] == NO) {
        ret = [[NSFileManager defaultManager] createDirectoryAtPath:toPath
                                        withIntermediateDirectories:YES
                                                         attributes:nil
                                                              error:nil];
    }
    return ret;
}

// キャッシュディレクトリ(Library/Caches/work/)を構築する。
- (BOOL) createWorkFolder {
    
#if (LOG == ON)
    DEBUG_LOG(@"%s", __func__);
#endif
    NSString *toPath = kCachedWorkPath;
    //
    BOOL ret = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:toPath] == NO) {
        ret = [[NSFileManager defaultManager] createDirectoryAtPath:toPath
                                        withIntermediateDirectories:YES
                                                         attributes:nil
                                                              error:nil];
    }
    return ret;
}

- (BOOL) create_iCloudFolder {
    
#if (LOG == ON)
    DEBUG_LOG(@"%s", __func__);
#endif
    // サンドボックス・コンテナ(~/Documents/.iCloud/ または Library/Caches/Documents/iCloud)を構築する。
    NSString *sandboxDocFolder = [iCloudStorage sandboxContainerDocPath];
    //
    BOOL ret = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:sandboxDocFolder] == NO) {
        ret = [[NSFileManager defaultManager] createDirectoryAtPath:sandboxDocFolder
                                        withIntermediateDirectories:YES
                                                         attributes:nil
                                                              error:nil];
    }
    return ret;
}

#pragma mark - iCloud Utility

- (void) init_iCloud {
    
    DEBUG_LOG(@"%s", __func__);
    
#if (!TARGET_IPHONE_SIMULATOR)
    // 【注意】iCloud をサポートしている場合はコンテナ・ドキュメントURLを取得する。
    self.ubiquityContainerURL = [self ubiquitousDocumentsDirectoryURL];
    DEBUG_LOG(@"Ubiquity Container URL: %@", [_ubiquityContainerURL relativePath]);
    if (_ubiquityContainerURL) {
        self.iCloudStorage = [[iCloudStorage alloc] initWithURL:_ubiquityContainerURL];
        _iCloudStorage.delegate = self;
    }
#endif
}

- (void) requestLoad:(NSString *)path {
    
    DEBUG_LOG(@"%s", __func__);
    
    if (_iCloudStorage) {
        [_iCloudStorage requestLoad:path];
    }
}

// ダウンロードパス＋ファイル名でのアクセスを考慮しているので注意！！
- (BOOL) enqueue_iCloudPublish:(NSString *)path {
    
    DEBUG_LOG(@"%s", __func__);
    
    BOOL invoked = NO;
    
    if (_iCloudStorage) {
        NSString *sandboxDocFolder = [iCloudStorage sandboxContainerDocPath];
        NSString *fileName = nil;
        NSString *targetFilePath = nil;
        BOOL isDirectory = NO;
        
#ifdef DEBUG
        NSAssert([path isAbsolutePath], @"Should be Absolute Path");
#endif
        if ([path isAbsolutePath])
        {// path がフルパスの場合
            fileName = [path lastPathComponent];
            targetFilePath = path;
        }
        
        if ([targetFilePath hasPrefix:sandboxDocFolder])
        {// iCloud が使用可能で、path がサンドボックスコンテナ内なら
            if ([[NSFileManager defaultManager] fileExistsAtPath:targetFilePath isDirectory:&isDirectory]) {
                NSURL *url  = [NSURL fileURLWithPath:targetFilePath
                                         isDirectory:isDirectory];
                if (url)
                {// ユビタスか否かはユビキティー・コンテナを見ないと分からん。
                    if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:url] == NO)
                    {// iCloud へのファイル転送をキューイングする。
                        FileRepresentation *fileRepresentation = [[FileRepresentation alloc] initWithFileName:fileName
                                                                                                          url:url];
                        [_iCloudStorage moveFileToiCloud:fileRepresentation];
                        invoked = YES;
                    }
                }
            }
        }
    }
    return invoked;
}

/*
 - (BOOL) enqueue_iCloudPublishHier:(NSString *)path {
 
 BOOL invoked = NO;
 
 if (_iCloud) {
 NSString *sandboxDocFolder = [iCloudStorage sandboxContainerDocPath];
 NSString *fileName = [path lastPathComponent];
 BOOL isDirectory = NO;
 
 if ([path hasPrefix:iCloudFolder])
 {// iCloud が使用可能で、path がサンドボックスコンテナ内なら
 if ([FileUtil fileExistsAtPath:path isDirectory:&isDirectory]) {
 if (isDirectory)
 {// サンドボックス・コンテナのファイル
 int documentPlace = kDocumentPlaceDefault;
 NSRange range;
 
 range = [path rangeOfString:kCachedDocumentPath];
 if (range.location != NSNotFound) {
 documentPlace = kDocumentPlaceCached;
 } else {
 range = [path rangeOfString:k_iCloudDocumentPath];
 if (range.location != NSNotFound) {
 documentPlace = kDocumentPlace_iCloud;
 }
 }
 NSArray *files = [FileUtil dirFileSpecs:path];
 
 for (FileSpec *spec in files) {
 //
 [_iCloud getAllAttributes:spec.path fileSpec:spec];
 
 [self enqueue_iCloudPublishHier:spec.path];
 }
 } else {
 NSURL *url = [NSURL fileURLWithPath:path
 isDirectory:isDirectory];
 if (url)
 {// ユビタスか否かはユビキティー・コンテナを見ないと分からん。
 if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:url] == NO)
 {// iCloud へのファイル転送をキューイングする。
 FileRepresentation *fileRepresentation = [[[FileRepresentation alloc] initWithFileName:fileName
 url:url] autorelease];
 [_iCloud moveFileToiCloud:fileRepresentation];
 invoked = YES;
 }
 }
 }
 }
 }
 }
 return invoked;
 }
 */

- (BOOL) enqueue_iCloudStopPublishing:(NSString *)path {
    
    DEBUG_LOG(@"%s", __func__);
    
    BOOL invoked = NO;
    
    if (_iCloudStorage) {
        NSString *sandboxDocFolder = [iCloudStorage sandboxContainerDocPath];
        NSString *fileName = [path lastPathComponent];
        BOOL isDirectory = NO;
        
        if ([path hasPrefix:sandboxDocFolder])
        {// iCloud が使用可能で、path がサンドボックスコンテナ内なら
            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
                NSURL *url  = [_iCloudStorage sandboxURL:path];
                if (url)
                {// ユビタスか否かはユビキティー・コンテナを見ないと分からん。
                    if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:url])
                    {// iCloud からのファイル転送をキューイングする。
                        FileRepresentation *fileRepresentation = [[FileRepresentation alloc] initWithFileName:fileName
                                                                                                          url:url];
                        [_iCloudStorage moveFileToLocal:fileRepresentation];
                        invoked = YES;
                    } else
                    {// ユーザーアプリからでなく、システムツールでファイルを消すと、サンドボックスコンテナにファイルは
                        // 有る事は間違いないが、ユビキタスでない孤児になっている模様！！
                        // なので、削除する。
                        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                    }
                }
            }
        }
    }
    return invoked;
}

- (BOOL) enqueue_iCloudModify:(NSString *)path
                         data:(NSData *)data {
    
    DEBUG_LOG(@"%s", __func__);
    
    BOOL delegated = NO;
    
    if (_iCloudStorage) {
        NSString *sandboxDocFolder = [iCloudStorage sandboxContainerDocPath];
        
        if ([path hasPrefix:sandboxDocFolder])
        {// iCloud が使用可能で、置換するファイルが iCloud なら
            NSURL *adminUrl = [_iCloudStorage sandboxURL:path];
            
            if (adminUrl)
            {// ユビタスか否かはユビキティー・コンテナを見ないと分からん。
                if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:adminUrl])
                {// iCloud へファイル置換をキューイングする。
                    FileRepresentation *fileRepresentation = [[FileRepresentation alloc] initWithFileName:[path lastPathComponent]
                                                                                                      url:adminUrl];
                    [_iCloudStorage modifyFile:fileRepresentation
                                          data:data];
                    delegated = YES;
                } else
                {// ユーザーアプリからでなく、システムツールでファイルを消すと、サンドボックスコンテナにファイルは
                    // 有る事は間違いないが、ユビキタスでない孤児になっている模様！！
                    // なので、削除する。
//                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                    DEBUG_LOG(@"%s", __func__);
                }
            }
        }
    }
    return delegated;
}

- (BOOL) enqueue_iCloudDelete:(NSString *)path {
    
    DEBUG_LOG(@"%s", __func__);
    
    BOOL invoked = NO;
    
    if (_iCloudStorage) {
        NSString *sandboxDocFolder = [iCloudStorage sandboxContainerDocPath];
        
        if ([path hasPrefix:sandboxDocFolder])
        {// iCloud が使用可能で、削除するファイルが iCloud なら
            NSURL *url = [_iCloudStorage sandboxURL:path];
            
            if (url)
            {// ユビタスか否かはユビキティー・コンテナを見ないと分からん。
                if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:url])
                {// iCloud へファイル削除をキューイングする。
                    FileRepresentation *fileRepresentation = [[FileRepresentation alloc] initWithFileName:[path lastPathComponent]
                                                                                                      url:url];
                    [_iCloudStorage deleteFile:fileRepresentation];
                    invoked = YES;
                } else
                {// ユーザーアプリからでなく、システムツールでファイルを消すと、サンドボックスコンテナにファイルは
                    // 有る事は間違いないが、ユビキタスでない孤児になっている模様！！
                    // なので、削除する。
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                }
            }
        }
    }
    return invoked;
}

- (void) get_iCloudAttributes:(NSString *)path fileSpec:(FileSpec *)fileSpec {
    
    DEBUG_LOG(@"%s", __func__);
    
    if (_iCloudStorage) {
        [_iCloudStorage get_iCloudAttributes:path
                                    fileSpec:fileSpec];
    }
}

#pragma mark - iCloud Primitives

// file://localhost/private/var/mobile/Library/Mobile%20Documents/iCloud~jp~mydns~rikki~HinshiMaster/
//
- (NSURL *) ubiquitousContainerURL {
    
    NSURL *ubiquitousContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:UbiquityContainerIdentifier];
    DEBUG_LOG(@"%s %@", __func__, ubiquitousContainerURL);
    return ubiquitousContainerURL;
}

// file://localhost/private/var/mobile/Library/Mobile%20Documents/iCloud~jp~mydns~rikki~HinshiMaster/Documents/
//
- (NSURL *) ubiquitousDocumentsDirectoryURL {

    NSURL *ubiquitousContainerURL = [self ubiquitousContainerURL];
    NSURL *dirURL = nil;
    
    if (ubiquitousContainerURL) {
        dirURL = [ubiquitousContainerURL URLByAppendingPathComponent:@"Documents"];
    }
    DEBUG_LOG(@"%s %@", __func__, dirURL);
    return dirURL;
}

#pragma mark - iCloudStorageDelegate

- (void) iCloudManageNotify:(NSString *)fileName
                 completion:(BOOL)completion {
    DEBUG_LOG(@"【iCloud】%s \"%@\" が管理対象にする様要請しました。状況[%@]", __func__, fileName, completion ? @"エラーなし" : @"エラー");
}

- (void) iCloudUnmanageNotify:(NSString *)fileName
                   completion:(BOOL)completion {
    DEBUG_LOG(@"【iCloud】%s \"%@\" を管理対象からの除外を要請しました。状況[%@]", __func__, fileName, completion ? @"エラーなし" : @"エラー");
}

- (void) iCloudModifyNotify:(NSString *)fileName
                 completion:(BOOL)completion {
    DEBUG_LOG(@"【iCloud】%s \"%@\" の更新を要請しました。状況[%@]", __func__, fileName, completion ? @"エラーなし" : @"エラー");
}

- (void) iCloudDeleteNotify:(NSString *)fileName
                 completion:(BOOL)completion {
    DEBUG_LOG(@"【iCloud】%s \"%@\" の削除を要請しました。状況[%@]", __func__, fileName, completion ? @"エラーなし" : @"エラー");
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    //
    [userInfo setObject:[self class] forKey:@"class"];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:iCloudDeletedNotification
                                                                                         object:self
                                                                                       userInfo:userInfo]];
    
    //    NSString *path = [[iCloudStorage sandboxContainerDocPath] stringByAppendingPathComponent:fileName];
    //    NSDate *modDate = [FileUtil modificationDate:path];
    //    if ([[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_ICLOUD_BACKUP_DATE_KEY] isEqualToString:[modDate description]])
    //    {// 自分自身がバックアップしたので、iCloud からの更新が主導ではない。
    //    } else {
    // iCloud書類が更新されたことを保持する。
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULT_ICLOUD_DOC_UPDATED_KEY];
    //    }
}

- (void) iCloudUpdatedNotify:(NSArray *)files {
    
    if ([files count]) {
        DEBUG_LOG(@"【iCloud】%s [%lu]個のファイルが更新されましたので、リスト要求をします。", __func__, (unsigned long)[files count]);
        for (NSUInteger i = 0; i < [files count]; i++) {
            DEBUG_LOG(@"%02lu[%@]", (unsigned long)i, files[i]);
        }
        // 更新があったので、リスト要求する。
        [_iCloudStorage requestListing:files[0]];
    }
}

// syncToLocal 後に呼ばれる。
- (void) iCloudListReceivedNotify:(NSUInteger)numTunes {
    DEBUG_LOG(@"【iCloud】%s [%lu]個のファイルを受信しました。", __func__, (unsigned long)numTunes);
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    // ユーザーデフォルトの設定が変わったことを通知する。
    [userInfo setObject:[self class] forKey:@"class"];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:iCloudListingNotification
                                                                                         object:self
                                                                                       userInfo:userInfo]];
}

- (void) iCloudSynchronizedNotify:(NSString *)fileName {
    DEBUG_LOG(@"【iCloud】%s \"%@\" が同期されました。", __func__, fileName);
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    // ユーザーデフォルトの設定が変わったことを通知する。
    [userInfo setObject:[self class] forKey:@"class"];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:iCloudSyncNotification
                                                                                         object:self
                                                                                       userInfo:userInfo]];
    
    //    NSString *path = [[iCloudStorage sandboxContainerDocPath] stringByAppendingPathComponent:fileName];
    //    NSDate *modDate = [FileUtil modificationDate:path];
    //    if ([[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_ICLOUD_BACKUP_DATE_KEY] isEqualToString:[modDate description]])
    //    {// 自分自身がバックアップしたので、iCloud からの更新が主導ではない。
    //    } else {
    // iCloud書類が更新されたことを保持する。
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULT_ICLOUD_DOC_UPDATED_KEY];
    //    }
}

- (void)dealloc {

    [_viewController release];
    [_window release];
    [_iCloudStorage release];
    
    [super dealloc];
}

@end
