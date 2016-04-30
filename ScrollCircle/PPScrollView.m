//
//  PPScrollView.m
//  ScrollerViewCircle
//
//  Created by Mu on 16/4/12.
//  Copyright © 2016年 lamco. All rights reserved.
//

#import "PPScrollView.h"
#import "UIImageView+WebCache.h"
#import <ImageIO/ImageIO.h>

// scrollView size.
#define PPWIDSCORLL self.frame.size.width //self.frame是该控件被初始化时传递的frame, 不一定就是手机的屏幕尺寸
#define PPHEISCORLL self.frame.size.height

@interface PPScrollView ()<UIScrollViewDelegate>

// 修复懒加载漏洞：当控件需要的是懒加载内的属性时, 避免控件被setter访问器赋值
// 1.重写setter访问器：当重写了setter和getter后Xcode就不会自动在.m文件中生成私有成员变量：这时候需要手动添加\
   重写setter是为了堵懒加载漏洞，setter访问器实现为空：因为分页控件需要懒加载内封装的属性和frame因此setter实现为空过滤掉外界赋值（实现为空不等于不写）\
   2.将控件属性设置为只读：Xcode就只会生成getter访问器：也需要手动添加私有成员变量, 因为只生成了getter访问器而且还被重写了因此Xcode也不会在.m文件中生成私有成员变量
{
    UIPageControl *_pageControl;
    
    UIButton *_buttonExperience;
}

// 记录偏移量：判断偏移后更改数组下标，通过数组下标进行显示（数组显示图片的下标即pageControl的页数）
@property (nonatomic, assign)NSInteger currentPage;

// 数据源不能留给外界赋值, 因为scroll没有reload方法, 因此需要在自定义构造方法对数据源进行初始化和传递
@property (nonatomic, strong)NSArray *arrImages;
// 创建一个自定义分页图片的imv：定义为全局变量为了使用懒加载（指针的单例：确保imv只存在一个也是重用的思想）
@property (nonatomic, strong)UIImageView *imvPage;
// 创建定时器，为了保证屏幕在点击时取消定时器
@property (nonatomic, strong)NSTimer *timer;
@end
@implementation PPScrollView

// 因为重写父类方法只能传递frame, 而且ScrollView没有reloadData方法, 为了初始化数据源因此需要自定义
// 自定义构造方法
- (PPScrollView *)initWithFrame:(CGRect)frame andarrDataScrollView:(NSArray *)arrDataScrollView
{
    if (self = [super initWithFrame:frame])
    {
        // 设置背景色（避免出现跳动的bug）
        self.backgroundColor = [UIColor clearColor];
        // 获取到数据源
        _arrImages = arrDataScrollView;
        // 初始化scroll
        [self createScrollerView];
    }
    return self;
}
// 提供类工厂方法
+ (PPScrollView *)ppScrollViewWithFrame:(CGRect)frame andarrDataScrollView:(NSArray *)arrDataScrollView
{
    return [[self alloc] initWithFrame:frame andarrDataScrollView:arrDataScrollView];
}

// 初始化scroll
- (void)createScrollerView
{
    // - scroll包含的视图范围
    self.contentSize = CGSizeMake(PPWIDSCORLL * self.arrImages.count, PPHEISCORLL);
    // - 指定代理：获取偏移量
    self.delegate = self;
    // - 允许分页
    self.pagingEnabled = YES;
    // - 隐藏滚动条
    self.showsHorizontalScrollIndicator = NO;
    // - 去掉回弹效果
    self.bounces = NO;
    
    // - 取消三个重用imageView属性, 定义为局部变量，通过tag值获取控件\
    // - 创建重用视图：每次使用都只是更换显示内容而不是创建新的对象, 加盟数据和显示进行分离
    UIImageView *imv_1 = [[UIImageView alloc] initWithFrame:CGRectZero];
    imv_1.tag = 2016;
    UIImageView *imv_2 = [[UIImageView alloc] initWithFrame:CGRectZero];
    imv_2.tag = 4;
    UIImageView *imv_3 = [[UIImageView alloc] initWithFrame:CGRectZero];
    imv_3.tag = 14;
    
    // - 将重用imv添加到scroll
    // - 通过tag值获取控件时, 控件必须要添加在视图上, 只有这样才能在它的父视图中通过tag找到对应的控件
    [self addSubview:imv_1];
    [self addSubview:imv_2];
    [self addSubview:imv_3];
    
    // - 默认加载第一张图
    [self reloadImage];
}

