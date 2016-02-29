//
//  GoDrinkVC.m
//  Wine
//
//  Created by 孙云 on 16/2/23.
//  Copyright © 2016年 haidai. All rights reserved.
//

#import "GoDrinkVC.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import <AMapSearchKit/AMapCommonObj.h>
#import "CustomAnnotationView.h"

#define kDefaultLocationZoomLevel       16.1
#define kDefaultControlMargin           22
#define kDefaultCalloutViewMargin       -8
@interface GoDrinkVC ()<MAMapViewDelegate,AMapSearchDelegate,UISearchBarDelegate>{

    //地图显示
    MAMapView *_mamapView;
    //定位按钮
    UIButton *_searchBtn;
    //显示逆地理编码
    AMapSearchAPI *_search;
    CLLocation *_currentLocation;
    UIButton * _locationButton;
    //搜索
    NSArray *_pois;
    NSMutableArray *_annotations;
    
    //搜索框
    UISearchBar *_searchBar;
}

@end

@implementation GoDrinkVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //自定义右边导航栏的搜索框
    [self initNavSearch];
    //加载地图
    [self initMapView];
    [self initSearchBtn];
    [self initSearch];
    [self initAttributes];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark- 界面的布局
/**
 *  自定义导航搜索框事件
 */
- (void)initNavSearch{

    UIColor *color =  self.navigationController.navigationBar.barTintColor;
    
    _searchBar = [[UISearchBar alloc] init];
    
    _searchBar.delegate = self;
    _searchBar.frame = CGRectMake(self.view.frame.size.width - 115,(44 - 20) / 2,110,20);
    _searchBar.backgroundColor = color;
    _searchBar.layer.cornerRadius = 3;
    _searchBar.layer.masksToBounds = YES;
    [_searchBar.layer setBorderColor:[UIColor whiteColor].CGColor];
    //设置边框为白色
    [self.navigationController.navigationBar addSubview:_searchBar];
}
/**
 *  加载mapView
 */
- (void)initMapView{

    _mamapView = [[MAMapView alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64 - 44)];
    _mamapView.delegate = self;
    _mamapView.showsUserLocation = YES;
    //比例尺不显示
    _mamapView.showsScale= NO;
    //右下角显示地图logo
    _mamapView.logoCenter = CGPointMake(CGRectGetWidth(self.view.bounds)-55, 450);
    [self.view addSubview:_mamapView];
    
}
/**
 *  加载定位按钮
 */
- (void)initSearchBtn{

    _searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _searchBtn.frame = CGRectMake(10, self.view.frame.size.height - 10 - 50 - 50, 50, 50);
    [_searchBtn setImage:[UIImage imageNamed:@"no location "] forState:UIControlStateNormal];
    _searchBtn.layer.cornerRadius = _searchBtn.frame.size.width / 2;
    _searchBtn.layer.masksToBounds = YES;
    [_searchBtn addTarget:self action:@selector(searchLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_searchBtn];
}
/**
 *  加载搜索
 */
- (void)initSearch{

    _search = [[AMapSearchAPI alloc]init];
    _search.delegate = self;
}
/**
 *   搜索按钮的事件
 */
- (void)searchLocation{

    if (_mamapView.userTrackingMode != MAUserTrackingModeFollow) {
        [_mamapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
        //搜索附近
        [self searchAction];
    }
}
#pragma mark-- 搜索框代理事件
/**
 *  点击搜索按钮
 *
 *  @param searchBar <#searchBar description#>
 */
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{

    [_searchBar resignFirstResponder];
    NSLog(@"%@",_searchBar.text);
}
#pragma mark--全局键盘消失
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    
}
#pragma mark-----地图代理
/**
 *  逆地理编码
 */
- (void)reGotion{
    
    if (_currentLocation) {
        AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc]init];
        request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        [_search AMapReGoecodeSearch:request];
    }
}

/**
 *  定位状态改变，按钮状态发生相应改变
 *
 */
- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated{
    
    //修订定位状态
    if (mode == MAUserTrackingModeNone) {
        [_searchBtn setImage:[UIImage imageNamed:@"no location "] forState:UIControlStateNormal];
    }else{
        
        [_searchBtn setImage:[UIImage imageNamed:@"Group"] forState:UIControlStateNormal];
    }
}
/**
 *  获取到定位的地理编码
 *
 */
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{
    
    _currentLocation = [userLocation.location copy];
}
/**
 *  逆地理编码
 *
 */
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view{
    
    if ([view.annotation isKindOfClass:[MAUserLocation class]]) {
        [self reGotion];
    }
}
#pragma mark - AMapSearchDelegate
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    
    NSString *title = response.regeocode.addressComponent.city;
    if (title.length == 0)
    {
        title = response.regeocode.addressComponent.province;
    }
    
    _mamapView.userLocation.title = title;
    _mamapView.userLocation.subtitle = response.regeocode.formattedAddress;
    
}
#pragma mark-搜索功能
/******************************************************/
//清空数据
- (void)initAttributes{
    
    _annotations = [NSMutableArray array];
    _pois = nil;
}
/**
 *  查询事件
 */
- (void)searchAction{
    
    if (_currentLocation == nil|| _search == nil) {
        NSLog(@"search failed");
        return;
    }
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc]init];
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.keywords = @"酒吧";
    [_search AMapPOIAroundSearch:request];
    
}
/**
 *  请求到搜索的内容
 *
 *  @param request  <#request description#>
 *  @param response <#response description#>
 */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    
    NSLog(@"request :%@",request);
    if (response.pois.count > 0) {
        _pois = response.pois;
        //晴空标注
        [_mamapView removeAnnotations:_annotations];
        [_annotations removeAllObjects];
        
                for (int i=0;i<_pois.count; i++) {
                    // 为点击的poi点添加标注
                    AMapPOI *poi = _pois[i];
        
                    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
                    annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
                    annotation.title = poi.name;
                    annotation.subtitle = poi.address;
        
                    [_mamapView addAnnotation:annotation];
        
                    [_annotations addObject:annotation];
        
                }
    }
}
/**
 *  搜索结果的显示
 *
 *  @param mapView    <#mapView description#>
 *  @param annotation <#annotation description#>
 *
 *  @return <#return value description#>
 */
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation{
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        CustomAnnotationView *annotationView = (CustomAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        annotationView.image = [UIImage imageNamed:@"restaurant"];
        
        // 设置为NO，用以调用自定义的calloutView
        annotationView.canShowCallout = NO;
        
        // 设置中心点偏移，使得标注底部中间点成为经纬度对应点
        annotationView.centerOffset = CGPointMake(0, -18);
        return annotationView;
    }
    
    return nil;
}
#pragma mark - Helpers

- (CGSize)offsetToContainRect:(CGRect)innerRect inRect:(CGRect)outerRect
{
    CGFloat nudgeRight = fmaxf(0, CGRectGetMinX(outerRect) - (CGRectGetMinX(innerRect)));
    CGFloat nudgeLeft = fminf(0, CGRectGetMaxX(outerRect) - (CGRectGetMaxX(innerRect)));
    CGFloat nudgeTop = fmaxf(0, CGRectGetMinY(outerRect) - (CGRectGetMinY(innerRect)));
    CGFloat nudgeBottom = fminf(0, CGRectGetMaxY(outerRect) - (CGRectGetMaxY(innerRect)));
    return CGSizeMake(nudgeLeft ?: nudgeRight, nudgeTop ?: nudgeBottom);
}
@end
