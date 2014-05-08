//
//  EPPZViewController.m
//  InteractiveTransition
//
//  Created by Carnation on 14/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import "EPPZViewController.h"
#import "EPPZModalViewController.h"
#import "EPPZTransition.debug.h"


@interface EPPZViewController ()

    <EPPZTransitionDebugDelegate>

@property (nonatomic, strong) EPPZTransition *transition;
@property (nonatomic, strong) NSDictionary *viewNamesForViewTags;

@end


@implementation EPPZViewController


#pragma mark - Creation

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create transition.
    self.transition = [EPPZLeftSwipeTransition transitionForPresenterViewController:self
                                                                modalViewController:^UIViewController*
    { return [[EPPZModalViewController alloc] initWithNibName:@"EPPZModalViewController"
                                                       bundle:nil]; }];
    
    // Debug.
    [self setupDebug];
}


#pragma mark - Interactions

-(IBAction)presentTouchedUp
{ [self.transition present]; }


#pragma mark - Debug

-(void)setupDebug
{
    self.viewNamesForViewTags = @{ @(0) : @"None", @(1) : @"Presenter", @(2) : @"Modal" };
    self.transition.delegate = self;
}

-(void)interactiveTransitionDidChage:(EPPZTransition*) transition
{
    // View.
    self.presenterViewLabel.text = self.viewNamesForViewTags[@(transition.presenterView.tag)];
    self.modalViewLabel.text = self.viewNamesForViewTags[@(transition.modalView.tag)];
    self.modalViewLabel.text = self.viewNamesForViewTags[@(transition.modalView.tag)];
    
    // Percent.
    self.percentProgressView.progress = transition.deltaPercent;
    self.positiveProgressView.progress = (transition.deltaPercent > 0.0) ? transition.deltaPercent : 0.0;
    self.negativeProgressView.progress = (transition.deltaPercent < 0.0) ? 1.0 + transition.deltaPercent : 1.0;
}


@end
