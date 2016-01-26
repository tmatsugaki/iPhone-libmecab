//
//  LibMecabSampleAppDelegate.h
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>
#if ICLOUD_ENABLD
#import "iCloudStorage.h"
#endif

@class LibMecabSampleViewController;

#if ICLOUD_ENABLD
@interface LibMecabSampleAppDelegate : NSObject <UIApplicationDelegate, iCloudStorageDelegate> {
    UIWindow *_window;
    LibMecabSampleViewController *_viewController;
    
#if ICLOUD_ENABLD
    iCloudStorage *_iCloudStorage;
    NSURL *_ubiquityContainerURL;
    NSInteger _listingCountByUpdate;
#endif
    BOOL _use_iCloud;
}
#else
@interface LibMecabSampleAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *_window;
    LibMecabSampleViewController *_viewController;
    BOOL _use_iCloud;
    BOOL _incrementalSearch;
}
#endif

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet LibMecabSampleViewController *viewController;
#if ICLOUD_ENABLD
@property (nonatomic, retain) iCloudStorage *iCloudStorage;
@property (retain, nonatomic) NSURL *ubiquityContainerURL;
@property (assign, nonatomic) NSInteger listingCountByUpdate;
#endif
@property (assign, nonatomic) BOOL use_iCloud;
@property (assign, nonatomic) BOOL incrementalSearch;

#if ICLOUD_ENABLD
// iCloud
- (void) init_iCloud;
- (void) saveTo_iCloud;
- (void) loadFrom_iCloud;

- (void) requestLoad:(NSString *)path;                                          // パスはサンドボックスコンテナ内であること
- (BOOL) enqueue_iCloudPublish:(NSString *)path;                                // パスはサンドボックスコンテナ内であること
//- (BOOL) enqueue_iCloudStopPublishing:(NSString *)path;                         // パスはサンドボックスコンテナ内であること
- (BOOL) enqueue_iCloudModify:(NSString *)path data:(NSData *)data;             // パスはサンドボックスコンテナ内であること
//- (BOOL) enqueue_iCloudDelete:(NSString *)path;                                 // パスはサンドボックスコンテナ内であること
//- (void) get_iCloudAttributes:(NSString *)path fileSpec:(FileSpec *)fileSpec;   // パスはサンドボックスコンテナ内であること
#endif

@end

