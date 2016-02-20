//
//  CustomLayoutValidator.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 20/02/2016.
//  Copyright © 2016 Moritz Pflanzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomLayoutParser : NSObject

- (NSMutableArray*)parseCustomLayout:(id)customLayout error:(NSError**)error;

@end
