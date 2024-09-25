#!/bin/bash
export TZ=Asia/Shanghai
# 定义日志文件路径
log_file="/home/hcucumber/vm_shutdown.log"
log_file_bak="/home/hcucumber/vm_shutdown.log.bak"
# 确保日志文件存在且可写
touch $log_file
sudo chmod a+rw $log_file
cp -af "$log_file" "$log_file_bak"
> $log_file

#列出虚拟机状态
vms_all=$(virsh list --all --name)
for vm in $vms_all;do
    echo "$(date '+%Y-%m-%d %H:%M:%S') $vm is $(virsh domstate $vm)" | sudo tee -a $log_file
done
# 获取已开机虚拟机的名称列表
vms=$(virsh list --name)
echo "$(date '+%Y-%m-%d %H:%M:%S') The vms list NOT shutdown:" | sudo tee -a $log_file
for vm in $vms; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') $vm" | sudo tee -a $log_file
done
#echo "$(date '+%Y-%m-%d %H:%M:%S') $vms" | sudo tee -a $log_file


# 遍历所有虚拟机
for vm in $vms; do
    # 获取当前虚拟机的状态
    status=$(virsh domstate "$vm")
    # 如果虚拟机状态不是“关闭”
    if [[ "$status" != "shut off" ]]; then
        # 记录关闭虚拟机的日志
        echo "$(date '+%Y-%m-%d %H:%M:%S') 正在关闭虚拟机 $vm。" | sudo tee -a $log_file  
        # 使用 wait 等待命令执行完成并检查返回值
        # 尝试优雅地关闭虚拟机
        if virsh shutdown "$vm"; then
            # 设置最大等待时间
            timeout=0
            max_timeout=300 # 10分钟
            while true; do
                new_status=$(virsh domstate "$vm")
                # 如果虚拟机已经关闭
                if [[ "$new_status" == "shut off" ]]; then
                    # 记录虚拟机成功关闭的日志
                    echo "$(date '+%Y-%m-%d %H:%M:%S') 虚拟机 $vm 已成功关闭。" | sudo tee -a $log_file  
                    break
                elif ((timeout >= max_timeout)); then
                    # 超时处理
                    echo "$(date '+%Y-%m-%d %H:%M:%S') 虚拟机 $vm 关闭超时。" | sudo tee -a $log_file  
                    break
                else
                    # 等待5秒后再次检查状态
                    sleep 2
                    ((timeout+=5))
                fi
            done
        else
            # 如果关闭虚拟机失败，则记录失败的日志
            echo "$(date '+%Y-%m-%d %H:%M:%S') 虚拟机 $vm 关闭失败。" | sudo tee -a $log_file   
        fi
    fi
done

# 所有虚拟机都已经关闭，记录日志
echo "$(date '+%Y-%m-%d %H:%M:%S') 所有虚拟机已关闭。" | sudo tee -a $log_file  

# 再次遍历所有虚拟机，记录最终状态
for vm in $vms_all; do
    status=$(virsh domstate "$vm")
    # 记录每个虚拟机的最终状态
    echo "$(date '+%Y-%m-%d %H:%M:%S') 虚拟机 $vm 的最终状态为：$status" | sudo tee -a $log_file 

done
echo "" | sudo tee -a $log_file
echo "" | sudo tee -a $log_file 
