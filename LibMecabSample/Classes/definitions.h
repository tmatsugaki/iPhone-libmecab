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
#define INITIAL_DOC                 0
#define GIVEUP_EDIT_WHEN_SCROLL     0
#define LOG_PATCH                   1

// 1
#define DELETE_ANIMATION            1
#define RELOAD_WHEN_TOGGLE_EDIT     1

#define REPLACE_OBJECT              1

// パス
#define kDocumentPath               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
// 例文ライブラリの XML ファイルのパス
#define kLibXMLPath                 [kDocumentPath stringByAppendingPathComponent:@"Library.xml"]

// ユーザーデフォルト
#define kDefaultsPatchMode          @"PatchMode"            // パッチモードを保持する。
#define kDefaultsEvaluatingSentence @"EvaluatingSentence"   // 評価中の文字列を保持する。
#define kDefaultsSearchingToken     @"SearchingToken"       // 検索中の文字列を保持する。
#define kUse_iCloudKey              @"iCloud"               // iCloud 使用フラグ
#define kIncrementalSearchKey       @"IncrementalSearch"    // インクリメンタルサーチするか否かのフラグ（未使用）

#define kTableViewBackgroundColor   [UIColor lightTextColor]
#define kDoubleTapDetectPeriod      0.3   // 【変更不可】0.25 秒以内にタップがされればダブルタップと見なす。

#ifdef DEBUG
#define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#define LOG_CURRENT_METHOD NSLog(NSStringFromSelector(_cmd))
#else
#define DEBUG_LOG(...) ;
#define LOG_CURRENT_METHOD ;
#endif

#endif /* definitions_h */
