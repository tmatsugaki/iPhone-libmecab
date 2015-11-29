//
//  definitions.h
//  LibMecabSample
//
//  Created by matsu on 2015/11/24.
//
//

#ifndef definitions_h
#define definitions_h

// パス
#define kDocumentPath   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
#define kTokesXMLPath   [kDocumentPath stringByAppendingPathComponent:@"Tokens.xml"]

// ユーザーデフォルト
#define kDefaultsPatch   @"Patch"
#define kDefaultsToken   @"Token"

#endif /* definitions_h */
