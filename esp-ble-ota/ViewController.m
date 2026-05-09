//
//  ViewController.m
//  ESPBluetoothDemo
//
//  Created by fanbaoying on 2019/10/31.
//  Copyright © 2019 fby. All rights reserved.
//

#import "ViewController.h"
#import "ESPFBYBLEHelper.h"
#import "payFirstNav.h"
#import "ESPFBYBLEIO.h"
#import "BleOTAUtils.h"
#import "EspCRC16.h"
#import "SVProgressHUD.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
    
typedef enum _RemindMessageType {
    defaultType = 0,          //默认
    hiddenImage,
    SuccessType,               //成功
    ErrorType,                //错误
}RemindMessageType;

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ESPFBYBleNotifyDelegate, UIDocumentPickerDelegate>

@property(strong, nonatomic)UIActivityIndicatorView *progressView;
@property (nonatomic, strong) ESPFBYBLEHelper *espFBYBleHelper;
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) UITableView *espBleDeviceTableView;
@property (nonatomic, assign) BOOL isScanDevice;

@property (strong, nonatomic) payFirstNav *nav;

@property(strong, nonatomic)UITextField *readTimeoutTextField;
@property(strong, nonatomic)UIView *keyboardview;
@property(strong, nonatomic)EspDevice *device;

@property(strong, nonatomic)NSData *binData;
@property(strong, nonatomic)NSMutableArray *binSectors;
@property(nonatomic, assign)NSUInteger sectorIndex;

#pragma mark - 新增：固件参数（与Android一致）
@property(nonatomic, assign) UpgradeType upgradeType;           // 升级类型: 0=APP, 1=SPIFFS
@property(nonatomic, assign) NSInteger partitionNumber;         // 分区号（SPIFS时有效）
@property(nonatomic, assign) BOOL isDeltaUpgrade;               // 是否差分升级
@property(nonatomic, assign) NSInteger partitionType;            // 分区类型
@property(nonatomic, assign) NSInteger partitionSubtype;         // 分区子类型
@property(nonatomic, assign) BOOL isSpecMode;                   // 是否spec模式
@property(nonatomic, assign) NSInteger bootPartition;           // 启动分区
@property(nonatomic, strong) NSString *selectedFileName;        // 选中的文件名

#pragma mark - 新增：UI组件
@property(strong, nonatomic) UIButton *selectFileBtn;          // 选择文件按钮
@property(strong, nonatomic) UILabel *fileInfoLabel;           // 文件信息标签

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.dataSource = [NSMutableArray arrayWithCapacity:0];
    self.binSectors = [NSMutableArray arrayWithCapacity:0];
    
    self.nav = [[payFirstNav alloc]initWithLeftBtn:nil andWithTitleLab:@"主页" andWithRightBtn:@"扫描" andWithBgImg:nil];
    [_nav.rightBtn addTarget:self action:@selector(navRightBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nav];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    UILabel *versionLab = [[UILabel alloc]initWithFrame:CGRectMake(10, statusHeight + 44, SCREEN_WIDTH - 20, 15)];
    versionLab.text = [NSString stringWithFormat:@"当前版本：%@", app_Version];
    [self.view addSubview:versionLab];
    
#pragma mark - 新增：选择文件按钮
    CGFloat btnY = statusHeight + 65;
    self.selectFileBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.selectFileBtn.frame = CGRectMake(20, btnY, SCREEN_WIDTH - 40, 44);
    [self.selectFileBtn setTitle:@"📁 选择固件文件 (.bin)" forState:UIControlStateNormal];
    [self.selectFileBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.selectFileBtn.backgroundColor = [UIColor systemBlueColor];
    self.selectFileBtn.layer.cornerRadius = 8;
    [self.selectFileBtn addTarget:self action:@selector(selectFirmwareFile:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.selectFileBtn];
    
#pragma mark - 新增：文件信息显示
    self.fileInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, btnY + 54, SCREEN_WIDTH - 40, 60)];
    self.fileInfoLabel.numberOfLines = 3;
    self.fileInfoLabel.textColor = [UIColor grayColor];
    self.fileInfoLabel.font = [UIFont systemFontOfSize:13];
    self.fileInfoLabel.text = @"未选择文件\n请点击上方按钮选择 .bin 固件文件";
    self.fileInfoLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.fileInfoLabel];
    
    self.espBleDeviceTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, statusHeight + 130, SCREEN_WIDTH, SCREEN_HEIGHT - (statusHeight + 130))];
    self.espBleDeviceTableView.delegate = self;
    self.espBleDeviceTableView.dataSource = self;
    self.espBleDeviceTableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_espBleDeviceTableView];
    
    self.keyboardview = [[UIView alloc]initWithFrame:CGRectMake(0, statusHeight + 90, SCREEN_WIDTH, SCREEN_HEIGHT - (statusHeight + 100))];
    self.keyboardview.backgroundColor = UICOLOR_RGBA(26, 26, 26, 0.1);
    self.keyboardview.hidden = YES;
    [self.view addSubview:_keyboardview];
    
    self.progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleMedium)];
    self.progressView.frame = CGRectMake(SCREEN_WIDTH / 2 - 50, SCREEN_HEIGHT / 2 - 50, 100, 100);
    self.progressView.color = [UIColor redColor];
    self.progressView.backgroundColor = UICOLOR_RGBA(236, 236, 236, 1);;
    [self.view addSubview:self.progressView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.espFBYBleHelper = [ESPFBYBLEHelper share];
    self.espFBYBleHelper.delegate = self;
    NSLog(@"self.espFBYBleHelper1%@",self.espFBYBleHelper);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.espBleDeviceTableView reloadData];
    });
}

