//
//  PPScrollView.h
//  ScrollerViewCircle
//
//  Created by Mu on 16/4/12.
//  Copyright © 2016年 lamco. All rights reserved.
//


//         2016.4.14\
- 使用指南\
1.需要导入第三方框架SDWebImage：可以使用cocospod也可以直接拖该框架到当前工程下\
2.如果传递的数据源内图片的URL地址是http类型：需要更改工程的info.plist文件允许http网络请求\
3.数据源类型为普通集合：集合内存储的是图片的URL地址, 需要在初始化该控件的时候进行传递（初始化需要时使用带有数据源的方法）\
4.暂时没有请求到或者不存在的图片通过一张默认图片进行占位：图片的名称为placeholderImage, 格式为png（需要手动拖动符合要求的图片到工程下）\
5.通过点语法访问就能直接得到分页控件, 不需要创建对象, 只读属性：分页控件需要和PPScrollView一样添加同一个父视图上, 不能直接添加在scroll上（scroll是不断偏移的）（需要先添加PPScrollView再添加pageControl避免分页控件被覆盖）\
6.显示立即体验按钮：为最后一个页面添加按钮；按钮为只读属性当是可以为按钮添加事件，触发事件可以自定义\
7.增加访问本地图片功能，对传入的数据源不限定只为图片的URL地址，也可以是工程下的图片的名称（注意：尺寸在非png格式的图片时需要将图片的后缀也写入图片名称字符串再存储到集合）：对显示图片和分页图片都适用\
\
- 更新功能\
1.提供了分页控件的属性：通过分页控件可以修改分页控件的属性以及需要显示的数量等（数据源超过10后缺省为10）\
2.新增了懒加载：对分页控件的创建进行处理, 使用getter访问器即可得到分页控件（只读属性）\
3.提供了默认显示第几页的属性：传递的参数为整型, 且页数不能小于0也不能超过集合内的数量（错误数值过滤为0, 但不切换页面）\
4.提供在最后一页显示立即体验按钮，需要将showExperience设置为YES，默认为NO；按钮事件需要自定义\
5.增加访问本地图片功能，对传入的数据源不限定只为图片的URL地址，也可以是工程下的图片的名称（注意：尺寸在非png格式的图片时需要将图片的后缀也写入图片名称字符串再存储到集合）\
6.增加了自定义分页图片，使用直接存入分页图片到集合即可（使用自定义分页图片就不需要再在其容器即父视图上添加pageController）\
7.增加了定时轮播功能：需要设置定时器的间隔值才会定时切换轮播图片：间隔值需要大于0（触碰屏幕停止3s）\
- bug说明：如果添加该控件滚动时出现不能锁定或者图片跳动的情况, 可以将该控件添加到一个和该控件相等frame的view或者imageView上, 再将该view或者imageView添加到视图（为控件添加背景色或者清除背景色）


#import <UIKit/UIKit.h>

@interface PPScrollView : UIScrollView

/**
 *  通过分页控件可以修改分页控件的属性以及需要显示的数量等（数据源超过10后缺省为10）
 */
@property (nonatomic, strong, readonly)UIPageControl *pageControl;

/**
 *  传递的参数为整型, 且页数不能小于0也不能超过集合内的数量（错误数值过滤为0, 但不切换页面）
 */
@property (nonatomic)NSInteger firstPage;  //default is 1（集合索引为0）

/**
 *  默认占位图片：图片的名称为placeholderImage, 格式为png（需要手动拖动符合要求的图片到工程下）
 *  也能加载工程下的图片的名称（注意：尺寸在非png格式的图片时需要将图片的后缀也写入图片名称字符串再存储到集合）
 */
- (PPScrollView *)initWithFrame:(CGRect)frame andarrDataScrollView:(NSArray *)arrDataScrollView;

/**
 *  数据源类型为普通集合：集合内存储的是图片的URL地址, 需要在初始化该控件的时候进行传递
 */
+ (PPScrollView *)ppScrollViewWithFrame:(CGRect)frame andarrDataScrollView:(NSArray *)arrDataScrollView;

/**
 *  是否加载立即体验按钮
 */
@property (nonatomic, getter=isShowExperienceButton)BOOL showExperienceButton;   //default is NO
/**
 *  添加立即体验按钮：可以为按钮添加事件（如果需要设置buttonExperience的图片，将懒加载中的代码注释：按住command+点击buttonExperience）
 */
@property (nonatomic, strong, readonly)UIButton *buttonExperience;
/**
 *  传入自定义分页控件的图片：存储图片的顺序请保持正确（可以是本地图片名称也可以是URl地址）
 */
@property (nonatomic, strong)NSArray *arrPageImages;
/**
 *  需要设置定时器的间隔值才会定时切换轮播图片：定时器的值需要大于0，非法值将会被设置为缺省值轮播
 */
@property (nonatomic)CGFloat timerSpace;   //defualt = 1;
@end
