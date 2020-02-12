from index import app,sql
import json
from functools import wraps
from flask import request,render_template,redirect,url_for,session
from config.config import username,password

#验证登录的修饰器
def cklogin(**kw):
    def ck(func):
        @wraps(func)
        def _ck(*args, **kwargs):
            pwd=session.get('password')
            name=session.get('username')
            if (name == username) and (pwd == password):
                return func(*args, **kwargs)
            else:
                return redirect(url_for('login'))
        return _ck
    return ck

#登陆
@app.route("/login",methods=["POST","GET"])
def login():
    if request.method == 'POST':
        if ( request.values.get('username') == username ) and ( request.values.get('password') == password ):
            session['password']=request.form['password']
            session['username']=request.form['username']
            session['secectList'] = '[]'
            return redirect('/')
        else:
            return render_template('login.html',text = '账号或密码错误!')
    else:
        return render_template('login.html',text = '')

#登出
@app.route("/loginout",methods=["GET"])
def loginout():
    session['password']=None
    session['username']=None
    return render_template('login.html')
