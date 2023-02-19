import pyautogui as p
import os
import time
from subprocess import Popen, PIPE

filename = "FUJIAPPLE"
disk = "MASTER.DSK"

global checked

checked = False

my_speed = 0.1

def find_file(file):
    global checked
    
    print("alt-e")
    p.press("alt")
    p.press("E")
    time.sleep(my_speed)
    print("F")
    p.press("F")

    p.write(file)
    if not checked:
        print("not checked")
        print("alt-w")
        p.keyDown("alt")
        p.press("W")
        p.keyUp("alt")
        p.press("enter")
        time.sleep(my_speed)
        checked = True

        for i in range(4):
            p.press("tab")
            print(f"{i+1} tab")
            time.sleep(0.1)
    else:
        print("already checked")
        p.press("enter")
        for i in range(5):
            p.press("tab")
            print(f"{i+1} tab")
            time.sleep(0.1)

    p.press("enter")
    time.sleep(my_speed)


def bin_file(file):

    print("alt-a")
    p.press("alt")
    p.press("A")
    time.sleep(my_speed)
    print("a")
    p.press("a")
    time.sleep(my_speed)
    
    
    for i in range(4):
        print(f"{i+1} tab")
        p.press("tab")
        time.sleep(0.1)
        
    for i in range(10):
        print(f"{i+1} up")
        p.press("up")
        time.sleep(0.1)
        
    print("down")
    p.press("down")
    time.sleep(my_speed)
    
    print("enter")
    p.press("enter")
    time.sleep(my_speed)
    
    print("enter")
    p.press("enter")
    time.sleep(my_speed)
        

#os.system("wine /home/ndavie/Documents/Windows\ Programs/CiderPress/ciderpress.exe /home/ndavie/Documents/Projects/fujiapple-ampersand/" + disk + " &")

cmd_str = "wine /home/ndavie/Documents/Windows\ Programs/CiderPress/ciderpress.exe /home/ndavie/Documents/Projects/fujiapple-ampersand/" + disk

proc = Popen([cmd_str], shell=True,
             stdin=None, stdout=None, stderr=None, close_fds=True)

print("click the title bar")

time.sleep(1)
t = 5
while t > 0:
    print(f"{t} ", end='')
    time.sleep(1)
    t -= 1
    
print()

find_file(filename)

print("press del")
p.press("del")
time.sleep(my_speed)
p.press("enter")
time.sleep(my_speed)

print("alt-a")
p.press("alt")
p.press("A")
time.sleep(my_speed)
print("F")
p.press("F")
time.sleep(my_speed)

for i in range(7):
    p.press("tab")
    time.sleep(0.1)
    
p.write(filename)
time.sleep(0.1)
p.press("enter")


find_file(filename)
bin_file(filename)
                
                
print("alt-f")
p.press("alt")
p.press("F")
time.sleep(my_speed)
print("E")
p.press("E")
time.sleep(my_speed)


print("STOPPED.")

