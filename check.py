import hashlib
import base64
import sys
import win32com.client

# 自定义密钥（重要！请修改为自己的密钥，防止他人破解）
SECRET_KEY = "YourCustomSecretKey123"  # 建议替换为随机字符串

def get_cpu_id():
    """获取CPU序列号"""
    try:
        cpu_id = win32com.client.Dispatch("WbemScripting.SWbemLocator")
        service = cpu_id.ConnectServer(".", "root\\cimv2")
        properties = service.InstancesOf("Win32_Processor")
        for prop in properties:
            return prop.ProcessorId.strip()
    except Exception as e:
        print(f"获取CPU序列号失败: {e}")
        return "CPU_ID_ERROR"

def get_disk_id():
    """获取硬盘序列号（取第一个物理硬盘）"""
    try:
        disk_id = win32com.client.Dispatch("WbemScripting.SWbemLocator")
        service = disk_id.ConnectServer(".", "root\\cimv2")
        properties = service.InstancesOf("Win32_DiskDrive")
        for prop in properties:
            if prop.MediaType == "Fixed hard disk media":
                return prop.SerialNumber.strip()
    except Exception as e:
        print(f"获取硬盘序列号失败: {e}")
        return "DISK_ID_ERROR"

def get_motherboard_id():
    """获取主板序列号"""
    try:
        motherboard_id = win32com.client.Dispatch("WbemScripting.SWbemLocator")
        service = motherboard_id.ConnectServer(".", "root\\cimv2")
        properties = service.InstancesOf("Win32_BaseBoard")
        for prop in properties:
            return prop.SerialNumber.strip()
    except Exception as e:
        print(f"获取主板序列号失败: {e}")
        return "MB_ID_ERROR"

def generate_32bit_machine_code():
    """生成32位机器码（原始逻辑）"""
    # 获取核心硬件信息
    cpu_id = get_cpu_id()
    disk_id = get_disk_id()
    motherboard_id = get_motherboard_id()
    
    # 拼接硬件信息
    hardware_info = f"{cpu_id}_{disk_id}_{motherboard_id}"
    
    # MD5哈希生成32位机器码
    md5_hash = hashlib.md5(hardware_info.encode("utf-8"))
    machine_code = md5_hash.hexdigest().upper()
    
    return machine_code

def generate_license_key(machine_code):
    """根据32位机器码+密钥生成BASE64格式的合法卡密"""
    # 1. 拼接机器码和密钥，生成原始字符串
    license_raw = f"{machine_code}_{SECRET_KEY}"
    # 2. 生成MD5哈希（字节流格式，而非十六进制字符串）
    md5_bytes = hashlib.md5(license_raw.encode("utf-8")).digest()
    # 3. 对MD5字节流进行BASE64编码，生成卡密（转为字符串便于存储/输入）
    license_base64 = base64.b64encode(md5_bytes).decode("utf-8")
    return license_base64

def verify_license_key(input_key):
    """校验用户输入的BASE64格式卡密是否正确"""
    try:
        # 1. 生成当前设备的32位机器码
        current_machine_code = generate_32bit_machine_code()
        # 2. 生成该机器码对应的合法BASE64卡密
        valid_license_key = generate_license_key(current_machine_code)
        # 3. 对比输入卡密和合法卡密（忽略大小写/空格，提升用户体验）
        return input_key.strip() == valid_license_key.strip()
    except Exception as e:
        print(f"卡密校验过程出错: {e}")
        return False

if __name__ == "__main__":
    # 1. 生成并显示当前设备的32位机器码
    machine_code = generate_32bit_machine_code()
    print(f"当前设备32位机器码: {machine_code}")
    
    # 2. 生成该机器码对应的BASE64格式合法卡密（仅供开发者生成卡密使用）
    valid_key = generate_license_key(machine_code)
    print(f"该设备的BASE64合法卡密: {valid_key}")
    
    # 3. 模拟用户输入卡密并校验
    user_input_key = input("\n请输入BASE64格式的卡密进行校验: ").strip()
    if verify_license_key(user_input_key):
        print("✅ 卡密校验成功！")
        sys.exit(1)  # 成功时返回码1，供外部切换更新通道判定
    else:
        print("❌ 卡密校验失败，卡密错误或设备不匹配！")
        sys.exit(0)