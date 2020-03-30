from flask import request,render_template,redirect,url_for,session,Response
import time
from index import app,sql,url
import json
import os
import base64,chardet
import traceback
from .login import cklogin
url.append( {
        "title": "快捷操作",
        "children": [
        {"title": "快捷按钮","href": "/linkButton"},
        {"title": "快捷文件","href": "/linkFile"},
        ]
    })
@app.route('/linkButton',methods=['GET','POST'])
def linkButton():
    if request.method == 'GET':
        #返回HTML网页
        return render_template('linkButton.html')
    else:
        #返回按钮数据
        allLinkButton = sql.selectLinkButton(CATEGORY='BUTTON')
        return json.dumps({'resultCode':0,'result':allLinkButton})

@app.route('/linkButton/Shell',methods=['GET','POST'])
@cklogin()
def getShell():
    if request.method == 'GET':
        #根据ID号单独获取按钮的SHELL,估计用不到这里
        BTID = request.values.get('BTID')
        result = sql.selectShellForLinkButton(BTID)
        try:
            result = result[0][0]
        except:
            result = '查询的按钮ID不存在'
        return json.dumps({'resultCode':0,'result':result})
    else:
        #更新按钮的shell
        BTID = request.values.get('BTID')
        SHELL = request.values.get('SHELL')
        result = sql.updateLinkButton(BTID,SHELL)
        if result[0]:
            return json.dumps({'resultCode':0})
        else:
            return json.dumps({'resultCode':1,'result':str(result[1])})
@app.route('/linkButton/Create',methods=['POST'])
@cklogin()
def CreateLinkButton():
    LinkButtonDict = {
        'BUTTONNAME' : request.values.get('BUTTONNAME','按钮')[:6],
        'TYPE' : request.values.get('TYPE'),
        'NOTE' : request.values.get('NOTE'),
        'SHELL' : request.values.get('SHELL'),
        'CATEGORY':'BUTTON'
    }
    sqlResult = sql.createLinkButton(LinkButtonDict)
    if sqlResult[0]:
        return json.dumps({'resultCode':0})
    else:
        return json.dumps({'resultCode':1,'result':str(sqlResult[1])})   
@app.route('/linkButton/Delete',methods=['POST'])
@cklogin()
def DeleteLinkButton():
    BTID = request.values.get('BTID')
    if BTID:
        sql.deleteLinkButton(BTID)
        return json.dumps({'resultCode':0})
    else:
        return json.dumps({'resultCode':1,'result':'???'})   
@app.route('/linkButton/Run',methods=['POST'])
@cklogin()
def RunLinkButton():
    BTID = request.values.get('BTID')
    SHELL = request.values.get('SHELL')
    if not BTID:
        return json.dumps({'resultCode':1,'result':'???'}) 
    SearchShell = sql.selectShellForLinkButton(BTID)[0][0]
    if SearchShell != SHELL:
        result = sql.updateLinkButton(BTID,SHELL)
    return json.dumps({'resultCode':0})

@app.route('/linkButton/RunShell',methods=['GET'])
@cklogin()
def RunLinkButtonRunShell():
    BTID = request.values.get('BTID')
    if not BTID:
        return json.dumps({'resultCode':1,'result':'???'}) 
    SearchShell = sql.selectShellForLinkButton(BTID)[0][0]
    import subprocess
    process = subprocess.Popen(
            SearchShell,
            shell=True,
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT)
    def getShellRunInfo(process):
        while process.poll() == None:
            time.sleep(0.1)
            lineData = process.stdout.readline()
            char=chardet.detect(lineData)
            fileCoding = char['encoding']
            if fileCoding == 'GB2312' or not fileCoding or fileCoding == 'TIS-620' or fileCoding == 'ISO-8859-9': fileCoding = 'GBK';
            if fileCoding == 'ascii' or fileCoding == 'ISO-8859-1': fileCoding = 'utf-8';
            if fileCoding == 'Big5': fileCoding = 'BIG5';
            if not fileCoding in ['GBK','utf-8','BIG5']: fileCoding = 'utf-8';
            if not fileCoding:
                fileCoding='utf-8'
            lineData = lineData.decode(fileCoding).encode('utf-8')
            yield lineData.replace(b'\n',b'<br>')
        yield "<br><br>----------------------------------------------<br>执行完成".encode()
    return Response(getShellRunInfo(process))


#--------#
@app.route('/linkFile',methods=['GET','POST'])
def linkFile():
    if request.method == 'GET':
        #返回HTML网页
        return render_template('linkFile.html')
    else:
        #返回按钮数据
        allLinkFile = sql.selectLinkButton(CATEGORY='FILE')
        return json.dumps({'resultCode':0,'result':allLinkFile})
@app.route('/linkFile/Create',methods=['POST'])
@cklogin()
def CreateLinkFile():
    FilePath = request.values.get('SHELL')
    if os.path.isfile(request.values.get('SHELL')):
        pass
    else:
        return json.dumps({'resultCode':1,'result':'文件不存在！'}) 
    LinkFileDict = {
        'BUTTONNAME' : request.values.get('BUTTONNAME','按钮')[:6],
        'TYPE' : request.values.get('TYPE'),
        'NOTE' : request.values.get('NOTE'),
        'SHELL' : request.values.get('SHELL'),
        'CATEGORY':'FILE'
    }
    sqlResult = sql.createLinkButton(LinkFileDict)
    if sqlResult[0]:
        return json.dumps({'resultCode':0})
    else:
        return json.dumps({'resultCode':1,'result':str(sqlResult[1])})   
@app.route('/linkFile/Delete',methods=['POST'])
@cklogin()
def DeleteLinkFile():
    BTID = request.values.get('BTID')
    if BTID:
        sql.deleteLinkButton(BTID)
        return json.dumps({'resultCode':0})
    else:
        return json.dumps({'resultCode':1,'result':'???'})
