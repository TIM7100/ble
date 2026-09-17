#ifndef __MYI2C_H_
#define __MYI2C_H_



#include "types.h"

#define I2C_MASTER_SDA P20
#define I2C_MASTER_CLK P23
#define IIC_SDA_H   AP_GPIO->swporta_dr |= BIT(I2C_MASTER_SDA)//hal_gpio_write(I2C_MASTER_SDA,HAL_HIGH_IDLE)
#define IIC_SDA_L   AP_GPIO->swporta_dr &= ~BIT(I2C_MASTER_SDA)//hal_gpio_write(I2C_MASTER_SDA,HAL_LOW_IDLE)

#define IIC_SCL_H   AP_GPIO->swporta_dr |= BIT(I2C_MASTER_CLK)//hal_gpio_write(I2C_MASTER_CLK,HAL_HIGH_IDLE)
#define IIC_SCL_L   AP_GPIO->swporta_dr &= ~BIT(I2C_MASTER_CLK)//hal_gpio_write(I2C_MASTER_CLK,HAL_LOW_IDLE)

#define IIC_SDA_IN   hal_gpio_read(I2C_MASTER_SDA)

#define SEND_DELAY_TIME  (1)
#define RECEIVE_DELAY_TIME  (5)
#define I2C_OK 0


void IIC_SDA_CHANGE_IN(void);
void IIC_SDA_CHANGE_OUT(void);
void Delay_us(uint32_t fu32_Delay);
void Delay_ms(u32 ms);

void IIC_Start(void);
u8 IIC_RecAck(void);
void IIC_SendAck(u8 ack);
u8 IIC_SendData_byte(u8 data);
u8 IIC_RecData_byte(u8 ack);
void IIC_Stop(void);

void i2c_init(void);
u8 IIC_SendData(u8 addr, u8 *data, u8 len);
u8 IIC_RecData(u8 addr, u8 cmd, u8 *data, u8 len);
#endif
