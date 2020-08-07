from luma.core.interface.serial import i2c, spi
from luma.core.render import canvas
from luma.oled.device import ssd1309
from luma.core.virtual import viewport
from time import sleep
import subprocess
import signal, os

import errno

class Status:
    users_connected_size = 0
    devices_connected_size = 0
    longest_line_size = 0
    max_offset = 0
    users_connected_str = "Connected users: 0"
    devices_connected_str = "Connected devices: 0"
    enter = 0

status = Status()

def get_ip():
    p = subprocess.Popen(("hostname", "-I"),stdout=subprocess.PIPE)
    ip = subprocess.check_output(('awk', "{print $1}"), stdin=p.stdout, universal_newlines=True)
    return (ip)

ip_str = "Host: " + get_ip()


users_status_file = "/tmp/server_smarthome/status/users"
devices_status_file = "/tmp/server_smarthome/status/devices"
new_users_dir = "/tmp/server_smarthome/new_users/"
serial = spi(device=0, port=0)
device = ssd1309(serial)
virtual = viewport(device, width=100000, height=100)

pid = os.getpid()

pid_file = "/tmp/server_smarthome/server_python_display_pid"
if not os.path.exists(os.path.dirname(pid_file)):
    try:
        os.makedirs(os.path.dirname(pid_file))
    except OSError as exc: # Guard against race condition
        if exc.errno != errno.EEXIST:
            raise

with open(pid_file, "w") as f:
    f.write(str(pid))
    f.close()

print("pid: ", pid)
def get_users_devices_connected():
    try:
        f = open(users_status_file)
        status.users_connected_size = f.read()
        status.users_connected_str = "Connected users: " + str(status.users_connected_size)
    except IOError:
        print("File not accessible")
    finally:
        f.close()
    try:
        f = open(devices_status_file)
        status.devices_connected_size = f.read()
        status.devices_connected_str = "Connected devices: " + str(status.devices_connected_size)
    except IOError:
        print("File not accessible")
    finally:
        f.close()


def check_longest_length(string_to_check):
    length_to_check = len(string_to_check)
    if (length_to_check > status.longest_line_size):
        status.longest_line_size = length_to_check

def draw_default_output():
    # virtual.clear()
    virtual.set_position((0, 0))
    status.longest_line_size = 0
    get_users_devices_connected()
    check_longest_length(ip_str)
    check_longest_length(status.users_connected_str)
    check_longest_length(status.devices_connected_str)
    status.max_offset = status.longest_line_size + 1 - int((128/6))
    with canvas(virtual) as draw:
        draw.text((0, 0), ip_str, fill="white")
        draw.text((0, 10), status.users_connected_str, fill="white")
        draw.text((0, 20), status.devices_connected_str, fill="white")

def set_offset_position():
    if status.max_offset > 0:
        for char_index in range(status.max_offset):
            virtual.set_position((char_index * 6, 0))
            sleep(0.3)
        sleep(2)
        for x in range(char_index + 1):
            virtual.set_position(((char_index - x) * 6, 0))
            sleep(0.3)
        sleep(2)
    else:
        sleep(4)

def draw_new_users():
    for filename in os.listdir(new_users_dir):
        status.longest_line_size = 0
        try:
            f = open(new_users_dir + filename, 'r')
            text = f.read()
            f.close()
            credentials = text.split('\n')
            name = "name: " + credentials[0]
            password = "password: " + credentials[1]
            check_longest_length(ip_str)
            check_longest_length(name)
            check_longest_length(password)
            # virtual.clear()
            virtual.set_position((0, 0))
            with canvas(virtual) as draw:
                draw.text((0, 0), ip_str, fill="white")
                draw.text((0, 10), name, fill="white")
                draw.text((0, 20), password, fill="white")
            status.max_offset = status.longest_line_size + 1 - int((128/6))
            i = 0
            while i < 2:
                set_offset_position()
                i += 1
        except IOError:
            print("File not accessible")
        finally:
            f.close()
enter = 0

def handler(signum, frame):
    status.enter += 1
    if os.path.isdir(new_users_dir) and status.enter == 1:
        while len(os.listdir(new_users_dir)) != 0:
            draw_new_users()
        status.enter = 0
    if os.path.isdir(new_users_dir) == False or len(os.listdir(new_users_dir)) == 0:
        draw_default_output()
        status.enter = 0

signal.signal(signal.SIGHUP, handler)


draw_default_output()

while True:
    # new_ip = get_ip()
    # if ip != new_ip:
    #     ip = new_ip

    set_offset_position()
    continue