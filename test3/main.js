import App from './App'



// Vue i18n 国际化
// import VueI18n from './common/vue-i18n.min.js';
import messages from './locale/index'

let i18nConfig = {
	locale: uni.getLocale(),
	messages
}


// i18n 部分的配置，引入语言包，注意路径
// import lang_zh_CN from './common/locales/zh_CN.js';
// import lang_en from './common/locales/en.js';
 

// Vue.config.productionTip = false
// App.mpType = 'app'

// const i18n = new VueI18n({
// 	// 默认语言
// 	locale: 'zh_CN',
// 	// 引入语言文件
// 	messages: {
// 		'zh_CN': lang_zh_CN,
// 		'en': lang_en,
// 	}
// });
// Vue.prototype._i18n = i18n;







// #ifndef VUE3
import Vue from 'vue'
import './uni.promisify.adaptor'
/**/
import VueI18n from 'vue-i18n'
Vue.use(VueI18n); 
export const i18n = new VueI18n(i18nConfig)
/**/
Vue.config.productionTip = false
App.mpType = 'app'
const app = new Vue({
	i18n,
  ...App
})
app.$mount()
// #endif

// #ifdef VUE3
import { createSSRApp } from 'vue'

/**/
import { createI18n } from 'vue-i18n'
export const i18n = createI18n(i18nConfig)
/**/
export function createApp() {
  const app = createSSRApp(App)
  app.use(i18n)
  return {
    app
  }
}





// #endif