import psutil
import time
from index import sql
from threading import Thread
from config.config import ResState,ResSaveDay,ResInv
class writeResTask(object):
    def __new__(cls):
        if not hasattr(cls,'instance'):
            cls.instance = super(writeResTask,cls).__new__(cls)
        return cls.instance
    def __init__(self):
        self.state = ResState
        self.saveDay = ResSaveDay
        self.inv = ResInv
        self.createTask()
    def createTask(self):
        t=Thread(target=self.write)
        t.setDaemon(True)
        t.start()
    def write(self):
        memoryTotal = round(psutil.virtual_memory().total/(1024.0*1024.0*1024.0), 2)
        while True :
            time.sleep(self.inv)
            if not self.state:
                continue
            #CPU信息
            cpuUsed = psutil.cpu_percent(1)
            #内存信息 
            memoryInfo = psutil.virtual_memory()
            memoryUsedSize = round(memoryInfo.used / (1024.0*1024.0*1024.0),2)
            memoryUsed = round(memoryUsedSize/memoryTotal,2)*100
            #网络io
            net = psutil.net_io_counters()
            bytesRcvd = (net.bytes_recv / 1024)
            bytesSent = (net.bytes_sent / 1024)
            time.sleep(1)
            net = psutil.net_io_counters()
            realTimeRcvd = round(((net.bytes_recv / 1024) - bytesRcvd),2)
            realTimeSent = round(((net.bytes_sent / 1024) - bytesSent),2)
            tim = time.strftime('%H:%M:%S',time.localtime())
            realTimeInfo = {
            'cpu':{'cpuUsed':cpuUsed},
            'memory':{'memoryUsed':memoryUsed},
            'net':{'rcvd':realTimeRcvd,'send':realTimeSent}
            }
            sql.insertInfo(info = realTimeInfo)
            sql.deleteInfo(day=self.saveDay)
            
