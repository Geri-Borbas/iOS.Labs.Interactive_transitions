//
//  EPPZViewController.m
//  InteractiveTransition
//
//  Created by Carnation on 14/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import "EPPZViewController.h"
#import "EPPZModalViewController.h"


#define EPPZTransitionLogging YES
#define ETRLog if (EPPZTransitionLogging) NSLog


typedef enum
{
    In,     // 0
    Out     // 1
} EPPZTransitionState;


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

@property (nonatomic, getter=isInteractive) BOOL interactive;
@property (nonatomic) EPPZTransitionState targetState;
@property (nonatomic) BOOL canceled;

@property (nonatomic, weak) id <UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, weak) UIView *presenterView;
@property (nonatomic, weak) UIView *modalView;
@property (nonatomic, weak) UIView *containerView;
 
@property (nonatomic, strong) EPPZViewControllerModalInstanceBlock modalInstance;
@property (nonatomic, strong) NSDictionary *viewNamesForViewTags;

@property (nonatomic) CGFloat duration;
@property (nonatomic) CGFloat damping;
@property (nonatomic) CGFloat initialSpringVelocity;

@end


@implementation EPPZViewController


-(IBAction)presentTouchedUp
{
    [self presentViewController:self.modalInstance()
                       animated:YES
                     completion:nil];
}


#pragma mark - Creation

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewNamesForViewTags = @{
                                  @(0) : @"None",
                                  @(1) : @"Presenter",
                                  @(2) : @"Modal",
                                  };
    
    [self setup];
    
    // Define modal instance.
    __block EPPZViewController *transition = self;
    self.modalInstance = ^()
    {
        ETRLog(@"modalInstance");
        
        EPPZModalViewController *modalViewController = [[EPPZModalViewController alloc] initWithNibName:@"EPPZModalViewController" bundle:nil];
        modalViewController.modalPresentationStyle = UIModalPresentationCustom;
        modalViewController.transitioningDelegate = transition;
        return modalViewController;
    };
    
    [self addGestureRecognizer];
}


#pragma mark - Debug

-(void)setPresenterView:(UIView*) presenterView
{
    _presenterView = presenterView;
    self.presenterViewLabel.text = self.viewNamesForViewTags[@(presenterView.tag)];
}

-(void)setModalView:(UIView*) modalView
{
    _modalView = modalView;
    self.modalViewLabel.text = self.viewNamesForViewTags[@(modalView.tag)];
}

-(void)showPercent:(CGFloat) percent
{
    // UI.
    self.positiveProgressView.progress = (percent > 0.0) ? percent : 0.0;
    self.negativeProgressView.progress = (percent < 0.0) ? 1.0 + percent : 1.0;
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
                {
                    // Sets `present` to YES internally.
                    [self presentViewController:self.modalInstance()
                                       animated:YES
                                     completion:nil];
                }
                
                // Dismiss.
                else
                {
                    // Sets `present` to NO internally.
                    [self dismissViewControllerAnimated:YES
                                             completion:nil];
                }
            }
            
            // Hook.
            CGFloat transitionPercent = (self.targetState == In) ? deltaPercent : 1.0 + deltaPercent;
            [self updateInteractiveTransition:transitionPercent];
            
            // UI.
            self.percentProgressView.progress = deltaPercent;
            [self showPercent:deltaPercent];
            
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


#pragma mark - Setup templates (override is optional)

-(void)setup
{
    ETRLog(@"EPPZTransition setup");
    
    self.duration = 2.0;
    self.damping = 0.68;
    self.initialSpringVelocity = 0.48;
}

-(void)setupPresentation
{
    ETRLog(@"EPPZTransition setupPresentation");
    
    // Add.
    [self.containerView addSubview:self.presenterView];
    [self.containerView insertSubview:self.modalView aboveSubview:self.presenterView];
    
    // Layout start.
    [self layoutStart];
}

-(void)setupDismissal
{
    ETRLog(@"EPPZTransition setupDismissal");
    
    // Views are probably already added.
    
    // Layout end.
    [self layoutEnd];
}


#pragma mark - Layout templates (override is required)

-(void)layoutStart
{
    ETRLog(@"EPPZTransition layoutStart");
    
    // Presenting view (as is).
    self.presenterView.transform = CGAffineTransformIdentity;
    
    // Modal view (left out).
    self.modalView.transform = CGAffineTransformMakeTranslation(-self.modalView.bounds.size.width, 0.0);
}

-(void)layoutEnd
{
    ETRLog(@"EPPZTransition layoutEnd");
    
    // Presenting view (as is).
    self.presenterView.transform = CGAffineTransformIdentity;
    
    // Modal view (in).
    self.modalView.transform = CGAffineTransformMakeTranslation(0.0, 0.0);
}

-(void)layoutInteractive:(CGFloat) percent
{
    ETRLog(@"EPPZTransition layoutInteractive: (%.2f) containerView:presentingView:modalView:", percent);
    
    // Modal view (0.0 is left out, 1.0 is in).
    self.modalView.transform = CGAffineTransformMakeTranslation(-self.modalView.bounds.size.width * (1.0 - percent), 0.0);
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

    // Animations.
    [self animateCompletion];
}

-(void)animateCompletion
{
    // Presenting.
    if (self.targetState == In)
    {
        ETRLog(@"Presenting");
        
        [self setupPresentation];
        [self animateEnd];
    }
    
    // Dismissal.
    else
    {
        ETRLog(@"Dismissal");
        
        [self setupDismissal];
        [self animateStart];
    }
}

-(void)animateEnd
{
    [UIView animateWithDuration:self.duration
                          delay:0.0
         usingSpringWithDamping:self.damping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ [self layoutEnd]; }
                     completion:^(BOOL finished)
     {
         [self reset];
         [self.transitionContext completeTransition:!self.canceled];
     }];
}

-(void)animateStart
{
    [UIView animateWithDuration:self.duration
                          delay:0.0
         usingSpringWithDamping:self.damping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ [self layoutStart]; }
                     completion:^(BOOL finished)
     {
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
    
    // Setup.
    if (self.targetState == In)
    { [self setupPresentation]; }
    else
    { [self setupDismissal]; }
}

-(void)updateInteractiveTransition:(CGFloat) percentComplete
{ [self layoutInteractive:percentComplete]; }


@end
