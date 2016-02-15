//
//  ObjectSelector.m
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 5/5/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "MPObjectSelector.h"
#import "NSData+MPBase64.h"

@interface MPObjectFilter : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSNumber *index;
@property (nonatomic, assign) BOOL unique;
@property (nonatomic, assign) BOOL nameOnly;

- (NSArray *)apply:(NSArray *)views;
- (NSArray *)applyReverse:(NSArray *)views;
- (BOOL)appliesTo:(NSObject *)view;
- (BOOL)appliesToAny:(NSArray *)views;

@end

@interface MPObjectSelector () {
    NSCharacterSet *_classAndPropertyChars;
    NSCharacterSet *_separatorChars;
    NSCharacterSet *_predicateStartChar;
    NSCharacterSet *_predicateEndChar;
    NSCharacterSet *_flagStartChar;
    NSCharacterSet *_flagEndChar;

}

@property (nonatomic, strong) NSScanner *scanner;
@property (nonatomic, strong) NSArray *filters;

@end

@implementation MPObjectSelector

+ (MPObjectSelector *)objectSelectorWithString:(NSString *)string
{// /UIView/UIButton[(mp_fingerprintVersion >= 1 AND mp_varE == "7939b7ff1ec0a3c196819b45ee22ef5429ee821c")]
    MPObjectSelector *objectSelector = [[MPObjectSelector alloc]initWithString:string];
    
//    return [[MPObjectSelector alloc] initWithString:string];
    return objectSelector;
}

- (instancetype)initWithString:(NSString *)string
{
    if (self = [super init]) {
        _string = string;
        _scanner = [NSScanner scannerWithString:string];
        [_scanner setCharactersToBeSkipped:nil];
        _separatorChars = [NSCharacterSet characterSetWithCharactersInString:@"/"];
        _predicateStartChar = [NSCharacterSet characterSetWithCharactersInString:@"["];
        _predicateEndChar = [NSCharacterSet characterSetWithCharactersInString:@"]"];
        _classAndPropertyChars = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.*"];
        _flagStartChar = [NSCharacterSet characterSetWithCharactersInString:@"("];
        _flagEndChar = [NSCharacterSet characterSetWithCharactersInString:@")"];

        NSMutableArray *filters = [NSMutableArray array];
        MPObjectFilter *filter;
        while((filter = [self nextFilter])) {
            [filters addObject:filter];
        }
        self.filters = [filters copy];
    }
    return self;
}

/*
 Starting at the root object, try and find an object
 in the view/controller tree that matches this selector.
*/

- (NSArray *)selectFromRoot:(id)root
{
    return [self selectFromRoot:root evaluatingFinalPredicate:YES];
}

- (NSArray *)fuzzySelectFromRoot:(id)root
{
    return [self selectFromRoot:root evaluatingFinalPredicate:NO];
}

- (NSArray *)selectFromRoot:(id)root evaluatingFinalPredicate:(BOOL)finalPredicate//root:ViewController
{
    NSArray *views = @[];
    if (root) {
        views = @[root];

        for (NSUInteger i = 0, n = [_filters count]; i < n; i++) {
            MPObjectFilter *filter = _filters[i];
            filter.nameOnly = (i == n-1 && !finalPredicate);//
            
            views = [filter apply:views];
            if ([views count] == 0) {
                break;
            }
        }
    }
    return views;
}


/*
 Starting at a leaf node, determine确定 if it would be selected
 by this selector starting from the root object given.
 */

- (BOOL)isLeafSelected:(id)leaf fromRoot:(id)root
{
    return [self isLeafSelected:leaf fromRoot:root evaluatingFinalPredicate:YES];
}

- (BOOL)fuzzyIsLeafSelected:(id)leaf fromRoot:(id)root
{
    return [self isLeafSelected:leaf fromRoot:root evaluatingFinalPredicate:NO];
}

