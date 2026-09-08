#include "OSAL.h"
#include "random.h"
#include "log.h"
#include <time.h>
#include <stdlib.h>
#include "app_datetime.h"

uint32 set_random_seed(void)
{
	struct tm set_time;
	time_t time_dat;
	datetime_t time_seed;
	
	app_datetime(&time_seed);
	set_time.tm_sec = time_seed.seconds;
	set_time.tm_min = time_seed.minutes;
	set_time.tm_hour = time_seed.hour;
	set_time.tm_mday = time_seed.day;
	set_time.tm_mon = time_seed.month - 1;
	set_time.tm_year = time_seed.year - 1900;
	set_time.tm_isdst = -1;
//	 LOG("My Time is %d-%d-%d, %d:%d:%d\n", time_seed.year, time_seed.month, time_seed.day, time_seed.hour, time_seed.minutes, time_seed.seconds);
	//C 库函数 time_t mktime(struct tm *timeptr) 把 timeptr 所指向的结构转换为一个依据本地时区的 time_t 值，根据当前时区设置。
	time_dat = mktime(&set_time);      //mktime()用来将参数timeptr所指的tm结构数据转换成从公元1970年1月1日0时0分0 秒算起至今的UTC时间所经过的秒数。
	LOG("%d\n", time_dat);
	srand((unsigned int)time_dat);
	return (uint32)time_dat;
}


//int get_random(void)
//{
//	return rand();
//}

void random_array(uint8 *array, uint8 sn_count)
{
	uint8 index;
	uint8 first_source[2] = {1, 2};
	uint8 second_source[2] = {1, 2};
	uint8* targe = array;
	uint8 random_num = 0;
	uint8 random_num2 = 0;
	static uint8 random_seed_flag = 0;
    
    if (random_seed_flag == 0)
    {
        set_random_seed();	                //根据当前时间，设置随机种子
        random_seed_flag = 1;
    }	
    if (sn_count > 2)
    {
        sn_count = 2;
    }
        
	for (index = 0; index < 2; index++)
	{
		random_num = rand() % sn_count; // 生成随机数
		if (index < sn_count)
		{
			while (first_source[random_num] == 0xFF)
			{
                random_num++;
				if (random_num == sn_count)
				{
					random_num = 0;
				}	
			}
			targe[index] = first_source[random_num];
			first_source[random_num] = 0xFF;
		}
		else
		{	
//			random_num = (random_num + random_num2) % 4;
			while (second_source[random_num] == targe[index - 1])
			{
				random_num2 = rand() % sn_count;
				random_num = random_num2;//(random_num + random_num2) % 4;
			}
			targe[index] = second_source[random_num];
		}
		LOG("SN : %d ", targe[index]);
	}
	LOG("\n");
}

