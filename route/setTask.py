from flask import request,render_template,redirect,send_file, send_from_directory,url_for,session,make_response
import time
from index import app,url
import json
import os
import time,random
from lib.task import taskset
from .login import cklogin
url.append( {
        "title": "计划任务",
        "href": "/Task",
    })
task = taskset()

@app.route('/Task',methods=['GET','POST'])
@cklogin()
def TaskHome():
    return render_template('Task.html')

@app.route('/CreatTask',methods=['POST'])
@cklogin()
def CreatTask():
    data=request.values.to_dict()
    if data['type'] == 'week':
        if data['week'] == '7':
            data['week'] = '0'
    elif data['type'] == 'month':
        if data['day'][0] == '0':
            data['day'] = data['day'][1:]
    elif data['type'] == 'once':
        if data['month'][0] == '0':
            data['month'] = data['month'][1:]
        if data['day'][0] == '0':
            data['day'] = data['day'][1:]
    data['creatTime'] = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime())
    data['taskID'] = str(time.time()+random.random())
    try:
        task.CreatTask(data)
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(e)})
    return json.dumps({'resultCode':0,'result':'success'})

@app.route('/SelectTask',methods=['POST'])
@cklogin()
def SelectTask():
    return json.dumps({'resultCode':0,'result':task.GetTaskList()})


@app.route('/DeleteTask',methods=['POST'])
@cklogin()
def DeleteTask():
    try:
        taskid = request.values.get('taskid')
        task.DeleteTask(taskid)
    except Exception as e:
        return json.dumps({'resultCode':1,'result':str(e)})
    return json.dumps({'resultCode':0,'result':task.GetTaskList()})
