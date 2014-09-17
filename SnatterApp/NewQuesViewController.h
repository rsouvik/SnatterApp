//
//  NewQuesViewController.h
//  SnatterApp
//
//  Created by Souvik Ray on 9/15/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewQuesViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextView *questionText;
- (IBAction)done:(id)sender;

@end
