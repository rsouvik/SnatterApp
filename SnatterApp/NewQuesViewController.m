//
//  NewQuesViewController.m
//  SnatterApp
//
//  Created by Souvik Ray on 9/15/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import "NewQuesViewController.h"
#import "SnSyncEngine.h"
#import "SnCoreDataController.h"

@interface NewQuesViewController ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObject *question;

@end

@implementation NewQuesViewController

@synthesize questionText;
@synthesize managedObjectContext;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.managedObjectContext = [[SnCoreDataController sharedInstance] newManagedObjectContext];
    self.question = [NSEntityDescription insertNewObjectForEntityForName:@"SnQuestion" inManagedObjectContext:self.managedObjectContext];
	// Do any additional setup after loading the view.
    [questionText becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender
{
   //[self newpostQ];
   //[self.delegate NewQViewControllerDidSave:self];
    //add question
    [self.question setValue:self.questionText.text forKey:@"questxt"];
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        BOOL saved = [self.managedObjectContext save:&error];
        if (!saved) {
            // do some real error handling
            NSLog(@"Could not save Date due to %@", error);
        }
        [[SnCoreDataController sharedInstance] saveMasterContext];
        NSLog(@"Saved data");
    }];
    //[self loadRecordsFromCoreData];
    //[self.tableView reloadData];
    
    [[SnSyncEngine sharedEngine] startSync];
}

@end
