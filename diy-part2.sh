#!/bin/bash
# DIY脚本
# https://github.com/P3TERX/Actions-OpenWrt
# 文件名: diy-part2.sh
# 功能说明: OpenWrt DIY脚本第2部分（更新feeds之后）
# 版权: (c) 2019-2024 P3TERX <https://p3terx.com>
# 基于 MIT 开源协议，详见 /LICENSE

# 修改默认IP地址
#sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate


# 修改默认主题为 argon（路径不存在时跳过，不中断编译）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 启用 IPv4 策略路由（直接写入内核 platform config，绕过 make defconfig 的依赖检查）
# CONFIG_KERNEL_IP_ADVANCED_ROUTER 在 OpenWrt Config.in 中无对应 wrapper，必须用此方式
#for cfg in target/linux/msm89xx/config-*; do
#  grep -q 'CONFIG_IP_ADVANCED_ROUTER' "$cfg" || echo 'CONFIG_IP_ADVANCED_ROUTER=y' >> "$cfg"
#  grep -q 'CONFIG_IP_MULTIPLE_TABLES' "$cfg" || echo 'CONFIG_IP_MULTIPLE_TABLES=y' >> "$cfg"
#done


# ==========================================
# 自动为 UFI103S (MSM8916) 注入 SIM 卡引脚控制节点
# ==========================================
echo "正在查找并修补目标设备树 (DTS)..."
find target/linux/qcom -name "*.dts" | while read -r dts; do
    if grep -q "pinctrl@1000000" "$dts" && ! grep -q "sim-ctrl-default-state" "$dts"; then
        echo "正在向 $dts 中注入 sim-ctrl-default-state 节点..."
        python3 -c '
import sys
dts_path = sys.argv[1]
with open(dts_path, "r", encoding="utf-8") as f:
    content = f.read()

target = "pinctrl@1000000 {"
node_code = """
			sim-ctrl-default-state {
				phandle = <0x54>;

				esim-sel-pins {
					pins = "gpio0", "gpio3";
					bias-disable;
					output-low;
				};

				sim-en-pins {
					pins = "gpio1";
					bias-disable;
					output-low;
				};

				sim-sel-pins {
					pins = "gpio2";
					bias-disable;
					output-high;
				};
			};
"""

if target in content and "sim-ctrl-default-state" not in content:
    content = content.replace(target, target + node_code, 1)
    with open(dts_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("DTS 注入成功！")
' "$dts"
    fi
done


# 临时添加的插件
# git clone https://github.com/lkiuyu/luci-app-cpu-perf package/luci-app-cpu-perf
# git clone https://github.com/lkiuyu/luci-app-cpu-status package/luci-app-cpu-status
# git clone https://github.com/gSpotx2f/luci-app-cpu-status-mini package/luci-app-cpu-status-mini
# git clone https://github.com/lkiuyu/luci-app-temp-status package/luci-app-temp-status
# git clone https://github.com/lkiuyu/DbusSmsForwardCPlus package/DbusSmsForwardCPlus
