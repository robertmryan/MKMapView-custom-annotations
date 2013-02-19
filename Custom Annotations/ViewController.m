//
//  ViewController.m
//  Custom Annotations
//
//  Created by Robert Ryan on 2/18/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CustomAnnotation.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ViewController () <MKMapViewDelegate, ABUnknownPersonViewControllerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow];
    
	// Do any additional setup after loading the view, typically from a nib.
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    MKMapRect mapRect = mapView.visibleMapRect;
    MKMapPoint eastMapPoint = MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMidY(mapRect));
    MKMapPoint westMapPoint = MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMidY(mapRect));
    
    CGFloat meters = MKMetersBetweenMapPoints(eastMapPoint, westMapPoint);

    if ([mapView.annotations count] > 0)
        [mapView removeAnnotations:mapView.annotations];

    if (meters > 5000)
        return;
    
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = @"restaurant";
    request.region = mapView.region;
    
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {

        NSMutableArray *annotations = [NSMutableArray array];
        
        [response.mapItems enumerateObjectsUsingBlock:^(MKMapItem *item, NSUInteger idx, BOOL *stop) {
            CustomAnnotation *annotation = [[CustomAnnotation alloc] initWithPlacemark:item.placemark];
            annotation.title = item.name;
            annotation.phone = item.phoneNumber;
            annotation.subtitle = item.placemark.addressDictionary[(NSString *)kABPersonAddressStreetKey];
            [annotations addObject:annotation];
        }];
        
        [self.mapView addAnnotations:annotations];
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[CustomAnnotation class]])
        return nil;
    
    MKAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                                       reuseIdentifier:@"CustomAnnotationView"];
    annotationView.canShowCallout = YES;
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];

    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if (![view.annotation isKindOfClass:[CustomAnnotation class]])
        return;
    CustomAnnotation *annotation = (CustomAnnotation *)view.annotation;
    
    ABRecordRef person = ABPersonCreate();
    ABRecordSetValue(person, kABPersonOrganizationProperty, (__bridge CFStringRef) annotation.title, NULL);
    
    if (annotation.phone)
    {
        ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFStringRef) annotation.phone, kABPersonPhoneMainLabel, NULL);
        ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
        CFRelease(phoneNumberMultiValue);
    }
    
    ABMutableMultiValueRef address = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    ABMultiValueAddValueAndLabel(address, (__bridge CFDictionaryRef) annotation.addressDictionary, kABWorkLabel, NULL);
    ABRecordSetValue(person, kABPersonAddressProperty, address, NULL);
    ABUnknownPersonViewController *personView = [[ABUnknownPersonViewController alloc] init];
    
    personView.unknownPersonViewDelegate = self;
    personView.displayedPerson = person;
    personView.allowsAddingToAddressBook = YES;
    
    [self.navigationController pushViewController:personView animated:YES];
    
    CFRelease(person);
}

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{
    
}

//- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
//{
//    if ([view.annotation isKindOfClass:[CustomAnnotation class]])
//    {
//        CustomAnnotation *annotation = view.annotation;
//        NSLog(@"index = %d; property1 = %@", annotation.index, annotation.property1);
//    }
//}
@end
