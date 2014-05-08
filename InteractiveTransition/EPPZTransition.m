//
//  EPPZTransition.m
//  InteractiveTransition
//
//  Created by Carnation on 24/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import "EPPZTransition.protected.h"
#import "EPPZTransition.debug.h"


#define LOG_METHOD NSLog(@"%@ %@", self.class, NSStringFromSelector(_cmd));


@interface EPPZTransition ()

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

    UIViewControllerInteractiveTransitioning,
    /*
     -[NSObject startInteractiveTransition:]
     -[NSObject completionSpeed]
     -[NSObject completionCurve]
     */

    UIGestureRecognizerDelegate

    >

{
    // (Protected)
    BOOL _interactive;
    EPPZTransitionState _targetState;
    BOOL _canceled;
    
    id <UIViewControllerContextTransitioning> _transitionContext;
    UIView *_presenterView;
    UIView *_modalView;
    UIView *_containerView;
    
    CGFloat _duration;
    CGFloat _damping;
    CGFloat _initialSpringVelocity;
    
    // (Debug)
    CGFloat _deltaPercent;
    id <EPPZTransitionDebugDelegate> _delegate;
}

@property (nonatomic, strong) UIGestureRecognizer *recognizer;
@property (nonatomic, weak) UIViewController *presenterViewController;
@property (nonatomic, strong) EPPZTransitionModalViewControllerInstanceBlock modalViewControllerInstanceBlock;


@end


@implementation EPPZTransition (Protected_accessors)

-(BOOL)isInteractive { return _interactive; }
-(void)setInteractive:(BOOL) interactive { _interactive = interactive; }

-(EPPZTransitionState)targetState { return _targetState; }
-(void)setTargetState:(EPPZTransitionState) targetState { _targetState = targetState; }

-(BOOL)canceled { return _canceled; }
-(void)setCanceled:(BOOL) canceled { _canceled = canceled; }

-(id<UIViewControllerContextTransitioning>)transitionContext { return _transitionContext; }
-(void)setTransitionContext:(id<UIViewControllerContextTransitioning>) transitionContext { _transitionContext = transitionContext; }

-(UIView*)presenterView { return _presenterView; }
-(void)setPresenterView:(UIView*) presenterView { _presenterView = presenterView; }

-(UIView*)modalView { return _modalView; }
-(void)setModalView:(UIView*) modalView { _modalView = modalView; }

-(UIView*)containerView { return _containerView; }
-(void)setContainerView:(UIView*) containerView { _containerView = containerView; }

-(CGFloat)duration { return _duration; }
-(void)setDuration:(CGFloat) duration { _duration = duration; }

-(CGFloat)damping { return _damping; }
-(void)setDamping:(CGFloat) damping { _damping = damping; }

-(CGFloat)initialSpringVelocity { return _initialSpringVelocity; }
-(void)setInitialSpringVelocity:(CGFloat) initialSpringVelocity { _initialSpringVelocity = initialSpringVelocity; }

@end


@implementation EPPZTransition (Debug)

-(CGFloat)deltaPercent { return _deltaPercent; }
-(void)setDeltaPercent:(CGFloat) deltaPercent { _deltaPercent = deltaPercent; }

-(id<EPPZTransitionDebugDelegate>)delegate { return _delegate; }
-(void)setDelegate:(id<EPPZTransitionDebugDelegate>) delegate { _delegate = delegate; }

@end


@implementation EPPZTransition


#pragma mark - Creation

+(instancetype)transitionForPresenterViewController:(UIViewController*) presenterViewController
                                modalViewController:(EPPZTransitionModalViewControllerInstanceBlock) modalViewControllerInstanceBlock
{
    EPPZTransition *instance = [self new];
    instance.presenterViewController = presenterViewController;
    instance.modalViewControllerInstanceBlock = modalViewControllerInstanceBlock;
    [instance setup];
    [instance addGestureRecognizerToPresenterView];
    return instance;
}


#pragma mark - Setup

-(void)setup
{ LOG_METHOD;
    
    self.duration = 2.0;
    self.damping = 0.68;
    self.initialSpringVelocity = 0.48;
}


#pragma mark - Setup templates (override is optional)

