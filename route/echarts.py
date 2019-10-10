import psutil
from flask import request,render_template,redirect,send_file, send_from_directory,url_for,session,make_response
from index import app
import json
import platform,os,datetime,sys,time
from .login import cklogin
#获取系统信息,返回给前端生成pie图表
@app.route('/GetPie',methods=['POST'])
@cklogin()
def GetPie():
    try:
        #cpu
        cpuCount = psutil.cpu_count(logical=False)  #CPU核心
        cpuPercent = psutil.cpu_percent(0.5)        #使用率
        cpufree = round(100 - cpuPercent, 2)        #CPU空余
        #内存
        m = psutil.virtual_memory()          #内存信息
        memoryTotal = round(m.total/(1024.0*1024.0*1024.0), 2) #总内存
        memoryUsed = round(m.used/(1024.0*1024.0*1024.0), 2)   #已用内存
        memoryFree = round(memoryTotal - memoryUsed,2)  #剩余内存

        #磁盘
        io = psutil.disk_partitions()
        if platform.system().upper() == 'WINDOWS':
            del io[-1]
        diskCount = len(io)
        diskTotal = 0   #总储存空间大小
        diskUsed = 0    #已用
        diskFree = 0    #剩余
        for i in io:
            try:
                #若windows下插入U盘,访问U盘磁盘时,会出现"设备未就绪的错误"
                o = psutil.disk_usage(i.mountpoint)
                diskTotal += int(o.total/(1024.0*1024.0*1024.0))
                diskUsed += int(o.used/(1024.0*1024.0*1024.0))
                diskFree += int(o.free/(1024.0*1024.0*1024.0))
            except:
                pass
        resJson = []
        resJson.append({
                'ttl':'CPU状态',
                'subtext':str(cpuCount)+'核心',
                'keys':['使用率','空闲'],
                'json':[{'value':cpuPercent,'name':'使用率'},{'value':cpufree,'name':'空闲'}],
                'pieBox':'echartsCPU',
                'suffix':'%'

            })
        resJson.append(
            {
                'ttl':'内存状态',
                'subtext':'总内存' + str(memoryTotal) + 'G',
                'keys':['已用','剩余'],
                'json':[{'value':memoryUsed,'name':'已用'},{'value':memoryFree,'name':'剩余'}],
                'pieBox':'echartsMemory',
                'suffix':'G'
            })
        resJson.append(
            {
                'ttl':'磁盘状态',
                'subtext':str(diskCount) + '个分区.' + '共' + str(diskTotal) + 'G',
                'keys':['已使用','未使用'],
                'json':[{'value':diskUsed,'name':'已使用'},{'value':diskFree,'name':'未使用'}],
                'pieBox':'echartsDisk',
                'suffix':'G'
            })
        #计算开机时间
        sd=(datetime.datetime.now() - datetime.datetime.fromtimestamp(psutil.boot_time())).seconds #当前时间减去开机时间的秒
        m, s = divmod(sd, 60)    #m是分钟,余数s是秒
        h, m = divmod(m, 60)     #分钟计算出小时
        systim = "%02d小时%02d分钟" % (h, m)
        sysinfo = [
        '系统信息：' + platform.platform() + '-' + platform.architecture()[0]
        ]
        try:
            sysinfo.append(platform.uname().processor)
        except:
            pass
        sysinfo.append('已开机运行了'+systim)
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(e)})
    else:
        return json.dumps({'resultCode':0,'result':resJson,'sysinfo':sysinfo})
@app.route('/GetLine',methods=['POST'])
def GetLine():
    try:
        net = psutil.net_io_counters() 
        bytesRcvd = (net.bytes_recv / 1024)
        bytesSent = (net.bytes_sent / 1024)
        time.sleep(0.2)
        net = psutil.net_io_counters()  
        newBytesRcvd = (net.bytes_recv / 1024)
        newBytesSent = (net.bytes_sent / 1024)
        realTimeRcvd = (newBytesRcvd - bytesRcvd)*5
        realTimeSent = (newBytesSent - bytesSent)*5
        tim = time.strftime('%H:%M:%S',time.localtime())
        return json.dumps({
            'resultCode':0,
            'realTimeSent':realTimeSent,
            'realTimeRcvd':realTimeRcvd,
            'BytesSent':newBytesSent,
            'BytesRcvd':newBytesRcvd,
            'tim':tim
            })
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(e)})