- (BOOL)isLeafSelected:(id)leaf fromRoot:(id)root evaluatingFinalPredicate:(BOOL)finalPredicate//finalPredicate控制_nameOnly,存在当有evaluating
{//leaf:UIImageView,父类:UIView(UIActivityIndicatorView),root:ViewController
    BOOL isSelected = YES;
    NSArray *views = @[leaf];
    NSUInteger n = [_filters count], i = n;
    while(i--) {
        MPObjectFilter *filter = _filters[i];
        filter.nameOnly = (i == n-1 && !finalPredicate);
        if (![filter appliesToAny:views]) {//能否通过Filter
            isSelected = NO;
            break;
        }
        views = [filter applyReverse:views];//获得nextResponse
        if ([views count] == 0) {
            break;
        }
    }
    return isSelected && [views indexOfObject:root] != NSNotFound;//能够通过Filter，root的下个反应链包含root
}

- (MPObjectFilter *)nextFilter//利用_scanner内信息进行Filter初始化
{//filter有_name,_predicate,_index,
   // /UIView/UIButton[(mp_fingerprintVersion >= 1 AND mp_varE == "7939b7ff1ec0a3c196819b45ee22ef5429ee821c")]
    MPObjectFilter *filter;
    if ([_scanner scanCharactersFromSet:_separatorChars intoString:nil])
    {//第一段为@"/"
        NSString *name;
        filter = [[MPObjectFilter alloc] init];
        if ([_scanner scanCharactersFromSet:_classAndPropertyChars intoString:&name])
        {//第二段为字母数字构成的名称
            filter.name = name;
        }
        else
        {
            filter.name = @"*";
        }
        
        
        if ([_scanner scanCharactersFromSet:_flagStartChar intoString:nil])
        {//()内有无@"unique"字符串
            NSString *flags;
            [_scanner scanUpToCharactersFromSet:_flagEndChar intoString:&flags];//截取()内容到flags
            for (NSString *flag in[flags componentsSeparatedByString:@"|"])
            {//以|分割截取内容
                if ([flag isEqualToString:@"unique"])
                {
                    filter.unique = YES;
                }
            }
        }
        
        
        if ([_scanner scanCharactersFromSet:_predicateStartChar intoString:nil])//如果第二段以@"["开头
        {
            NSString *predicateFormat;
            NSInteger index = 0;
            if ([_scanner scanInteger:&index] && [_scanner scanCharactersFromSet:_predicateEndChar intoString:nil])
            {//如果数字开头，作为index存入
                filter.index = @((NSUInteger)index);
            }
            else
            {//如果开头非数字
                [_scanner scanUpToCharactersFromSet:_predicateEndChar intoString:&predicateFormat];//截取[]内容于predicateFormate
                @try
                {
                    NSPredicate *parsedPredicate = [NSPredicate predicateWithFormat:predicateFormat];//截取内容生成_predicate
                    filter.predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings)
                    {
                        @try
                        {
                            return [parsedPredicate evaluateWithObject:evaluatedObject substitutionVariables:bindings];
                        }
                        @catch (NSException *exception)
                        {
                            return false;
                        }
                    }];
                }
                @catch (NSException *exception)
                {
                    filter.predicate = [NSPredicate predicateWithValue:NO];//通过评估一个给定的值来创建并返回一个谓词
                }

                [_scanner scanCharactersFromSet:_predicateEndChar intoString:nil];
            }
        }

    }
    
    return filter;
}

- (Class)selectedClass
{
    if ([_filters count] > 0) {
        return NSClassFromString(((MPObjectFilter *)_filters[[_filters count] - 1]).name);
    }
    return nil;
}

- (NSString *)description
{
    return self.string;
}

@end

@implementation MPObjectFilter

- (instancetype)init
{
    if((self = [super init])) {
        self.unique = NO;
        self.nameOnly = NO;
    }
    return self;
}

/*
 Apply this filter to the views, returning all of their children
 that match this filter's class / predicate pattern
 */