// 根据提供的索引加载数组内对应的图片：只是负责显示
-(void)reloadImage
{
    // 根据数组索引显示对应索引以及它前后的图片图片：每次都显示中间一张图（偏移量为一个imageView的宽度）
    
    // 根据tag值获取对控件，没有定义为全局变量
    UIImageView *imv_1 = [self viewWithTag:2016];
    UIImageView *imv_2 = [self viewWithTag:4];
    UIImageView *imv_3 = [self viewWithTag:14];
    
    // 根据_currentPage加载对应图片
    [self loadImage];
    
    // 立即体验按钮：最后一页再添加
    if (_currentPage == self.arrImages.count -1 & _showExperienceButton==YES)
    {
        [imv_2 addSubview:self.buttonExperience];
        imv_2.userInteractionEnabled = YES;
    }else
    {
        if (_buttonExperience)
        {
            [self.buttonExperience removeFromSuperview];
        }
        imv_2.userInteractionEnabled = NO;
    }
    
    // 加载自定义分页图片
    if (self.arrPageImages[_currentPage])
    {
        // 懒加载即完成所有工作，使用该控件只是更换其内容
        
        if ([_arrPageImages[_currentPage] hasPrefix:@"http"])
        {
            [self.imvPage sd_setImageWithURL:_arrPageImages[_currentPage]];
        }else
        {
            self.imvPage.image = [UIImage imageNamed:self.arrPageImages[_currentPage]];
        }
        //[imv_2 addSubview:self.imvPage];
    }
    
    // 每次修改frame：显示数据不为空再给frame赋值
    imv_1.frame = CGRectMake(0, 0, PPWIDSCORLL, PPHEISCORLL);
    imv_2.frame = CGRectMake(PPWIDSCORLL, 0, PPWIDSCORLL, PPHEISCORLL);
    imv_3.frame = CGRectMake(PPWIDSCORLL*2, 0, PPWIDSCORLL, PPHEISCORLL);
    
    // 让每次切换都能看到三张图：保证流畅性（每次显示的都是中间一张图）
    self.contentOffset = CGPointMake(PPWIDSCORLL, 0);
    
}
- (void)loadImage
{
    // 根据tag值获取对控件，没有定义为全局变量
    UIImageView *imv_1 = [self viewWithTag:2016];
    UIImageView *imv_2 = [self viewWithTag:4];
    UIImageView *imv_3 = [self viewWithTag:14];
    
    // 通过SDwebImage请求图片
    if ([_arrImages[_currentPage] hasPrefix:@"http"])
    {
        // 第一页：
        if (!_currentPage)
        {
            [imv_1 sd_setImageWithURL:[_arrImages lastObject] placeholderImage:[UIImage imageNamed:@"placeholderImage.jpg"] options:SDWebImageRetryFailed];
            [imv_3 sd_setImageWithURL:_arrImages[_currentPage+1] placeholderImage:[UIImage imageNamed:@"placeholderImage.jpg"] options:SDWebImageRetryFailed];
        }
        // 最后一页
        else if (_currentPage == self.arrImages.count -1) //数组的count从1开始
        {
            [imv_1 sd_setImageWithURL:_arrImages[_currentPage-1] placeholderImage:[UIImage imageNamed:@"placeholderImage.jpg"] options:SDWebImageRetryFailed];
            [imv_3 sd_setImageWithURL:[_arrImages firstObject] placeholderImage:[UIImage imageNamed:@"placeholderImage.jpg"] options:SDWebImageRetryFailed];
        }
        // 中间页
        else
        {
            [imv_1 sd_setImageWithURL:_arrImages[_currentPage-1] placeholderImage:[UIImage imageNamed:@"placeholderImage.jpg"] options:SDWebImageRetryFailed];
            [imv_3 sd_setImageWithURL:_arrImages[_currentPage+1] placeholderImage:[UIImage imageNamed:@"placeholderImage.jpg"] options:SDWebImageRetryFailed];
        }
        // 无论怎么走，中间imv一定显示当前图片
        [imv_2 sd_setImageWithURL:_arrImages[_currentPage]  placeholderImage:[UIImage imageNamed:@"placeholderImage.jpg"] options:SDWebImageRetryFailed];
    }
    // 加载本地图片
    else
    {
        // 第一页：
        if (!_currentPage)
        {
            imv_1.image = [UIImage imageNamed:[_arrImages lastObject]];
            imv_3.image = [UIImage imageNamed:_arrImages[_currentPage+1]];
        }
        // 最后一页
        else if (_currentPage == self.arrImages.count -1) //数组的count从1开始
        {
            imv_1.image = [UIImage imageNamed:_arrImages[_currentPage-1]];
            imv_3.image = [UIImage imageNamed:[_arrImages firstObject]];
        }
        // 中间页
        else
        {
            imv_1.image = [UIImage imageNamed:_arrImages[_currentPage-1]];
            imv_3.image = [UIImage imageNamed:_arrImages[_currentPage+1]];
        }
        // 无论怎么走，中间imv一定显示当前图片
        imv_2.image = [UIImage imageNamed:_arrImages[_currentPage]];
    }
}

