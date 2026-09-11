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
				
				<!-- 最新版本：点击对比云端APP版本，有更新则下载安装 -->
				<view class="uni-list-box" style="color:#007aff;" @click="checkForAppUpdate">{{$t('index.latest_version')}}</view>
				
			</view>
			
			
			
		</view>
		
		
	</view>
</template>

<script>
	// 直接读取 manifest.json 的 versionCode/versionName（uni-app 支持导入）
	import manifestJson from '../../manifest.json'
	export default {
		data() {
				return {
					title: 'Hello',
					version_number:'',
					isAndroid: false,
					
					
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
			},
			
			toast(msg) {
			  uni.showToast({title: msg, icon: 'none', duration: 2000});
			},
			
			// 对比云端APP版本并升级
			checkForAppUpdate() {
			  var that = this;
			  uni.showToast({
			    title: this.$t('index.check_new_version'),
			    icon: 'none',
			    duration: 99999
			  });
			  const db = uniCloud.database();
			  db.collection('APK').where({ name: 'HP9APK' }).get().then(res => {
			    uni.hideToast();
			    if (!res.result || !res.result.data || res.result.data.length === 0) {
			      that.toast(that.$t('index.app_no_version'));
			      return;
			    }
			    // 云端版本（可能为数字versionCode 或 字符串versionName）
			    const raw = res.result.data[0].version;
			    const cloudNum = Number(raw);
			    const cloudStr = String(raw == null ? '' : raw).trim();

			    // 本地版本：以 manifest.json 的 versionCode/versionName 为准
			    const localCode = (manifestJson && Number(manifestJson.versionCode)) || 0;   // = 2
			    const localName = String((manifestJson && manifestJson.versionName) || that.version_number || '').trim(); // = "1.0.1"
			    console.log('云端APP版本:', cloudNum, cloudStr, '本地code:', localCode, '本地name:', localName);
			    // 已最新：云端数字==本地versionCode，或 云端字符串==本地versionName
			    const isLatest = (cloudNum !== 0 && cloudNum === localCode)
			                  || (cloudStr !== '' && cloudStr === localName);
			    if (isLatest) {
			      that.toast(that.$t('index.app_already_latest'));
			      return;
			    }
			    const url = res.result.data[0].URL;
			    uni.showModal({
			      title: that.$t('index.app_update_title'),
			      content: that.$t('index.app_update_confirm'),
			      success: (modal) => {
			        if (modal.confirm) {
			          that.downloadAndInstallApk(url);
			        }
			      }
			    });
			  }).catch(err => {
			    uni.hideToast();
			    console.error('APK查询失败:', err);
			    that.toast(that.$t('index.download_failed'));
			  });
			},
			
			// 下载APK包（plus.downloader，index.vue已验证；下载后直接安装）
			downloadAndInstallApk(url) {
			  var that = this;
			  uni.showLoading({ title: (that.$t('index.app_downloading')), mask: true });
			  try {
			    const dtask = plus.downloader.createDownload(url, {}, function(d, status) {
			      if (status === 200) {
			        try {
			          // 与index.vue一致：d.filename 形如 _downloads/xxx
			          const apkPath = plus.io.convertLocalFileSystemURL(d.filename);
			          uni.hideLoading();
			          console.log('APK已就绪:', apkPath);
			          that.installApk(apkPath);
			        } catch (e) {
			          uni.hideLoading();
			          console.error('解析APK路径失败:', e);
			          that.toast('APK路径解析失败');
			        }
			      } else {
			        uni.hideLoading();
			        console.error('APK下载失败, status=', status);
			        that.toast(that.$t('index.download_failed') + '[' + status + ']');
			      }
			    });
			    // 尽力显示进度（不支持则忽略）
			    try {
			      dtask.addEventListener('downloadprogress', function(e) {
			        const total = Number(e && e.totalSize) || 0;
			        const cur = Number(e && e.downloadSize) || 0;
			        const pct = total > 0 ? Math.round(cur / total * 100) : 0;
			        uni.showLoading({ title: (that.$t('index.app_downloading')) + ' ' + pct + '%', mask: true });
			      });
			    } catch (e) {}
			    dtask.start();
			  } catch (e) {
			    uni.hideLoading();
			    console.error('创建下载任务失败:', e);
			    that.toast(that.$t('index.download_failed'));
			  }
			},
			
			// 请求权限并调用系统安装界面
			installApk(apkPath) {
			  var that = this;
			  // plus.runtime.install 会调起系统安装器；
			  // 系统会自行请求"安装未知应用"权限
			  plus.runtime.install(apkPath, { force: true }, function() {
			    console.log('APK安装成功');
			  }, function(e) {
			    console.error('安装失败:', e);
			    that.toast('安装失败：' + (e && e.message ? e.message : e.code));
			  });
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