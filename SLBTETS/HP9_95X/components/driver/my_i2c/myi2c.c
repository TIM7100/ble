
#include "OSAL.h"

#include "gpio.h"
#include "clock.h"
#include "myi2c.h"

/*******软件IIC添加的代码*********/
/****************************************************************************
* 函数名         ：IIC_SDA_CHANGE_IN
* 函数功能       ：SDA引脚切换为输入模式
* 输入           ：无
* 输出           ：无
****************************************************************************/
void IIC_SDA_CHANGE_IN(void)
{
		hal_gpio_pin_init(I2C_MASTER_SDA,IE);   //IE--输入

}
/****************************************************************************
* 函数名         ：IIC_SDA_CHANGE_OUT
* 函数功能       ：SDA引脚切换为输出模式
* 输入           ：无
* 输出           ：无
****************************************************************************/
void IIC_SDA_CHANGE_OUT(void)
{
		hal_gpio_pin_init(I2C_MASTER_SDA,OEN);   //OEN--输出
}



void i2c_init(void)         //IIC初始化
{
    hal_gpio_pin_init(I2C_MASTER_SDA, OEN);     //SDA  P20      OEN--输出
    hal_gpio_pin_init(I2C_MASTER_CLK, OEN);     //SCL
    hal_gpio_pull_set(I2C_MASTER_SDA, STRONG_PULL_UP);
    hal_gpio_pull_set(I2C_MASTER_CLK, STRONG_PULL_UP);
}

/*********************************************************************************
* Function    : Delay_us
* Description : us delay. 
* Input       : delay period, measured as us  
* Output      : none  
* Author      :      
* 作用        ： 微秒延时（误差在+ - 3us左右）只适用于64MHz主频
**********************************************************************************/
void Delay_us(uint32_t fu32_Delay)
{
	int i;

    while (fu32_Delay--)
	{		
		for (i = 10; i > 0; i--)   // 20
		{
		}
	}
}

/****************************************************************************
* 函数名         ：Delay_ms
* 函数功能       ：毫秒延时
* 输入           ：ms
* 输出           ：无
****************************************************************************/
void Delay_ms(u32 ms)	//@64MHz
{
	while(ms--)
	{
		unsigned long i;

		__NOP();
		__NOP();
		__NOP();
		i = 6498;		//6498
		while (i)
		{
			i--;
		}
	}
			
}




/*******************************************************************************
* 函 数 名         : IIC_Start
* 函数功能		   		: IIC起始信号
* 输    入         :  无
* 输    出         : 无
*******************************************************************************/

void IIC_Start(void)
{
	/**注意：在起始信号和停止信号 SDA要 比SCL先改变**/
	IIC_SDA_H;//拉高数据线
	IIC_SCL_H;//拉高时钟线
	Delay_us(SEND_DELAY_TIME);//延时
	IIC_SDA_L;//拉低数据线
	Delay_us(SEND_DELAY_TIME - 1);//延时
	IIC_SCL_L;	
}


/*******************************************************************************
* 函 数 名         : IIC_RecAck
* 函数功能		   		: IIC接收1bit应答
* 输    入         : 无
* 输    出         : u8 从机发送过来的应答	0：应答	1：非应答
*******************************************************************************/
u8 IIC_RecAck(void)
{
	u8 ack = 0;

	
	IIC_SDA_L;
	IIC_SDA_CHANGE_IN();	//改变引脚为输入模式
	Delay_us(RECEIVE_DELAY_TIME);
	IIC_SCL_H;			//拉高时钟线，准备接收数据
	/**Delay_us**/
	Delay_us(RECEIVE_DELAY_TIME);
	if(IIC_SDA_IN)
	{
		ack |= 1;
	}
	
	IIC_SCL_L;//拉低时钟线，保证周期完整
	Delay_us(RECEIVE_DELAY_TIME / 2);
	IIC_SDA_CHANGE_OUT();	//改变引脚为输出模式
	Delay_us(RECEIVE_DELAY_TIME / 2);	//和以上Delay_us替换使用
	return ack;
}

/*******************************************************************************
* 函 数 名         : IIC_SendAck
* 函数功能		   : IIC发送1bit应答
* 输    入         : u8 ack
* 输    出         : 无
*******************************************************************************/
void IIC_SendAck(u8 ack)
{
//	IIC_SDA_L;
//	IIC_SDA_CHANGE_OUT();  //改变引脚为输出模式
//	Delay_us(SEND_DELAY_TIME);
	if (ack)
	{
		IIC_SDA_H;//逻辑1
	}
	else
	{
		IIC_SDA_L;//逻辑0
	}
	Delay_us(SEND_DELAY_TIME);
	IIC_SCL_H;//主机拉高时钟线，准备接收数据
	Delay_us(SEND_DELAY_TIME);
	
	IIC_SCL_L;	//拉低时钟线，保证周期完整
	Delay_us(SEND_DELAY_TIME);		
}



