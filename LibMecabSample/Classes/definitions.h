//
//  definitions.h
//  LibMecabSample
//
//  Created by tmatsugaki on 2015/11/24.
//
//

#ifndef definitions_h
#define definitions_h

// パス
#define kDocumentPath   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
// 例文ライブラリの XML ファイルのパス
#define kLibXMLPath     [kDocumentPath stringByAppendingPathComponent:@"Sentences.xml"]

// ユーザーデフォルト
#define kDefaultsPatchMode  @"PatchMode"            // パッチモードを保持する。
#define kDefaultsSentence   @"EvaluatingSentence"   // 評価中の文字列を保持する。

#ifdef DEBUG
#define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#define LOG_CURRENT_METHOD NSLog(NSStringFromSelector(_cmd))
#else
#define DEBUG_LOG(...) ;
#define LOG_CURRENT_METHOD ;
#endif

#endif /* definitions_h */
