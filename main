import os
import sys
import urllib.parse
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import threading
import datetime
import ntplib
import vlc
import requests
import re
import time
from datetime import timezone, timedelta

class IPTVPlayer:
    def __init__(self, root):
        self.root = root
        self.root.title("Windows IPTV播放器 - 专业全屏版")
        self.root.geometry("1000x700")
        self.root.configure(bg="#f0f0f0")
        
        # 初始化变量
        self.channel_list = []
        self.server_list = []
        self.current_server = ""
        self.ntp_offset = 0
        self.player = None
        self.is_playing = False
        self.current_channel = None
        self.fullscreen_window = None
        self.fullscreen_canvas = None
        self.current_media = None
        self.last_position = 0.0
        
        # 创建界面
        self.create_widgets()
        
        # 加载演示数据
        self.load_demo_data()
        
        # 自动同步时间
        self.sync_time()

    def check_server_available(self, url):
        """检查服务器是否可用 - 优化版本"""
        try:
            # 解析URL获取主机部分
            parsed_url = urllib.parse.urlparse(url)
            base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
            
            # 尝试连接服务器
            response = requests.head(base_url, timeout=3)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            # 如果HEAD方法失败，尝试GET方法（更可靠）
            try:
                response = requests.get(base_url, timeout=3, stream=True)
                return response.status_code == 200
            except:
                return False
        except:
            return False

    def create_widgets(self):
        # 创建主框架
        self.main_frame = ttk.Frame(self.root, padding=10)
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 创建左侧面板
        self.left_panel = ttk.Frame(self.main_frame, padding=10)
        self.left_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=False)
        
        # 创建右侧面板
        self.right_panel = ttk.Frame(self.main_frame, padding=10)
        self.right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)
        
        # 左侧面板内容 - 控制区域
        control_frame = ttk.LabelFrame(self.left_panel, text="控制面板", padding=10)
        control_frame.pack(fill=tk.X, pady=5)
        
        # 时间同步区域
        time_frame = ttk.Frame(control_frame)
        time_frame.pack(fill=tk.X, pady=5)
        
        ttk.Label(time_frame, text="本地时间:").pack(side=tk.LEFT)
        self.local_time = ttk.Label(time_frame, text="", width=15)
        self.local_time.pack(side=tk.LEFT, padx=5)
        
        ttk.Label(time_frame, text="UTC时间:").pack(side=tk.LEFT)
        self.utc_time = ttk.Label(time_frame, text="", width=15)
        self.utc_time.pack(side=tk.LEFT, padx=5)
        
        self.sync_btn = ttk.Button(control_frame, text="同步时间", command=self.sync_time)
        self.sync_btn.pack(fill=tk.X, pady=5)
        
        # 文件导入区域
        ttk.Label(control_frame, text="导入文件:").pack(anchor=tk.W, pady=(10, 0))
        
        self.import_server_btn = ttk.Button(
            control_frame, 
            text="导入服务器列表", 
            command=lambda: self.import_file("server")
        )
        self.import_server_btn.pack(fill=tk.X, pady=5)
        
        self.import_channel_btn = ttk.Button(
            control_frame, 
            text="导入频道列表", 
            command=lambda: self.import_file("channel")
        )
        self.import_channel_btn.pack(fill=tk.X, pady=5)
        
        # 播放控制区域
        ttk.Separator(control_frame).pack(fill=tk.X, pady=10)
        
        self.play_btn = ttk.Button(
            control_frame, 
            text="播放", 
            command=self.play_channel,
            state=tk.DISABLED
        )
        self.play_btn.pack(fill=tk.X, pady=5)
        
        self.stop_btn = ttk.Button(
            control_frame, 
            text="停止", 
            command=self.stop_playback,
            state=tk.DISABLED
        )
        self.stop_btn.pack(fill=tk.X, pady=5)
        
        # 全屏控制按钮
        self.fullscreen_btn = ttk.Button(
            control_frame, 
            text="进入全屏", 
            command=self.enter_fullscreen,
            state=tk.DISABLED
        )
        self.fullscreen_btn.pack(fill=tk.X, pady=5)
        
        # 添加自定义频道区域
        custom_frame = ttk.LabelFrame(self.left_panel, text="添加自定义频道", padding=10)
        custom_frame.pack(fill=tk.X, pady=5)
        
        ttk.Label(custom_frame, text="频道名称:").pack(anchor=tk.W)
        self.channel_name_entry = ttk.Entry(custom_frame)
        self.channel_name_entry.pack(fill=tk.X, pady=5)
        
        ttk.Label(custom_frame, text="播放地址:").pack(anchor=tk.W)
        self.channel_url_entry = ttk.Entry(custom_frame)
        self.channel_url_entry.pack(fill=tk.X, pady=5)
        
        self.add_channel_btn = ttk.Button(
            custom_frame, 
            text="添加频道", 
            command=self.add_custom_channel
        )
        self.add_channel_btn.pack(fill=tk.X, pady=5)
        
        # 右侧面板内容 - 频道列表
        channel_frame = ttk.LabelFrame(self.right_panel, text="频道列表", padding=10)
        channel_frame.pack(fill=tk.BOTH, expand=True)
        
        # 创建树形视图显示频道
        self.channel_tree = ttk.Treeview(
            channel_frame, 
            columns=("name", "url"),
            show="headings",
            selectmode="browse"
        )
        
        # 设置列
        self.channel_tree.heading("name", text="频道名称")
        self.channel_tree.heading("url", text="播放地址")
        
        # 设置列宽
        self.channel_tree.column("name", width=200, anchor=tk.W)
        self.channel_tree.column("url", width=700, anchor=tk.W)
        
        # 添加滚动条
        scrollbar = ttk.Scrollbar(channel_frame, orient=tk.VERTICAL, command=self.channel_tree.yview)
        self.channel_tree.configure(yscroll=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.channel_tree.pack(fill=tk.BOTH, expand=True)
        
        # 绑定选择事件
        self.channel_tree.bind("<<TreeviewSelect>>", self.on_channel_select)
        
        # 底部状态栏
        self.status_bar = ttk.Label(
            self.root, 
            text="就绪", 
            relief=tk.SUNKEN, 
            anchor=tk.W,
            padding=5
        )
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X)
        
        # 视频播放区域
        self.video_frame = ttk.Frame(self.right_panel)
        self.video_frame.pack(fill=tk.BOTH, expand=True, pady=(10, 0))
        
        # 创建VLC实例 - 修复参数问题
        # 使用更简单的参数设置
        self.instance = vlc.Instance("--no-xlib")
        if not self.instance:
            # 如果创建失败，尝试不使用参数
            self.instance = vlc.Instance()
            
        if not self.instance:
            # 如果仍然失败，显示错误信息
            messagebox.showerror("VLC错误", "无法初始化VLC播放器，请确保已正确安装VLC")
            sys.exit(1)
            
        self.media_player = self.instance.media_player_new()
        
        # 创建画布用于显示视频
        self.canvas = tk.Canvas(self.video_frame, bg="black")
        self.canvas.pack(fill=tk.BOTH, expand=True)
        
        # 设置媒体播放器窗口
        if sys.platform == "win32":
            self.media_player.set_hwnd(self.canvas.winfo_id())
        else:
            self.media_player.set_xwindow(self.canvas.winfo_id())
        
        # 绑定双击事件用于切换全屏
        self.canvas.bind("<Double-Button-1>", self.toggle_fullscreen)
        # 绑定ESC键退出全屏
        self.root.bind("<Escape>", self.exit_fullscreen)
        
        # 绑定画布大小改变事件
        self.canvas.bind("<Configure>", self.on_canvas_resize)
        
        # 启动时间更新线程
        self.update_time_thread = threading.Thread(target=self.update_time_loop, daemon=True)
        self.update_time_thread.start()
    
    def create_fullscreen_window(self):
        """创建全屏专用窗口 - 修复版本"""
        if self.fullscreen_window:
            return
            
        # 创建新窗口
        self.fullscreen_window = tk.Toplevel(self.root)
        self.fullscreen_window.title("全屏播放")
        self.fullscreen_window.attributes("-fullscreen", True)
        self.fullscreen_window.configure(bg="black")
        
        # 创建全屏画布
        self.fullscreen_canvas = tk.Canvas(
            self.fullscreen_window, 
            bg="black", 
            highlightthickness=0
        )
        self.fullscreen_canvas.pack(fill=tk.BOTH, expand=True)
        
        # 绑定退出全屏事件
        self.fullscreen_canvas.bind("<Double-Button-1>", self.exit_fullscreen)
        self.fullscreen_window.bind("<Escape>", self.exit_fullscreen)
        
        # 绑定画布大小改变事件
        self.fullscreen_canvas.bind("<Configure>", self.on_canvas_resize)
        
        # 窗口关闭事件处理
        self.fullscreen_window.protocol("WM_DELETE_WINDOW", self.exit_fullscreen)
        
        # 隐藏窗口初始状态
        self.fullscreen_window.withdraw()
    
    def enter_fullscreen(self):
        """进入全屏模式 - 修复版本"""
        if not self.is_playing or not self.media_player:
            return
            
        # 确保全屏窗口已创建
        if not self.fullscreen_window:
            self.create_fullscreen_window()
            
        # 显示全屏窗口
        self.fullscreen_window.deiconify()
        
        # 添加延迟确保窗口完全创建
        self.fullscreen_window.update_idletasks()
        self.fullscreen_window.update()
        time.sleep(0.1)
        
        try:
            # 记录当前播放状态和位置
            was_playing = self.media_player.is_playing()
            self.last_position = self.media_player.get_position() if was_playing else 0
            
            # 将视频播放器切换到全屏窗口
            if sys.platform == "win32":
                self.media_player.set_hwnd(self.fullscreen_canvas.winfo_id())
            else:
                self.media_player.set_xwindow(self.fullscreen_canvas.winfo_id())
            
            # 恢复播放状态
            if was_playing:
                self.media_player.play()
                # 恢复播放位置
                if self.last_position > 0:
                    time.sleep(0.2)  # 增加等待时间确保播放器初始化
                    self.media_player.set_position(self.last_position)
            
            # 隐藏主窗口
            self.root.withdraw()
            
            self.update_status("已进入全屏模式 - 双击画面或按ESC键退出")
            
        except Exception as e:
            print(f"设置全屏失败: {e}")
            self.update_status(f"全屏设置错误: {e}")
            # 出错时恢复主窗口
            self.root.deiconify()
            self.fullscreen_window.withdraw()
    
    def exit_fullscreen(self, event=None):
        """退出全屏模式 - 修复版本"""
        if not self.fullscreen_window:
            return
            
        try:
            # 记录当前播放状态和位置
            was_playing = self.media_player.is_playing()
            self.last_position = self.media_player.get_position() if was_playing else 0
            
            # 显示主窗口
            self.root.deiconify()
            self.root.update_idletasks()
            self.root.update()
            time.sleep(0.1)
            
            # 将视频播放器切回主窗口
            if sys.platform == "win32":
                self.media_player.set_hwnd(self.canvas.winfo_id())
            else:
                self.media_player.set_xwindow(self.canvas.winfo_id())
            
            # 恢复播放状态
            if was_playing:
                self.media_player.play()
                # 恢复播放位置
                if self.last_position > 0:
                    time.sleep(0.2)  # 增加等待时间确保播放器初始化
                    self.media_player.set_position(self.last_position)
            
            # 隐藏全屏窗口
            self.fullscreen_window.withdraw()
            
            self.update_status("已退出全屏模式")
            
        except Exception as e:
            print(f"退出全屏失败: {e}")
            self.update_status(f"退出全屏错误: {e}")
            # 出错时确保主窗口可见
            self.root.deiconify()
    
    def toggle_fullscreen(self, event=None):
        """切换全屏模式 - 修复版本"""
        if not self.is_playing or not self.media_player:
            return
            
        # 检查当前是否已在全屏模式
        if self.fullscreen_window and self.fullscreen_window.winfo_viewable():
            self.exit_fullscreen()
        else:
            self.enter_fullscreen()
    
    def on_canvas_resize(self, event):
        """当画布大小改变时重绘视频"""
        if self.is_playing and self.media_player:
            try:
                self.media_player.video_update_viewport()
            except:
                pass
    
    def update_time_loop(self):
        """更新时间显示循环"""
        while True:
            # 获取当前本地时间
            local_now = datetime.datetime.now()
            self.root.after(0, lambda: self.local_time.config(
                text=local_now.strftime("%Y-%m-%d %H:%M:%S")
            ))
            
            # 获取当前UTC时间
            utc_now = datetime.datetime.now(timezone.utc)
            self.root.after(0, lambda: self.utc_time.config(
                text=utc_now.strftime("%Y-%m-%d %H:%M:%S") + " UTC"
            ))
            
            time.sleep(1)
    
    def load_demo_data(self):
        """加载演示数据"""
        # 添加演示服务器
        self.server_list = [
            "124.232.231.172:8089",
            "218.76.205.6:6410"
        ]
        
        # 添加演示频道
        demo_channels = [
            ("CCTV1 高清", "http://{server}/000000002000/201500000063/1000.m3u8?starttime={timestamp}"),
            ("湖南卫视", "http://{server}/000000002000/201500000067/1000.m3u8?starttime={timestamp}"),
            ("测试RTP-CCTV", "rtp://239.76.253.151:9000")
        ]
        
        for name, url in demo_channels:
            self.channel_list.append({"name": name, "url": url})
            self.channel_tree.insert("", "end", values=(name, url))
        
        self.update_status(f"已加载 {len(demo_channels)} 个演示频道")
    
    def sync_time(self):
        """同步时间"""
        self.sync_btn.config(state=tk.DISABLED, text="同步中...")
        self.update_status("正在同步时间...")
        
        # 在新线程中执行同步
        threading.Thread(target=self._sync_time_thread, daemon=True).start()
    
    def _sync_time_thread(self):
        """时间同步线程"""
        try:
            client = ntplib.NTPClient()
            response = client.request("124.232.139.1")
            self.ntp_offset = response.offset
            
            # 更新UI
            self.root.after(0, lambda: self.update_status(
                f"时间同步成功! NTP偏移: {self.ntp_offset:.3f}秒"
            ))
        except Exception as e:
            self.root.after(0, lambda: self.update_status(f"时间同步失败: {str(e)}"))
        finally:
            self.root.after(0, lambda: self.sync_btn.config(state=tk.NORMAL, text="同步时间"))
    
    def get_utc_timestamp(self):
        """获取UTC时间戳"""
        utc_now = datetime.datetime.now(timezone.utc)
        corrected_utc = utc_now + datetime.timedelta(seconds=self.ntp_offset)
        return corrected_utc.strftime("%Y%m%dT%H%M%S.00Z")
    
    def import_file(self, file_type):
        """导入文件"""
        file_path = filedialog.askopenfilename(
            title=f"选择{file_type}文件",
            filetypes=[("文本文件", "*.txt"), ("所有文件", "*.*")]
        )
        
        if not file_path:
            return
        
        try:
            if file_type == "server":
                self.import_server_file(file_path)
            elif file_type == "channel":
                self.import_channel_file(file_path)
        except Exception as e:
            messagebox.showerror("导入错误", f"导入文件时出错:\n{str(e)}")
    
    def convert_url(self, original_url):
        """将URL中的服务器地址和时间戳替换为占位符"""
        # 替换服务器地址
        converted_url = re.sub(r'http://[^/]+', 'http://{server}', original_url)
        
        # 替换时间戳
        converted_url = re.sub(r'starttime=\d{8}T\d{6}\.\d{2}Z', 'starttime={timestamp}', converted_url)
        
        return converted_url
    
    def import_server_file(self, file_path):
        """导入服务器列表文件"""
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        self.server_list = [line.strip() for line in lines if line.strip()]
        
        if self.server_list:
            self.current_server = self.server_list[0]
            messagebox.showinfo("导入成功", f"成功导入 {len(self.server_list)} 个服务器")
            self.update_status(f"已导入 {len(self.server_list)} 个服务器")
        else:
            messagebox.showwarning("导入失败", "文件中没有有效的服务器地址")
    
    def import_channel_file(self, file_path):
        """导入频道列表文件"""
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        imported_count = 0
        
        # 跳过第一行标题行
        for line in lines[1:]:
            line = line.strip()
            if not line:
                continue
            
            # 检查格式：频道名\t播放地址
            if "\t" in line:
                parts = line.split("\t", 1)
                if len(parts) == 2:
                    name, url = parts
                    converted_url = self.convert_url(url)
                    self.channel_list.append({"name": name, "url": converted_url})
                    self.channel_tree.insert("", "end", values=(name, converted_url))
                    imported_count += 1
        
        if imported_count > 0:
            messagebox.showinfo("导入成功", f"成功导入 {imported_count} 个频道")
            self.update_status(f"已导入 {imported_count} 个频道")
        else:
            messagebox.showwarning("导入失败", "文件中没有有效的频道数据")
    
    def add_custom_channel(self):
        """添加自定义频道"""
        name = self.channel_name_entry.get().strip()
        url = self.channel_url_entry.get().strip()
        
        if not name:
            messagebox.showwarning("输入错误", "请输入频道名称")
            return
        
        if not url:
            messagebox.showwarning("输入错误", "请输入播放地址")
            return
        
        # 转换URL格式
        converted_url = self.convert_url(url)
        
        # 添加到列表和树形视图
        self.channel_list.append({"name": name, "url": converted_url})
        self.channel_tree.insert("", "end", values=(name, converted_url))
        
        # 清空输入框
        self.channel_name_entry.delete(0, tk.END)
        self.channel_url_entry.delete(0, tk.END)
        
        self.update_status(f"已添加频道: {name}")
    
    def on_channel_select(self, event):
        """频道选择事件"""
        selected = self.channel_tree.selection()
        if selected:
            self.play_btn.config(state=tk.NORMAL)
            self.current_channel = self.channel_tree.item(selected[0])
        else:
            self.play_btn.config(state=tk.DISABLED)
            self.current_channel = None
    
    def play_channel(self):
        """播放选中的频道"""
        if not self.current_channel:
            return
        
        # 获取选中的行索引
        selected_item = self.channel_tree.selection()[0]
        index = self.channel_tree.index(selected_item)
        channel_info = self.channel_list[index]
        channel_name = channel_info["name"]
        channel_url = channel_info["url"]
        
        # 生成播放URL
        play_url = self.generate_play_url(channel_url)
        
        # 检查服务器可用性
        if not self.check_server_available(play_url):
            self.update_status(f"服务器检查失败，但仍尝试播放: {channel_name}")
        else:
            self.update_status(f"服务器可用，正在播放: {channel_name}")
        
        try:
            # 停止当前播放
            if self.is_playing:
                self.media_player.stop()
                time.sleep(0.5)  # 增加停止后的延迟
            
            # 创建媒体对象
            self.current_media = self.instance.media_new(play_url)
            
            # 设置媒体选项 - 增加缓存大小解决TS不连续问题
            self.current_media.add_option(":network-caching=1000")  # 增加到1000ms缓存
            self.current_media.add_option(":clock-jitter=0")
            self.current_media.add_option(":clock-synchro=0")
            self.current_media.add_option(":ts-seek-percent")  # 允许百分比定位
            
            # 设置媒体播放器
            self.media_player.set_media(self.current_media)
            
            # 开始播放
            if self.media_player.play() == -1:
                raise Exception("VLC播放失败")
            
            self.is_playing = True
            self.stop_btn.config(state=tk.NORMAL)
            self.fullscreen_btn.config(state=tk.NORMAL)
            self.update_status(f"正在播放: {channel_name} - 双击画面或按ESC键切换全屏")
            
        except Exception as e:
            self.is_playing = False
            messagebox.showerror("播放错误", f"无法播放频道:\n{str(e)}\nURL: {play_url}")
            self.update_status("播放失败")
    
    def generate_play_url(self, template_url):
        """生成播放URL - 优化版本"""
        # 获取UTC时间戳
        timestamp = self.get_utc_timestamp()
        
        # 如果URL中包含{server}占位符，则替换为当前服务器
        if "{server}" in template_url:
            if not self.server_list:
                messagebox.showwarning("服务器错误", "没有可用的服务器，请先导入服务器列表")
                return template_url
            
            # 随机选择一个服务器
            import random
            server = random.choice(self.server_list)
            template_url = template_url.replace("{server}", server)
        
        # 替换时间戳占位符
        if "{timestamp}" in template_url:
            template_url = template_url.replace("{timestamp}", timestamp)
        
        # 打印生成的URL用于调试
        print(f"生成的播放URL: {template_url}")
        return template_url
    
    def stop_playback(self):
        """停止播放"""
        if self.is_playing:
            # 记录最后播放位置
            self.last_position = self.media_player.get_position()
            
            self.media_player.stop()
            self.is_playing = False
            self.update_status("播放已停止")
            self.stop_btn.config(state=tk.DISABLED)
            self.fullscreen_btn.config(state=tk.DISABLED)
            self.current_media = None
            
            # 如果全屏中，退出全屏
            if self.fullscreen_window and self.fullscreen_window.winfo_viewable():
                self.exit_fullscreen()
    
    def update_status(self, message):
        """更新状态栏"""
        self.status_bar.config(text=message)
        self.root.update_idletasks()
    
    def on_closing(self):
        """关闭窗口事件"""
        self.stop_playback()
        
        # 关闭全屏窗口
        if self.fullscreen_window:
            self.fullscreen_window.destroy()
            
        self.root.destroy()

def main():
    root = tk.Tk()
    app = IPTVPlayer(root)
    
    # 设置关闭事件处理
    root.protocol("WM_DELETE_WINDOW", app.on_closing)
    
    # 设置窗口图标
    try:
        root.iconbitmap("iptv_icon.ico")
    except:
        pass
    
    root.mainloop()

if __name__ == "__main__":
    main()
