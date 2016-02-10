//
//  definitions.h
//  LibMecabSample
//
//  Created by tmatsugaki on 2015/11/24.
//
//

#ifndef definitions_h
#define definitions_h

// 0
#define INHIBIT_BUNSETSU_WITH_SUBVERB   0
#define SHOW_DERIVED_NOUN               0
#define SHOW_RENTAIKA                   0
#define SHOW_FUKUSHIKA                  0
#define SHOW_FUKUGO_MEISHI              0

// 1
#define LOG_PATCH                       0   // 局所を解析する際には 0 する。
#define SHOW_SENTENCE                   0   // 局所を解析する際には 0 する。
#define DELETE_ANIMATION                1
#define RELOAD_WHEN_TOGGLE_EDIT         1
#define REPLACE_OBJECT                  1
#define DISPOSE_KEYBOARD_WHEN_SCROLL    1

#ifdef DEBUG
#define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#define LOG_CURRENT_METHOD NSLog(NSStringFromSelector(_cmd))
#else
#define DEBUG_LOG(...) ;
#define LOG_CURRENT_METHOD ;
#undef LOG_PATCH
#endif

// パス
#define kDocumentPath               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
// 例文ライブラリの XML ファイルのパス
#define kLibXMLName                 @"Library.xml"
#define kLibXMLPath                 [kDocumentPath stringByAppendingPathComponent:@"Library.xml"]

// ユーザーデフォルト
#define kDefaultsPatchMode          @"PatchMode"            // パッチモードを保持する。
#define kDefaultsEvaluatingSentence @"EvaluatingSentence"   // 評価中の文字列を保持する。
#define kDefaultsSearchingToken     @"SearchingToken"       // 検索中の文字列を保持する。
#define kUse_iCloudKey              @"iCloud"               // iCloud 使用フラグ
#define kIncrementalSearchKey       @"IncrementalSearch"    // インクリメンタルサーチするか否かのフラグ
#define kDevelopmentModeKey         @"DevelopmentMode"      // 開発モードか否かのフラグ

#define kTableViewBackgroundColor   [UIColor whiteColor]
#define kJiritsugoCellColor         [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.05]
#define kFuzokugoCellColor          [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.05]
#define kSelectionColor             [UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:0.5]

#define kEnabledTextColor           [UIColor colorWithRed:0.0/256.0 green:122.0/256.0 blue:255.0/256.0 alpha:1.0]
#define kDisabledTextColor          [UIColor lightGrayColor]

#define kDoubleTapDetectPeriod      0.3   // 【変更不可】0.25 秒以内にタップがされればダブルタップと見なす。

/*
  iCloud 関係
 */
#define ICLOUD_ENABLD                       1
#define ICLOUD_LOG                          0
#define ICLOUD_FALLBACK_STORE_IN_CACHE      1

#define kDocumentRoot					NSHomeDirectory()
#define kLibraryPath					[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
#define kMainBundlePath                 [[NSBundle mainBundle] bundlePath]

// ユビキティー・コンテナのパス（ドキュメントストレージの場合）
#define kHinshiMasterUbiquityCotainerPath   @"/private/var/mobile/Library/Mobile Documents/iCloud~jp~mydns~rikki~HinshiMaster/Documents"
// バックアップ対象（iCloud に保存される）
#define kPreferencesPath				[kLibraryPath stringByAppendingPathComponent:@"Preferences"]
// ~/Library/Preferences/jp.mydns.rikki.HinshiMaster.plist には、デフォルトの差分が保持されている！！

extern NSString *iCloudListingProgressNotification;
extern NSString *iCloudDownloadCompletedNotification;
extern NSString *iCloudSyncNotification;
extern NSString *iCloudDeletedNotification;

// 固定ディレクトリ名
#define SHOULDNOT_BE_ACCESSIBLE_FILE_PATH   @"/Application/Preferences.app/General.plist"
#define LOCAL_CACHE_FOLDER_NAME				@"cachedDocuments"
#define ICLOUD_FOLDER_NAME                  @"iCloud"
#define WORK_FOLDER_NAME                    @"work"

// バックアップ対象外（iCloud に保存されない）
#define kCachedDocumentPath				[kCachedDocumentRoot stringByAppendingPathComponent:@"Documents"]
#define kCachedDocumentRoot				[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
#define kCachedXMLPath                  [kCachedDocumentRoot stringByAppendingPathComponent:@"xml"]
#define k_iCloudDocumentPath			[kCachedDocumentRoot stringByAppendingPathComponent:ICLOUD_FOLDER_NAME]
#define kCachedWorkPath                 [kCachedDocumentRoot stringByAppendingPathComponent:WORK_FOLDER_NAME]

static NSString *UbiquityContainerIdentifier = @"iCloud.jp.mydns.rikki.HinshiMaster";

#endif /* definitions_h */
