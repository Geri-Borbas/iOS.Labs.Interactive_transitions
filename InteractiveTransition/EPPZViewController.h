//
//  EPPZViewController.h
//  InteractiveTransition
//
//  Created by Carnation on 14/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPPZGeometry.h"


typedef UIViewController *(^EPPZViewControllerModalInstanceBlock)();


@interface EPPZViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIProgressView *percentProgressView;
@property (nonatomic, weak) IBOutlet UIProgressView *positiveProgressView;
@property (nonatomic, weak) IBOutlet UIProgressView *negativeProgressView;
@property (nonatomic, weak) IBOutlet UILabel *presenterViewLabel;
@property (nonatomic, weak) IBOutlet UILabel *modalViewLabel;
-(IBAction)presentTouchedUp;

@end