#pragma mark - ScrollView Delegate
//在滚动结束状态换图：DidEnd
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    // 确定下标：通过判断偏移量改变索引
    // 因为只有三个视图，因此偏移量是两个定值
    
    // 向左：偏移量恒为0
    if (!self.contentOffset.x)
    {
        if (!_currentPage)
        {
            // 在第0页左移后，集合索引为最后一个对象：
            _currentPage = _arrImages.count - 1; //数组的count从1开始
        }
        else
        {
            _currentPage--; // 一直左移，只会走一次if语句直到0
        }
    }
    
    // 向右：偏移量恒为两倍
    if (self.contentOffset.x == PPWIDSCORLL*2)
    {
        if (_currentPage == _arrImages.count - 1) //数组的count从1开始
        {
            _currentPage = 0; // 在最后一页右移：集合索引就赋值为0
        }
        else
        {
            // 一直右移，只会在到达最后一个元素位置走if语句
            _currentPage++;
        }
    }
    
    // 仔细观察打印数据，左右拖动一点都是打印一个imageView宽度，左移切换打印为0，右移切换打印为两个imageView宽度（因为只有三个imageView）
    //NSLog(@"%f", self.contentOffset.x);
    
    // 集合的下标即为当前页数：同步切换
    _pageControl.currentPage = _currentPage;
    
    // 通过偏移计算得到的索引调用方法确定显示的imageView
    [self reloadImage];
    
    // 视图滑动结束后延迟3s后再开启定时器
    [self performSelector:@selector(delayTimer) withObject:nil afterDelay:3.0];

}

// 懒加载也称为延迟加载\
通过重写getter访问器实现，即在需要的时候才加载，节省了内存资源，代码彼此之间的独立性更强强，耦合性更低，代码可读性更高\
每个控件的getter方法中分别负责各自的实例化处理，封装了创建该属性的对象的过程（需要使用self.属性名取值才会调用getter访问器因此在当前类中不能通过_属性名取值）\
懒加载一定要注意先判断该对象是否已经存在，如果不存在再进行实例化, 只是针对某个属性或者控件, 一个指针对应一个对象\
\
确保只要使用这个对象才会创建而不会重复创建\
益处_1：避免了对象不存在却使用该对象而导致的程序没反应的情况，因为定义的指针没有关联对象之前默认是空指针：不需要在考虑调用方法或者属性时该对象是否被创建\
益处_2：确保不会重复创建同一个对象：定义属性只是一个该类型的指针，每一次alloc都会创建一个新的对象，虽然还是这个指针但是指针却指向了该类的另一个对象：懒加载获取对象通过getter方法\
\
\
赌掉setter访问器后, 对getter访问器进行懒加载时我认为是属于指针的单例\
当控件需要懒加载内封装的属性和frame时, 要屏蔽掉setter访问器\
1.重写setter访问器：当重写了setter和getter后Xcode就不会自动在.m文件中生成私有成员变量：这时候需要手动添加\
setter访问器实现为空, 目的是让赋值变得无效：过滤掉外界赋值（实现为空不等于不写）\
2.将控件属性设置为只读：Xcode就只会生成getter访问器：也需要手动添加私有成员变量, 因为只生成了getter访问器而且还被重写了因此Xcode也不会在.m文件中生成私有成员变量

