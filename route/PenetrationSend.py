import psutil
from flask import request,render_template,redirect,send_file, send_from_directory,url_for,session,make_response
from index import app
import json
import platform
@app.route('/PenetrationSend',methods=['POST'])
def PenetrationSendFunc():
    m = psutil.virtual_memory()
    io = psutil.disk_partitions()
    if platform.system().upper() == 'WINDOWS':
        del io[-1]
    diskCount = len(io)
    diskTotal = 0
    diskUsed = 0
    for i in io:
        #windows下插入U盘,访问U盘时会出现"设备未就绪"
        try:
            o = psutil.disk_usage(i.mountpoint)
            diskTotal += o.total
            diskUsed += o.used
        except:
            pass
    response = make_response(json.dumps({
        'cpu':psutil.cpu_percent(0.5),
        'memory':round(m.used/m.total, 3),
        'disk':round(diskUsed/diskTotal,3)
        }))
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Origin'] = request.environ['HTTP_ORIGIN']
    response.headers['Access-Control-Allow-Methods'] = 'POST'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Requested-With'
    return response