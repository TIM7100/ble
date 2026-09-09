<template>
	<!--   -->
	<view class="connect1" >
		<!-- 遮盖层 -->
		<view class="overlay" v-if="lockInterface"></view>
		
		<view v-if="connected === false" class="connect2">		<!-- 初始界面 -->
				<view class="bg-image" mode="aspectFill">
					<image src="../../static/ble2x.png" mode="aspectFill">
					
					</image>
				</view>
	
				<button type="primary" class="connectbutton" @click="queryDevices">
					{{$t('BLE.connect')}}<!-- 搜索蓝牙设备 -->
				</button>
			

			<view></view>
			
		</view>
		
		<view v-if="connected === true" class="connect2">		<!-- 连接蓝牙成功后界面 -->
				<view class="title">			
					<text>{{chip_name + " "}}{{$t('BLE.series')}}</text>
				</view>
				<view class="uni-BLE_name">			<!-- 显示连接设备的名字 -->
					<text>{{device_name}}</text>
				</view>
				<view class="textbox" mode="aspectFill">
					
					<view v-if="updata_version_last !== '20140101' " >
						
						<view class="text_title" :key="versionkey">{{$t('BLE.Local_version')}}{{":" + updata_version_before}}</view>
						<view class="text_title" :key="versionkey">{{$t('BLE.Cloud_version')}}{{":" + server_version}}</view>
	
					</view>
					<view v-else >
						
						<view class="text_title">{{$t('index.version_error')}}<!-- 版本出错，请重新更新 --></view>
					
					</view>
					
					<!-- 固件版本：本地 + 云端 -->
					<view class="text_title">{{$t('BLE.FW_Local_version')}}{{":" + (fw_ota_local_version || '0000000000')}}</view>
					<view class="text_title">{{$t('BLE.FW_Cloud_version')}}{{":" + (fw_ota_version || '--')}}</view>
				</view>
				
				<!-- 升级模式选择 -->
				<view v-if="!pg_flag && !rx_notify" class="mode-select">
					<button type="primary" class="mode-btn" @click="startUpgrade(false)">
						{{$t('index.hp9DataUpgrade')}}
					</button>
					<button type="primary" class="mode-btn" @click="startUpgrade(true)">
						{{$t('index.fwOTAUpgrade')}}
					</button>
				</view>
				
				<button type="warn" class="backbutton" @click="Disconnect">
					{{$t('BLE.disconnect')}}<!-- 断开蓝牙连接 -->
				</button>
			
			
			<view v-if ="pg_flag === true">		<!-- 升级烧录进度条 -->
					<text class="uni-update_tips">{{ fw_ota_mode ? $t('Upgrade.OTAUpgrading') : $t('Upgrade.Upgrading') }}</text>
				<view class="uni-Rx_toast" >
					
					<view class="Rx_progress"  >
						
						<text> {{$t('Upgrade.Progress')}}</text>
						<view class="progress-box">
							<progress :percent="pgList" style="height:10px; width:100%" show-info stroke-width="10" border-radius="1" />
						</view>
					</view>
					
				
				</view>
			</view>
			
			
			
			<view v-else-if ="rx_notify === true" >			<!-- 烧录状态回显 -->   <!-- 当芯片有进行烧录时状态回显里面关闭，只显示进度条 -->
				
					<view v-if="rx_notify_success === true">
						<view class="uni-Rx_toast" >
							<view class="Rx_toast_success" >
								<text> {{rx_toast}}</text>
							</view>
						</view>
					</view>
					<view v-else>
						<view class="uni-Rx_toast" >
							<view class="Rx_toast" >
								<text> {{rx_toast}}</text>
							</view>
						</view>
					</view>
			
			</view>
			
			
		</view>
		
		<view v-if="maskShow" class="uni-mask" @touchmove.stop.prevent="moveHandle" @click="maskclose">		<!-- 显示搜索到的蓝牙设备 -->
			
			<scroll-view class="uni-scroll_box" scroll-y @touchmove.stop.prevent="moveHandle" @click.stop="moveHandle">
				
				<view class="uni-title">
					{{ devices.length }}{{" "}}{{$t('index.finded')}}<!-- 已经发现{{ devices.length }}{{ showMaskType === 'device' ? '台设备' : '个服务' }}: -->
				</view>
				
				
				
				<view v-for="(item, index) in devices" :key="index">
					
					<view v-if="showMaskType === 'device'">
						<view v-if="item.name.indexOf('MX') >= 0">			<!-- 通过蓝牙设备广播的名字过滤 -->
							
							<view class="uni-list-box" @click="tapQuery(item)">
								<view class="uni-list_name">{{ item.name || item.localName }}</view>
								<view class="uni-list_item">{{$t('BLE.RSSI')}}:{{ item.RSSI }}dBm</view>
								<view class="uni-list_item">MAC:{{ item.deviceId }}</view>
							</view>
						
						</view>
					
					</view>
	
				</view>
				
			</scroll-view>
		</view>
			
	</view>
	
	
	
	
</template>

