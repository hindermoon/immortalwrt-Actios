#!/bin/bash
# DIY脚本
# https://github.com/P3TERX/Actions-OpenWrt
# 文件名: diy-part2.sh
# 功能说明: OpenWrt DIY脚本第2部分（更新feeds之后）

# 修改默认主题为 argon（路径不存在时跳过，不中断编译）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# ==========================================
# 1. 自动为 UFI103S (MSM8916) 注入 SIM 卡引脚控制节点
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

# ==========================================
# 2. 修复依赖缺失导致的编译报错 (libffi / glib2)
# ==========================================
echo "CONFIG_PACKAGE_libffi=y" >> .config
echo "CONFIG_PACKAGE_glib2=y" >> .config
