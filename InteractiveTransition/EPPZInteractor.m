//
//  EPPZInteractor.m
//  InteractiveTransition
//
//  Created by Carnation on 14/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import "EPPZInteractor.h"


@interface EPPZInteractor ()
@property (nonatomic, strong) UIViewController *parentViewController;
@end


@implementation EPPZInteractor


-(id)initWithParentViewController:(UIViewController*) viewController
{
    if (!(self = [super init])) return nil;
    
    self.parentViewController = viewController;
    return self;
}



@end
