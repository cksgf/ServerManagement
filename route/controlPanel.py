from index import app,sql,url
from flask import request,render_template
import json
from lib.writeRes import writeResTask
from config.config import visitDay
import platform,datetime,psutil,re,requests
import socket
from .login import cklogin
NAThost = '未获取'
netIP = '未获取'
PCname = socket.gethostname()
try:
    ipContent = requests.get('http://pv.sohu.com/cityjson?ie=utf-8').text
    ipContentJson = json.loads('{'+re.findall(r'{(.+?)}',ipContent)[0]+"}")
    netIP = ipContentJson.get('cip')
except:
    pass
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(('8.8.8.8', 80))
    NAThost = s.getsockname()[0]
except:
    pass
finally:
    s.close()
ResTask = writeResTask()
visitDay= visitDay
@app.route('/ControlPanel',methods=['POST','GET'])
@cklogin()
def ControlPanel():
    if request.method == 'GET':
        return render_template('ControlPanel.html',
            inv = ResTask.inv,
            saveDay=ResTask.saveDay,
            state = ('checked=""' if ResTask.state else ''),
            visitDay = visitDay,
            platform = platform.platform(),
            NETHOST = netIP,
            NATHOST = NAThost,
            PCname = PCname,
            bootTime = datetime.datetime.fromtimestamp(psutil.boot_time()).strftime("%Y-%m-%d,%H:%M:%S")
            )
    sqlResult = sql.selectInfo(day = visitDay)
    if not sqlResult[0]:
        return json.dumps({'resultCode':1,'result':sqlResult[1]})
    return json.dumps({'resultCode':0,'result':sqlResult[1]})


@app.route('/ControlPanelConfig',methods=['POST'])
@cklogin()
def ControlPanelConfig():
    state = request.values.get('state')
    saveDay = request.values.get('saveDay')
    inv = request.values.get('inv')
    reqVisitDay = request.values.get('visitDay')
    if reqVisitDay:
        reqVisitDay = int(reqVisitDay)
        if reqVisitDay < 1 :
            return json.dumps({'resultCode':1,'result':'最少查看1天'})
        global visitDay
        visitDay = reqVisitDay
    if inv:
        inv = int(inv)
        if inv < 1 :
            return json.dumps({'resultCode':1,'result':'最少间隔1秒'})
        ResTask.inv=inv
    if saveDay:
        saveDay = int(saveDay)
        if saveDay < 1 :
            return json.dumps({'resultCode':1,'result':'最少储存一天,或者您可以选择关闭此功能'})
        ResTask.saveDay=saveDay
    ResTask.state=(True if (state == 'on') or (state == 'true') else False)
    return json.dumps({'resultCode':0,'result':'success'})