- (NSArray *)apply:(NSArray *)views
{
    NSMutableArray *result = [NSMutableArray array];

    Class class = NSClassFromString(_name);//获得类名
    if (class || [_name isEqualToString:@"*"]) {//class存在或者_name为:@"*"
        // Select all children
        for (NSObject *view in views) {//遍历对象
            NSArray *children = [self getChildrenOfObject:view ofType:class];//获得类型为class的对象
            if (_index && [_index unsignedIntegerValue] < [children count]) {//index属性在nextFilter中被设置,这里是判断index存在并没有数组越界
                // Indexing can only be used for subviews of UIView
                if ([view isKindOfClass:[UIView class]]) {
                    children = @[children[[_index unsignedIntegerValue]]];
                } else {
                    children = @[];
                }
            }
            [result addObjectsFromArray:children];
        }
    }

    if (!self.nameOnly) {
        // If unique is set and there are more than one, return nothing
        if(self.unique && [result count] != 1) {//排除unique是且不为一的异常
            return @[];
        }
        // Filter any resulting views by predicate
        if (self.predicate) {
            return [result filteredArrayUsingPredicate:self.predicate];
        }
    }
    return [result copy];
}

/*
 Apply this filter to the views. For any view that
 matches this filter's class / predicate pattern, return
 its parents.
 */
- (NSArray *)applyReverse:(NSArray *)views//反向获得反应链
{ //UIimageView->UIActivityIndicatorView
    NSMutableArray *result = [NSMutableArray array];
    for (NSObject *view in views) {
        if ([self appliesTo:view]) { //Returns whether the given view would pass this filter.
            [result addObjectsFromArray:[self getParentsOfObject:view]];//获得view的一些页面属性(UIViewController)
        }
    }
    return [result copy];
}

/*
 Returns whether the given view would pass this filter.
 */
- (BOOL)appliesTo:(NSObject *)view
{
//    NSLog(@"self.name is equalTo'*':%d",[self.name isEqualToString:@"*"]);
//    NSLog(@"view is self.name class:%d",[view isKindOfClass:NSClassFromString(self.name)]);
//    NSLog(@"----------");
//    NSLog(@"self.nameOnly:%d",self.nameOnly);
//    NSLog(@"!self.predicate:%d",!self.predicate);
//    NSLog(@"_predicate evaluateWithObj:view:%d",[_predicate evaluateWithObject:view]);
//    NSLog(@"----------");
//    NSLog(@"!self.index:%d",!self.index);
//    NSLog(@"self isView siblingNum:[_index integerValue]:%d",[self isView:view siblingNumber:[_index integerValue]]);
//    NSLog(@"----------");
//    NSLog(@"!self.unique:%d",!self.unique);
//    NSLog(@"self isView oneOfSibing:1:%d",[self isView:view oneOfNSiblings:1]);
    return (([self.name isEqualToString:@"*"] || [view isKindOfClass:NSClassFromString(self.name)])//0||1->1
            && (self.nameOnly || (//0
                (!self.predicate || [_predicate evaluateWithObject:view])//0||1
                && (!self.index || [self isView:view siblingNumber:[_index integerValue]])//1||1
                && (!(self.unique) || [self isView:view oneOfNSiblings:1])))//1||0
            );
}

/*
 Returns whether any of the given views would pass this filter
 */
- (BOOL)appliesToAny:(NSArray *)views
{
    for (NSObject *view in views) {
        if ([self appliesTo:view]) {
            return YES;
        }
    }
    return NO;
}

/*
 Returns true if the given view is at the index given by number in
 its parent's subviews. The view's parent must be of type UIView
 */

- (BOOL)isView:(NSObject *)view siblingNumber:(NSInteger)number
{
    return [self isView:view siblingNumber:number of:-1];
}

- (BOOL)isView:(NSObject *)view oneOfNSiblings:(NSInteger)number
{
    return [self isView:view siblingNumber:-1 of:number];
}

