//
//  SettingsTableViewController.m
//  LNPopupControllerExample
//
//  Created by Leo Natan on 18/03/2017.
//  Copyright © 2017 Leo Natan. All rights reserved.
//

#import "SettingsTableViewController.h"
#import <LNPopupController/LNPopupContentView.h>

NSString* const PopupSettingsPresentationStyle = @"PopupSettingsPresentationStyle";
NSString* const PopupSettingsEnableDimming = @"PopupSettingsEnableDimming";
NSString* const PopupSettingsEnableDimmingClose = @"PopupSettingsEnableDimmingClose";
NSString* const PopupSettingsBarStyle = @"PopupSettingsBarStyle";
NSString* const PopupSettingsInteractionStyle = @"PopupSettingsInteractionStyle";
NSString* const PopupSettingsProgressViewStyle = @"PopupSettingsProgressViewStyle";
NSString* const PopupSettingsCloseButtonStyle = @"PopupSettingsCloseButtonStyle";
NSString* const PopupSettingsMarqueeStyle = @"PopupSettingsMarqueeStyle";
NSString* const PopupSettingsEnableCustomizations = @"PopupSettingsEnableCustomizations";

@interface SettingsTableViewController ()
{
	NSDictionary<NSNumber*, NSString*>* _sectionToKeyMapping;
	
	UISwitch* _dimmingCloseSwitch;
}

@end

@implementation SettingsTableViewController

+ (void)load
{
	@autoreleasepool
	{
		[NSUserDefaults.standardUserDefaults registerDefaults:@{PopupSettingsEnableDimming: @YES, PopupSettingsEnableDimmingClose: @YES}];
		
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			[NSUserDefaults.standardUserDefaults registerDefaults:@{PopupSettingsPresentationStyle: @(LNPopupPresentationStyleFullHeight)}];
		}
		else
		{
			[NSUserDefaults.standardUserDefaults registerDefaults:@{PopupSettingsPresentationStyle: @(LNPopupPresentationStyleSheet)}];
		}
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_sectionToKeyMapping = @{@0: PopupSettingsPresentationStyle, @1: PopupSettingsBarStyle, @2: PopupSettingsInteractionStyle, @3: PopupSettingsProgressViewStyle, @4: PopupSettingsCloseButtonStyle, @5: PopupSettingsMarqueeStyle};
	
	_dimmingCloseSwitch = [UISwitch new];
	_dimmingCloseSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:PopupSettingsEnableDimmingClose];
	_dimmingCloseSwitch.enabled = [[NSUserDefaults standardUserDefaults] boolForKey:PopupSettingsEnableDimming];
	[_dimmingCloseSwitch addTarget:self action:@selector(_dimCloseSwitchValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.accessoryView = nil;
	cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	
	NSString* key = _sectionToKeyMapping[@(indexPath.section)];
	if(key == nil)
	{
		UISwitch* customizations = [UISwitch new];
		customizations.on = [[NSUserDefaults standardUserDefaults] boolForKey:PopupSettingsEnableCustomizations];
		[customizations addTarget:self action:@selector(_demoSwitchValueDidChange:) forControlEvents:UIControlEventValueChanged];
		cell.accessoryView = customizations;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	else
	{
		if(key == PopupSettingsPresentationStyle)
		{
			if(indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 2)
			{
				UISwitch* customizations = [UISwitch new];
				customizations.on = [[NSUserDefaults standardUserDefaults] boolForKey:PopupSettingsEnableDimming];
				[customizations addTarget:self action:@selector(_dimSwitchValueDidChange:) forControlEvents:UIControlEventValueChanged];
				cell.accessoryView = customizations;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			else if(indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1)
			{
				cell.accessoryView = _dimmingCloseSwitch;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
		}
		
		NSUInteger value = [[[NSUserDefaults standardUserDefaults] objectForKey:key] unsignedIntegerValue];
		if(value == 0xFFFF)
		{
			value = 3;
		}
		
		if(indexPath.row == value)
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	
	return cell;
}

- (IBAction)_resetButtonTapped:(UIBarButtonItem *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:PopupSettingsEnableCustomizations];
	[_sectionToKeyMapping enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		[[NSUserDefaults standardUserDefaults] setObject:@0 forKey:obj];
	}];
	
	[self.tableView reloadData];
}

- (void)_demoSwitchValueDidChange:(UISwitch*)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:PopupSettingsEnableCustomizations];
}

- (void)_dimSwitchValueDidChange:(UISwitch*)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:PopupSettingsEnableDimming];
	_dimmingCloseSwitch.enabled = sender.isOn;
}

- (void)_dimCloseSwitchValueDidChange:(UISwitch*)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:PopupSettingsEnableDimmingClose];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* key = _sectionToKeyMapping[@(indexPath.section)];
	if(key == nil)
	{
		return NO;
	}
	
	if(key == PopupSettingsPresentationStyle)
	{
		return indexPath.row < [tableView numberOfRowsInSection:indexPath.section] - 2;
	}
	
	return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* key = _sectionToKeyMapping[@(indexPath.section)];
	NSUInteger prevValue = [[[NSUserDefaults standardUserDefaults] objectForKey:key] unsignedIntegerValue];
	if(prevValue == 0xFFFF)
	{
		prevValue = 3;
	}

	[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:prevValue inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryNone;
	[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
	
	NSUInteger value = indexPath.row;
	if(key != PopupSettingsPresentationStyle && value == 3)
	{
		value = 0xFFFF;
	}
	[[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:key];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
