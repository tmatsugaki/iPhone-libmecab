// $Id: FileRepresentation.m,v 1.1.1.1 2011-03-17 07:14:34 matsu Exp $
//
//  FileRepresentation.m
//  HinshiMaster
//
//  Created by matsu on 10/09/23.
//  Copyright 2010 Takuji Matsugaki. All rights reserved.
//

#import "FileRepresentation.h"
#import "definitions.h"

@implementation FileRepresentation

@synthesize url=_url;
@synthesize fileName=_fileName;
@synthesize request=_request;

- (id) initWithFileName:(NSString *)fileName
                    url:(NSURL *)url {
#if (LOG == ON)
	DEBUG_LOG(@"%s", __func__);
#endif
    
    self = [super init];
    if (self != nil)
	{
        self.fileName = fileName;
        self.url = url;
        self.request = kFileReplReuestNone;
	}
	return self;
}

- (void) dealloc
{
}

@end