-(void)setupPresentation
{ LOG_METHOD;
    
    // Add.
    [self.containerView addSubview:self.presenterView];
    [self.containerView insertSubview:self.modalView aboveSubview:self.presenterView];
    
    // Layout start.
    [self layoutStart];
}

-(void)setupDismissal
{ LOG_METHOD;
    
    // Views are probably already added at `setupPresentation`.
    
    // Layout end.
    [self layoutEnd];
}


#pragma mark - Layout templates (override is required)

-(void)layoutStart
{ /* Template */ }

-(void)layoutEnd
{ /* Template */ }

-(void)layoutInteractive:(CGFloat) percent
{ /* Template */ }


#pragma mark - Gestures

-(UIGestureRecognizer*)gestureRecognizer
{
    // Create pan recognizer.
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGestureRecognizer.minimumNumberOfTouches = 1;
    panGestureRecognizer.delegate = self;

    return panGestureRecognizer;
}

-(UIGestureRecognizer*)recognizer
{
    if (_recognizer == nil)
    { _recognizer = [self gestureRecognizer]; }
    return _recognizer;
}

-(void)addGestureRecognizerToPresenterView
{
    [self.presenterViewController.view removeGestureRecognizer:self.recognizer];
    [self.modalView.superview removeGestureRecognizer:self.recognizer];
    [self.presenterViewController.view addGestureRecognizer:self.recognizer]; // Add
}

-(void)addGestureRecognizerToModalView
{
    [self.presenterViewController.view removeGestureRecognizer:self.recognizer];
    [self.modalView.superview removeGestureRecognizer:self.recognizer];
    [self.modalView.superview addGestureRecognizer:self.recognizer]; // Add
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{ return YES; }

-(void)handlePan:(UIPanGestureRecognizer*) panGesture
{
    // Get translation.
    CGPoint location = [panGesture locationInView:panGesture.view];
    // CGPoint velocityVectorPoint = [panGesture velocityInView:panGesture.view];
    // CGFloat horizontalVelocity = velocityVectorPoint.x;
    static CGPoint touchPoint;
    
    // Calculate percentage.
    CGFloat deltaPercent = 0.0;
    if (CGPointEqualToPoint(touchPoint, CGPointZero) == NO)
    { deltaPercent = (location.x - touchPoint.x) / panGesture.view.bounds.size.width; }
    
    // Gesture dispatch.
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan :
        {
            touchPoint = location;
            break;
        }
            
        case UIGestureRecognizerStateChanged :
        {
            // Start if not already.
            if ([self isInteractive] == NO)
            {
                self.interactive = YES;
                
                // Present.
                BOOL presenting = (deltaPercent > 0.0);
                if (presenting)
                { [self present]; } // Sets `present` to YES internally.
                else
                { [self dismiss]; } // Sets `present` to NO internally.
            }
            
            // Hook.
            CGFloat transitionPercent = (self.targetState == In) ? deltaPercent : 1.0 + deltaPercent;
            [self updateInteractiveTransition:transitionPercent];
            
            // Debug hook.
            [self.delegate interactiveTransitionDidChage:self];
            
            break;
        }
            
        case UIGestureRecognizerStateEnded :
        case UIGestureRecognizerStateCancelled :
        {
            // Only if an interactive transition started.
            if ([self isInteractive] == NO) return;
            
            // Inspect for cancellation.
            BOOL isFast = NO; // verticalVelocity < 5.0;
            self.canceled = (isFast == NO && fabsf(deltaPercent) <= 0.3);
            self.interactive = NO;
            
            // Swap back target state if interaction canceled.
            if (self.canceled)
            { self.targetState = (self.targetState == In) ? Out : In; }
            
            [self animateCompletion];
            
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


#pragma mark - UIViewControllerTransitioningDelegate

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController*) presented
                                                                 presentingController:(UIViewController*) presenting
                                                                     sourceController:(UIViewController*) source
{
    ETRLog(@"UIViewControllerTransitioningDelegate animationControllerForPresentedController:presentingController:sourceController:");
    
    self.targetState = In;
    return self;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController*) dismissed
{
    ETRLog(@"UIViewControllerTransitioningDelegate animationControllerForDismissedController:");
    
    self.targetState = Out;
    return self;
}


#pragma mark - UIViewControllerTransitioningDelegate (interactive)

-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>) animator
{ return (self.interactive) ? self : nil; }

-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>) animator
{ return (self.interactive) ? self : nil; }


