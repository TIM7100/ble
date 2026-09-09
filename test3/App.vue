<script>
	import { mapMutations} from 'vuex'
	export default {
		onLaunch: function() {
			console.log('App Launch')
			
		},
		onShow: function() {
			console.log('App Show')
			
		},
		onHide: function() {
			console.log('App Hide')
		},
		// created:function(){
		// 	uni.$on('setTabBarItem',res => {
		// 		this.setTabBarItems()
		// 	})
		// },
		
		
		//全局变量
		globalData: {
			path: "",
			updata_version: "",
			
		}
	
	}
	
	
	
</script>

<style>
	/*每个页面公共css */
	
</style>
