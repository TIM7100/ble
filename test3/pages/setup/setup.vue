<template>
	<view class="content">
		
		<view class="connect2">
			<view class="text-area">
				<!-- <text class="title">{{title}}</text> -->
				
				<view class="uni-list-box" @click="">{{$t('index.language')}}<!-- 语言 --></view>
				
			</view>
		<view class="language">
		  <view class="locale-item" v-for="(item, index) in locales" :key="index" @click="onLocaleChange(item)">
				
				<text class="text">{{item.text}}</text>
				<text class="icon-check" v-if="item.code == applicationLocale"></text>
				
		  </view>
		</view>	
		</view>
		<view class="connect2">
			<view class="text-area">
				<!-- <text class="title">{{title}}</text> -->
				
				<view class="uni-list-box"><!-- 版本 -->{{$t('index.app_version')}} V{{version_number}}</view>
				
			</view>
			
			
			
		</view>
		
		
	</view>
</template>

<script>
	export default {
		data() {
			return {
				title: 'Hello',
				version_number:'',
				
				
				systemLocale: '',
				applicationLocale: ''
			}
		},
		onLoad() {
			// 获取当前app的版本
			var that = this;
			const systemInfo = uni.getSystemInfoSync();
			// 应用程序版本号
			// 条件编译，只在APP渲染
			// #ifdef APP
			this.version_number = systemInfo.appWgtVersion;
			// #endif
			console.log(this.version_number);
			
			
			
			
			
			this.systemLocale = systemInfo.language;
			this.applicationLocale = uni.getLocale();
			this.isAndroid = systemInfo.platform.toLowerCase() === 'android';
			uni.onLocaleChange((e) => {
			  this.applicationLocale = e.locale;
			})
			
			
		},
		computed:{
		  locales() {
		    return [ {
		        text: this.$t('locale.en'),
		        code: 'en'
		      },
		      {
		        text: this.$t('locale.zh-hans'),
		        code: 'zh-Hans'
		      },
      
		    ]
		  }
		},
		methods: {
			onLocaleChange(e) {
			  if (this.isAndroid) {
				  
			    uni.showModal({
			      content: this.$t('index.language-change-confirm'),
			      success: (res) => {
			        if (res.confirm) {
			          uni.setLocale(e.code);
			        }
			      }
			    })
			  } else {
				 
			    uni.setLocale(e.code);
			    this.$i18n.locale = e.code;
			  }
			}
		}
	}
</script>

<style>
	.content {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
	}
	.text-area {
		height: auto;
		width: 100%;
		display: flex;
		flex-wrap:wrap;
		justify-content: space-between;
	}
	.title {
		font-size: 36rpx;
		color: #000000;
	}
	.uni-list-box {
		margin: 0 20rpx;
		padding: 15rpx 0;
		font-size: 36rpx;
		/* border-bottom: 1px #bcbcbc solid; */
		height: auto;
	}
	.connect2
	{
		display: flex;
		/* grid-template-columns: 70% 70% 50% ; */ 
		align-items: center; /* 垂直居中*/
		flex-direction: column;
		flex-wrap: wrap;
		/* justify-content: space-between; */ /* 均匀排列每个元素每个元素之间的间隔相等 *//* 水平居中 */
		
		
		margin-top: 6%;
		height: auto; /* 设置容器高度适应屏幕 */
		width: 90%;
		
		/* height: 474px; */
		opacity: 0.9;
		border-radius: 6px;
		background: rgba(255, 255, 255, 0.5);
		box-shadow: 2px 10px 10px  rgba(0, 0, 0, 0.18);
		
		/* border-bottom: 1px #bcbcbc solid; */
	}
	
	
	
	
	.locale-item {
	  display: grid;
	  flex-direction: row;
	  justify-content: center;
	  align-items: center;
	  padding: 10px 0;
	 
	}
	
	.locale-item .text {
	  flex: 1;
	  
	  border-bottom: 1px #bcbcbc solid;
	}
	
	.icon-check {
	 /* margin-right: -200px; */
	  border: 2px solid #007aff;
	  border-left: 0;
	  border-top: 0;
	  height: 12px;
	  width: 6px;
	  transform-origin: center;
	  margin-top: -15%;
	  margin-left: 100%;
	  /* #ifndef APP-NVUE */
	  transition: all 0.3s;
	  /* #endif */
	  transform: rotate(45deg);
	}
	
	.language {
		display: 1;
		flex: 1 1 auto;
		/* flex-wrap: wrap; */
		justify-content: center;
		align-items: center;
		/* border-bottom: 1px #bcbcbc solid; */
	}

	
	page{
		height: 100%;
		background-image: linear-gradient(to bottom, #9bdeff 0%, #cdf0ff 40%, #ffffff 70%);
		/* background-color: #fefefe; */
	}
</style>