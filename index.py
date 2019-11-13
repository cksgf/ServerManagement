from flask import Flask,render_template,request,jsonify
import time,os,requests,platform,json
from config.config import port,NATPenetration,NATPenetrationPort
from sqlitedb.sqlitedb import sqlClass
from threading import Thread
sql = sqlClass()
app=Flask(__name__)
app.secret_key='1996-05-16'
from route.login import cklogin
url=[]
@app.route('/',methods=['GET','POST'])
@cklogin()
def index():
    if request.method == 'GET':
        return render_template('index.html',url=url)
    else:
        return jsonify(url)
if __name__ == '__main__':
    from route import *
    if NATPenetration:
        from lib.slaver import main_slaver
        import uuid
        try:
            NATData = requests.post('http://'+NATPenetration+':'+str(NATPenetrationPort)+'/CreatDriver',
            data={'driverID':
            platform.platform() + '__MAC:_' + uuid.UUID(int = uuid.getnode()).hex[-12:]
            }).text
        except:
            pass#若出错,请检查你的内网穿透服务端是否正确配置
        else:
            NATData = json.loads(NATData).get('result')
            WANIP = NATPenetration+':'+str(NATData[1]) #内网穿透后,外网可访问的IP及端口
            connectIP = NATPenetration+':'+str(NATData[0])
            pwd = NATData[2]
            t=Thread(target=main_slaver, args=(connectIP,'127.0.0.1:'+str(port),pwd))
            t.setDaemon(True)
            t.start()
    app.run(host='0.0.0.0',port=port,debug = False)
