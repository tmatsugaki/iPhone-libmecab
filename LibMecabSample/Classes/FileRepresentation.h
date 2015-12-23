// $Id: FileRepresentation.h,v 1.1.1.1 2011-03-17 07:14:34 matsu Exp $
//
//  FileRepresentation.h
//  Yardbird
//
//  Created by matsu on 10/09/23.
//  Copyright 2010 Takuji Matsugaki. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    kFileReplReuestNone,
    kFileReplUploadReuested,
    kFileReplDownloadReuested
};

@interface FileRepresentation : NSObject {

    NSString *_fileName;
    NSURL *_url;
    NSUInteger _request;
}
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, assign) NSUInteger request;

- (id) initWithFileName:(NSString *)fileName url:(NSURL *)url;
@end
