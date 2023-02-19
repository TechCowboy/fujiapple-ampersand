import pyautogui as p
import os
import time
from subprocess import Popen, PIPE

filename  = "FUJIAPPLE"
pfilename = "FUJIAPPLEP"
dosdisk   = "FUJIAPPLE.dsk"
prodisk   = "FUJIAPPLE.po"

global checked

checked = False

my_speed = 0.1
tab_speed = 0.2

def erase_field():
    
    p.keyDown("ctrl")
    p.press("a")
    p.keyUp("ctrl")
    time.sleep(my_speed)
    p.press('del')
    time.sleep(my_speed)
    

def do_tabs(count):
    for i in range(count):
        print(f"{i+1}/{count} tab ", end='')
        p.press("tab")
        time.sleep(tab_speed)
    print()
    time.sleep(my_speed)
    
def find_file(file):
    global checked
    
    print(f"find_file {file}")
    
    print("alt-e")
    p.press("alt")
    time.sleep(my_speed)
    p.press("E")
    time.sleep(my_speed)
    print("F")
    p.press("F")
    time.sleep(my_speed)

    erase_field()
        
    p.write(file)
    time.sleep(my_speed)
    if not checked:
        print("not checked")
        print("alt-w")
        p.keyDown("alt")
        p.press("W")
        p.keyUp("alt")

        time.sleep(my_speed)
        checked = True 
        
    else:
        print("already checked")

    p.keyDown("alt")
    p.press("F")
    p.keyUp("alt")
    do_tabs(1)
    p.press("enter")
        
    time.sleep(0.5)

def add_file(file):
    
    print(f"add_file {file}")
    print("alt-a")
    p.press("alt")
    p.press("A")
    time.sleep(my_speed)
    print("F")
    p.press("F")
    time.sleep(my_speed)
    
    p.keyDown("alt")
    p.press("n")
    p.keyUp("alt")
    
    erase_field()
    
    print(f"write {file}")
    p.write(file)
    
    time.sleep(my_speed)
    
    p.press("enter")
    time.sleep(0.5)


def prodos_bin_file(file, address):

    find_file(file)
    
    print(f"bin_file {file}")
    
    print("alt-a")
    p.press("alt")
    p.press("A")
    time.sleep(my_speed)
    
    print("a")
    p.press("a")
    time.sleep(my_speed)
    
    
    do_tabs(4)
    
    for i in range(10):
        print(f"{i+1}/10 up ", end='')
        p.press("up")
        time.sleep(tab_speed)
    print()
    
    for i in range(6):
        print(f"{i+1}/6 down ", end='')
        p.press("down")
        time.sleep(my_speed)
    print()
    
    do_tabs(1)
    
    erase_field()
    p.write(address)
    time.sleep(my_speed)
    
    print("enter")
    p.press("enter")
    time.sleep(my_speed)
    
    print("enter")
    p.press("enter")
    time.sleep(0.5)

def dos_bin_file(file):

    find_file(file)
    
    print(f"bin_file {file}")
    
    print("alt-a")
    p.press("alt")
    p.press("A")
    time.sleep(my_speed)
    print("a")
    p.press("a")
    time.sleep(my_speed)
       
    do_tabs(4)
    
    for i in range(10):
        print(f"{i+1}/10 up ", end='')
        p.press("up")
        time.sleep(tab_speed)
    print()
    
    for i in range(1):
        print(f"{i+1}/1 down ", end='')
        p.press("down")
        time.sleep(my_speed)
    print()
    
    p.press("tab")
    
    print("enter")
    p.press("enter")
    time.sleep(my_speed)
    
    print("enter")
    p.press("enter")
    time.sleep(0.5)
        

def del_file(file):

    time.sleep(0.5)

    find_file(file)
    
    print(f"del_file {file}")
    print("alt-a")
    p.press("alt")
    p.press("A")
    time.sleep(my_speed)
    print("d")
    p.press("d")
    time.sleep(0.5)
    
    p.press("enter")
    p.sleep(0.5)

def leave():
    print("alt-f")
    p.press("alt")
    p.press("F")
    time.sleep(my_speed)
    print("E")
    p.press("E")
    time.sleep(my_speed)
        

def DOS3_version(disk, filename):
    #os.system("wine /home/ndavie/Documents/Windows\ Programs/CiderPress/ciderpress.exe /home/ndavie/Documents/Projects/fujiapple-ampersand/" + disk + " &")

    cmd_str = "wine /home/ndavie/Documents/Windows\ Programs/CiderPress/ciderpress.exe /home/ndavie/Documents/Projects/fujiapple-ampersand/" + disk

    proc = Popen([cmd_str], shell=True,
             stdin=None, stdout=None, stderr=None, close_fds=True)

    print("click the title bar")

    t = 5
    while t > 0:
        print(f"{t} ", end='')
        time.sleep(1)
        t -= 1
    
    print()

    del_file(filename)

    add_file(filename)

    dos_bin_file(filename)

    leave()
        
def ProDOS_version(disk, filename, address):
    #os.system("wine /home/ndavie/Documents/Windows\ Programs/CiderPress/ciderpress.exe /home/ndavie/Documents/Projects/fujiapple-ampersand/" + disk + " &")

    cmd_str = "wine /home/ndavie/Documents/Windows\ Programs/CiderPress/ciderpress.exe /home/ndavie/Documents/Projects/fujiapple-ampersand/" + disk

    proc = Popen([cmd_str], shell=True,
             stdin=None, stdout=None, stderr=None, close_fds=True)

    print("click the title bar")
    
    checked = False

    t = 5
    while t > 0:
        print(f"{t} ", end='')
        time.sleep(1)
        t -= 1
    
    print()

    del_file(filename)

    add_file(filename)

    prodos_bin_file(filename, address)

    leave()
    


def convert_dos_bin_to_prodos(src, tgt):
    
    file_in = open(src, 'rb')
    address = file_in.read(2)
    print(address)
    
    dec_address = address[1]*256 + address[0]

    address = hex(dec_address)[2:].zfill(4)
        
    size    = file_in.read(2)
    print(size)
    content = file_in.read()
    file_in.close()
    
    file_out = open(tgt, 'wb')
    file_out.write(content)
    file_out.close()
    
    return address


if __name__ == "__main__":
    
    do_dos = True
    
    if do_dos:
        quit_program = False
        start_program = not quit_program
    
        DOS3_version(dosdisk, filename)
    else:
        start_program = True
        
    address = convert_dos_bin_to_prodos(filename, pfilename)
    ProDOS_version(prodisk, pfilename, address)
    
    print("Copy to TNFS server...")

    os.system("cp "+prodisk + " /run/user/1000/gvfs/smb-share:server=192.168.2.21,share=tnfs/apple")
    os.system("cp "+dosdisk + " /run/user/1000/gvfs/smb-share:server=192.168.2.21,share=tnfs/apple")


    print("STOPPED.")

