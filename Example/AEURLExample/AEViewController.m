//
//  AEViewController.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/12/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEViewController.h"
#import "AEURLConnection.h"
#import "AEJSONProcessingBlock.h"

@interface AEViewController ()
@property (nonatomic, retain) NSArray *keys;
@property (nonatomic, retain) NSDictionary *result;
@end

@implementation AEViewController

@synthesize keys=_keys;
@synthesize result=_result;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
        
        [self setTitle:@"AEURL Example"];
        [[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:spinner] autorelease]];
        [spinner startAnimating];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://graph.facebook.com/137947732957611"]];
        [AEURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                                 processingBlock:[AEJSONProcessingBlock JSONResponseProcessingBlock]
                               completionHandler:^(NSURLResponse *response, id data, NSError *error) {
                                   [spinner stopAnimating];
                                   
                                   if (error) {
                                       [[[[UIAlertView alloc] initWithTitle:[error localizedDescription] 
                                                                    message:[error localizedRecoverySuggestion]
                                                                   delegate:nil 
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil] autorelease] show];
                                   } else {
                                       [self setKeys:[data allKeys]];
                                       [self setResult:data];
                                       [[self tableView] reloadData];
                                   }
                               }];
    }
    return self;
}

- (void)dealloc {
    [_keys release];
    [_result release];
    [super dealloc];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self keys] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id key = [[self keys] objectAtIndex:[indexPath row]];
    id value = [[self result] objectForKey:key];
    
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil] autorelease];
    [[cell textLabel] setText:[key description]];
    [[cell detailTextLabel] setText:[value description]];
    return cell;
}

@end
