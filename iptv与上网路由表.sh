#!/bin/sh

echo "=== 路由初始化脚本 ==="

# 自动获取 PPPoE 网关
get_pppoe_gateway() {
    ip addr show pppoe-wan 2>/dev/null | awk '/peer/ {print $4}' | cut -d'/' -f1
}

# 固定设置 phy1-sta0 的网关地址
STA_GATEWAY="192.168.6.1"
# 固定设置 wan 接口的网关地址
WAN_GATEWAY="192.168.9.1"

# 获取 PPPoE 网关
PPPOE_GATEWAY=$(get_pppoe_gateway)

if [ -z "$PPPOE_GATEWAY" ]; then
    echo "❌ 未检测到 pppoe-wan 网关地址，PPPoE 连接可能未建立！"
    exit 1
fi

echo "✔ PPPoE 网关地址: $PPPOE_GATEWAY"
echo "✔ 内网 STA 网关地址（固定）: $STA_GATEWAY"
echo "✔ WAN 网关地址（固定）: $WAN_GATEWAY"

# 删除所有默认路由和特定冲突路由
echo "🧹 删除现有默认路由和冲突路由..."
ip route del default 2>/dev/null
# 特别注意：删除通过 WAN 接口的默认路由（如果存在）
ip route del default via "$WAN_GATEWAY" dev wan 2>/dev/null

# 添加默认路由（走内网）
echo "➡ 添加默认路由: default via $STA_GATEWAY dev phy1-sta0"
ip route add default via "$STA_GATEWAY" dev phy1-sta0 

# 路由添加函数
add_route_if_not_exists() {
    local dest="$1"
    local via="$2"
    local dev="$3"

    if ! ip route show "$dest" | grep -q "via $via dev $dev"; then
        echo "➕ 添加路由: $dest via $via dev $dev"
        ip route add "$dest" via "$via" dev "$dev"
    else
        echo "✔ 路由已存在: $dest via $via dev $dev (跳过)"
    fi
}

# 添加通过 PPPoE 出口的特定目标路由（更新列表）
ROUTE_LIST="224.0.0.0/4 10.0.0.0/8 124.232.231.172 124.232.139.1 218.76.205.0/24 222.246.132.231 124.232.135.0/24 124.232.232.145"
for DEST in $ROUTE_LIST; do
    add_route_if_not_exists "$DEST" "$PPPOE_GATEWAY" "pppoe-wan"
done

# 添加本地网络路由（确保在）
add_route_if_not_exists "192.168.21.0/24" "0.0.0.0" "br-lan"
add_route_if_not_exists "192.168.6.0/24" "0.0.0.0" "phy1-sta0"
# 新增：确保 192.168.9.0/24 路由存在且指向 WAN 接口
add_route_if_not_exists "192.168.9.0/24" "0.0.0.0" "wan"

# 显示最终路由表
echo
echo "📋 当前路由表:"
ip route show | grep -E "default|10.0.0.0/8|124.232|218.76|224.0.0.0/4|192.168|222.246"

# 网络诊断
echo
echo "🛠 网络诊断:"

echo "1️⃣ 接口状态:"
ip -br addr show | grep -E "br-lan|phy1-sta0|pppoe-wan|wan"

echo
echo "2️⃣ 路由测试:"
test_route() {
    echo -n "🔍 测试 $1: "
    if ip route get "$1" >/dev/null 2>&1; then
        result=$(ip route get "$1")
        next_hop=$(echo "$result" | awk '{print $3}')
        iface=$(echo "$result" | awk '{print $5}')
        echo "通过 $next_hop ($iface)"
    else
        echo "✗ 无法路由!"
    fi
}
test_route "10.1.1.1"
test_route "124.232.231.172"
test_route "124.232.135.225"  # 新增测试点
test_route "8.8.8.8"
test_route "192.168.9.5"
test_route "224.0.0.2"
test_route "222.246.132.231"

# 提取 pppoe 接口的 IP
pppoe_ip=$(ifconfig | awk '/pppoe/{iface=$1} iface && /inet addr:10\./{sub("addr:", "", $2); print $2; exit}')
echo "当前 PPPoE IP 是: $pppoe_ip"

echo
echo "3️⃣ PPPoE 本地可达性:"
if ping -c 1 -W 1 "$pppoe_ip" >/dev/null 2>&1; then
    echo "✅ PPPoE 本机ip $pppoe_ip 可达"
else
    echo "⚠ PPPoE 本机ip $pppoe_ip 不可达（可能是禁止 ping）"
fi

echo
echo "4️⃣ 互联网连通性:"
if ping -c 2 -W 1 qq.com >/dev/null 2>&1; then
    echo "🌍 互联网访问正常 ✓"
else
    echo "❌ 无法访问互联网"
    echo "➡ 路由追踪:"
    traceroute -n qq.com
fi
