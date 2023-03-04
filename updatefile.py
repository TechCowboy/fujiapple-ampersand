import pyautogui as p
import os
import time
from subprocess import Popen, PIPE
import datetime

filename   = [ "FUJIAPPLE"]
pconvert   = [ 0x2000 ] # If entry is zero, it will get the address from pfilenames entry (dos 3 file)
pfilenames = [ "FUJIAPPLE"  ]
pfilenamed = [ "FUJIAPPLE" ]
dosdisk   = "FUJIAPPLE.dsk"
prodisk   = "FUJIAPPLE.po"

global checked

checked = False

my_speed = 0.1
tab_speed = 0.2

debug = False

def erase_field():
    
    p.keyDown("ctrl")
    p.press("a")
    p.keyUp("ctrl")
    time.sleep(my_speed)
    p.press('del')
    time.sleep(my_speed)
    

def do_tabs(count):
    for i in range(count):
        if debug:
            print(f"{i+1}/{count} tab ", end='')
        p.press("tab")
        time.sleep(tab_speed)
    if debug:
        print()
    time.sleep(my_speed)
    
def find_file(file):
    global checked
    
    if debug:
        print(f"find_file {file}")
    
    if debug:
        print("alt-e")
    p.press("alt")
    time.sleep(my_speed)
    p.press("E")
    time.sleep(my_speed)
    if debug:
        print("F")
    p.press("F")
    time.sleep(my_speed)
    
    p.keyDown("alt")
    p.press("n")
    p.keyUp("alt")
    time.sleep(my_speed)

    erase_field()
        
    if debug:
        print(f"Searching for '{file}'")    
    p.write(file)

    time.sleep(my_speed)
    if not checked:
        if debug:
            print("not checked")
            print("alt-w")
        p.keyDown("alt")
        p.press("W")
        p.keyUp("alt")

        time.sleep(my_speed)
        checked = True 
        
    else:
        if debug:
            print("already checked")

    p.keyDown("alt")
    p.press("F")
    p.keyUp("alt")
    do_tabs(1)
    p.press("enter")
        
    time.sleep(0.5)

def add_file(files):

    for file in files:
    
        if debug:
            print(f"add_file {file}")
        
            print("alt-a")
        p.press("alt")
        p.press("A")
        time.sleep(my_speed)
        if debug:
            print("F")
        p.press("F")
        time.sleep(0.4)
        
        p.keyDown("alt")
        p.press("d")
        p.keyUp("alt")
        time.sleep(my_speed)
        
        p.keyDown("alt")
        p.press("n")
        p.keyUp("alt")
        time.sleep(my_speed)
        			
        erase_field()
        time.sleep(my_speed)
        
        if debug:
            print(f"add file '{file}'")
        p.write(file)

        time.sleep(my_speed)
        
        p.press("enter")
        time.sleep(0.5)


def prodos_bin_file(files, address):

    for file in files:
        find_file(file)
        
        if debug:
            print(f"bin_file {file}")
        
            print("alt-a")
        p.press("alt")
        p.press("A")
        time.sleep(my_speed)
        
        if debug:
            print("a")
        p.press("a")
        time.sleep(my_speed)
        
        
        do_tabs(4)
        '''
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
        '''
        p.press('b')
        time.sleep(my_speed)
        p.press('b')
        time.sleep(my_speed)
        
        do_tabs(1)
        
        erase_field()
        p.write(address)
        time.sleep(my_speed)
        
        if debug:
            print("enter")
        p.press("enter")
        time.sleep(my_speed)
        
        if debug:
            print("enter")
        p.press("enter")
        time.sleep(0.5)

def dos_bin_file(files):

    for file in files:
        find_file(file)
        
        if debug:
            print(f"bin_file {file}")
        
            print("alt-a")
        p.press("alt")
        p.press("A")
        time.sleep(my_speed)
        if debug:
            print("a")
        p.press("a")
        time.sleep(my_speed)
           
        do_tabs(4)
        
        for i in range(10):
            if debug:
                print(f"{i+1}/10 up ", end='')
            p.press("up")
            time.sleep(tab_speed)
        if debug:
            print()
        
        for i in range(1):
            if debug:
                print(f"{i+1}/1 down ", end='')
            p.press("down")
            time.sleep(my_speed)
        if debug:
            print()
        
        p.press("tab")
        
        if debug:
            print("enter")
        p.press("enter")
        time.sleep(my_speed)
        
        if debug:
            print("enter")
        p.press("enter")
        time.sleep(0.5)
        

def del_file(files):

    for file in files:
        time.sleep(0.5)

        find_file(file)
        
        if debug:
            print(f"del_file {file}")
            print("alt-a")
        p.press("alt")
        p.press("A")
        time.sleep(my_speed)
        if debug:
            print("d")
        p.press("d")
        time.sleep(0.5)
        
        p.press("enter")
        p.sleep(0.5)

def leave():
    if debug:
        print("alt-f")
    p.press("alt")
    p.press("F")
    time.sleep(my_speed)
    if debug:
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

    time.sleep(1)
    print("**************************************")
    print("***** click the Ciderpress window ****")
    print("**************************************")
    
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

def update_version(file, version_signature, new_version):
    
    updated = False
    
    fp = open(file, "rb")
    contents=fp.read()
    fp.close()
    
    content = bytearray(contents)
    
    version_signature = bytearray(version_signature.encode("ascii"))
    new_version = bytearray(new_version.encode("ascii"))
    position = contents.find(version_signature)

    if position > 0:
        for i in range(len(new_version)):
            content[position+i] = new_version[i]
            
        fp = open(file, "wb")
        fp.write(content)
        fp.close()
        updated = True
    else:
        print("version signature not found")
    
    return updated
    
if __name__ == "__main__":
    
    do_dos = False
    
    
    if do_dos:
        quit_program = False
        start_program = not quit_program
    
        DOS3_version(dosdisk, filename)
    else:
        start_program = True
    
    version_signature = "YYYYMMDD.HHMM"
    now = datetime.datetime.now()
    new_version = now.strftime('%Y%m%d.%H%M')
    
    
        
    for i in range(len(pfilenames)):
        
        updated = update_version(pfilenames[i], version_signature, new_version)
        if not updated:
            new_version = "Version not updated"
        else:    
            address = pconvert[i]
            if address == 0:
                address = convert_dos_bin_to_prodos(pfilenames[i], pfilenamed[i])
            else:
                address = hex(address)[2:]
            ProDOS_version(prodisk, [ pfilenamed[i] ], address)
    
        if updated:
            print("Copy to TNFS server...")

            cmd = "cp "+prodisk + " /run/user/1000/gvfs/smb-share:server=192.168.2.21,share=tnfs/apple"
            print(cmd)
            os.system(cmd)
            
            if do_dos:
                cmd = "cp "+dosdisk + " /run/user/1000/gvfs/smb-share:server=192.168.2.21,share=tnfs/apple"
                print(cmd)
                os.system(cmd)


            print("Completed.")
        print(f"New version: {new_version}")

