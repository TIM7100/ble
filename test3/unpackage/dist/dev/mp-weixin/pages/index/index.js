"use strict";
const common_vendor = require("../../common/vendor.js");
const _sfc_main = {
  data() {
    return {
      title: "蓝牙设备列表",
      devices: []
    };
  },
  onLoad: function() {
    common_vendor.index.openBluetoothAdapter({
      success: (res) => {
        console.log("第一步，蓝牙初始化成功", res);
        this.startBluetoothDevicesDiscovery();
      },
      fail: (res) => {
        console.log("第一步，蓝牙初始化失败", res);
        common_vendor.index.showToast({
          title: "蓝牙初始化失败",
          icon: "none"
        });
      }
    });
  },
  methods: {},
  //第二步 开始搜索附近的蓝牙设备
  startBluetoothDevicesDiscovery() {
    common_vendor.index.startBluetoothDevicesDiscovery({
      allowDuplicatesKey: false,
      success: (res) => {
        console.log("开始搜索附近的蓝牙设备", res);
        this.onBluetoothDeviceFound();
      },
      fail: (err) => {
        console.error("蓝牙搜索失败", err);
      }
    });
  },
  //第三步 监听发现附近的蓝牙设备
  onBluetoothDeviceFound() {
    common_vendor.index.onBluetoothDeviceFound((res) => {
      res.devices.forEach((device) => {
        console.log("发现的蓝牙设备", device);
        this.data.devices.push(device);
        this.setData({ devices: this.data.devices });
      });
    });
  },
  //第四步 建立连接
  connectDevice: function(e) {
    const device = e.currentTarget.dataset.device;
    common_vendor.index.createBLEConnection({
      deviceId: device.deviceId,
      success: (res) => {
        console.log("createBLEConnection success", res);
        common_vendor.index.showToast({
          title: "蓝牙连接成功",
          icon: "none"
        });
        this.stopBluetoothDevicesDiscovery();
        common_vendor.index.navigateTo({
          url: "/pages/main/main?deviceID=" + device.deviceId
        });
      },
      fail: (res) => {
        common_vendor.index.showToast({
          title: "蓝牙连接失败",
          icon: "none"
        });
      }
    });
  },
  //第五步 停止搜索
  stopBluetoothDevicesDiscovery() {
    common_vendor.index.stopBluetoothDevicesDiscovery({
      success: function(res) {
        console.log("停止搜索成功");
      },
      fail: function(res) {
        console.log("停止搜索失败");
      }
    });
  }
};
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return {
    a: common_vendor.t($data.title),
    b: common_vendor.f($data.devices, (device, index, i0) => {
      return common_vendor.e(_ctx.item.name ? {
        a: common_vendor.t(_ctx.item.name)
      } : {}, {
        b: index
      });
    }),
    c: _ctx.item.name,
    d: common_vendor.t(_ctx.item.deviceId),
    e: common_vendor.t(_ctx.item.RSSI)
  };
}
const MiniProgramPage = /* @__PURE__ */ common_vendor._export_sfc(_sfc_main, [["render", _sfc_render]]);
wx.createPage(MiniProgramPage);