- (void)navRightBtn:(UIButton *)sender {
    if (_isScanDevice) {
        NSLog(@"停止扫描");
        _isScanDevice = NO;
        [_nav.rightBtn setTitle:@"扫描" forState:0];
        [self.espFBYBleHelper stopDeviceScan];
    } else {
        _isScanDevice = YES;
        [_nav.rightBtn setTitle:@"停止" forState:0];
        NSLog(@"扫描设备");
        [self startDeviceScan];
    }
}

- (void)showProgress:(BOOL)show {
    if (show) {
        [self.progressView startAnimating];
    } else {
        [self.progressView stopAnimating];
    }
}

- (void)alterMessage:(NSString *)msgStr {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msgStr preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)startDeviceScan {
    [self.espFBYBleHelper startScan:^(EspDevice *device) {
        if (![self isAlreadyExist:device.uuidBle BLEDeviceArray:self.dataSource]) {
            [self.dataSource addObject:device];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.espBleDeviceTableView reloadData];
        });
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    if (!ValidArray(_dataSource)) {
        return cell;
    }
    EspDevice *device = [self.dataSource objectAtIndex:indexPath.row];
    
    cell.accessibilityIdentifier = device.name;
    
    UILabel *nameLab = [[UILabel alloc] init];
    nameLab.frame = CGRectMake(15, 10, CGRectGetWidth(tableView.frame), 40);
    NSString *deviceInfo = [NSString stringWithFormat:@"Name: %@    RSSI: %d",device.name,device.RSSI];
    nameLab.text = deviceInfo;
    nameLab.font = [UIFont systemFontOfSize:16];
    [cell.contentView addSubview:nameLab];
    
    UILabel *reminderLab = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 100, 30, 85, 20)];
    reminderLab.textAlignment = NSTextAlignmentRight;
    reminderLab.font = [UIFont systemFontOfSize:12];
    if (device.isConnected) {
        reminderLab.textColor = UICOLOR_RGBA(39, 158, 242, 1);
        reminderLab.text = @"connect";
    }else {
        reminderLab.textColor = [UIColor redColor];
        reminderLab.text = @"disconnect";
    }
    [cell.contentView addSubview:reminderLab];
    
    UILabel *uuidLab = [[UILabel alloc] init];
    uuidLab.frame = CGRectMake(15, 45,CGRectGetWidth(tableView.frame), 20);
    uuidLab.text = device.uuidBle;
    uuidLab.font = [UIFont systemFontOfSize:14];
    [cell.contentView addSubview:uuidLab];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!ValidArray(_dataSource)) {
        return;
    }
    
    if (!_binData) {
        [self remindMessage:@"请先选择固件文件" withType:hiddenImage];
        return;
    }
    
    _isScanDevice = NO;
    [_nav.rightBtn setTitle:@"扫描" forState:0];
    [self.espFBYBleHelper stopDeviceScan];
    EspDevice *device = _dataSource[indexPath.row];
    if (device.isConnected) {
        [self.espFBYBleHelper disconnect];
        self.dataSource = [NSMutableArray arrayWithArray:@[]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.espBleDeviceTableView reloadData];
        });
    }else {
        __weak typeof(self) weakSelf = self;
        [self.espFBYBleHelper connectBle:device callBackBlock:^(NSString * _Nonnull msg, EspDevice * _Nonnull encryptionSucDevice) {
            NSArray *msgArr = [msg componentsSeparatedByString:@":"];
            if (msgArr.count > 2 && [msgArr[2] intValue] == FoundCharacteristic) {
                NSLog(@"连接过程返回数据 %@",msg);
                weakSelf.device = encryptionSucDevice;
                weakSelf.device.isConnected = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.espBleDeviceTableView reloadData];
                });
                [weakSelf startOTAUpgrade];
            }
        }];
    }
}

