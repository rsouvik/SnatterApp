//
//  QADetailViewController.h
//  SnatterApp
//
//  Created by Souvik Ray on 8/20/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QADetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