/*******************************************************************************
* 函 数 名         : IIC_SendData_byte
* 函数功能		   : IIC发送8bit数据，接收1bit应答
* 输    入         : u8 data	主机发送8bit数据
* 输    出         : u8 ack		接收从机应答		0：正常响应		1：非正常响应
*******************************************************************************/

u8 IIC_SendData_byte(u8 data)
{
	u8 ack=0;
	u8 i;
	for (i=0;i<8;i++)
	{
		if(data & (0x80 >> i))//高位先出
		{
			IIC_SDA_H;//逻辑1
		}
		else
		{
			IIC_SDA_L;//逻辑0
		}
		Delay_us(SEND_DELAY_TIME);
		
		IIC_SCL_H;
		Delay_us(SEND_DELAY_TIME);
		IIC_SCL_L;//拉低时钟线，准备发送数据
//		Delay_us(SEND_DELAY_TIME);
	}
	
	ack = IIC_RecAck();	//发送完8bit后，接收1bit应答
	
	return ack;
}




/*******************************************************************************
* 函 数 名         : IIC_RecData_byte
* 函数功能		   : IIC接收8bit数据，发送1bit应答
* 输    入         : u8 ack		发送给从机应答      0：正常响应		1：非正常响应
* 输    出         :u8 data	接收从机发送8bit数据		                    
*******************************************************************************/
u8 IIC_RecData_byte(u8 ack)
{
	u8 i;
	u8 data=0;
	
	IIC_SDA_CHANGE_IN();  //改变引脚为输入模式
	Delay_us(RECEIVE_DELAY_TIME);
	
	for(i=0;i<8;i++)
	{
		IIC_SCL_H;//拉高时钟线，准备接收数据
		data <<= 1;
		if(IIC_SDA_IN)//IO接收到高电平
		{
			data |= 1;
		}
		Delay_us(RECEIVE_DELAY_TIME / 3);
		IIC_SCL_L;//拉低时钟线，准备发送数据
		Delay_us(RECEIVE_DELAY_TIME);
	}
	IIC_SDA_CHANGE_OUT();  //改变引脚为输出模式
	Delay_us(RECEIVE_DELAY_TIME / 2);
	IIC_SendAck(ack);
	return data;
}




/*******************************************************************************
* 函 数 名         : IIC_Stop
* 函数功能		   : IIC停止信号
* 输    入         : 无
* 输    出         : 无
*******************************************************************************/
void IIC_Stop(void)
{
	/**注意：在起始信号和停止信号 SDA要 比SCL先改变**/
	IIC_SDA_L;//拉低数据线
	Delay_us(SEND_DELAY_TIME);
	IIC_SCL_H;//拉高时钟线
	Delay_us(SEND_DELAY_TIME / 2);
	IIC_SDA_H;//拉高数据线
	Delay_us(SEND_DELAY_TIME);
}




/****************************************************************************
* 函数名         ：IIC_SendData
* 函数功能       ：IIC发送数据包
* 输入           ：u8 addr    从机地址
                                     u8 *data       要发送的数据包（例 数组）
                                     u8 len         要发送的数据的个数（例 数组里有多少个元素（下标））
* 输出           ：u8  为0时，发送正常
****************************************************************************/
u8 IIC_SendData(u8 addr, u8 *data, u8 len)
{
    int i = 0;
    IIC_Start();            //起始信号

    if (IIC_SendData_byte(addr))        //发送从机地址,判断应答
    {
        return 1;
    }


    for (i = 0; i < len; i++)
    {
        if (IIC_SendData_byte(*(data++)))  //发送数据,判断应答
        {
            return 2;
        }

    }
    IIC_Stop();

    return 0;
}


/****************************************************************************
* 函数名         ：IIC_RecData
* 函数功能       ：IIC接收数据包
* 输入           ：u8 addr 从机8位地址
                                    u8 cmd      命令
                                    u8 *data        要存放接收的数据包（例 数组）
                                    u8 len          要存放的数据的个数（例 数组里有多少个元素（下标））
* 输出           ：u8                   为0时，接收正常
****************************************************************************/
u8 IIC_RecData(u8 addr, u8 cmd, u8 *data, u8 len)
{
    int i = 0;
    IIC_Start();            //起始信号

    while (IIC_SendData_byte(addr) != I2C_OK)       //发送从机地址,判断应答
    {
        IIC_Stop();
//      return 1;
        Delay_us(10);
        i++;
        if (i > 5)
        {
            return 1;
        }
        IIC_Start();            //起始信号
    }


    if (IIC_SendData_byte(cmd))     //发送命令
    {
        return 2;
    }

    IIC_Start();            //起始信号

    if (IIC_SendData_byte(addr | 1))        //发送从机地址，读数据
    {
        return 3;
    }

    for (i = 0; i < len - 1; i++)
    {
        *(data++) = IIC_RecData_byte(0);

    }
    *(data++) = IIC_RecData_byte(1);

    IIC_Stop();

    return 0;
}


