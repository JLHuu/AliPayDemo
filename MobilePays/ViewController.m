//
//  ViewController.m
//  MobilePays
//
//  Created by RichyLeo on 15/10/28.
//  Copyright (c) 2015年 RL. All rights reserved.
//

#import "ViewController.h"

// 支付宝支付需要的头文件
#import "Order.h"
#import <AlipaySDK/AlipaySDK.h>
#import "DataSigner.h"
// 微信支付需要的头文件
#import "WXPayClient.h"

#import "MBProgressHUD.h"

NSString * const HUDDismissNotification = @"HUDDismissNotification";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Events

- (IBAction)choosePayMethods:(id)sender {
    
    // 回顾
    UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"选择支付方式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 支付宝支付
    UIAlertAction * zhifubaoAction = [UIAlertAction actionWithTitle:@"支付宝支付" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self alipayAction];
    }];
    [alertC addAction:zhifubaoAction];
    
    // 微信支付
    UIAlertAction * wxAction = [UIAlertAction actionWithTitle:@"微信支付" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self wxPayAction];
    }];
    [alertC addAction:wxAction];
    
    // 取消
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alertC addAction:cancelAction];
    
    // 调起AlertController
    [self presentViewController:alertC animated:YES completion:nil];
}

#pragma mark - 支付宝支付

-(void)alipayAction
{
    /*
     *商户的唯一的parnter和seller。
     *签约后，支付宝会为每个商户分配一个唯一的 parnter 和 seller。
     */

    NSString *partner = ALIPAY_PARTNER;
    NSString *seller = ALIPAY_SELLER;
    NSString *privateKey = ALIPAY_PRIVATE_KEY;
    
    //partner和seller获取失败,提示
    if ([partner length] == 0 ||
        [seller length] == 0 ||
        [privateKey length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"缺少partner或者seller或者私钥。"
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // name=@"as"&description=@"sdfasdf"&...
    // ASCII 排序
    // RSA 算法处理－－得到新的字符串value（签名后的结果）
    // origalStr&sign=value
    
    /*
     *生成订单信息及签名
     */
    //将商品信息赋予AlixPayOrder的成员变量
    Order *order = [[Order alloc] init];
    order.partner = partner;
    order.seller = seller;
    order.tradeNO = [self generateTradeNO]; //订单ID（由商家自行制定）
    
    /**
     *  商品信息（标题，描述，价格）
     *  此内容在展示商品时，已然存在
     */
    order.productName = @"R"; //商品标题
    order.productDescription = @"mm"; //商品描述
    order.amount = [NSString stringWithFormat:@"%.2f",0.01]; //商品价格
    order.notifyURL =  @"https://www.baidu.com"; //回调URL
    
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showUrl = @"m.alipay.com";
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"alipayScheme";
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    /*
        签名处理：
        1. 将所有订单信息拼接 &
        2. 结合私钥对订单信息进行RSA签名处理
            （a。对所有订单参数作ASCII排序，b。对订单地址进行base64
     和URL编码）
     */
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
            
            /*
                对支付结果的处理：
                1. 成功 （判断条件会有两个：a。本身error_code = 0(表示成功)， b。返回的信息中会包含一个签名newSign，如果newSign＝＝ oldSign）
                2. 失败
             */
            
        }];
    
    }
    
    
    /*
        支付问点：
        1. 订单信息构建；
        2. 签名方式是怎样的，
        3. 签名的过程有哪些注意事项：（ASCII升序排序；中英文处理base64和Url编码；将sign作为新的订单参数 ）
        4. 支付成功如何处理；
     */
}

// 生成订单号（正常此工作由服务端生成并返回）
- (NSString *)generateTradeNO
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand(time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

#pragma mark - 微信支付

-(void)wxPayAction
{
    NSLog(@"wx");
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[WXPayClient shareInstance] payProduct];
}

@end
