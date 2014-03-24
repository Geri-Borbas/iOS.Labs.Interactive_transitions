//
//  EPPZTransition.protected.h
//  InteractiveTransition
//
//  Created by Carnation on 24/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import "EPPZTransition.h"


@class EPPZTransition;
@protocol EPPZTransitionDebugDelegate <NSObject>
-(void)interactiveTransitionDidChage:(EPPZTransition*) transition;
@end


@interface EPPZTransition (Debug)

@property (nonatomic, weak) UIView *presenterView;
@property (nonatomic, weak) UIView *modalView;
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic) CGFloat deltaPercent;

@property (nonatomic, weak) id <EPPZTransitionDebugDelegate> delegate;


@end