- (BOOL)isView:(NSObject *)view siblingNumber:(NSInteger)index of:(NSInteger)numSiblings
{//siblings[(NSUInteger)index] == view
    NSArray *parents = [self getParentsOfObject:view];
    for (NSObject *parent in parents) {
        if ([parent isKindOfClass:[UIView class]]) {//对一些UIView对象进行操作
            NSArray *siblings = [self getChildrenOfObject:parent ofType:NSClassFromString(_name)];//parent中需要的子类对象
            if ((index < 0 || ((NSUInteger)index < [siblings count] && siblings[(NSUInteger)index] == view))
                && (numSiblings < 0 || [siblings count] == (NSUInteger)numSiblings)) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSArray *)getParentsOfObject:(NSObject *)obj//UIView
{//根据obj类型获得View(superview,nextresponse),ViewController(parentViewController,presentingViewController),.keywindow
    
    NSMutableArray *result = [NSMutableArray array];
    if ([obj isKindOfClass:[UIView class]])
    {//UIView
        
        if ([(UIView *)obj superview])
        {
            [result addObject:[(UIView *)obj superview]];
        }
        // For UIView, nextResponder should be its controller or its  .
        if ([(UIView *)obj nextResponder] && [(UIView *)obj nextResponder] != [(UIView *)obj superview])
        {//nextResponder != superView
            [result addObject:[(UIView *)obj nextResponder]];
        }
    }
    else if ([obj isKindOfClass:[UIViewController class]])
    {//UIViewController
        if ([(UIViewController *)obj parentViewController]) {
            [result addObject:[(UIViewController *)obj parentViewController]];
        }
        if ([(UIViewController *)obj presentingViewController]) {
            [result addObject:[(UIViewController *)obj presentingViewController]];//强制类型转换后，不能用点扩展属性 =obj.presentingViewController
        }
        if ([UIApplication sharedApplication].keyWindow.rootViewController == obj) {
            //TODO is there a better way to get the actual window that has this VC
            [result addObject:[UIApplication sharedApplication].keyWindow];
        }
    }
    return [result copy];
}

- (NSArray *)getChildrenOfObject:(NSObject *)obj ofType:(Class)class//从obj中取出需要的class类对象
{//根据obj的类的不同，取出需要的class类型的对象放入数组
    NSMutableArray *children = [NSMutableArray array];
    // A UIWindow is also a UIView, so we could in theory follow the subviews chain from UIWindow, but
    // for now we only follow rootViewController from UIView.
    
    if ([obj isKindOfClass:[UIWindow class]] && [((UIWindow *)obj).rootViewController isKindOfClass:class])
    {//obj:UIWindow
        [children addObject:((UIWindow *)obj).rootViewController];
    }
    else if ([obj isKindOfClass:[UIView class]])
    {//obj:UIView
        // NB. For UIViews, only add subviews, nothing else.
        // The ordering of this result is critical to being able to
        // apply the index filter.
        for (NSObject *child in [(UIView *)obj subviews]) {//遍历子视图
            if (!class || [child isKindOfClass:class]) {//class为nil,或obj的子视图为[class class]
                [children addObject:child];
            }
        }
    } else if ([obj isKindOfClass:[UIViewController class]])
    {//UIViewController
        UIViewController *viewController = (UIViewController *)obj;
        for (NSObject *child in [viewController childViewControllers])
        {
            if (!class || [child isKindOfClass:class])
            {
                [children addObject:child];
            }
        }
        if (viewController.presentedViewController && (!class || [viewController.presentedViewController isKindOfClass:class]))
        {
            [children addObject:viewController.presentedViewController];
        }
        if (!class || (viewController.isViewLoaded && [viewController.view isKindOfClass:class]))
        {
            [children addObject:viewController.view];
        }
    }
    NSArray *result;
    // Reorder the cells in a table view so that they are arranged by y position
    if ([class isSubclassOfClass:[UITableViewCell class]]) {//判断是否为TableViewCell的子类
        result = [children sortedArrayUsingComparator:^NSComparisonResult(UIView *obj1, UIView *obj2) {//生成有序数组
            if (obj2.frame.origin.y > obj1.frame.origin.y) {
                return NSOrderedAscending;
            } else if (obj2.frame.origin.y < obj1.frame.origin.y) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
    } else {
        result = [children copy];
    }
    return result;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@[%@]", self.name, self.index ?: self.predicate];
}

@end
