//
//  SJPlayModelPropertiesObserver.m
//  SJVideoPlayerAssetCarrier
//
//  Created by 畅三江 on 2018/6/29.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJPlayModelPropertiesObserver.h"
#import <objc/message.h>
#import <UIKit/UIKit.h>
#import "SJIsAppeared.h"

#if __has_include(<SJObserverHelper/NSObject+SJObserverHelper.h>)
#import <SJObserverHelper/NSObject+SJObserverHelper.h>
#else
#import "NSObject+SJObserverHelper.h"
#endif

NS_ASSUME_NONNULL_BEGIN
@interface SJPlayModelPropertiesObserver()
@property (nonatomic, strong, readonly) id<SJPlayModel> playModel;
@property (nonatomic) CGPoint beforeOffset;
@property (nonatomic) BOOL isAppeared;
@end

@implementation SJPlayModelPropertiesObserver

- (instancetype)initWithPlayModel:(__kindof SJPlayModel *)playModel {
    NSParameterAssert(playModel);
    
    self = [super init];
    if ( !self ) return nil;
    _playModel = playModel;
    if ( [playModel isMemberOfClass:[SJPlayModel class]] ) {
        _isAppeared = YES;
    }
    else {
        [self _observeProperties];
    }
    return self;
}

- (void)_observeProperties {
    if ( [_playModel isKindOfClass:[SJUITableViewCellPlayModel class]] ) {
        SJUITableViewCellPlayModel *playModel = _playModel;
        _isAppeared = [self _isAppearedInTheScrollingView:playModel.tableView];
        [self _observeScrollView:playModel.tableView];
        _beforeOffset = playModel.tableView.contentOffset;
    }
    else if ( [_playModel isKindOfClass:[SJUICollectionViewCellPlayModel class]] ) {
        SJUICollectionViewCellPlayModel *playModel = _playModel;
        _isAppeared = [self _isAppearedInTheScrollingView:playModel.collectionView];
        [self _observeScrollView:playModel.collectionView];
        _beforeOffset = playModel.collectionView.contentOffset;
    }
    else if ( [_playModel isKindOfClass:[SJUITableViewHeaderViewPlayModel class]] ) {
        SJUITableViewHeaderViewPlayModel *playModel = _playModel;
        _isAppeared = [self _isAppearedInTheScrollingView:playModel.tableView];
        [self _observeScrollView:playModel.tableView];
    }
    else if ( [_playModel isKindOfClass:[SJUICollectionViewNestedInUITableViewHeaderViewPlayModel class]] ) {
        SJUICollectionViewNestedInUITableViewHeaderViewPlayModel *playModel = _playModel;
        _isAppeared = [self _isAppearedInTheScrollingView:playModel.collectionView];
        [self _observeScrollView:playModel.collectionView];
        [self _observeScrollView:playModel.tableView];
    }
    else if ( [_playModel isKindOfClass:[SJUICollectionViewNestedInUITableViewCellPlayModel class]] ) {
        SJUICollectionViewNestedInUITableViewCellPlayModel *playModel = _playModel;
        _isAppeared = [self _isAppearedInTheScrollingView:playModel.collectionView];
        [self _observeScrollView:playModel.collectionView];
        [self _observeScrollView:playModel.tableView];
    }
    else if ( [_playModel isKindOfClass:[SJUICollectionViewNestedInUICollectionViewCellPlayModel class]] ) {
        SJUICollectionViewNestedInUICollectionViewCellPlayModel *playModel = _playModel;
        _isAppeared = [self _isAppearedInTheScrollingView:playModel.collectionView];
        [self _observeScrollView:playModel.collectionView];
        [self _observeScrollView:playModel.rootCollectionView];
    }
}

