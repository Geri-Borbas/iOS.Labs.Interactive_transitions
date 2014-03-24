//
//  EPPZTransition.h
//  InteractiveTransition
//
//  Created by Carnation on 24/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


#define EPPZTransitionLogging YES
#define ETRLog if (EPPZTransitionLogging) NSLog


typedef UIViewController *(^EPPZTransitionModalViewControllerInstanceBlock)();


@interface EPPZTransition : NSObject

/*! 
 
 Creates an interactive transition with a presenter view controller to
 present a modal view controller at some point. Modal view instatiating
 is lazy, as transition object gonna ask for an instance calling instantiating
 block passed in. Returned transition pbject must be retained (for now).
 
 @param presenterViewController A view controller that presents modal view.
 @param modalViewControllerInstanceBlock A block that returns an instance of modal view to be presented.
 
 */
+(instancetype)transitionForPresenterViewController:(UIViewController*) presenterViewController
                                modalViewController:(EPPZTransitionModalViewControllerInstanceBlock) modalViewControllerInstanceBlock;

/*!
 
 Shortcut to `presentViewController:animated:completion:` (animated).
 
 */
-(void)present;


@end