#pragma mark - UIViewControllerAnimatedTransitioning

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>) transitionContext
{
    ETRLog(@"UIViewControllerAnimatedTransitioning transitionDuration: (%.1f)", self.duration);
    return self.duration;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>) transitionContext
{
    ETRLog(@"UIViewControllerAnimatedTransitioning animateTransition:");
    
    // Aliases.
    UIView *fromView = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey].view;
    UIView *toView = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey].view;
    UIView *containerView = [transitionContext containerView];
    
    // References.
    self.transitionContext = transitionContext;
    self.presenterView = (self.targetState == In) ? fromView : toView;
    self.modalView = (self.targetState == In) ? toView : fromView;
    self.containerView = containerView;
    
    // Debug hook.
    [self.delegate interactiveTransitionDidChage:self];
    
    // Animations.
    [self animateCompletion];
}

-(void)animateCompletion
{
    // Presenting.
    if (self.targetState == In)
    {
        ETRLog(@"EPPZTransition presenting");
        
        [self setupPresentation];
        [self animateToEnd];
    }
    
    // Dismissal.
    else
    {
        ETRLog(@"EPPZTransition dismissal");
        
        [self setupDismissal];
        [self animateToStart];
    }
}

-(CGFloat)remainingDuration
{
    NSLog(@"%.2f", self.duration);
    return self.duration;
    
    #warning Scale delta percent upon stuff.
    CGFloat remainingPercent = 1.0 - fabsf(self.deltaPercent);
    CGFloat remainingDuration = (remainingPercent > 0.0) ? self.duration * remainingPercent : self.duration;
    return remainingDuration;
}

-(void)animateToEnd
{
    [UIView animateWithDuration:self.remainingDuration
                          delay:0.0
         usingSpringWithDamping:self.damping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ [self layoutEnd]; }
                     completion:^(BOOL finished)
     {
         [self addGestureRecognizerToModalView];
         [self reset];
         [self.transitionContext completeTransition:!self.canceled];
     }];
}

-(void)animateToStart
{
    [UIView animateWithDuration:self.remainingDuration
                          delay:0.0
         usingSpringWithDamping:self.damping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ [self layoutStart]; }
                     completion:^(BOOL finished)
     {
         [self addGestureRecognizerToPresenterView];
         [self reset];
         [self.transitionContext completeTransition:!self.canceled];
     }];
}

-(void)reset
{
    // Reset.
    self.presenterView = nil;
    self.modalView = nil;
    
    self.targetState = Out;
    self.interactive = NO;
    
    // Debug hook.
    [self.delegate interactiveTransitionDidChage:self];
}


#pragma mark - UIViewControllerInteractiveTransitioning

-(void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>) transitionContext
{
    ETRLog(@"UIViewControllerInteractiveTransitioning startInteractiveTransition:");
    
    // Aliases.
    UIView *fromView = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey].view;
    UIView *toView = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey].view;
    UIView *containerView = [transitionContext containerView];
    
    // References.
    self.transitionContext = transitionContext;
    self.presenterView = (self.targetState == In) ? fromView : toView;
    self.modalView = (self.targetState == In) ? toView : fromView;
    self.containerView = containerView;
    
    // Debug hook.
    [self.delegate interactiveTransitionDidChage:self];
    
    // Setup.
    if (self.targetState == In)
    { [self setupPresentation]; }
    else
    { [self setupDismissal]; }
}

-(void)updateInteractiveTransition:(CGFloat) percentComplete
{ [self layoutInteractive:percentComplete]; }


#pragma mark - Present / dismiss

-(void)present
{
    // Instantiate.
    UIViewController *modalViewController = self.modalViewControllerInstanceBlock();
    
    // Wire up transition.
    modalViewController.modalPresentationStyle = UIModalPresentationCustom;
    modalViewController.transitioningDelegate = self;
    
    // Present.
    [self.presenterViewController presentViewController:modalViewController
                                               animated:YES
                                             completion:nil];
}

-(void)dismiss
{
    [self.presenterViewController dismissViewControllerAnimated:YES
                                                     completion:nil];
}


@end