// 添加分页标识
// 修补了懒加载漏洞：过滤掉通过setter访问器赋值或者拒绝被赋值（重写setter空实现或者为属性添加readonly）, 确保分页控件的使用没有bug
- (UIPageControl *)pageControl
{
    // 显示分页控件：需要和scroll一样添加同一个父视图上, 不能直接添加在scroll上（scroll是不断偏移的）
    // - 传递页数需要代理实现：该控件
    if (!_pageControl)
    {
        /*----------bug修复-------------*/
        // > 让pageControl和scroll同步移动：距离屏幕的左右间距加上scroll的self.frame.origin.y和x（因为和scroll一样添加同一个父视图上而不是添加在scoll内）
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake((PPWIDSCORLL-PPWIDSCORLL/4)/2 + self.frame.origin.x, PPHEISCORLL-PPHEISCORLL/10 + self.frame.origin.y, PPWIDSCORLL/4, PPHEISCORLL/10)];
        // - 限定页数：不能直接集合内数据源数量作为总页数, 当数量小于10时使用集合的count
        if (_arrImages.count >= 10)
        {
            _pageControl.numberOfPages = 10;
            
        }else
        {
            _pageControl.numberOfPages = self.arrImages.count;
        }
        // - 清除背景色
        _pageControl.backgroundColor = [UIColor clearColor];
        // - 更换分页颜色
        _pageControl.currentPageIndicatorTintColor = [UIColor purpleColor]; //当前页
        _pageControl.pageIndicatorTintColor = [UIColor whiteColor]; //页面指示器
        // - 和用户不交互（没有代理方法, 因此不能通过点击分页点切换页面）
        _pageControl.userInteractionEnabled = NO;
    }
    
    return _pageControl;
}
// 重写getter是为了懒加载，重写setter是为了避免属性被赋值，此时分页控件需要懒加载内封装的属性和frame因此setter实现为空过滤掉外界赋值
- (void)setPageControl:(UIPageControl *)pageControl
{
    // 属性为readonly时可以省略
    // 实现为空不等于没写：实现为空通过setter赋值被过滤，即赋值操作无效（使用到该属性就会调用懒加载因此程序是没有bug的）
}

- (void)setFirstPage:(NSInteger)firstPage
{
    if (firstPage>=0 && firstPage<=self.arrImages.count)
    {
        // 让页数从1开始：第一页（都习惯数量从0开始了）\
        虽然采用imageView显示就会先先向右偏移一个imageView宽度, 但是数组的count是从1开始的，虽然数组的下标从0开始但是还是需要减去1
        self.currentPage = firstPage -1;
        self.pageControl.currentPage = firstPage -1;
        [self reloadImage];
    }else
    {
        // 过滤掉方法值，默认设为0，但不调用图片显示
        firstPage = 0;
    }
}