<script>
	export default {
		data() {
			return {
				// title: '系列',
				devices:[],
				
				
				lockInterface: false, // 控制遮盖层是否显示
				
				connected: false,//蓝牙连接状态
				
				maskShow: false,
				showMaskType: 'device',
				
				servicesData: [],		//服务数据缓存
				characteristicsData: [],		//特征数据缓存
				
				equipment: [],	//连接设备数据缓存
				
				// 当前连接的对应芯片升级仪的芯片名
				chip_name:"",
				//广播名
				device_name:'',
				// 当前连接的蓝牙设备ID  
				connectedDeviceId: null ,
				//当前连接的蓝牙设备的服务UUID
				connectedserviceId: null,
				//当前连接的蓝牙设备的特征UUID
				connectedcharacteristicId: [],
				// 固件OTA模式标志
			fw_ota_mode: false,
			// 固件OTA升级等待重连标志（设备重启进入OTA模式后重新连接）
			waiting_ota_reconnect: false,
			// OTA重连中标志（阻止Disconnect清空设备信息）
			ota_reconnecting: false,
			// OTA重连用的设备ID（断开前保存）
			ota_reconnect_device_id: '',
			// 固件OTA响应跟踪
			ota_rsp: null,        // 最近收到的OTA响应字节
			ota_rsp_ready: false, // OTA响应就绪标志
			ota_rsp_extra: null,  // OTA响应附带数据（如sector号）
			ota_ver_rsp: null,    // 固件OTA版本对比响应('4')：'Newest'/'Updata'/'NO_CMD'
			ota_get_ver_pending: false,  // 正在请求固件返回本地版本('6')，通知回调据此接收版本串
				
				chatMessage: '', // 用户输入的聊天消息 
				chatMessage_size: null,	//用户输入的聊天消息长度
				
				retryCount:0,//消息重发
				
				CharacteristicValueChangeCB: false,//notify监听启动标志位
				
				valueChangeData: {},//接收到的消息 //蓝牙
				valueErrData: [],		//接收返回为错误的信息
				
				
				
				data_lenth:128,		//每次发送正式数据包的长度
				MTU:(128 + 6),		//蓝牙MTU
			
				
				CNT_K:0,		//烧录时序列号的套数
				CNT_C:0,
				CNT_M:0,
				CNT_Y:0,
				
				Download_url: "",	//下载链接
				updata_version_before:"",	//更新之前的版本
				updata_version_last:"",	//更新之后的版本
				server_version:"",//服务器版本
				fw_ota_version:"",		//固件OTA云版本
				fw_ota_local_version:"0000000000",	//固件本地版本(读自固件)
				fw_ota_url:"",			//固件OTA下载链接
				versionkey:0,	//用于版本号刷新时的显示 
				
				BLEState: true,		
				
				
				
				interval:'',		//循环定时器
				interval_BLE:'',
				
				
				systemLocale: '',			//系统
				applicationLocale: '',
				
				/*实时时钟*/
				time:0,
				year:0,
				month:0,
				day:0,
				hour:0,
				minute:0,
				second:0,
				/******/
				
				/*更新状态回显*/
				rx_notify:false,
				rx_notify_flag:0,
				rx_notify_success:false,  //成功升级标志位
				rx_toast:"",		//烧录状态回显
				
				pgList: 0,			//进度条
				pg_flag: false,		//进度条显示flag
			}
		},
		
		onLoad() {
			var that = this;
			console.log("onload1\r\n");
			let systemInfo = uni.getSystemInfoSync();		
			this.systemLocale = systemInfo.language;
			this.applicationLocale = uni.getLocale();
			this.isAndroid = systemInfo.platform.toLowerCase() === 'android';
			uni.onLocaleChange((e) => {
			  this.applicationLocale = e.locale;
			});
			
			
			that.interval_BLE = setInterval(() => {
				if (that.connected === true)
				{
					uni.onBLEConnectionStateChange(function(res) {
						// 该方法回调中可以用于处理连接意外断开等异常情况
						
						if (res.connected === false)
						{
							// 如果正在等待OTA重连（设备收到0102后重启进入OTA模式）
							if (that.waiting_ota_reconnect) {
								console.log('设备进入OTA模式断开连接，准备重连...');
								// 保存deviceId，防止Disconnect清空equipment
								that.ota_reconnect_device_id = res.deviceId;
								that.waiting_ota_reconnect = false;
								that.ota_reconnecting = true; // 阻止Disconnect清空设备信息
								that.connected = false;
								// 等待设备重启完成
								setTimeout(() => {
									that.reconnectForOTA();
								}, 3000);
								return;
							}
							
							// OTA重连中不触发正常断开流程
							if (that.ota_reconnecting) return;
							
							that.BLEState = false;
						}
						  
					})
				}
				
				
				if (that.BLEState === false)
				{
					// that.BLEState = uni.getStorageSync('BLEConnectionState')
					console.log(that.BLEState);
					that.BLEState = true;
					this.lockInterface = false; // 关闭遮盖层
					that.Disconnect();
					// clearInterval(that.interval_BLE);
					
				}
				
				
				if (that.rx_notify === true)		//烧录状态回显 延时5s 清除显示
				{
					if (that.rx_notify_flag === 0)
					{
						that.rx_notify_flag = 1;
						setTimeout(function() {
							
							that.rx_notify = false;
							that.rx_notify_flag = 0;
							
							this.rx_notify_success = false;
						},5000)
					}
					
					
				}
				
			},160);
			
			
		},
		onShow() {
			// console.log("page");
			let that = this;
			// console.log(that.connected);
			
			// //打开定时器
			// that.interval_BLE = setInterval(() => {
			// 	if (that.connected === true)
			// 	{
			// 		uni.onBLEConnectionStateChange(function(res) {
			// 			// 该方法回调中可以用于处理连接意外断开等异常情况
			// 			// console.log(`device ${res.deviceId} state has changed, connected: ${res.connected}`);
						
			// 			uni.setStorageSync('BLEConnectionState',res.connected);
			// 			if (res.connected === false)
			// 			{
			// 				// that.$forceUpdate();
			// 				that.BLEState = false;
							
			// 			}
						  
			// 		})
			// 	}
				
				
			// 	if (that.BLEState === false)
			// 	{
			// 		that.BLEState = uni.getStorageSync('BLEConnectionState')
			// 		console.log(that.BLEState);
			// 		that.BLEState = true;
			// 		this.lockInterface = false; // 关闭遮盖层
			// 		that.Disconnect();
			// 		// clearInterval(that.interval_BLE);
					
			// 	}
				
				
			// 	if (that.rx_notify === true)
			// 	{
			// 		if (that.rx_notify_flag === 0)
			// 		{
			// 			that.rx_notify_flag = 1;
			// 			setTimeout(function() {
							
			// 				that.rx_notify = false;
			// 				that.rx_notify_flag = 0;
							
			// 				this.rx_notify_success = false;
			// 			},5000)
			// 		}
					
					
			// 	}
				
			// },260);
			
			
			
			
			
		},
 
		
 
		mounted() {
			var timer = setInterval(() => {
				this.getNowTime()
			},1000)
		},
		// 组件销毁时关闭定时器
		beforeDestroy() {
			clearInterval(timer)
	
		},
 
		
		
		methods: {
				// 选择升级模式并开始升级
				startUpgrade(isFirmware) {
					this.fw_ota_mode = isFirmware;
					this.where();
				},
				
				//查询云数据库
			where(){
					const db = uniCloud.database();
					var that = this;
					
					this.lockInterface = true; // 显示遮盖层
					
					uni.showToast({
						title:this.$t('index.check_new_version'),
						icon: 'none',
						duration:99999,
						
					})
					
					console.log(that.chip_name)
					
					// 固件OTA模式：查询 "IAP" 集合
						if (that.fw_ota_mode) {
								db.collection('IAP').where({
									name : new RegExp('^' + that.chip_name)		//获取数据库中name包含对应固件数据的数据包
								}).get().then( async(res) => {
									console.log(res);
									uni.hideToast();  // 关闭"正在检测"提示
									
									// 检查是否有数据
									if (!res.result.data || res.result.data.length === 0) {
										that.toast('未找到固件信息，请检查云数据库IAP集合');
										this.lockInterface = false;
										return;
									}
									
									that.fw_ota_version = res.result.data[0].version || '';
									that.fw_ota_url = res.result.data[0].URL || '';
									
									if (!that.fw_ota_url) {
										that.toast('固件下载链接为空');
										this.lockInterface = false;
										return;
									}
									
									// 先对比固件本地OTA版本与云端版本，决定是否需要下载/升级
									uni.showToast({
										title: '正在检查固件版本...',
										icon: 'none',
										duration: 99999,
									});
									const verRes = await that.compareOtaVersion(that.fw_ota_version);
									if (verRes === 'Newest') {
										uni.hideToast();
										that.toast('已是最新版本，无需升级');
										that.fw_ota_mode = false;
										that.lockInterface = false;
										return;
									}
									
									// 下载固件文件
									uni.showToast({
										title: '正在下载固件...',
										icon: 'none',
										duration: 99999,
									});
									
									await that.createDownload(that.fw_ota_url).then(async path_data => {
											getApp().globalData.path = path_data;
											
											uni.hideToast();
											
											// 触发设备进入固件OTA模式：
											// 方式：向OTA服务(5833ff01)的CMD特征(ff02)写入 0102
											//   0x01 = OTA_CMD_START_OTA，0x02 = SLB模式
											// 设备收到后会重启进入OTA Bootloader，蓝牙会断开。
											// 断开后由 onBLEConnectionStateChange 自动重连并进入固件升级流程。
											let deviceId = that.equipment[0].deviceId;
											
											// 把本次升级版本写入"待定槽"(命令'5'，写0x11042000)；
											// boot在OTA成功后、重启前才会提升为当前版本，因此OTA失败不会误改本地版本
											that.ota_get_ver_pending = false;   // 关掉版本读，避免'5'回的OK被当作本地版本
											let pendVer = String(that.fw_ota_version || '');
											if (pendVer.length > 10) pendVer = pendVer.substring(0, 10);
											while (pendVer.length < 10) pendVer += ' ';
											that.chatMessage = string2Hex('5' + pendVer);
											await that.writeBLECharacteristicValue(that.connectedcharacteristicId[0]);
											that.chatMessage = '';
											// 等'5'写完成、避免与后续OTA触发竞争
											await new Promise(r => setTimeout(r, 600));
											
											// 先发现OTA服务
											uni.getBLEDeviceServices({
												deviceId,
												success: svcRes => {
													const OTA_SVC = '5833ff01-9b8b-5191-6142-22a4536ef123';
													const otaSvc = svcRes.services.find(s =>
														s.uuid.toLowerCase() === OTA_SVC.toLowerCase()
													);
													if (!otaSvc) {
														that.toast('未发现OTA服务');
														that.lockInterface = false;
														return;
													}
													
													// 获取OTA服务的CMD特征值
													uni.getBLEDeviceCharacteristics({
														deviceId,
														serviceId: otaSvc.uuid,
														success: charRes => {
															const chars = charRes.characteristics;
															let cmdChar = chars.find(c =>
																c.uuid.toLowerCase().indexOf('ff02') >= 0
															);
															if (!cmdChar && chars.length > 0) cmdChar = chars[0];
															if (!cmdChar) {
																that.toast('未找到OTA CMD特征值');
																that.lockInterface = false;
																return;
															}
															
															// 写入 0102 触发OTA模式
															uni.writeBLECharacteristicValue({
																deviceId,
																serviceId: otaSvc.uuid,
																characteristicId: cmdChar.uuid,
																value: hex2ArrayBuffer('0102'),
																success: () => {
																	console.log('OTA触发命令(0102)发送成功，设备将重启进入OTA模式');
																	that.toast('设备进入OTA模式，正在重连...');
																	// 设置重连标志，断开后自动重连并执行固件升级
																	that.waiting_ota_reconnect = true;
																},
																fail: err => {
																	console.error('OTA触发命令发送失败:', err);
																	that.toast('触发OTA失败');
																	that.lockInterface = false;
																}
															});
														},
														fail: err => {
															console.error('获取OTA特征值失败:', err);
															that.toast('获取OTA特征值失败');
															that.lockInterface = false;
														}
													});
												},
												fail: err => {
													console.error('发现OTA服务失败:', err);
													that.toast('发现OTA服务失败');
													that.lockInterface = false;
												}
											});
									}).catch(err => {
										uni.hideToast();
										that.toast('下载固件失败');
										this.lockInterface = false;
									});
									
								}).catch(err => {
									console.error('IAP查询失败:', err);
									uni.hideToast();
									that.toast('查询固件信息失败，请检查云数据库IAP集合');
									that.fw_ota_mode = false;
									this.lockInterface = false;
								});
								return;
							}
					
					// 原有HP9数据模式：查询 "ble" 集合
					db.collection('ble').where({
						name : new RegExp('^' + that.chip_name)		//获取数据库中name为chip_name开头的数据包
					}).get().then( async(res) => {
						that.server_version = res.result.data[0].version;
						uni.getStorage({		//读取缓存
						key: that.chip_name,
						success: function(res){
							this.updata_version_before = res.data.version;		//获取旧版本号
							getApp().globalData.path = res.data.path;			//获取文件存储地址
						}
					});
					
					
					this.CNT_K = res.result.data[0].K;		//获取烧录的序列号套数
					this.CNT_C = res.result.data[0].C;
					this.CNT_M = res.result.data[0].M;
					this.CNT_Y = res.result.data[0].Y;
					
					// this.updata_version_before = getApp().globalData.updata_version;
					// console.log(this.updata_version_before);
					// console.log(res.result.data[0].version);
					if (that.updata_version_before !== res.result.data[0].version)//如果本地端版本与数据库端版本不一致，则需要更新本地端数据
					{
						uni.hideToast();
						
						uni.showToast({
							title:this.$t('index.update_new_version'),
							icon: 'none',
							duration:99999,
							
						})
						
				
						this.Download_url = res.result.data[0].URL;	//获取下载链接
						
							
						
	
						await that.createDownload(this.Download_url).then(path_data => {
							
							//更新显示版本号
							uni.setStorage({
								key: that.chip_name,
								data: {
									name: res.result.data[0].name,
									version: res.result.data[0].version,
									URL: res.result.data[0].URL,
									path: path_data,
								},
								success: function () {
									getApp().globalData.updata_version = res.result.data[0].version;
									console.log(getApp().globalData.updata_version);
									console.log('数据版本与下载链接存储成功');
								}
							});
							
							setTimeout(() => {
								uni.getStorage({
									key:that.chip_name,
									success: function (res) {
										console.log(res.data.version);
										// this.updata_version = res.data.version;
										that.updata_version_last = res.data.version;
										that.updata_version_before = res.data.version;
										getApp().globalData.path = res.data.path;
										++that.versionkey;
										++that.versionkey;
										//用下面的代码强制更显
										// this.$forceUpdate();
										that.TxUpdate();  //发送数据
									},
									fail: function() {
										console.log('数据版本获取失败，请重新下载更新');
									}
								});
								
								
							},200)
							
							
						}).catch(err => {
							getApp().globalData.updata_version = "20140101";
							
							that.toast(this.$t('index.download_failed'));//'下载数据包失败'
							
							
						}) //下载数据包
				
						
					}
					else 
					{
						uni.hideToast();
						// this.lockInterface = false; // 关闭遮盖层
						// toast("已是最新版本" + this.updata_version_before);
						that.TxUpdate(); //发送数据包
					}
					
					console.log(res.result.data[0].name); 
					console.log(res.result.data[0].version); 
					console.log(res.result.data[0].URL);
					
				})
				.catch(err => {
						console.error('ble查询失败:', err);
						uni.hideToast();
						that.toast('查询数据失败，请检查网络');
						this.lockInterface = false;
					})
			},
			
			moveHandle() {
				
			},
			/**
			 * 关闭遮罩
			 */
			maskclose(){
				this.maskShow = false;
				this.devices = [];
				this.stopBluetoothDevicesDiscovery();
			},
			
			openBluetoothAdapter(){
				uni.openBluetoothAdapter({
					success: (res) => {
						console.log('第一步，蓝牙初始化成功',res);
						//开始搜索附近蓝牙
						this.startBluetoothDevicesDiscovery();		
					},
					fail: (err) => {
						console.log('第一步，蓝牙初始化失败',err);
						uni.showToast({
							title:this.$t('BLE.not_started'),icon: 'none'  //未开启蓝牙
						})
						
						
					}
				})
			},
			
			
			//第二步 开始搜索附近的蓝牙设备
			startBluetoothDevicesDiscovery() {
				uni.startBluetoothDevicesDiscovery({
				allowDuplicatesKey: false,
			    success: (res) => {
			      console.log('开始搜索附近的蓝牙设备',res);
			      this.onBluetoothDeviceFound();
			    },
			    fail: (err) => {
			      console.error('蓝牙搜索失败',err);
				  
			    }
			  })
			},
			
			//第三步 监听发现附近的蓝牙设备
			onBluetoothDeviceFound() {
			  uni.onBluetoothDeviceFound(device => {

				this.getBluetoothDevices();
				
			  });
			},
			
			/**
			 * 获取在蓝牙模块生效期间所有已发现的蓝牙设备。包括已经和本机处于连接状态的设备。
			 */
			getBluetoothDevices() {
				let i = 0;
				// this.devices=[];
				uni.getBluetoothDevices({
					success: res => {
						
						this.newDeviceLoad = false;
						// this.devices=[];
						res.devices.forEach(res => {
							// console.log('获取蓝牙设备成功:' + res.errMsg);
							// console.log("发现的蓝牙设备",res);

							// console.log(JSON.stringify(res))
							if (res.name.indexOf('MX') >= 0)
							{
								console.log("发现的蓝牙设备",res);
								this.devices[i++] = res;					
							}
		
						})

						// console.log('获取蓝牙设备成功:' + res.errMsg);
						// console.log(JSON.stringify(res))
						
						// console.log(JSON.stringify(this.devices))
						
					},
					fail: e => {
						console.log('获取蓝牙设备错误，错误码：' + e.errCode);
						if (e.errCode !== 0) {
							this.initTypes(e.errCode);
						}
					}
				});
			},
			
			
			
			
			// //第四步 建立连接
			
			//第五步 停止搜索
			stopBluetoothDevicesDiscovery(){
			  uni.stopBluetoothDevicesDiscovery({
			    success: function(res) {
			      console.log('停止搜索成功',res);
			    },
			    fail: function(res) {
			      console.log('停止搜索失败',res);
			    }
			  });
			  
			},
			
			
			
			
			
			/**
			 * 断开蓝牙连接
			 */
			async Disconnect() {			
				var that = this;
				let text = '';
				this.stopBluetoothDevicesDiscovery();
				
				await delay(200);
				uni.closeBluetoothAdapter({
					success: res => {
						console.log('断开蓝牙模块成功');
						this.equipment = [];
						this.servicesData = [];
						this.characteristicsData = [];
						this.valueChangeData = {};
						this.maskShow = false;
						this.connected = false;
						this.chip_name = '';
						this.device_name = '';
						this.connectedDeviceId = null;
						this.connectedserviceId = null;
						this.connectedcharacteristicId = []; 
						this.chatMessage = [];
						this.chatMessage_size = 0;
						this.devices = [];

						
						that.valueErrData = {};
						that.valueChangeData.value = "";
						
						this.pg_flag = false;
						this.pgList = 0;
						
						this.rx_notify = false;
						this.rx_notify_success = false;
						
						this.lockInterface = false;		//关闭遮盖层
						
						uni.hideToast();
						
						that.toast(this.$t('BLE.Disconnect_Bluetooth_connection'));
						
						
						
					}
				});
			},
			
			
			/**
			 * 选择设备
			 */
			queryDevices() {
				// this.newDeviceLoad = true;
				this.showMaskType = 'device';
				this.maskShow = true;
				// this.createDownload();
				this.openBluetoothAdapter();
			},
			
			tapQuery(devices) {
				if (this.showMaskType === 'device') {
					// this.$set(this.disabled, 4, false);
					if (this.equipment.length > 0) {
						this.equipment[0] = devices;
					} else {
						this.equipment.push(devices);
					}
					// this.newDeviceLoad = false;
				}
				if (this.showMaskType === 'service') {
					// this.$set(this.disabled, 6, false);
					if (this.servicesData.length > 0) {
						this.servicesData[0] = devices;
					} else {
						this.servicesData.push(devices);
					}
				}
				if (this.showMaskType === 'characteristics') {
					// this.$set(this.disabled, 7, false);
					if (this.characteristicsData.length > 0) {
						this.characteristicsData[0] = devices;
					} else {
						this.characteristicsData.push(devices);
					}
				}
				this.maskShow = false;
				this.createBLEConnection();
			},
			
			/**
			 * 连接低功耗蓝牙
			 */
			createBLEConnection() {
				var that = this;
				let deviceId = this.equipment[0].deviceId;
				
				this.device_name = this.equipment[0].name;
				// this.connectedDeviceId = deviceId;
				this.connectedserviceId = this.equipment[0].advertisServiceUUIDs[0];
					
				this.chip_name = arrayBuffer2String(this.equipment[0].advertisData);
				console.log(this.chip_name);
	
				// console.log(this.connectedserviceId);
				// console.log(this.equipment[0].deviceId);
				
				uni.showToast({
					title: this.$t('BLE.connecting'),	//连接蓝牙...
					icon: 'loading',
					duration: 20000
				});
				
			
				
				this.lockInterface = true; // 显示遮盖层
					uni.createBLEConnection({
						// 这里的 deviceId 需要已经通过 createBLEConnection 与对应设备建立链接
						deviceId,
						success:async  res => {
							console.log(res);
							console.log('连接蓝牙成功:' + res.errMsg);
							// console.log(res.advertisData);
							
							that.connected = true;
							
							// 连接设备后断开搜索 并且不能搜索设备
							this.stopBluetoothDevicesDiscovery();
							uni.hideToast();
							
							uni.showToast({
								title: this.$t('BLE.connect_success'), //连接成功
								icon: 'success',
								duration: 2000
							});
							
											
	

							// this.connected = true;
							
							that.check_version_path();
							
							setTimeout(() => {  
							    console.log('createBLEConnection完成');  
							    if (this.connected === true) {  
									this.setBLEMTU(this.MTU);
									this.getBLEDeviceServices();  
							    }  
							}, 3000);  
							
							
							
						},
						fail: e => {
							console.log('连接低功耗蓝牙失败，错误码：' + e.code);
							
							that.connected = false;
							this.lockInterface = false; // 关闭遮盖层
							this.stopBluetoothDevicesDiscovery();
							uni.hideToast();
							if (e.code !== 0) {
								// console.log(e);
								this.initTypes(e.code);
								this.Disconnect();
							}
						}
						
					});
				
				
				
				
			},
			
			/**
			 * 获取所有服务
			 */
			getBLEDeviceServices() {
						let deviceId = this.equipment[0].deviceId;
						console.log('获取所有服务的 uuid:' + deviceId);
					
						uni.getBLEDeviceServices({
							// 这里的 deviceId 需要已经通过 createBLEConnection 与对应设备建立链接
							deviceId,
							success: res => {
								// console.log(res);
								console.log(JSON.stringify(res.services));
								console.log('获取设备服务成功:' + res.errMsg);
								
								// 统一使用设备广播的服务（HP9服务）
									this.connectedserviceId = this.equipment[0].advertisServiceUUIDs[0];
									console.log('使用HP9原始服务:', this.connectedserviceId);
									
									this.characteristicsData = [];
								if (res.services.length <= 0) {
									
									this.toast(this.$t('BLE.service_fail'));//'获取服务失败，请重试!'
									this.lockInterface = false;
									return;
								}
								this.maskShow = false;
								this.getBLEDeviceCharacteristics();
							},
						fail: e => {
							console.log('获取设备服务失败，错误码：' + e.errCode);
							this.lockInterface = false;
							if (e.errCode !== 0) {
								this.initTypes(e.errCode);
								this.Disconnect();
							}
						}
					});
				},
			
			/**
			 * 获取某个服务下的所有特征值
			 */
			getBLEDeviceCharacteristics() {
				// this.servicesData[0].uuid = this.equipment[0].advertisServiceUUIDs;
				// console.log(this.servicesData[0].uuid);
				let deviceId = this.equipment[0].deviceId;
				let serviceId = this.connectedserviceId;
				
				console.log(deviceId);
				console.log(serviceId);
				uni.getBLEDeviceCharacteristics({
					// 这里的 deviceId 需要已经通过 createBLEConnection 与对应设备建立链接
					deviceId,
					// 这里的 serviceId 需要在 getBLEDeviceServices 接口中获取
					serviceId,
					success: res => {
						console.log(JSON.stringify(res));
						console.log('获取特征值成功:' + res.errMsg);
						// this.$set(this.disabled, 7, true);
						// this.valueChangeData = {};
						this.showMaskType = 'characteristics';
						this.devices = res.characteristics[0];
						this.connectedcharacteristicId[0] = res.characteristics[0].uuid;
						this.connectedcharacteristicId[1] = res.characteristics[1].uuid;
						this.connectedcharacteristicId[2] = res.characteristics[2].uuid;
						this.characteristicsData = res.characteristics;
						console.log(this.devices);
						if (this.devices.length <= 0) {
							
							that.toast(this.$t('BLE.characteristic_fail')); //'获取特征值失败，请重试!'
							
							return;
						}
						
											
						
						
						setTimeout(() => {
							this.notifyBLECharacteristicValueChange();//获取notify
						},300)
						this.maskShow = false;
						
						// 特征值与notify就绪后读取固件版本(本地+云端)
						setTimeout(() => {
							this.getFwVersions();
						}, 800);
					},
					fail: e => {
						console.log('获取特征值失败，错误码：' + e.code);
						this.lockInterface = false; // 关闭遮盖层
						if (e.code !== 0) {
							this.initTypes(e.code);
							this.Disconnect();
						}
					}
				});
			},
			
			
			
			//检查版本号和固件存放地址
			check_version_path() {
				var that = this;
				uni.getStorage({
					key: that.chip_name,
					success: function (res) {
						console.log(res.data.version);
						console.log(res.data.path);
						// this.updata_version = res.data.version;
						that.updata_version_before = res.data.version;
						getApp().globalData.updata_version = res.data.version;
						that.updata_version_last = res.data.version;
						getApp().globalData.path = res.data.path;
					},
					fail: function() {
						console.log('数据获取失败，请重新下载更新');
					}
				});
				// uni.getStorage({
				// 	key:'path',
				// 	success: function (res) {
				// 		console.log(res.data.path);
				// 		getApp().globalData.path = res.data.path
				// 	},
				// 	fail: function() {
				// 		console.log('数据地址获取失败，请重新下载更新');
				// 	}
				// });
			},
			
			
			
			
			
			//发送数据
			writeBLECharacteristicValue(characteristicId) {
				var that = this;
				let deviceId = this.equipment[0].deviceId;
				let serviceId = this.connectedserviceId;
				// let characteristicId = this.connectedcharacteristicId[0];
				console.log(deviceId);
				console.log(serviceId);
				console.log(characteristicId);
				
				// let buffer = string2Hex(this.chatMessage);
				// let buffer = string2Hex(tx_data);
				let buffer = this.chatMessage;
				
				return new Promise(resolve =>{//文件读写是一个异步请求 用promise包起来方便使用时的async+await
					// 发送蓝牙数据
					uni.writeBLECharacteristicValue({  
					    deviceId,  
					    serviceId,  
					    characteristicId,  
					    value: hex2ArrayBuffer(buffer), // 如果蓝牙API需要ArrayBuffer，则需要进行转换  
					    success: (res) => {  
							
					      console.log('消息发送成功', res);  
					      // 可选：将发送的消息添加到聊天历史记录中  
					      // this.chatHistory.push(this.chatMessage);  
					      // 清空输入框  
					      this.chatMessage = '';  
						  resolve(this.chatMessage);
					    },  
					    fail: (err) => {  
							
							if(that.retryCount < 10)//重发10次
							{
								that.retryCount++;
								console.log('消息发送失败,正在重发', err);
								
								setTimeout(() => {
									that.writeBLECharacteristicValue(characteristicId).then(res => {
										that.retryCount = 0;
										this.chatMessage = '';
										resolve(this.chatMessage);
									});
									
									
								},500);
							}							
							else if (that.retryCount >= 10)
							{
								that.retryCount = 0;
								console.error('消息发送失败', err);  
							
								uni.showToast({ title: '发送失败', icon: 'none' ,duration: 5000}); 
								
								this.chatMessage = '';
								resolve(this.chatMessage);
							}
							
							
							
					     
					    }  
					});
				
				}); 
				
				
				
			},
			
			/**
			 * 读取低功耗蓝牙设备的特征值的二进制数据值。注意：必须设备的特征值支持 read 才可以成功调用
			 */
			readBLECharacteristicValue() {
				let deviceId = this.equipment[0].deviceId;
				let serviceId = this.connectedserviceId;
				let characteristicId = this.connectedcharacteristicId[1];
				console.log(deviceId);
				console.log(serviceId);
				console.log(characteristicId);
				uni.readBLECharacteristicValue({
					// 这里的 deviceId 需要已经通过 createBLEConnection 与对应设备建立链接
					deviceId,
					// 这里的 serviceId 需要在 getBLEDeviceServices 接口中获取
					serviceId,
					// 这里的 characteristicId 需要在 getBLEDeviceCharacteristics 接口中获取
					characteristicId,
					success: res => {
						console.log('读取设备数据值成功');
						console.log(JSON.stringify(res));
						this.notifyBLECharacteristicValueChange();
					},
					fail(e) {
						
						console.log('读取设备数据值失败，错误码：' + e.errCode);
						if (e.errCode !== 0) {
							this.initTypes(e.errCode);
							this.Disconnect();
						}
					}
				});
				
				// this.onBLECharacteristicValueChange();
			},
			/**
			 * 监听低功耗蓝牙设备的特征值变化事件。必须先启用 notifyBLECharacteristicValueChange 接口才能接收到设备推送的 notification。
			 */
			onBLECharacteristicValueChange() {
				let rx_buf = "";
				let RXdata;
				// 必须在这里的回调才能获取
				uni.onBLECharacteristicValueChange(async res => {   //characteristic
					// console.log('监听低功耗蓝牙设备的特征值变化事件成功');
					// console.log(JSON.stringify(res));
					
					// console.log(res);
					
					// ===== 固件OTA响应处理（二进制协议）=====
						// OTA响应格式：2字节 [status, cmd_response]
						// 0x81=START_OTA应答, 0x84=分区信息应答, 
						// 0x87=块(扇区)完成应答, 0x83=OTA完成
						if (this.fw_ota_mode) {
							try {
								let u8 = new Uint8Array(res.value);
								if (u8.length > 0) {
									// 响应码在最后一个字节（官方SDK: "0081" = [0x00, 0x81]）
									let rsp = u8[u8.length - 1];
									console.log('OTA响应: 0x' + rsp.toString(16), '长度:', u8.length, 
										'原始:', Array.from(u8).map(b => '0x'+b.toString(16)).join(' '));
									this.ota_rsp = rsp;
									this.ota_rsp_extra = (u8.length > 1) ? u8[0] : null; // status byte
									this.ota_rsp_ready = true;
								}
							} catch(e) {
								console.error('OTA响应解析异常:', e);
							}
						}
					
					this.valueChangeData.value = arrayBuffer2String(res.value);		//把订阅的回传数据从arrayBuffer转字符串
					
					console.log(this.valueChangeData.value);
					
					// 固件OTA版本对比响应('4')专用标志，避免读到其他流程遗留的旧值
					if (this.fw_ota_mode && (this.valueChangeData.value === 'Newest' ||
						this.valueChangeData.value === 'Updata' ||
						this.valueChangeData.value === 'NO_CMD')) {
						this.ota_ver_rsp = this.valueChangeData.value;
					}
					// 固件返回本地OTA版本('6')：取等到非状态串的版本字符串
					if (this.ota_get_ver_pending) {
						const vv = String(this.valueChangeData.value || '').trim();
						if (vv && vv !== 'Newest' && vv !== 'Updata' && vv !== 'NO_CMD') {
							this.fw_ota_local_version = vv;
							this.ota_get_ver_pending = false;
						}
					}
					
					this.valueErrData = new Uint16Array(res.value);					//如果有丢包，则使用该变量
					// console.log(this.valueErrData);
					
					
					if (this.valueChangeData.value.indexOf("Progress") != (-1) )		//进度条回显
					{	
						this.pg_flag = true;
						rx_buf = this.valueChangeData.value.slice(9);
						
						this.pgList = Number(rx_buf);
						
					}
					
					rx_buf = '';
					if (this.valueChangeData.value.indexOf("Code") != (-1) )			//芯片更新状态
					{
						this.rx_notify_success = false;
						this.pg_flag = false;
						this.pgList = 0;
						rx_buf = this.valueChangeData.value.slice(5);
						this.rx_notify = true;
						console.log(rx_buf);
						if (rx_buf === "0")
						{
							console.log("success_over\r\n")
							// this.toast("SUCCESS_OVER");
							this.rx_notify_success = true;	//成功升级标志位
							this.rx_toast = this.$t('notify.info_0');
						}
						else if(rx_buf === "1")
						{
							// this.toast("芯片更新失败1");
							
							this.rx_toast = this.$t('notify.info_1');
						}
						else if(rx_buf === "2")
						{
							// this.toast("芯片更新失败2");
							this.rx_toast = this.$t('notify.info_2');
						}
						else if(rx_buf === "3")
						{
							// this.toast("芯片更新失败3");
							this.rx_toast = this.$t('notify.info_3');
						}
						else if(rx_buf === "4")
						{
							// this.toast("芯片更新失败4");
							this.rx_toast = this.$t('notify.info_4');
						}
						else if(rx_buf === "6")
						{
							// this.toast("芯片更新失败6");
							this.rx_toast = this.$t('notify.info_6');
						}
						else if(rx_buf === "7")
						{
							// this.toast("芯片已经是最新版本");
							this.rx_notify_success = true;	//成功升级标志位
							this.rx_toast = this.$t('notify.info_7');
						}
						else if(rx_buf === "8")
						{
							// this.toast("芯片更新失败8");		//读后门错误
							this.rx_toast = this.$t('notify.info_8');
						}
						else if(rx_buf === "9")
						{
							// this.toast("芯片系列不符");
							this.rx_toast = this.$t('notify.info_9');
						}
					}
					
					/****************/
					// if (that.valueChangeData.value.indexOf('ERR') >= 0)		//如果有丢包
					// {
						
					// 	console.log(that.valueErrData);
					// 	//重新发送丢包
					// 	for (var i = 2; i < (that.valueErrData.length); i++)
					// 	{
					// 		RXdata = that.valueErrData[i];
					// 		console.log(RXdata);
					// 		await that.sendData(RXdata - 1 ,RXdata).then(res => {
					// 			if (i === (that.valueErrData.length - 1) )
					// 			{
					// 				that.sendDatastop(SectorCnt);  
					// 			}
					// 		});
					// 	}

					// 	uni.hideToast();
					// 	this.lockInterface = false; // 关闭遮盖层
						
					// 	// toast("已是最新版本" + this.updata_version_before);
					// 	that.toast(this.$t('BLE.new_version') + '\n' + this.updata_version_before); //"已是最新版本"

					// }
					// else {
					// 	uni.hideToast();
					// 	this.lockInterface = false; // 关闭遮盖层
						
					// 	// toast("已是最新版本" + this.updata_version_before);
					// 	that.toast(this.$t('BLE.new_version') + '\n' + this.updata_version_before); //"已是最新版本"
					// }
					/***/
					
				});
			},
			/**
			 * 订阅操作成功后需要设备主动更新特征值的 value，才会触发 uni.onBLECharacteristicValueChange 回调。
			 */
			notifyBLECharacteristicValueChange() {
				let deviceId = this.equipment[0].deviceId;
				let serviceId = this.connectedserviceId;
				let characteristicId = this.connectedcharacteristicId[1];
				let notify = this.characteristicsData[1].properties.notify;
				console.log(deviceId);
				console.log(serviceId);
				console.log(characteristicId);
				console.log(notify);
				uni.notifyBLECharacteristicValueChange({
					state: true, // 启用 notify 功能
					// 这里的 deviceId 需要已经通过 createBLEConnection 与对应设备建立链接
					deviceId,
					// 这里的 serviceId 需要在 getBLEDeviceServices 接口中获取
					serviceId,
					// 这里的 characteristicId 需要在 getBLEDeviceCharacteristics 接口中获取
					characteristicId,
					
					success:(res) => {
								console.log('notifyBLECharacteristicValueChange success:' + res.errMsg);
								console.log(JSON.stringify(res));
								
								
								this.lockInterface = false; // 关闭遮盖层
								
								// 不再自动检查版本，等待用户点击升级按钮
								
								if (this.CharacteristicValueChangeCB === false)
								{
									this.CharacteristicValueChangeCB = true;
									this.onBLECharacteristicValueChange();
								}
							
						},
						fail: (e) => {
							console.log('notifyBLECharacteristicValueChange failed:', e);
							this.lockInterface = false; // 关闭遮盖层
							this.toast('蓝牙订阅失败，请重试');
						}
					});
			},
			
			
			
			
			/*
			设置蓝牙MTU
			*/
			setBLEMTU(mtu) {
				let deviceId = this.equipment[0].deviceId;
				// let mtu = 512;
				
				uni.setBLEMTU({
					deviceId,
					mtu,
					success: res => {
						 
						console.log('修改MTU值成功:' + mtu);
						
					},
					fail: e => {
						console.log('修改MTU值失败，'  );
						if (e.errCode !== 0) {
							return;
						}
					}
				});
			},
			
			
			
			
			//发送读取到的数据包（起始包，读取包的数量）
			sendData(num_SectorCnt,SectorCnt) {
				let j = 0;
				
				let num = '';
				
				return new Promise(resolve =>{
					this.getbindata().then(async (res) => {
					// this.getJsonData().then(async (res) => {
						
						let str ='';
						
						for (j = num_SectorCnt; j < SectorCnt ; j++)
						{
							str = res.slice((j * (this.data_lenth)),((j * (this.data_lenth)) + (this.data_lenth)));		//地址偏移
							// console.log(str);
							num = (j + 1).toString(16);//转换成16进制字符串，前缀为0x
							num = num.padStart(4,'0');//确保结果是四位数字，不够则补0
							console.log(num);
							this.chatMessage = string2Hex('3') + (num) + ab2hex(str) ;//string2Hex(str);		//拼接 指令3 + 第几包数据 + 包数据
							// await delay(100);
							await this.writeBLECharacteristicValue(this.connectedcharacteristicId[2]);		//发送
							
							
							this.chatMessage = '';
						}
						
						// await this.sendDatastop(SectorCnt);
						resolve('write_over');
					});
				})

			},
			
			//发送数据停止信号（最后一个包）
			sendDatastop(SectorCnt) {
				let num = '';
				num = (SectorCnt + 1).toString(16);//转换成16进制字符串，前缀为0x
				num = num.padStart(4,'0');//确保结果是四位数字，不够则补0
				this.chatMessage = string2Hex('3') + (num);
				this.writeBLECharacteristicValue(this.connectedcharacteristicId[0]);
				this.chatMessage = '';
			},
			
			
			
			//获取固件版本(本地+云端)，用于主页固件版本栏显示
			async getFwVersions() {
				var that = this;
				// 1. 云端版本：查询 IAP 集合(与where里固件OTA分支一致，用chip_name开头匹配)
				try {
					const db = uniCloud.database();
					const res = await db.collection('IAP').where({
						name: new RegExp('^' + that.chip_name)
					}).get();
					if (res.result.data && res.result.data.length) {
						that.fw_ota_version = res.result.data[0].version || that.fw_ota_version;
					}
				} catch (e) {
					console.warn('固件云端版本查询失败:', e);
				}
				// 2. 本地版本：发命令'6'请求固件返回
				that.ota_get_ver_pending = true;
				that.chatMessage = string2Hex('6');
				that.writeBLECharacteristicValue(that.connectedcharacteristicId[0]);
				that.chatMessage = '';
				await new Promise(resolve => setTimeout(resolve, 600));
				// 超时后必须清掉标志，避免后续 '5'/'4' 的OK等通知被误当作本地版本
				that.ota_get_ver_pending = false;
			},
				
			//发送OTA固件版本对比命令('4')，返回 'Newest' 或 'Updata'
			compareOtaVersion(cloudVersion) {
				var that = this;
				let ver = String(cloudVersion || '');
				if (ver.length > 10) ver = ver.substring(0, 10);
				while (ver.length < 10) ver += ' ';   // 补足10字节，与固件OTA_VERSION_LEN一致
				return new Promise(resolve => {
					that.ota_ver_rsp = null;               // 清空独立标志，只信本次写命令后的新响应
					that.chatMessage = string2Hex('4' + ver);
					that.writeBLECharacteristicValue(that.connectedcharacteristicId[0]);
					that.chatMessage = '';
					// 轮询等待固件通知 Newest / Updata / NO_CMD
					let elapsed = 0;
					let tick = setInterval(() => {
						if (that.ota_ver_rsp !== null) {
							clearInterval(tick);
							console.log('OTA版本对比响应:', that.ota_ver_rsp);
							if (that.ota_ver_rsp.indexOf('Newest') >= 0) resolve('Newest');
							else resolve('Updata');   // Updata/NO_CMD/未知 → 走更新
							return;
						}
						elapsed += 100;
						if (elapsed >= 1500) {           // 超时兜底：按需更新
							clearInterval(tick);
							that.ota_ver_rsp = null;
							console.warn('OTA版本对比超时，按需更新');
							resolve('Updata');
						}
					}, 100);
				});
			},
				
			//获取到getJsonData读到的值并通过BLE发送，总发送流程
			async TxUpdate(){
					var that = this;
					try{
						let SectorCnt = 0;
						let Sec = '';
						let KCnt;
						let CCnt;
						let MCnt;
						let YCnt;
						
						console.log(that.time);
					
					//第一、发送第一个包
					this.chatMessage = string2Hex('1' + this.updata_version_before) + ab2hex(numberToArrayBuffer(that.year,2)) + ab2hex(numberToArrayBuffer(that.month,1)) + ab2hex(numberToArrayBuffer(that.day,1)) + ab2hex(numberToArrayBuffer(that.hour,1)) + ab2hex(numberToArrayBuffer(that.minute,1)) + ab2hex(numberToArrayBuffer(that.second,1)) ;	//先发送版本 + 以及手机当前时间 年月日时分秒
					console.log(this.chatMessage);
					this.writeBLECharacteristicValue(this.connectedcharacteristicId[0]);
					this.chatMessage = '';
					
				
					await delay(400);
					
					
					//如果不需要更新（已是最新版本）
					if (this.valueChangeData.value === 'Newest')
					{
						console.log(this.valueChangeData.value);
						this.lockInterface = false; // 关闭遮盖层
						
						that.toast(that.$t('BLE.new_version') + '\n' + this.updata_version_before); //"已是最新版本"
						
						return;
					}
					
					
					
					//第二、读取数据包的大小
					await this.gettxtsize().then(res => {
						this.chatMessage_size = res;
						console.log(this.chatMessage_size);
						SectorCnt = (this.chatMessage_size + (this.data_lenth - 1)) / (this.data_lenth);	//计算需要发送的次数
						SectorCnt = parseInt(SectorCnt);  //保留整数部分，
						
						
						//发送第二个数据包
						// setTimeout(() =>{
							KCnt = numberToArrayBuffer(this.CNT_K,1);
							CCnt = numberToArrayBuffer(this.CNT_C,1);
							MCnt = numberToArrayBuffer(this.CNT_M,1);
							YCnt = numberToArrayBuffer(this.CNT_Y,1);
							
							console.log(SectorCnt);
							Sec = SectorCnt.toString(16);//转换成16进制字符串，前缀为0x
							Sec = Sec.padStart(4,'0');//确保结果是两位数字，不够则补0
							console.log(Sec);
							console.log(KCnt);
							this.chatMessage = string2Hex('2') + Sec + ab2hex(KCnt) + ab2hex(CCnt) + ab2hex(MCnt) + ab2hex(YCnt);
							console.log(this.chatMessage);
							// this.chatMessage = string2Hex(this.chatMessage);
							this.writeBLECharacteristicValue(this.connectedcharacteristicId[0]);
							this.chatMessage = '';
							
						// },500);
						
					});

					
					await delay(2000);
					
					
					uni.showToast({
						title:this.$t('BLE.updating_version'),//"正在更新新版本"
						icon: 'none',
						duration:99999,
						
					})
					
					
					
					console.log(this.valueChangeData.value);
					//如果发送第二个数据包失败（一般不会失败）则退出程序，需重新连接蓝牙
					if (this.valueChangeData.value !== 'OK')
					{
						return;
					}
					
					//第三、发送有效数据包
					// setTimeout(async() => {
						let first = 0;
						let RXdata;
						var num = 0;
						
						
						this.valueChangeData.value = '';
						await this.sendData(first,SectorCnt).then(async res => {
							// this.sendDatastop(SectorCnt);
							// this.onBLECharacteristicValueChange();
							// Uint8Array(this.valueErrData);
							
 							console.log('succ');
							
							await that.sendDatastop(SectorCnt);		//发送完成，发送结束
							
							//进入循环定时器     //等待12s等待解密完成 主控回复
							that.interval = setInterval(async() => {
								num += 1;
								
								
								setTimeout(async() => {
									console.log(that.valueChangeData.value);
									if (that.valueChangeData.value !== '')
									{
										clearInterval(that.interval);	//关闭循环定时器
										if (that.valueChangeData.value.indexOf('ERR') >= 0)		//如果有丢包
										{
											// console.log(that.valueChangeData.value.length);
											
											// console.log(that.valueChangeData.value);
											
											// console.log(that.valueErrData.length );
											console.log(that.valueErrData);
											
											//重新发送丢包
											for (var i = 2; i < (that.valueErrData.length); i++)
											{
												RXdata = that.valueErrData[i];
												console.log(RXdata);
												//只有一轮重新发送丢包，正常情况下不会丢太多包，重新发送一次都能成功
												await that.sendData(RXdata - 1 ,RXdata).then(res => {
													if (i === (that.valueErrData.length - 1) )
													{
														that.sendDatastop(SectorCnt);  
														
														uni.hideToast();
														this.lockInterface = false; // 关闭遮盖层
														that.toast(this.$t('BLE.new_version') + '\n' + this.updata_version_before); //"已是最新版本"
													}
												});
											
											}
											
											
											// uni.hideToast();
											// this.lockInterface = false; // 关闭遮盖层
											
											// // toast("已是最新版本" + this.updata_version_before);
											// that.toast(this.$t('BLE.new_version') + '\n' + this.updata_version_before); //"已是最新版本"
											
											
										}
										else {
											uni.hideToast();
											this.lockInterface = false; // 关闭遮盖层
											
											// toast("已是最新版本" + this.updata_version_before);
											that.toast(this.$t('BLE.new_version') + '\n' + this.updata_version_before); //"已是最新版本"
										
										}
										
									}
									else 
									{
										
										await that.sendDatastop(SectorCnt);		//发送完成，发送结束
									}
								},600);
								
								// this.onBLECharacteristicValueChange();
								if (num === 10)
								{
									clearInterval(that.interval);	//关闭循环定时器
									
									that.toast(this.$t('BLE.lost_data'));//"数据丢失，请重新发送！"
									
								}
								
							},10000);
								
					
						});
	
						
					// },900);
				} catch(err){
					
				}
				
				
				
				
				
			},				
			//读取json文件
			getJsonData(){ //path:路径
				// let path = "/storage/emulated/0/Android/data/io.dcloud.HBuilder/apps/HBuilder/doc/XXY.txt";//"/storage/emulated/0/android/data/io.dcloud.HBuilder/apps/HBuilder/www/data/XXY.txt";
				
				
					
				return new Promise(resolve =>{//文件读写是一个异步请求 用promise包起来方便使用时的async+await
					plus.io.requestFileSystem(plus.io.PUBLIC_DOWNLOADS,fs =>{ //请求文件系统
						fs.root.getFile(
							getApp().globalData.path, { //请求地址文件//'/storage/emulated/0/XXT.txt'
								create: true,//当文件不存在时创建
							},
							(fileEntry) => {
								 fileEntry.file(
									function (file) {
										console.log("读取文件");
										let fileReader = new plus.io.FileReader();//new一个可以用来读取文件的对象fileReader
										fileReader.readAsText(file,"utf-8");//读取文件的格式
										// fileReader.onloadstart((data) => {
										// 	console.log("开始读取",data);
										// });
										
										// fileReader.readAsDataURL()
										fileReader.onload = data => {
											console.log("读取成功:",data);
											// txtData = data.target.result;
											// console.log(txtData);
											// this.chatMessage = txtData;
											resolve(data.target.result);		//返回读取数据
										};
										fileReader.onloadend = data => {
											console.log("读取成功2:",data.target.result);
											
											
											// resolve(data.target.result);
											
										};
										fileReader.onerror = e => {
											console.log("读取失败：",e);
										};
									
									},
									(error) => {
										console.log("新建获取文件失败",error);
										return;
									}
								);
							},
							(e) => {
								console.log("请求文件系统失败",e.message);
								return;
							}
						);					
					})
				});
				
				
				
				
			},
			
			//得到文件的大小
			gettxtsize() {
				// let filepath = "/storage/emulated/0/Android/data/io.dcloud.HBuilder/apps/HBuilder/doc/XXY.txt";//"/storage/emulated/0/android/data/io.dcloud.HBuilder/apps/HBuilder/www/data/XXY.txt";
				console.log(getApp().globalData.path);
				return new Promise(resolve =>{//文件读写是一个异步请求 用promise包起来方便使用时的async+await
					plus.io.getFileInfo({
						filePath: getApp().globalData.path,
						digestAlgorithm:"md5",
						success: function(res) {
							console.log(res);
							resolve(res.size);		//返回文件的大小，用于计算需要发送多少个包
						},
						fail: function(e) {
							
						}
						
					});
				});
			},
			
			//读取bin文件的数据并转化
			getbindata() {
				
				return new Promise(resolve =>{//文件读写是一个异步请求 用promise包起来方便使用时的async+await
					plus.io.resolveLocalFileSystemURL(getApp().globalData.path, function(entry) {  
					        entry.file(function(file) {  
					            var reader = new plus.io.FileReader();  
								reader.readAsDataURL(file); 
								
								//文件读取完成会执行
					            reader.onloadend = function(e) {  
					                var u8arr = (function(path, name) {  
					                    var arr = path.split(','),  
					                        mime = arr[0].match(/:(.*?);/)[1],  
					                        bstr = atob(arr[1]),  
					                        n = bstr.length,  
					                        u8arr = new Uint8Array(n);  
					                    while (n--) {  
					                        u8arr[n] = bstr.charCodeAt(n);  
					                    }  
										// 这里就是ArrayBuffer数据
										// console.log((u8arr));
										// console.log(ab2hex(u8arr));
										
					                    //return u8arr;  
										resolve((u8arr));
					                })(e.target.result, entry.name);  
					
					            };  
					            
								
					        });  
						    },  
						    function(e) {  
						        console.log("Resolve file URL failed: " + e.message);  
						    }
							
						);  
					})
				},
					
				// 设备重启进入OTA模式后的重连流程
				// OTA bootloader 可能使用不同的 MAC 地址（末字节+1），需要尝试重连
				reconnectForOTA() {
					var that = this;
					// 使用断开前保存的deviceId，不依赖equipment（可能已被清空）
					let originalDeviceId = this.ota_reconnect_device_id;
					console.log('reconnectForOTA, deviceId:', originalDeviceId);
					
					if (!originalDeviceId) {
						that.toast('OTA重连失败：设备ID丢失');
						that.ota_reconnecting = false;
						that.lockInterface = false;
						return;
					}
					
					uni.showToast({
						title: '正在重连OTA设备...',
						icon: 'loading',
						duration: 99999
					});
					
					// 尝试连接到设备（先试OTA MAC（末字节+1），失败再试原始MAC）（bootloader进OTA后MAC+1）
						function tryConnect(dId) {
							uni.createBLEConnection({
								deviceId: dId,
								success: res => {
									console.log('OTA模式重连成功, deviceId:', dId);
									that.connected = true;
									// 确保equipment中有设备信息
									if (!that.equipment || that.equipment.length === 0) {
										that.equipment = [{ deviceId: dId, name: '' }];
									} else {
										that.equipment[0].deviceId = dId;
									}
									
									// 设置MTU
									that.setBLEMTU(that.MTU);
									
									setTimeout(() => {
										// 发现OTA服务并获取特征值
										that.findFirmwareOTAService().then(() => {
											uni.hideToast();
											console.log('OTA服务就绪，开始固件升级');
											// 开始固件OTA升级
											that.TxUpdate_Firmware();
										}).catch(err => {
											uni.hideToast();
											console.error('OTA服务发现失败:', err);
											that.toast('OTA服务发现失败: ' + (err.errMsg || err));
											that.ota_reconnecting = false;
											that.lockInterface = false;
										});
									}, 1500);
								},
								fail: e => {
									console.error('连接失败 deviceId=' + dId + ':', e);
									// 当前尝试的是OTA MAC且失败 → 回退试原始MAC
									let originalId = that.ota_reconnect_device_id;
									if (dId !== originalId) {
										console.log('OTA MAC失败，尝试原始MAC:', originalId);
										tryConnect(originalId);
									} else {
										uni.hideToast();
										that.toast('OTA重连失败，请靠近设备重试');
										that.ota_reconnecting = false;
										that.lockInterface = false;
									}
								}
							});
						}
						// 进OTA后bootloader的MAC=原MAC+1，优先尝试OTA MAC，省去30s超时
						tryConnect(that.getOTAMacAddress(that.ota_reconnect_device_id));
				},
				
				// 计算OTA bootloader的MAC地址（末字节+1）
				getOTAMacAddress(mac) {
					// MAC格式: AA:BB:CC:DD:EE:FF 或 AABBCCDDEEFF
					try {
						let clean = mac.replace(/:/g, '').replace(/-/g, '');
						if (clean.length === 12) {
							let lastByte = parseInt(clean.substr(10, 2), 16);
							let newLast = ((lastByte + 1) & 0xFF).toString(16).toUpperCase();
							if (newLast.length < 2) newLast = '0' + newLast;
							let otaMac = clean.substr(0, 10) + newLast;
							// 格式化为 AA:BB:CC:DD:EE:FF
							return otaMac.match(/.{2}/g).join(':');
						}
					} catch(e) {
						console.error('计算OTA MAC失败:', e);
					}
					return mac; // 失败则返回原地址
				},
				
				// 查找并切换到固件OTA服务（正确UUID：5833ff01-9b8b-5191-6142-22a4536ef123）
				findFirmwareOTAService() {
					var that = this;
					return new Promise((resolve, reject) => {
						let deviceId = this.equipment[0].deviceId;
						const FW_OTA_SVC_UUID = '5833ff01-9b8b-5191-6142-22a4536ef123';
						
						// 第一步：重新发现所有服务，找到固件OTA服务UUID
						uni.getBLEDeviceServices({
							deviceId,
							success: res => {
								console.log('发现服务:', JSON.stringify(res.services));
								
								// 查找固件OTA服务（兼容大小写）
								const fwSvc = res.services.find(s => 
									s.uuid.toLowerCase() === FW_OTA_SVC_UUID.toLowerCase()
								);
								
								if (!fwSvc) {
									console.error('未找到固件OTA服务');
									reject('未找到固件OTA服务');
									return;
								}
								
								console.log('找到固件OTA服务:', fwSvc.uuid);
								that.connectedserviceId = fwSvc.uuid;
								
								// 第二步：获取固件OTA服务的特征值
								uni.getBLEDeviceCharacteristics({
									deviceId,
									serviceId: fwSvc.uuid,
									success: res2 => {
										console.log('固件OTA特征值:', JSON.stringify(res2));
										
										// OTA服务有3个特征值：CMD(write)、Notify(notify)、Data(write_no_rsp)
										// UUID分别以 ff02、ff03、ff04 结尾
										const chars = res2.characteristics;
										let cmdChar = null, notifyChar = null, dataChar = null;
										
										for (let i = 0; i < chars.length; i++) {
											const uuid = chars[i].uuid.toLowerCase();
											if (uuid.indexOf('ff02') >= 0) {
												cmdChar = chars[i];
											} else if (uuid.indexOf('ff03') >= 0) {
												notifyChar = chars[i];
											} else if (uuid.indexOf('ff04') >= 0) {
												dataChar = chars[i];
											}
										}
										
										// 若未按UUID区分，按顺序兜底
										if (!cmdChar && chars.length > 0) cmdChar = chars[0];
										if (!notifyChar && chars.length > 1) notifyChar = chars[1];
										if (!dataChar && chars.length > 2) dataChar = chars[2];
										
										if (!cmdChar || !notifyChar || !dataChar) {
											reject('OTA特征值不足，无法进行固件升级');
											return;
										}
										
										// 保存特征值UUID
										that.connectedcharacteristicId[0] = cmdChar.uuid;   // CMD  (ff02)
										that.connectedcharacteristicId[1] = notifyChar.uuid; // Notify (ff03)
										that.connectedcharacteristicId[2] = dataChar.uuid;   // Data  (ff04)
										// 按 CMD/Notify/Data 顺序重排，确保索引与角色一致
										that.characteristicsData = [cmdChar, notifyChar, dataChar];
										
										console.log('OTA CMD:', that.connectedcharacteristicId[0]);
										console.log('OTA Notify:', that.connectedcharacteristicId[1]);
										console.log('OTA Data:', that.connectedcharacteristicId[2]);
										
										// 重新订阅通知（强制重新注册全局监听器）
										setTimeout(() => {
											// 重置标志，强制重新注册 onBLECharacteristicValueChange
											that.CharacteristicValueChangeCB = false;
											that.notifyBLECharacteristicValueChange();
											// 等订阅完成后再resolve
											setTimeout(() => resolve(), 500);
										}, 300);
									},
									fail: e => {
										console.error('获取固件OTA特征值失败:', e);
										reject(e);
									}
								});
							},
							fail: e => {
								console.error('发现服务失败:', e);
								reject(e);
							}
						});
					});
				},
					
					// OTA专用写入方法：直接传入hex字符串，避免chatMessage被清空导致重试失败
				writeHexData(characteristicId, hexStr) {
					var that = this;
					let deviceId = this.equipment[0].deviceId;
					let serviceId = this.connectedserviceId;
					let buffer = hexStr; // 捕获数据，重试时复用
					
					return new Promise((resolve, reject) => {
						function doSend(retry) {
							uni.writeBLECharacteristicValue({
								deviceId,
								serviceId,
								characteristicId,
								value: hex2ArrayBuffer(buffer),
								success: res => {
									resolve(res);
								},
								fail: err => {
									if (retry < 10) {
										console.log('OTA写入失败，重试:', retry + 1, err);
										setTimeout(() => doSend(retry + 1), 200);
									} else {
										console.error('OTA写入最终失败:', err);
										reject(err);
									}
								}
							});
						}
						doSend(0);
					});
				},
				
				// 解析 Intel HEX (hex16) 格式文件
					// 返回分区数组：[{address: "11000000", binData: Uint8Array, size: N, addrInt: 0x11000000}]
					parseHex16File(u8arr) {
						// 将 Uint8Array 转为文本字符串
						let text = '';
						for (let i = 0; i < u8arr.length; i++) {
							text += String.fromCharCode(u8arr[i]);
						}
						
						let lines = text.split(/\r?\n/);
						let partitions = [];
						let currentBase = 0;      // 当前段基地址(数值)
						let partAddrInt = 0;     // 分区起始地址(数值)
						let partAddrHex = '';
						let currentData = '';
						let flag = 0;
						
						for (let li = 0; li < lines.length; li++) {
							let line = lines[li].trim();
							if (line.length < 9 || line.charAt(0) !== ':') continue;
							
							let size = parseInt(line.substring(1, 3), 16);
							let recordType = line.substring(7, 9);
							
							if (recordType === '04') {
								// 扩展线性地址 (upper16<<16)
								if (currentData.length > 0) {
									partitions.push({ address: partAddrHex, hexData: currentData });
								}
								currentBase = parseInt(line.substring(9, 13), 16) << 16;
								flag = 0; currentData = '';
								continue;
							}
							if (recordType === '02') {
								// 扩展段地址 (segment<<4)
								if (currentData.length > 0) {
									partitions.push({ address: partAddrHex, hexData: currentData });
								}
								currentBase = parseInt(line.substring(9, 11), 16) << 4;
								flag = 0; currentData = '';
								continue;
							}
							if (recordType === '05' || recordType === '01') {
								// 结束记录
								if (currentData.length > 0) {
									partitions.push({ address: partAddrHex, hexData: currentData });
								}
								break;
							}
							if (recordType !== '00') continue; // 跳过非数据记录(03等)
							
							// 数据记录：记录地址 = 段基址 + 偏移
							let recAddr = (currentBase + parseInt(line.substring(3, 7), 16)) >>> 0;
							if (flag === 0) {
								flag = 1;
								partAddrInt = recAddr;
								partAddrHex = ('00000000' + recAddr.toString(16).toUpperCase()).slice(-8);
							}
							currentData += line.substring(9, 9 + size * 2);
						}
						
						// 将 hex 数据字符串转为 Uint8Array
						for (let i = 0; i < partitions.length; i++) {
							let part = partitions[i];
							let hexStr = part.hexData;
							let binData = new Uint8Array(hexStr.length / 2);
							for (let j = 0; j < hexStr.length; j += 2) {
								binData[j / 2] = parseInt(hexStr.substring(j, j + 2), 16);
							}
							part.binData = binData;
							part.size = binData.length;
							part.addrInt = parseInt(part.address, 16);
							delete part.hexData; // 释放内存
						}
						
						console.log('解析到分区数:', partitions.length);
						for (let i = 0; i < partitions.length; i++) {
							console.log('分区' + i + ': address=0x' + partitions[i].address + 
								', size=' + partitions[i].size + ', addrInt=0x' + partitions[i].addrInt.toString(16));
						}
						
						return partitions;
					},
					
					// CRC16 (与设备 crc16.c 的 crc16_byte 完全一致, 多项式0xA001)
					crc16Update(crc, byte) {
						const tbl = [0x0000,0xCC01,0xD801,0x1400,0xF001,0x3C00,0x2800,0xE401,
							0xA001,0x6C00,0x7800,0xB401,0x5000,0x9C01,0x8801,0x4400];
						let temp = tbl[crc & 0xF];
						crc = (crc >> 4) & 0x0FFF;
						crc = crc ^ temp ^ tbl[byte & 0xF];
						temp = tbl[crc & 0xF];
						crc = (crc >> 4) & 0x0FFF;
						crc = crc ^ temp ^ tbl[(byte >> 4) & 0xF];
						return crc;
					},
					// 计算分区数据的CRC16
					calcCRC16(data) {
						let crc = 0;
						for (let i = 0; i < data.length; i++) {
							crc = this.crc16Update(crc, data[i]);
						}
						return crc;
					},
					
					// 将 hex16 解析出的分区按 ≤16KB 拆成OTA分区块，发送**所有**分区(含SRAM装入段)
					// 设备 buffer OTA_PBUF_SIZE=16K+16。
					// Single Bank：
					//  - XIP 区段(地址0x11000000~0x1107ffff)：运行于flash，flash_addr=run_addr=地址
					//  - SRAM 区段(地址0x1FFFxxxx)：bootloader从 flash_addr+bank_addr 装载到 SRAM，
					//    run_addr=SRAM地址，flash_addr=相对 bank_base 的累加存储偏移
					// bank_base = OTAF_APP_BANK_0_ADDR(CFG_FLASH=512,USE_FCT=0,SINGLE_BANK)=0x11011000
					splitPartitions(partitions) {
						const CHUNK = 16 * 1024;       // 16KB
						const FLASH_MIN = 0x11000000;
						const FLASH_MAX = 0x1107ffff;   // CFG_FLASH=512
						const SRAM_MIN  = 0x1FFF0000;    // SRAM0
						const BANK_ADDR = 0x11011000;    // OTAF_APP_BANK_0_ADDR
						let chunks = [];
						let sramFlashOffset = 0;        // SRAM分区的flash存储偏移(相对bank)
						
						for (let p of partitions) {
							let base = p.addrInt;
							let isFlash = base >= FLASH_MIN && base <= FLASH_MAX;
							let isSram  = base >= SRAM_MIN;
							
							for (let offset = 0; offset < p.size; offset += CHUNK) {
								let end = Math.min(offset + CHUNK, p.size);
								let sub = p.binData.slice(offset, end);
								let crc = this.calcCRC16(sub);
								
								if (isFlash) {
									// XIP：flash=run=绝对地址
									let fa = (base + offset) >>> 0;
									if (fa + sub.length - 1 > FLASH_MAX) {
										console.warn('分区超出flash末尾，跳过: 0x' + fa.toString(16));
										continue;
									}
									chunks.push({ flash_addr: fa, run_addr: fa, size: sub.length, data: sub, crc: crc });
								} else if (isSram) {
									// SRAM装入：run=SRAM地址, flash=存储偏移(设备写到 flash_addr+bank_addr)
									let ra = (base + offset) >>> 0;
									let fa = sramFlashOffset;
									sramFlashOffset = (sramFlashOffset + sub.length + 8) >>> 0;
									chunks.push({ flash_addr: fa, run_addr: ra, size: sub.length, data: sub, crc: crc });
								} else {
									console.warn('跳过未知分区: 0x' + p.address);
								}
							}
						}
						// 打印各分区块
						for (let c of chunks) {
							console.log('OTA子分区: flash=0x' + c.flash_addr.toString(16) +
								' run=0x' + c.run_addr.toString(16) +
								' size=' + c.size + ' crc=0x' + c.crc.toString(16));
						}
						return chunks;
					},
				
				// 将4字节整数转为小端Uint8Array
				intToLE(num) {
					return new Uint8Array([
						num & 0xFF,
						(num >> 8) & 0xFF,
						(num >> 16) & 0xFF,
						(num >> 24) & 0xFF
					]);
				},
				
				// 等待OTA响应（带超时）
				waitOTA(expectedRsp, timeout) {
					var that = this;
					timeout = timeout || 5000;
					return new Promise((resolve, reject) => {
						let elapsed = 0;
						let tick = setInterval(() => {
							if (that.ota_rsp_ready && that.ota_rsp === expectedRsp) {
								clearInterval(tick);
								that.ota_rsp_ready = false;
								resolve(that.ota_rsp_extra);
								return;
							}
							elapsed += 50;
							if (elapsed >= timeout) {
								clearInterval(tick);
								reject('OTA响应超时(期望0x' + expectedRsp.toString(16) + 
								       ',实际0x' + (that.ota_rsp ? that.ota_rsp.toString(16) : 'null') + ')');
							}
						}, 50);
					});
				},
				
				// 固件 OTA 升级（SLB 模式，严格对齐设备 ota_protocol.c）
				async TxUpdate_Firmware() {
					var that = this;
					try {
						// 1. 读取固件文件（hex16 格式）
						let raw_data = await this.getbindata();
						
						// 2. 解析 hex16 → 分区
						let partitions = this.parseHex16File(raw_data);
						if (partitions.length === 0) {
							throw '未解析到有效分区数据';
						}
						
						// 3. 按 ≤16KB 拆分成分区块（设备 buffer OTA_PBUF_SIZE=16K+16）
						let chunks = this.splitPartitions(partitions);
						if (chunks.length === 0) {
							throw '固件数据为空';
						}
						if (chunks.length > 0xFF) {
							throw '分区块数超过255，固件过大';
						}
						
						console.log('OTA分区块数:', chunks.length);
						
						// 数据包大小 = MTU - 3
						let pktSize = this.MTU - 3;
						if (pktSize < 20) pktSize = 20;
						
						// 重置OTA响应跟踪
						this.ota_rsp = null;
						this.ota_rsp_ready = false;
						this.ota_rsp_extra = null;
						
						// 4. START_OTA: "01 {分区块数} ff"（0xff=SLB模式, 无逐块0x87应答, 分区结束时应答0x85/0x83）
						let startCmd = new Uint8Array([0x01, chunks.length & 0xFF, 0xFF]);
						await this.writeHexData(this.connectedcharacteristicId[0], ab2hex(startCmd));
						console.log('已发送START_OTA(01 ' + chunks.length.toString(16) + ' ff), 等待0x81...');
						await this.waitOTA(0x81, 10000);
						console.log('收到START_OTA应答(0x81)');
						
						// 总数据量（进度条用）
						let totalSize = 0;
						for (let c of chunks) totalSize += c.size;
						let totalSent = 0;
						
						that.pg_flag = true;
						that.pgList = 0;
						uni.showToast({
							title: '正在升级固件...',
							icon: 'none',
							duration: 99999,
						});
						
						// 5. 逐个分区块：PARTITION_INFO → 数据流 → 0x85/0x83
						for (let ci = 0; ci < chunks.length; ci++) {
							let c = chunks[ci];
							let isLast = (ci === chunks.length - 1);
							
							// 5a. PARTITION_INFO (18字节)
							// 格式: 02 + index(1) + flash_addr(4LE) + run_addr(4LE) + size(4LE) + checksum(4LE)
							let partCmd = new Uint8Array(18);
							partCmd[0] = 0x02;
							partCmd[1] = ci & 0xFF;
							partCmd.set(this.intToLE(c.flash_addr), 2);
							partCmd.set(this.intToLE(c.run_addr), 6);
							partCmd.set(this.intToLE(c.size), 10);
							partCmd.set(this.intToLE(c.crc), 14); // 4字节 checksum
							
							await this.writeHexData(this.connectedcharacteristicId[0], ab2hex(partCmd));
							console.log('已发送PARTITION_INFO[' + ci + '] flash=0x' + c.flash_addr.toString(16) + 
								' run=0x' + c.run_addr.toString(16) + ' size=' + c.size + 
								' crc=0x' + c.crc.toString(16) + ', 等待0x84...');
							await this.waitOTA(0x84, 10000);
							console.log('收到分区信息应答(0x84)');
							
							// 5b. 发送该分区全部数据（SLB模式连续发送，等待分区结束应答）
							let pkts = Math.ceil(c.size / pktSize);
							for (let j = 0; j < pkts; j++) {
								let start = j * pktSize;
								let end = Math.min(start + pktSize, c.size);
								let pdata = c.data.slice(start, end);
								await this.writeHexData(this.connectedcharacteristicId[2], ab2hex(pdata));
								totalSent += (end - start);
								// 每若干包轻微延时，避免溢出发送队列
								if (j % 8 === 0) await delay(5);
								that.pgList = Math.floor(totalSent / totalSize * 100);
							}
							
							// 5c. 等待分区完成应答 0x85（最后一个为 0x83）
							if (isLast) {
								console.log('最后一个分区发送完毕, 等待0x83...');
								await this.waitOTA(0x83, 15000);
								console.log('收到OTA完成应答(0x83)');
							} else {
								try {
									await this.waitOTA(0x85, 15000);
									console.log('收到分区完成应答(0x85), chunk ' + ci);
								} catch(e) {
									// 部分设备直接发0x83；若超时则继续下个分区
									console.warn('分区完成应答超时，尝试继续:', e);
								}
							}
						}
						
						// 6. REBOOT 命令 "04"
						await this.writeHexData(this.connectedcharacteristicId[0], '04');
						console.log('已发送REBOOT(04), 设备重启中...');
						
						uni.hideToast();
						that.pg_flag = false;
						that.pgList = 0;
						this.fw_ota_mode = false;
						this.ota_reconnecting = false;
						this.lockInterface = false;
						that.toast('固件升级完成，设备重启中...');
						
					} catch(err) {
						console.error('固件OTA失败:', err);
						uni.hideToast();
						that.pg_flag = false;
						that.pgList = 0;
						this.fw_ota_mode = false;
						this.ota_reconnecting = false;
						this.lockInterface = false;
						let msg = (err && err.errMsg) ? err.errMsg : err;
						that.toast('固件升级失败: ' + msg);
					}
				},
			
			
			
			
			
			//保存下载的文件
			checkDownload(){ 
				var that = this;
			    plus.io.requestFileSystem( plus.io.PUBLIC_DOWNLOADS, function(fs){  
			            var directoryReader = fs.root.createReader();  
			            directoryReader.readEntries( function( entries ){  
			                var i;  
			                for( i = 0; i < entries.length; i++ ) {  
			                            console.log( entries[i].name );  
										// console.log(getApp().globalData.path);
			                            entries[i].name = i  
			                }
							uni.hideToast();
							// that.lockInterface = false; // 关闭遮盖层
							// uni.getStorage({
							// 	key:'path',
							// 	success: function (res) {
							// 		console.log(res.data.path);
							// 		getApp().globalData.path = res.data.path;
							// 		toast("数据更新成功");
									
							// 		that.TxUpdate();  //发送数据
							// 	},
							// 	fail: function() {
							// 		console.log('数据地址获取失败，请重新下载更新');
									
							// 		toast("数据地址获取失败，请重新下载更新");
							// 	}
							// })
							
			            }, function ( e ) {  
			                console.log( "Read entries failed: " + e.message );  
			            });  
			        });  
			},   
			
			// 创建下载任务  
			createDownload(Download_url) {  
				// let path_test = "/storage/emulated/0/Android/data/io.dcloud.HBuilder/";
				// let path_test = "/storage/emulated/0/Android/data/com.BLE903.android/";
				var that = this;
				
				return new Promise((resolve , reject)=>{
					var dtask = plus.downloader.createDownload(Download_url, {}, function(d, status){
					    // 下载完成 下载的文件会保存在 PUBLIC_DOWNLOADS 目录下，只要不主动删除都会存在  
					    if(status == 200){   
					        console.log("Download success: ");  
					        console.log(d);
							
							//绝对路径
							const path_buff = plus.io.convertLocalFileSystemURL(d.filename);
							console.log(path_buff)
							
							that.checkDownload();
							resolve(path_buff);				//返回下载文件的路径信息
							// getApp().globalData.path = path_buff;//path_test + d.filename.substring(1)//this.removeCharAt(d.filename,0);
							// uni.setStorage({
							// 	key: 'path',
							// 	data: {
							// 		path: getApp().globalData.path
							// 	},
							// 	success:  (res) => {
							// 		console.log('数据地址存储成功');
									
							// 		that.updata_version_before = getApp().globalData.updata_version;
							// 		++that.versionkey;
							
							// 	}
							// })

					          
					    } else {
							// getApp().globalData.updata_version = "20140101";
							// uni.setStorage({
							// 	key: that.chip_name,
							// 	data: {			
							// 		version: getApp().globalData.updata_version ,
							// 	},
							// 	success: function () {
							// 		console.log('数据版本与下载链接存储成功');
							// 	}
							// });
							
					        console.log("Download failed: " + status);
							uni.hideToast();
							that.lockInterface = false; // 关闭遮盖层
							
							that.toast(this.$t('Download.fail') + status);//"数据下载失败，请重新下载: "
							
							reject(null);
					    }    
					});  
					      
					dtask.start();
				})
			       
			},
			 
			
			
			/**
			 * 弹出框封装
			 */
			toast(content, showCancel = false) {
				uni.showModal({
					title: this.$t('api.message'),
					content,
					showCancel
				});
			},
			
			/**
			 * 判断初始化蓝牙状态
			 */
			initTypes(code, errMsg) {
				
				switch (code) {
					case 10000:
						this.toast(this.$t('initTypes.10000')); //'未初始化蓝牙适配器'
						break;
					case 10001:
						this.toast(this.$t('initTypes.10001')); //'未检测到蓝牙，请打开蓝牙重试！'
						break;
					case 10002:
						this.toast(this.$t('initTypes.10002')); //'没有找到指定设备'
						break;
					case 10003:
						this.toast(this.$t('initTypes.10003')); //'连接失败'
						break;
					case 10004:
						this.toast(this.$t('initTypes.10004'));  //'没有找到指定服务'
						break;
					case 10005:
						this.toast(this.$t('initTypes.10005'));	//'没有找到指定特征值'
						break;
					case 10006:
						this.toast(this.$t('initTypes.10006')); //'当前连接已断开'
						break;
					case 10007:
						this.toast(this.$t('initTypes.10007')); //'当前特征值不支持此操作'
						break;
					case 10008:
						this.toast(this.$t('initTypes.10008'));	//'其余所有系统上报的异常'
						break;
					case 10009:
						this.toast(this.$t('initTypes.10009'));	//'Android 系统特有，系统版本低于 4.3 不支持 BLE'
						break;
					case 10010:
						this.toast(this.$t('initTypes.10010'));	//'Android 系统特有，系统版本低于 4.3 不支持 BLE'
						break;
					case 10011:
						this.toast(this.$t('initTypes.10011'));	//'Android 系统特有，系统版本低于 4.3 不支持 BLE'
						break;
					case 10012:
						this.toast(this.$t('initTypes.10012'));	//'Android 系统特有，系统版本低于 4.3 不支持 BLE'
						break;
					case 11000:
						this.toast(this.$t('initTypes.11000'));	//'获取特征值失败'
						break;	
					
					default:
						this.toast(errMsg);
				}
					
			},
			
			
			//获取当前时间
			getNowTime() {
				var that = this;
				var date = new Date();
				//年 getFullYear()：四位数字返回年份
				that.year = date.getFullYear(); //getFullYear()代替getYear()
				//月 getMonth()：0 ~ 11
				that.month = date.getMonth() + 1;
				//日 getDate()：(1 ~ 31)
				that.day = date.getDate();
				//时 getHours()：(0 ~ 23)
				that.hour = date.getHours();
				//分 getMinutes()： (0 ~ 59)
				that.minute = date.getMinutes();
				//秒 getSeconds()：(0 ~ 59)
				that.second = date.getSeconds();
				var time = that.year + this.addZero(that.month) + this.addZero(that.day) + this.addZero(that.hour) +this.addZero(that.minute) + this.addZero(that.second);
				// var time = year << 5 + month << 4 + day << 3 + hour << 2 + minute << 1 + second;
	
					this.time = Number(time);
					// console.log(numberToArrayBuffer(this.time,4));
					// console.log(this.time);
			},
			//小于10的拼接上0字符串
			addZero(s) {
				return s < 10 ? ('0' + s) : s;
			},
			
			
			
		
		
	
			
		},
	
		
	}
	

	
	
	// 字符串转16进制字符串
	function string2Hex(str) {
	    let val = ""
	    for (let i = 0; i < str.length; i++) {
			if (val == "")
				val = str.charCodeAt(i).toString(16)
			else
				val += str.charCodeAt(i).toString(16)
	    }
	    return val
	}
	
	// 16进制字符串转ArrayBuffer
	function hex2ArrayBuffer(hex_str) {
	// let hex_str = 'AA5504B10000B5'
	    let typedArray = new Uint8Array(hex_str.match(/[\da-f]{2}/gi).map(function (h) {
			return parseInt(h, 16)
	    }))
	    let buffer = typedArray.buffer
	    return buffer
	}
	
	// ArrayBuffer转16进度字符串示例
	function ab2hex(buffer) {
	  const hexArr = Array.prototype.map.call(
	    new Uint8Array(buffer),
	    function (bit) {
	      return ('00' + bit.toString(16)).slice(-2)
	    }
	  )
	  return hexArr.join('')
	}
	
	// ArrayBuffer转字符串
    function arrayBuffer2String(buffer) {
      return String.fromCharCode.apply(null, new Uint8Array(buffer))
    }
	
	//数字转ArrayBuffer
	function numberToArrayBuffer(num, byteLength = 2) {
		if (byteLength > 8) {
			throw new Error('Number cannot be greater than 64 bits.');
		}
		const buffer = new ArrayBuffer(byteLength);
		const view = new DataView(buffer);

		if (byteLength === 2) 
		{
			view.setUint16(0, num, false);
		} else if (byteLength === 4) 
		{
			view.setUint32(0, num, false);
		} else if (byteLength === 1)
		{
			view.setUint8(0, num, false);
		}
		else {
			// Handle other cases, e.g., 8 bytes for Float64
		}

		return buffer;
	}
	
	function delay(ms) {
	    return new Promise(resolve => setTimeout(resolve, ms));
	}


	
	