static NSString *kContentOffset = @"contentOffset";
static NSString *kState = @"state";
- (void)_observeScrollView:(UIScrollView *)scrollView {
    if ( !scrollView ) return;
    if ( ![scrollView isKindOfClass:[UIScrollView class]] ) return;
    [scrollView sj_addObserver:self forKeyPath:kContentOffset context:&kContentOffset];
    [scrollView.panGestureRecognizer sj_addObserver:self forKeyPath:kState context:&kState];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(nullable void *)context {
    if ( &kContentOffset == context ) {
        [self _scrollViewDidScroll:object];
    }
    else if ( &kState == context ) {
        [self _panGestureStateDidChange:object];
    }
}

- (void)_panGestureStateDidChange:(UIPanGestureRecognizer *)pan {
    if ( !pan ) return;
    UIGestureRecognizerState state = pan.state;
    BOOL isTableView = NO;
    BOOL isCollectionView = NO;
    switch ( state ) {
        case UIGestureRecognizerStateChanged: return;
        case UIGestureRecognizerStatePossible: return;
        case UIGestureRecognizerStateBegan: {
            if ( [pan.view isKindOfClass:[UITableView class]] ) {
                _isTouchedTablView = YES;
                isTableView = YES;
            }
            else if ( [pan.view isKindOfClass:[UICollectionView class]] ) {
                _isTouchedCollectionView = YES;
                isCollectionView = YES;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            if ( [pan.view isKindOfClass:[UITableView class]] ) {
                _isTouchedTablView = NO;
                isTableView = YES;
            }
            else if ( [pan.view isKindOfClass:[UICollectionView class]] ) {
                _isTouchedCollectionView = NO;
                isCollectionView = YES;
            }
        }
            break;
    }
    
    if ( isTableView ) {
        if ( [self.delegate respondsToSelector:@selector(observer:userTouchedTableView:)] ) {
            [self.delegate observer:self userTouchedTableView:_isTouchedTablView];
        }
    }
    else if ( isCollectionView ) {
        if ( [self.delegate respondsToSelector:@selector(observer:userTouchedCollectionView:)] ) {
            [self.delegate observer:self userTouchedCollectionView:_isTouchedCollectionView];
        }
    }
}

- (BOOL)_isAppearedInTheScrollingView:(UIScrollView *)scrollView {
    return sj_isAppeared2(_playModel.playerSuperview, scrollView);
}

- (void)_scrollViewDidScroll:(UIScrollView *)scrollView {
    if ( !scrollView ) return;
    if ( CGPointEqualToPoint(_beforeOffset, scrollView.contentOffset) ) return;
    self.isAppeared = [self _isAppearedInTheScrollingView:scrollView];
    _beforeOffset = scrollView.contentOffset;
}

@synthesize isAppeared = _isAppeared;
- (void)setIsAppeared:(BOOL)isAppeared {
    if ( isAppeared == _isAppeared ) return;
    _isAppeared = isAppeared;
    if ( isAppeared ) {
        if ( [self.delegate respondsToSelector:@selector(playerWillAppearForObserver:superview:)] ) {
            [self.delegate playerWillAppearForObserver:self superview:_playModel.playerSuperview];
        }
    }
    else {
        if ( [self.delegate respondsToSelector:@selector(playerWillDisappearForObserver:)] ) {
            [self.delegate playerWillDisappearForObserver:self];
        }
    }
}

- (BOOL)isPlayInTableView {
    return _playModel.isPlayInTableView;
}

- (BOOL)isPlayInCollectionView {
    return _playModel.isPlayInCollectionView;
}

- (void)refreshAppearState {
    if ( [_playModel isMemberOfClass:[SJPlayModel class]] ) {
        self.isAppeared = YES;
        return;
    }
    
    UIView *superview = _playModel.playerSuperview;
    while ( superview && !([superview isKindOfClass:[UITableView class]] || [superview isKindOfClass:[UICollectionView class]]) ) {
        superview = superview.superview;
    }
    if ( !superview ) {
        self.isAppeared = NO;
        return;
    }
    self.isAppeared = [self _isAppearedInTheScrollingView:(id)superview];
}
@end
NS_ASSUME_NONNULL_END
