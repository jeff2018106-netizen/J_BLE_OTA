//
//  BleOTAUtils.h
//  itest
//
//  Created by fby on 2021/10/29.
//

#import <Foundation/Foundation.h>
#import "OTAMessage.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    AckAccept = 0x0000,
    AckRefuse = 0x0001
}CommandAck;

typedef NS_ENUM(NSInteger, UpgradeType) {
    UpgradeTypeApp = 0,      // APP固件升级
    UpgradeTypeSPIFFS = 1,   // SPIFS文件系统升级
    UpgradeTypeUnknown = 2   // 未知类型
};

@interface BleOTAUtils : NSObject

+ (NSArray<NSData *> *)generateSectors:(NSData *)bin;

+ (NSData *)generateBinPakcet:(Byte *)data dataLength:(NSUInteger)dataLength index:(NSUInteger)index sequence:(int)sequence crc:(UInt16)crc;

#pragma mark - 原有方法（保留兼容）
+ (NSData *)generateStartCommandPacket:(NSUInteger)binSize;

#pragma mark - 新增：完整START命令（与Android一致）
+ (NSData *)generateStartCommandPacketWithSize:(NSUInteger)binSize
                                   upgradeType:(UpgradeType)upgradeType
                                partitionNumber:(NSInteger)partitionNumber
                                 isDeltaUpgrade:(BOOL)isDeltaUpgrade
                                   partitionType:(NSInteger)partitionType
                               partitionSubtype:(NSInteger)partitionSubtype
                                      isSpecMode:(BOOL)isSpecMode
                                   bootPartition:(NSInteger)bootPartition;

+ (NSData *)generateEndCommandPacket;

+ (OTAMessage *)parseCommandPacket:(NSData *)data checksum:(BOOL)checksum;

+ (OTAMessage *)parseBinAckPacket:(NSData *)data;

#pragma mark - 新增：文件名解析功能（与Android一致）
+ (NSDictionary *)parseFirmwareFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END