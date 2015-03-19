#import <IntentKit/INKBrowserHandler.h>
#import <IntentKit/INKMailHandler.h>
#import <iRate/iRate.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <VTAcknowledgementsViewController/VTAcknowledgementsViewController.h>

#import "DataStore.h"

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithDataStore:(DataStore *)dataStore {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:NSBundle.mainBundle];
    SettingsViewController *vc = [storyboard instantiateInitialViewController];
    vc.dataStore = dataStore;

    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings / About";

    UILabel *footerView = [[UILabel alloc] init];
    footerView.font = [UIFont systemFontOfSize:UIFont.smallSystemFontSize];

    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *build = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    if (![version isEqualToString:build]) {
        version = [version stringByAppendingFormat:@" (%@)", build];
    }

    footerView.text = [NSString stringWithFormat:@"Version %@", version];
    [footerView sizeToFit];
    footerView.frame = ({
        CGRect frame = footerView.frame;
        frame.origin.x = 15;
        frame;
    });
    self.tableView.tableFooterView = footerView;

}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:@"share"]) {
        [self showShareSheet];
    } else if ([cell.reuseIdentifier isEqualToString:@"acknowledgements"]) {
        [self showAcknowledgements];
    } else if ([cell.reuseIdentifier isEqualToString:@"contact"]) {
        [self showEmailSheet];
    } else if ([cell.reuseIdentifier isEqualToString:@"lazerwalker"]) {
        [self showWebSite];
    } else if ([cell.reuseIdentifier isEqualToString:@"rate"]) {
        [self rateInAppStore];
    } else if ([cell.reuseIdentifier isEqualToString:@"reimport"]) {
        [self reimportFromHealthKit];
    }
}


#pragma mark - Actions

- (void)showShareSheet {
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[@"I'm tracking my caffeine consumption using Cortado!", [NSURL URLWithString:@"http://lazerwalker.com"]] applicationActivities:nil];

    shareController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList];

    [self.navigationController presentViewController:shareController animated:YES completion:nil];
}

- (void)showAcknowledgements {
    VTAcknowledgementsViewController *viewController = [VTAcknowledgementsViewController acknowledgementsViewController];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showEmailSheet {
    INKMailHandler *mailHandler = [[INKMailHandler alloc] init];
    mailHandler.subject = @"Cortado Feedback";
    [[mailHandler sendMailTo:@"cortado@lazerwalker.com"] presentModally];
}

- (void)showWebSite {
    NSURL *url = [NSURL URLWithString:@"http://lazerwalker.com"];
    INKBrowserHandler *browser = [[INKBrowserHandler alloc] init];
    browser.useSystemDefault = YES;
    [[browser openURL:url] presentModally];
}

- (void)rateInAppStore {
    [[iRate sharedInstance] openRatingsPageInAppStore];
}

- (void)reimportFromHealthKit {
    [[[self.dataStore importFromHealthKit] deliverOnMainThread]
        subscribeError:^(NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Uh Oh!"
                message:@"There was an error importing your previous caffeine history from HealthKit Double-check that you have granted Cortado read access to caffeine history in Health.app."
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil]
            show];
        } completed:^{
            [[[UIAlertView alloc] initWithTitle:@"Data Imported!"
                message:@"Your previous caffeine history has been successfully imported from HealthKit."
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil]
             show];
        }];
}

@end