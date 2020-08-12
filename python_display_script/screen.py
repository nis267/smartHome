from luma.core.interface.serial import spi
from luma.core.render import canvas
from luma.oled.device import ssd1309
from luma.core.virtual import viewport
from luma.core.virtual import hotspot
from PIL import Image, ImageDraw, ImageFont
from time import sleep
import subprocess
import signal, os
import errno
import threading
import RPi.GPIO as GPIO # Import Raspberry Pi GPIO library
import multiprocessing

try:

    GPIO.setwarnings(False) # Ignore warning for now
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(18, GPIO.IN, pull_up_down=GPIO.PUD_DOWN) # Set pin 10 to be an input pin and set initial value to be pulled low (off)
    GPIO.setup(27, GPIO.IN, pull_up_down=GPIO.PUD_DOWN) # Set pin 10 to be an input pin and set initial value to be pulled low (off)

    class Display:
        users_connected_nbr = 0
        devices_connected_nbr = 0
        first_line = None
        seconde_line = "Connected users: 0"
        third_line = "Connected devices: 0"
        proc = None

    class CurrentUserCredentials:
        filename = None
        dir_list = None
        activated = False

    def get_ip():
        p = subprocess.Popen(("hostname", "-I"),stdout=subprocess.PIPE)
        ip = subprocess.check_output(('awk', "{print $1}"), stdin=p.stdout, universal_newlines=True)
        return (ip)
    
    currentUserCredentials = CurrentUserCredentials()
    display = Display()
    
    fnt = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf")

    users_status_file = "/tmp/server_smarthome/status/users"
    devices_status_file = "/tmp/server_smarthome/status/devices"
    new_users_dir = "/tmp/server_smarthome/new_users/"
    serial = spi(device=0, port=0)
    device = ssd1309(serial)
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

    def get_users_devices_connected():
        try:
            f = open(users_status_file)
            display.users_connected_nbr = f.read()
            display.seconde_line = "Connected users: " + str(display.users_connected_nbr)
            f.close()
        except IOError:
            print("Users status file not accessible")
        try:
            f = open(devices_status_file)
            display.devices_connected_nbr = f.read()
            display.third_line = "Connected devices: " + str(display.devices_connected_nbr)
            f.close()
        except IOError:
            print("Devices status file not accessible")

    def get_default_output():
        # virtual.set_position((0, 0))
        get_users_devices_connected()

    def draw_offset_position(line, line_nbr):
        i = 0
        while i < len(line) + 1 - int((128/6)):
            with canvas(device) as draw:
                if line_nbr == 1:
                    draw.text((0, 0), display.first_line[i:], font=fnt, fill="white")
                else:
                    draw.text((0, 0), display.first_line, font=fnt, fill="white")
                if line_nbr == 2:
                    draw.text((0, 10), display.seconde_line[i:], font=fnt, fill="white")
                else:
                    draw.text((0, 10), display.seconde_line, font=fnt, fill="white")
                if line_nbr == 3:
                    draw.text((0, 20), display.third_line[i:], font=fnt, fill="white")
                else:
                    draw.text((0, 20), display.third_line, font=fnt, fill="white")
                if currentUserCredentials.dir_list.index(currentUserCredentials.filename) == 0 and len(currentUserCredentials.dir_list) > 1:
                    draw.text((105, 50), "next", font=fnt, fill="white")
                elif currentUserCredentials.dir_list.index(currentUserCredentials.filename) >= 1 and currentUserCredentials.dir_list.index(currentUserCredentials.filename) < len(currentUserCredentials.dir_list) - 1:
                    draw.text((0, 50), "previous", font=fnt, fill="white")
                    draw.text((105, 50), "next", font=fnt, fill="white")
                elif len(currentUserCredentials.dir_list) > 1:
                    draw.text((0, 50), "previous", font=fnt, fill="white")
            sleep(0.3)
            i += 1
        sleep(2)

    
    def draw_output_without_offset():
        with canvas(device) as draw:
            draw.text((0, 0), display.first_line, font=fnt, fill="white")
            draw.text((0, 10), display.seconde_line, font=fnt, fill="white")
            draw.text((0, 20), display.third_line, font=fnt, fill="white")
            if currentUserCredentials.dir_list and len(currentUserCredentials.dir_list) > 0:
                if currentUserCredentials.dir_list.index(currentUserCredentials.filename) == 0 and len(currentUserCredentials.dir_list) > 1:
                    draw.text((105, 50), "next", font=fnt, fill="white")
                elif currentUserCredentials.dir_list.index(currentUserCredentials.filename) >= 1 and currentUserCredentials.dir_list.index(currentUserCredentials.filename) < len(currentUserCredentials.dir_list) - 1:
                    draw.text((0, 50), "previous", font=fnt, fill="white")
                    draw.text((105, 50), "next", font=fnt, fill="white")
                elif len(currentUserCredentials.dir_list) > 1:
                    draw.text((0, 50), "previous", font=fnt, fill="white")

    def draw_output():
        enter = False
        while True:
            if (len(display.first_line) + 1 - int((128/6))) > 0:
                enter = True
                draw_offset_position(display.first_line, 1)
            if (len(display.seconde_line) + 1 - int((128/6))) > 0:
                enter = True
                draw_offset_position(display.seconde_line, 2)
            if (len(display.third_line) + 1 - int((128/6))) > 0:
                enter = True
                draw_offset_position(display.third_line, 3)
            if enter == False:
                break
        if enter == False:
            draw_output_without_offset()

    def get_new_user(filename):
        try:
            f = open(new_users_dir + filename, 'r')
            text = f.read()
            f.close()
            credentials = text.split('\n')
            display.seconde_line = "name: " + credentials[0]
            display.third_line = "password: " + credentials[1]
            currentUserCredentials.filename = filename
        except IOError:
            print("File not accessible")
    
    def button_left_callback(channel):
        if currentUserCredentials.dir_list.index(currentUserCredentials.filename) > 0:
            get_new_user(currentUserCredentials.dir_list[currentUserCredentials.dir_list.index(currentUserCredentials.filename) - 1])
            display.proc.terminate()
            display.proc = None

    def button_right_callback(channel):
        if currentUserCredentials.dir_list.index(currentUserCredentials.filename) < len(currentUserCredentials.dir_list) - 1:
            get_new_user(currentUserCredentials.dir_list[currentUserCredentials.dir_list.index(currentUserCredentials.filename) + 1])
            display.proc.terminate()
            display.proc = None

    
    def prepare_output():
        if os.path.isdir(new_users_dir) and len(os.listdir(new_users_dir)):
            currentUserCredentials.dir_list = os.listdir(new_users_dir)
            currentUserCredentials.dir_list.sort(key=int)
            if len(currentUserCredentials.dir_list) > 1 and currentUserCredentials.activated == False:
                GPIO.add_event_detect(18,GPIO.RISING,callback=button_left_callback, bouncetime=300) # Setup event on pin 10 rising edge
                GPIO.add_event_detect(27,GPIO.RISING,callback=button_right_callback, bouncetime=300) # Setup event on pin 10 rising edge
                currentUserCredentials.activated = True
            if currentUserCredentials.dir_list and (currentUserCredentials.filename == None or currentUserCredentials.filename not in currentUserCredentials.dir_list):
                currentUserCredentials.filename = currentUserCredentials.dir_list[0]
                currentUserCredentials.index = 0
            get_new_user(currentUserCredentials.filename)
        else:
            if currentUserCredentials.activated == True:
                GPIO.remove_event_detect(18)
                GPIO.remove_event_detect(27)
                currentUserCredentials.activated = False
            get_default_output()

    def handler(signum, frame):
        display.proc.terminate()
        prepare_output()
        display.proc = None

    def main():
        signal.signal(signal.SIGHUP, handler)
        ip = get_ip()
        display.first_line = "Host: " + get_ip()
        while True:
            new_ip = get_ip()
            if ip != new_ip:
                ip = new_ip
                display.first_line = "Host: " + ip
                display.proc.terminate()
                display.proc = None
            if display.proc == None:
                prepare_output()
                display.proc = multiprocessing.Process(target=draw_output, args=())
                display.proc.start()

    if __name__ == "__main__":
        main()
        
except KeyboardInterrupt:
    if display.proc:
        display.proc.terminate()
finally:
    GPIO.cleanup()
if display.proc:
        display.proc.terminate()
GPIO.cleanup()