#pragma mark - 新增：选择固件文件（支持文件夹选择）
- (void)selectFirmwareFile:(UIButton *)sender {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
                                                  initForOpeningContentTypes:@[UTTypeData]
                                                 mode:UIDocumentPickerModeImportMultiple];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count == 0) return;
    
    NSURL *fileURL = urls.firstObject;
    NSString *fileName = [fileURL lastPathComponent];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([fm fileExistsAtPath:fileURL.path]) {
        NSData *data = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:&error];
        
        if (!error && data.length > 0) {
            self.binData = data;
            self.selectedFileName = fileName;
            
#pragma mark - 解析文件名获取升级参数（与Android一致）
            NSDictionary *params = [BleOTAUtils parseFirmwareFileName:fileName];
            self.upgradeType = [params[@"upgradeType"] integerValue];
            self.partitionNumber = [params[@"partitionNumber"] integerValue];
            self.isDeltaUpgrade = [params[@"isDeltaUpgrade"] boolValue];
            self.partitionType = [params[@"partitionType"] integerValue];
            self.partitionSubtype = [params[@"partitionSubtype"] integerValue];
            self.isSpecMode = [params[@"isSpecMode"] boolValue];
            self.bootPartition = [params[@"bootPartition"] integerValue];
            
            NSString *upgradeTypeName = (self.upgradeType == UpgradeTypeApp) ? @"APP固件" : 
                                      (self.upgradeType == UpgradeTypeSPIFFS) ? @"SPIFS" : @"未知";
            
            self.fileInfoLabel.text = [NSString stringWithFormat:
                @"✅ 文件: %@\n"
                @"大小: %.1f KB | 类型: %@\n"
                @"差分:%@ | Spec:%@ | 分区:%ld",
                fileName,
                data.length / 1024.0,
                upgradeTypeName,
                self.isDeltaUpgrade ? @"是" : @"否",
                self.isSpecMode ? @"是" : @"否",
                (long)self.partitionNumber];
            
            self.fileInfoLabel.textColor = [UIColor darkTextColor];
            
            NSLog(@"[ViewController] 选择文件成功: %@ (%lu bytes)", fileName, (unsigned long)data.length);
            NSLog(@"[ViewController] 解析参数: type=%ld, partNum=%ld, delta=%@, spec=%@", 
                  (long)self.upgradeType, (long)self.partitionNumber,
                  self.isDeltaUpgrade ? @"YES" : @"NO", self.isSpecMode ? @"YES" : @"NO");
            
            [self remindMessage:[NSString stringWithFormat:@"已选择: %@", fileName] withType:SuccessType];
        } else {
            [self remindMessage:@"读取文件失败" withType:ErrorType];
            NSLog(@"[ViewController] 读取文件失败: %@", error.localizedDescription);
        }
    } else {
        [self remindMessage:@"文件不存在" withType:ErrorType];
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSLog(@"[ViewController] 用户取消文件选择");
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OTA升级流程（与Android一致）

/**
 * 初始化固件数据（切分为扇区）
 */
- (void)initBinData:(NSData *)bin {
    self.binData = bin;
    
    [self.binSectors removeAllObjects];
    [self.binSectors addObjectsFromArray:[BleOTAUtils generateSectors:bin]];
    self.sectorIndex = 0;
}

/**
 * 开始OTA升级流程
 * 与Android BleOTAActivity.doConnectGatt → BleOTAClient.connect → ota 一致
 */
- (void)startOTAUpgrade {
    if (!self.binData || !self.device) {
        [self remindMessage:@"未选择文件或未连接设备" withType:ErrorType];
        return;
    }
    
    NSLog(@"[ViewController] 开始OTA升级...");
    NSLog(@"[ViewController] 参数: type=%ld, partNum=%ld, delta=%@, pType=%ld, pSubtype=%ld, spec=%@, bootPart=%ld",
          (long)self.upgradeType, (long)self.partitionNumber,
          self.isDeltaUpgrade ? @"YES" : @"NO",
          (long)self.partitionType, (long)self.partitionSubtype,
          self.isSpecMode ? @"YES" : @"NO", (long)self.bootPartition);
    
    [self showProgress:YES];
    [self remindMessage:@"正在发送START命令..." withType:defaultType];
    
#pragma mark - 发送完整的START命令（18字节payload，与Android一致）
    NSData *startCommand = [BleOTAUtils generateStartCommandPacketWithSize:self.binData.length
                                                                upgradeType:self.upgradeType
                                                             partitionNumber:self.partitionNumber
                                                              isDeltaUpgrade:self.isDeltaUpgrade
                                                                partitionType:self.partitionType
                                                            partitionSubtype:self.partitionSubtype
                                                                   isSpecMode:self.isSpecMode
                                                                bootPartition:self.bootPartition];
    
    [self.device.currPeripheral writeValue:startCommand forCharacteristic:self.device.charCommand type:CBCharacteristicWriteWithResponse];
    
    [self initBinData:self.binData];
}

/**
 * OTA数据传输（发送固件扇区）
 * 与Android BleOTAClient.ota() → postNextPacket 一致
 */
- (void)ota {
    if (self.sectorIndex < self.binSectors.count) {
        NSData *sector = self.binSectors[self.sectorIndex];
        [self sendMsgWithSector:sector SectorIndex:self.sectorIndex];
    } else {
        NSData *endCommand = [BleOTAUtils generateEndCommandPacket];
        [self.device.currPeripheral writeValue:endCommand forCharacteristic:self.device.charCommand type:CBCharacteristicWriteWithResponse];
    }
}

/**
 * 原有方法保留兼容：从Documents目录读取（不推荐使用）
 */
- (void)getDocBinFile {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
    if (!ValidArray(files)) {
        [self remindMessage:@"升级文件不存在" withType:hiddenImage];
        return;
    }
    path = [path stringByAppendingPathComponent:files[0]];
    NSLog(@"file path:%@",path);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:path];
    if (!isExist) {
        [self remindMessage:@"升级文件路径错误" withType:hiddenImage];
        return;
    }
    NSData *data =[NSData dataWithContentsOfFile:path];
    NSLog(@"获取到的data：%@",data);
    
    [self showProgress:YES];
    
#pragma mark - 使用简化的START命令（仅binSize，用于向后兼容）
    [self.device.currPeripheral writeValue:[BleOTAUtils generateStartCommandPacket:data.length] forCharacteristic:self.device.charCommand type:CBCharacteristicWriteWithResponse];
    
    [self initBinData:data];
}

