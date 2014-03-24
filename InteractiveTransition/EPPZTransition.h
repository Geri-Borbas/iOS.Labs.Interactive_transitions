//
//  EPPZTransition.h
//  InteractiveTransition
//
//  Created by Carnation on 24/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@class EPPZTransition;
@protocol EPPZTransitionDelegate <NSObject>
-(void)interactiveTransitionDidChage:(EPPZTransition*) transition;
@end


@interface EPPZTransition : NSObject

@end
