//
//  EPPZTransition.protected.h
//  InteractiveTransition
//
//  Created by Carnation on 24/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import "EPPZTransition.h"


typedef enum
{
    In,     // 0
    Out     // 1
} EPPZTransitionState;


@interface EPPZTransition (Protected)


#pragma mark - States

@property (nonatomic, getter=isInteractive) BOOL interactive;
@property (nonatomic) EPPZTransitionState targetState;
@property (nonatomic) BOOL canceled;


#pragma mark - Role players

@property (nonatomic, weak) id <UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, weak) UIView *presenterView;
@property (nonatomic, weak) UIView *modalView;
@property (nonatomic, weak) UIView *containerView;


#pragma mark - Animation characteristics

@property (nonatomic) CGFloat duration;
@property (nonatomic) CGFloat damping;
@property (nonatomic) CGFloat initialSpringVelocity;


#pragma mark - Methods needs to be implemented in subclass

-(void)setup;
-(void)layoutStart;
-(void)layoutEnd;

-(UIGestureRecognizer*)gestureRecognizer;
-(void)layoutInteractive:(CGFloat) percent;



@end