- (void)bleCharacteristicNotifyMsg:(CBCharacteristic *)characteristic {
    if (characteristic == self.device.charCommand) {
        OTAMessage *message = [BleOTAUtils parseCommandPacket:characteristic.value checksum:false];
        NSLog(@"message id=%d, status=%d", message.mid, message.status);
        switch (message.mid) {
            case COMMAND_ID_START:
                if (message.status == AckAccept) {
                    NSLog(@"[OTA] START ACK 接受，开始传输数据");
                    [self ota];
                } else {
                    NSLog(@"[OTA] START ACK 拒绝");
                    [self showProgress:NO];
                    [self alterMessage:@"升级启动失败"];
                }
                break;
            case COMMAND_ID_END:
                if (message.status == AckAccept) {
                    NSLog(@"[OTA] END ACK 接受，升级完成！");
                    [self.espFBYBleHelper disconnect:_device];
                    [self showProgress:NO];
                    [self alterMessage:@"✅ 升级成功！"];
                } else {
                    NSLog(@"[OTA] END ACK 拒绝");
                    [self showProgress:NO];
                    [self alterMessage:@"升级结束失败"];
                }
                break;
            default:
                break;
        }
    } else if (characteristic == self.device.charRecvFW) {
        OTAMessage *message = [BleOTAUtils parseBinAckPacket:characteristic.value];
        if (message.index != self.sectorIndex) {
            NSLog(@"[OTA] 扇区ACK索引不匹配: 期望=%lu, 实际=%d", (unsigned long)self.sectorIndex, message.index);
            [self showProgress:NO];
            [self alterMessage:@"扇区索引错误"];
            return;
        }
        
        switch (message.status) {
            case BIN_ACK_SUCCESS:
                self.sectorIndex++;
                [self ota];
                break;
            default:
                NSLog(@"[OTA] 扇区ACK失败: status=%d", message.status);
                [self showProgress:NO];
                [self alterMessage:@"数据传输失败"];
                break;
        }
    }
    
}

