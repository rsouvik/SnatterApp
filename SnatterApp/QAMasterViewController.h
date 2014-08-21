//
//  QAMasterViewController.h
//  SnatterApp
//
//  Created by Souvik Ray on 8/20/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

@interface QAMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