</script>






<style>
	
	
	/*文字*/
	.textbox{
		/* left: 30px; */
		margin-bottom: 10%;
		width: auto;
		height: auto;
		 
	}
	
	/** 文本1 */
	.text_title{
		/* font-size: 20px;
		font-weight: 400;
		letter-spacing: 0px;
		line-height: 24px;
		color: rgba(74, 74, 74, 1);
		text-align: center;
		vertical-align: top;
		margin-top: 100px; */ /* 示例中下移50px */
		/* margin-top : 5%; */
		font-size: 14px;
		color: #000000;
		
	}
	
	
	
	
	
	.bg-image {
		/* display: flex; */
		/* background-image: url('/static/ble2x.png'); */ /* 图片路径 */
		/* background-size: 120%; */ /* 背景图片覆盖整个元素 */
		/* background-position: center; */ /* 背景图片居中 */
		/* background-repeat: no-repeat; */

		/* height: 300px; */ /* 设置高度 */
		height: auto;
		width: auto; /* 设置宽度 */
		
		/* justify-content: center;
		align-items: center; */
		


		
	}
	
	.connect1	
	{
		display: flex;
		align-items: center; /* 垂直居中 */
		justify-content: center; /* 水平居中 */
		height: 100%; /* 设置容器高度适应屏幕 */
		flex-direction: column;
		
	}
	
	.connect2
	{
		display: flex;
		/* grid-template-columns: 70% 70% 50% ; */ 
		align-items: center; /* 垂直居中*/
		flex-direction: column;
		flex-wrap: wrap;
		/* justify-content: space-between; */ /* 均匀排列每个元素每个元素之间的间隔相等 *//* 水平居中 */
		
		
		
		height: 60%; /* 设置容器高度适应屏幕 */
		width: 90%;
		
		/* height: 474px; */
		opacity: 0.9;
		border-radius: 28px;
		background: rgba(255, 255, 255, 0.5);
		box-shadow: 2px 10px 23px  rgba(0, 0, 0, 0.18);
	}
	
	
	
	

	/*button*/
	.connectbutton{
		
		margin-bottom : 2%;
		/* margin-left: 5%; */
		display: flex;
		
		align-items: center; /* 垂直居中 */
		
		justify-content: center; /* 水平居中 */
		/* height: auto; */ /* 设置容器高度适应屏幕 */
		width: 80%;
		
		color: #ffffff;
		
		/* left: 55px; */
		
		
		height: 55px;
		opacity: 1;
		border-radius: 27.5px;
		/* background: rgba(27, 105, 253, 1); */
		box-shadow: 0px 6px 12px  rgba(27, 105, 253, 0.39);
		
		position: absolute;
		top: 70%;
		left: 50%;
		transform: translate(-50%, -50%);
	}
	
	.backbutton{
		/* margin-top : 50%; */
		/* margin-left: 5%; */
		display: flex;
		
		align-items: center; /* 垂直居中 */
		
		justify-content: center; /* 水平居中 */
		/* height: auto; */ /* 设置容器高度适应屏幕 */
		/* width: 90%; */
		
		color: #ffffff;
		
		/* left: 55px; */
		
		width: 80%;
		height: 55px;
		opacity: 1;
		border-radius: 27.5px;
		/* background: rgba(27, 105, 253, 1); */
		box-shadow: 0px 6px 12px  rgba(170, 0, 0, 0.4);
		
		position: absolute;
		top: 70%;
		left: 50%;
		transform: translate(-50%, -50%);
	}





	
	
	


	.title {
		font-size: 36rpx;
		color: #000000;
	}
	
	
	
	.Rx_progress {
		height: 100%;
		/* font-size: 36rpx; */
		/* background: #fff; */
		text-align: center;
		display: block;
		align-items: center;
		justify-content: center; /* 水平居中 */
		opacity: 0.9;
		/* border-radius: 28px;
		background: rgba(255, 170, 0, 0.8);
		box-shadow: 2px 10px 23px  rgba(255, 270, 4, 0.2); */
		/* color: #ff0000; */
		
	}
	
	.Rx_toast_success {
		height: 100%;
		font-size: 36rpx;
		/* background: #fff; */
		
		display: flex;
		align-items: center;
		justify-content: center; /* 水平居中 */
		opacity: 0.9;
		border-radius: 28px;
		/* background: rgba(0, 255, 0, 0.8);
		box-shadow: 2px 10px 23px  rgba(0, 255, 4, 0.2);
		color: #ffffff; */
		
		background: rgba(240, 240, 240, 0.5);
		box-shadow: 2px 5px 30px  rgba(0, 0, 0, 0.2);
		border: 2px solid #eaeaea;/* 黑色边框 */
		color: #00ff00;  
		
	}
	
	.Rx_toast {
		height: 100%;
		font-size: 36rpx;
		/* background: #fff; */
		
		display: flex;
		align-items: center;
		justify-content: center; /* 水平居中 */
		opacity: 0.9;
		border-radius: 28px;
		/* background: rgba(255, 170, 0, 0.8);
		box-shadow: 2px 10px 23px  rgba(255, 170, 4, 0.2); */
		color: #ff0000;
		
		background: rgba(240, 240, 240, 0.5);
		box-shadow: 2px 5px 30px  rgba(0, 0, 0, 0.2);
		border: 2px solid #eaeaea;/* 黑色边框 */
		
	}
	.uni-Rx_toast {
		position: absolute;
		/* margin-bottom: 10%; */
		/* top: 10%; */
		left: 0;
		bottom: 6%;
		display: block;
		align-items: center;
		justify-content: center; /* 水平居中 */
		width: 100%;
		height: 9%;
		/* background: rgba(255, 255, 255, 0.6); */
		padding: 0 50rpx;
		box-sizing: border-box;
	}
	.uni-update_tips {
		
		text-align: center;
		font-size: 24px;
		font-weight: bold;
		color: #ff330a;
	}
	
		
	
	
	.uni-scroll_box {
		height: 70%;
		background: #fff;
		border-radius: 20rpx;
	}
	.uni-title {
		/* width: 100%; */
		/* height: 80rpx; */
		text-align: center;
	}
	

	
	.uni-list-box {
		margin: 0 20rpx;
		padding: 15rpx 0;
		border-bottom: 1px #bcbcbc solid;
		height: auto;
	}
	.uni-list_name {
		font-size: 30rpx;
		color: #333;
	}
	.uni-list_item {
		font-size: 24rpx;
		color: #555;
		line-height: 1.5;
	}
	.uni-mask {
		position: fixed;
		top: 0;
		left: 0;
		bottom: 0;
		display: flex;
		align-items: center;
		width: 100%;
		background: rgba(0, 0, 0, 0.6);
		padding: 0 30rpx;
		box-sizing: border-box;
	}
	.uni-BLE_name {
		
		text-align: center;
		font-size: 14px;
		font-weight: bold;
		color: #000000;
	}


	.time {
	    margin-left: 56rpx;
	    color: #02A53C;
	    font-size: 30rpx;
	    font-weight: 500;
	}
	  
	  
	.progress-box {
		display: flex;
		height: 50rpx;
		/* margin-bottom: 60rpx; */
	}
	
	
	/* 遮盖层 */
	.overlay {
	  position: absolute;
	  top: 0;
	  left: 0;
	  width: 100%;
	  height: 100%;
	  background-color: rgba(0, 0, 0, 0.5); /* 半透明遮盖层 */
	  z-index: 1000; /* 确保覆盖在其他元素上方 */
	}
	
	page{
		height: 100%;
		background-image: linear-gradient(to bottom, #9bdeff 0%, #cdf0ff 40%, #ffffff 70%); 
	}

	/* 升级模式选择：两个按钮水平排布并留间距 */
.mode-select{
	display: flex;
	align-items: center;
	justify-content: center;
	margin: 30rpx 0;
	gap: 30rpx;
}
.mode-btn{
	width: 100%; 
	box-sizing: border-box;
	white-space: nowrap; 
	overflow: hidden;   
	padding: 15rpx 60rpx !important;
}

.mode-btn::after{
	border: none;
}
.mode-btn{
		padding-left: 40rpx !important;
		padding-right: 40rpx !important;
	}
::v-deep .mode-btn text{
		padding: 0 100rpx;
		}

</style>