// 懒加载
- (UIButton *)buttonExperience
{
    if (!_buttonExperience)
    {
        _buttonExperience = [UIButton buttonWithType:UIButtonTypeCustom];
        _buttonExperience.frame = CGRectMake((PPWIDSCORLL -PPWIDSCORLL *.2)/2, PPHEISCORLL* 17/20, PPWIDSCORLL *.2, PPHEISCORLL /20);
        
        // 如果需要设置_buttonExperience的图片，将这些代码注释
        /*
        _buttonExperience.layer.cornerRadius = PPHEISCORLL/50;
        _buttonExperience.backgroundColor = [UIColor whiteColor];
        _buttonExperience.titleLabel.font = [UIFont systemFontOfSize:PPWIDSCORLL/34];
        [_buttonExperience setTitle:@"立即体验" forState:UIControlStateNormal];
        [_buttonExperience setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];  // 点击有动态效果
        _buttonExperience.tag = 1001;  //不需要tag值，因为懒加载使用getter
        */
        //_buttonExperience.showsTouchWhenHighlighted = YES;
    }
    return _buttonExperience;
}

// 创建一个自定义分页图片的imv：定义为全局变量为了使用懒加载（指针的单例：确保imv只存在一个也是重用的思想
- (UIImageView *)imvPage
{
    if (!_imvPage)
    {
        // 懒加载即完成所有工作，使用该控件只是更换其内容
        _imvPage = [[UIImageView alloc] initWithFrame:CGRectMake((PPWIDSCORLL-PPWIDSCORLL/4)/2, PPHEISCORLL -PPHEISCORLL/10 +PPHEISCORLL/40 , PPWIDSCORLL/4, PPHEISCORLL/20)]; //自定义控件只占据pageController的一半，距离上下都让出本身的1/4
        [[self viewWithTag:4] addSubview:_imvPage];
    }
    return _imvPage;
}

// 重写setter访问器是为了监听赋值即时属性显示的状态：避免赋值操作没有刷新第一页的情况
- (void)setArrPageImages:(NSArray *)arrPageImages
{
    if (_arrPageImages != arrPageImages)
    {
        _arrPageImages = arrPageImages;
        
        // 避免赋值是在创建当前类的对象之后，第一张图不能刷新的情况
        [self reloadImage];
    }
}

// 监听轮播间隔被赋值才操作
- (void)setTimerSpace:(CGFloat)timerSpace
{
    if (_timerSpace != timerSpace)
    {
        // 先取值
        _timerSpace = timerSpace;
        if (_timerSpace < 0.0f)
        {
            // 过滤非法值为1s
            _timerSpace = 1.0f;
        }
        // 创建定时器
        self.timer = [NSTimer scheduledTimerWithTimeInterval:_timerSpace target:self selector:@selector(timerLoadImage) userInfo:nil repeats:YES];
    }
}
- (void)timerLoadImage
{
    if (_currentPage == _arrImages.count - 1) //数组的count从1开始
    {
        _currentPage = 0; // 在最后一页右移：集合索引就赋值为0
    }
    else
    {
        // 一直右移，只会在到达最后一个元素位置走if语句
        _currentPage++;
    }
    
    // 集合的下标即为当前页数：同步切换
    _pageControl.currentPage = _currentPage;
    
    // 通过偏移计算得到的索引调用方法确定显示的imageView
    [self reloadImage];
}

// 通过手机屏幕的触碰确定定时器的开关
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 关闭定时器
    [self.timer setFireDate:[NSDate distantFuture]];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 关闭定时器
    [self.timer setFireDate:[NSDate distantFuture]];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 延迟3s后开启定时器
    [self performSelector:@selector(delayTimer) withObject:nil afterDelay:3.0];
}
- (void)delayTimer
{
    // 开启定时器
    [self.timer setFireDate:[NSDate distantPast]];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // 关闭定时器（视图滑动结束后延迟3s后再开启定时器）
    [self.timer setFireDate:[NSDate distantFuture]];
}

//注意：将计数器的repeats设置为YES的时候，self的引用计数会加1。\
       因此可能会导致self（即viewController）不能release\
       所以，必须在viewWillAppear的时候，将计数器timer停止，否则可能会导致内存泄露。
//页面将要进入前台，开启定时器
-(void)viewWillAppear:(BOOL)animated
{
    //开启定时器
    [self.timer setFireDate:[NSDate distantPast]];
}
//页面消失，进入后台不显示该页面，关闭定时器
-(void)viewDidDisappear:(BOOL)animated
{
    //关闭定时器
    [self.timer setFireDate:[NSDate distantFuture]];
}
@end
