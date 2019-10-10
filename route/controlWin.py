import platform
if 'WINDOWS' in platform.platform().upper():
    from flask import render_template, Response,request
    import time
    import math
    import json,subprocess
    from index import app,url
    from .login import cklogin
    from PIL import ImageGrab,Image
    import pyautogui
    url.append({'title': 'Windows远程', 'href': '/control/windows'})
    RATE = 2
    @app.route('/control/windows')
    @cklogin()
    def controlWindows():
        return render_template('controlWin.html')
    def getScreen():
        while True:
            time.sleep(0.08)
            try:
                img = ImageGrab.grab()
            except :
                return (b'--frame\r\nContent-Type: image/jpeg\r\n\r\n  \r\n')
            img = img.resize((int(img.size[0]/RATE),int(img.size[1]/RATE)), Image.ANTIALIAS)
            img.save('temp/1.jpg')
            with open('temp/1.jpg','rb') as c:
                yield (b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + c.read() + b'\r\n')
    @app.route('/control/screen')
    @cklogin()
    def controlScreen():
        return Response(getScreen(),mimetype='multipart/x-mixed-replace; boundary=frame')
    @app.route('/control/mouse',methods=['POST'])
    @cklogin()
    def controlMouse():
        x = int(request.values.get('x'))*RATE
        y = int(request.values.get('y'))*RATE
        clickButton = request.values.get('button','left')
        pyautogui.click(x=x, y=y, button=clickButton)
        return ''
    @app.route('/control/keyword',methods = ['POST'])
    @cklogin()
    def controlKeyword():
        types = request.values.get('types')
        if types == 'chr':
            pyautogui.typewrite(request.values.get('chr'))
        elif types == 'key':
            key=[i for i in json.loads(request.values.get('key')) if i != '']
            pyautogui.hotkey(*key)
        return ''
    @app.route('/control/moveTo',methods=['POST'])
    @cklogin()
    def controlMoveTo():
        ox = int(request.values.get('ox'))*RATE
        oy = int(request.values.get('oy'))*RATE
        x = int(request.values.get('x'))*RATE
        y = int(request.values.get('y'))*RATE
        pyautogui.moveTo(ox, oy, duration=0.1)
        moveTime = math.sqrt(abs(ox-x)**2+abs(oy-y)**2)/1080 #根据移动距离计算时间,此处为移动1080px需要1秒,可自行更改
        pyautogui.dragTo(x, y, duration=(moveTime if moveTime > 0.3 else 0.3))
        return ''
    @app.route('/control/RunShell',methods=['POST'])
    @cklogin()
    def controlRunShell():
        shell = request.values.get('shell')
        subprocess.Popen(shell,shell=True)
        return json.dumps({'resultCode':0})
