//
//  LibMecabSampleAppDelegate.h
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCloudStorage.h"

@class LibMecabSampleViewController;

@interface LibMecabSampleAppDelegate : NSObject <UIApplicationDelegate, iCloudStorageDelegate> {
    UIWindow *_window;
    LibMecabSampleViewController *_viewController;

    iCloudStorage *_iCloudStorage;
    NSURL *_ubiquityContainerURL;
    NSInteger _listingCountByUpdate;
    
    BOOL _use_iCloud;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet LibMecabSampleViewController *viewController;
@property (nonatomic, retain) iCloudStorage *iCloudStorage;
@property (retain, nonatomic) NSURL *ubiquityContainerURL;
@property (assign, nonatomic) NSInteger listingCountByUpdate;
@property (assign, nonatomic) BOOL use_iCloud;

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

@end

