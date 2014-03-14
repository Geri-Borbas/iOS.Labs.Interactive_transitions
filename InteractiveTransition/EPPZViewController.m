//
//  EPPZViewController.m
//  InteractiveTransition
//
//  Created by Carnation on 14/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import "EPPZViewController.h"
#import "EPPZModalViewController.h"


@interface EPPZViewController ()

    <

    UIViewControllerTransitioningDelegate,
    /*
     -[NSObject animationControllerForPresentedController:presentingController:sourceController:]
     -[NSObject animationControllerForDismissedController:]
     -[NSObject interactionControllerForPresentation:]
     -[NSObject interactionControllerForDismissal:]
    */

    UIViewControllerAnimatedTransitioning,
    /*
     -[NSObject transitionDuration:]
     -[NSObject animateTransition:] // This method can only be a nop if the transition is interactive and not a percentDriven interactive transition.
    */

    UIViewControllerInteractiveTransitioning
    /*
     -[NSObject startInteractiveTransition:]
     -[NSObject completionSpeed]
     -[NSObject completionCurve]
    */

    >

@property (nonatomic) BOOL interactive;
@property (nonatomic) BOOL presenting;
@property (nonatomic, strong) id <UIViewControllerContextTransitioning> transitionContext;

@end


@implementation EPPZViewController


-(void)viewDidLoad
{
    [super viewDidLoad];
    [self addGestureRecognizer];
}


#pragma mark - Gestures

-(void)addGestureRecognizer
{
    // Create pan recognizer.
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGestureRecognizer.minimumNumberOfTouches = 1;
    
    // Add to view.
    [self.view addGestureRecognizer:panGestureRecognizer];
}


-(void)handlePan:(UIPanGestureRecognizer*) panGesture
{
    // Get translation.
    CGPoint location = [panGesture locationInView:panGesture.view];
    CGPoint velocityVectorPoint = [panGesture velocityInView:panGesture.view];
    // CGFloat verticalVelocity = velocityVectorPoint.y;
    static CGPoint touchPoint;
    
    // Calculate percentage.
    CGFloat percent;
    if (CGPointEqualToPoint(touchPoint, CGPointZero) == NO)
    { percent = (touchPoint.y - location.y) / panGesture.view.bounds.size.height; }
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan :
        {
            touchPoint = location;
            self.interactive = YES;
            
            // Present.
            if (location.x < CGRectGetMidX(panGesture.view.bounds))
            {
                self.presenting = YES;
                
                EPPZModalViewController *modalViewController = [[EPPZModalViewController alloc] initWithNibName:@"EPPZModalViewController" bundle:nil];
                modalViewController.modalPresentationStyle = UIModalPresentationCustom;
                modalViewController.transitioningDelegate = self;
            
                [self presentViewController:modalViewController
                                   animated:YES
                                 completion:nil];
            }
            
            // Dismiss.
            else
            {
                [self.parentViewController dismissViewControllerAnimated:YES
                                                              completion:nil];
            }
            
            
            
            break;
        }
            
        case UIGestureRecognizerStateChanged :
        {
            [self updateInteractiveTransition:percent];
            // NSLog(@"%.2f%% %.2f", percent * 100, verticalVelocity);
            
            break;
        }
            
        case UIGestureRecognizerStateEnded :
        case UIGestureRecognizerStateCancelled :
        {
            // Inspect for cancellation.
            BOOL cancelled = ( /* verticalVelocity < 5.0 && */ fabsf(percent) <= 0.3);
            
            // Depending on our state and the velocity, determine whether to cancel or complete the transition.
            /*
            if (self.presenting)
            {
                if (velocity.x > 0)
                { [self finishInteractiveTransition]; }
                else
                { [self cancelInteractiveTransition]; }
            }
            else
            {
                if (velocity.x < 0) {
                    [self finishInteractiveTransition];
                }
                else {
                    [self cancelInteractiveTransition];
                }
            }
            */
             
            // Finish or cancel transition.
            if (cancelled) NSLog(@"Cancel"); // [self cancelInteractiveTransition];
            else NSLog(@"Finish"); // [self finishInteractiveTransition];
            
            break;
        }
            
        case UIGestureRecognizerStatePossible :
        case UIGestureRecognizerStateFailed :
        default :
        {
            break;
        }
    }
}


#pragma mark - Animated transitioning delegate (is self)

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController*) presented
                                                                 presentingController:(UIViewController*) presenting
                                                                     sourceController:(UIViewController*) source
{ return self; }

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController*) dismissed
{ return self; }


#pragma mark - Interactor (is self)

-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>) animator
{ return (self.interactive) ? self : nil; }

-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>) animator
{ return (self.interactive) ? self : nil; }


#pragma mark - Animation (non interactive)

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>) transitionContext
{ return 2.0; }

-(void)animateTransition:(id<UIViewControllerContextTransitioning>) transitionContext
{
    // Do nothing when interactive.
    if (self.interactive) return;
    
    // This code is lifted wholesale from the TLTransitionAnimator class.
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect endFrame = [[transitionContext containerView] bounds];
    if (self.presenting)
    {
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        
        CGRect startFrame = endFrame;
        startFrame.origin.x -= CGRectGetWidth([[transitionContext containerView] bounds]);
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^
        { toViewController.view.frame = endFrame; }
                         completion:^(BOOL finished)
        { [transitionContext completeTransition:YES]; }];
    }
    
    else
    {
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        
        endFrame.origin.x -= CGRectGetWidth([[transitionContext containerView] bounds]);
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^
        { fromViewController.view.frame = endFrame; }
                         completion:^(BOOL finished)
        { [transitionContext completeTransition:YES]; }];
    }
}

#pragma mark - Animation (interactive)

-(void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>) transitionContext
{
    self.transitionContext = transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect frame = [[transitionContext containerView] bounds];
    
    if (self.presenting)
    {
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        
        frame.origin.x -= CGRectGetWidth([[transitionContext containerView] bounds]);
    }
    else
    {
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
    }
    
    toViewController.view.frame = frame;
}

-(void)updateInteractiveTransition:(CGFloat)percentComplete
{
    id <UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Presenting goes from 0...1 and dismissing goes from 1...0
    CGRect frame = CGRectOffset([[transitionContext containerView] bounds], -CGRectGetWidth([[transitionContext containerView] bounds]) * (1.0f - percentComplete), 0);
    
    if (self.presenting)
    {
        toViewController.view.frame = frame;
    }
    else {
        fromViewController.view.frame = frame;
    }
}

-(void)finishInteractiveTransition
{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presenting)
    {
        CGRect endFrame = [[transitionContext containerView] bounds];
        
        [UIView animateWithDuration:0.5f animations:^{
            toViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        CGRect endFrame = CGRectOffset([[transitionContext containerView] bounds], -CGRectGetWidth([[self.transitionContext containerView] bounds]), 0);
        
        [UIView animateWithDuration:0.5f animations:^{
            fromViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

-(void)cancelInteractiveTransition
{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presenting)
    {
        CGRect endFrame = CGRectOffset([[transitionContext containerView] bounds], -CGRectGetWidth([[transitionContext containerView] bounds]), 0);
        
        [UIView animateWithDuration:0.5f animations:^
        { toViewController.view.frame = endFrame; }
                         completion:^(BOOL finished)
        { [transitionContext completeTransition:NO]; }];
    }
    else
    {
        CGRect endFrame = [[transitionContext containerView] bounds];
        
        [UIView animateWithDuration:0.5f animations:^
        { fromViewController.view.frame = endFrame; }
                         completion:^(BOOL finished)
        { [transitionContext completeTransition:NO]; }];
    }
}


@end