- (void)bleDisconnectMsg:(BOOL)isConnected {
    NSLog(@"蓝牙断开连接");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.espBleDeviceTableView reloadData];
    });
}

//分包发送蓝牙数据
-(void)sendMsgWithSector:(NSData*)sector
                 SectorIndex:(NSUInteger)index
{
    UInt16 crc = 0;
    int sequence = 0;
    NSUInteger mtu = [self.device.currPeripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse];
    NSLog(@"mtu: %lu", (unsigned long)mtu);
    Byte buf[mtu-5];
    NSInputStream *stream = [[NSInputStream alloc] initWithData:sector];
    [stream open];
    while (stream.hasBytesAvailable) {
        NSUInteger read = [stream read:buf maxLength:mtu-5];
        if (!stream.hasBytesAvailable) {
            crc = [EspCRC16 crc:sector];
            sequence = -1;
        }
        NSData *binPacket = [BleOTAUtils generateBinPakcet: buf dataLength:read index:index sequence:sequence crc:crc];
        ++sequence;
        [self.device.currPeripheral writeValue:binPacket forCharacteristic:self.device.charRecvFW type:CBCharacteristicWriteWithResponse];
    }
    [stream close];
    
}

- (BOOL)isAlreadyExist:(NSString *)deviceMac BLEDeviceArray:(NSMutableArray *)array {
    for (int i = 0; i < array.count; i++) {
        EspDevice *device = array[i];
        if ([deviceMac isEqualToString:device.uuidBle]) {
            return YES;
        }
    }
    return NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.espFBYBleHelper stopDeviceScan];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

//UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.keyboardview.hidden = NO;
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.keyboardview.hidden = YES;
}
- (void)remindMessage:(NSString *)message withType:(RemindMessageType)type {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (type == defaultType) {
            [SVProgressHUD showWithStatus:NSLocalizedString(message, nil)];
        } else if (type == hiddenImage) {
            [SVProgressHUD showImage:[UIImage imageNamed:@""] status:NSLocalizedString(message, nil)];
        } else if (type == SuccessType) {
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(message, nil)];
        } else {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(message, nil)];
        }
        [SVProgressHUD dismissWithDelay:2];
    });
}

@end