from luma.core.interface.serial import spi
from luma.core.render import canvas
from luma.oled.device import ssd1309
from luma.core.virtual import viewport
from PIL import Image, ImageDraw, ImageFont
from time import sleep
import subprocess
import signal, os
import errno
import RPi.GPIO as GPIO # Import Raspberry Pi GPIO library

try:

    GPIO.setwarnings(False) # Ignore warning for now
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(18, GPIO.IN, pull_up_down=GPIO.PUD_DOWN) # Set pin 10 to be an input pin and set initial value to be pulled low (off)
    GPIO.setup(27, GPIO.IN, pull_up_down=GPIO.PUD_DOWN) # Set pin 10 to be an input pin and set initial value to be pulled low (off)

    class Status:
        ip_str = None
        users_connected_size = 0
        devices_connected_size = 0
        longest_line_size = 0
        max_offset = 0
        users_connected_str = "Connected users: 0"
        devices_connected_str = "Connected devices: 0"

    class CurrentUserCredentials:
        filename = None
        dir_list = None
        activated = False


    currentUserCredentials = CurrentUserCredentials()
    status = Status()

    def get_ip():
        p = subprocess.Popen(("hostname", "-I"),stdout=subprocess.PIPE)
        ip = subprocess.check_output(('awk', "{print $1}"), stdin=p.stdout, universal_newlines=True)
        return (ip)
    
    ip = get_ip()
    status.ip_str = "Host: " + get_ip()
    fnt = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf")

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
            f.close()
        except IOError:
            print("Users status file not accessible")
        try:
            f = open(devices_status_file)
            status.devices_connected_size = f.read()
            status.devices_connected_str = "Connected devices: " + str(status.devices_connected_size)
            f.close()
        except IOError:
            print("Devices status file not accessible")


    def check_longest_length(string_to_check):
        length_to_check = len(string_to_check)
        if (length_to_check > status.longest_line_size):
            status.longest_line_size = length_to_check

    def draw_default_output():
        virtual.set_position((0, 0))
        status.longest_line_size = 0
        get_users_devices_connected()
        check_longest_length(status.ip_str)
        check_longest_length(status.users_connected_str)
        check_longest_length(status.devices_connected_str)
        status.max_offset = status.longest_line_size + 1 - int((128/6))
        with canvas(virtual) as draw:
            draw.text((0, 0), status.ip_str, font=fnt, fill="white")
            draw.text((0, 10), status.users_connected_str, font=fnt, fill="white")
            draw.text((0, 20), status.devices_connected_str, font=fnt, fill="white")
        virtual.set_position((0, 0))

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

    def draw_new_users(filename):
        try:
            f = open(new_users_dir + filename, 'r')
            text = f.read()
            f.close()
            credentials = text.split('\n')
            name = "name: " + credentials[0]
            password = "password: " + credentials[1]
            status.longest_line_size = 0
            check_longest_length(status.ip_str)
            check_longest_length(name)
            check_longest_length(password)
            virtual.set_position((0, 0))
            with canvas(virtual) as draw:
                draw.text((0, 0), status.ip_str, font=fnt, fill="white")
                draw.text((0, 10), name, font=fnt, fill="white")
                draw.text((0, 20), password, font=fnt, fill="white")
                if currentUserCredentials.dir_list.index(filename) == 0 and len(currentUserCredentials.dir_list) > 1:
                    draw.text((105, 50), "next", font=fnt, fill="white")
                elif currentUserCredentials.dir_list.index(filename) >= 1 and currentUserCredentials.dir_list.index(filename) < len(currentUserCredentials.dir_list) - 1:
                    draw.text((0, 50), "previous", font=fnt, fill="white")
                    draw.text((105, 50), "next", font=fnt, fill="white")
                elif len(currentUserCredentials.dir_list) > 1:
                    draw.text((0, 50), "previous", font=fnt, fill="white")
            status.max_offset = status.longest_line_size + 1 - int((128/6))
            virtual.set_position((0, 0))
            currentUserCredentials.filename = filename
        except IOError:
            print("File not accessible")
    
    def button_left_callback(channel):
        if currentUserCredentials.dir_list.index(currentUserCredentials.filename) > 0:
            draw_new_users(currentUserCredentials.dir_list[currentUserCredentials.dir_list.index(currentUserCredentials.filename) - 1])

        print("Button left was pushed!")

    def button_right_callback(channel):
        if currentUserCredentials.dir_list.index(currentUserCredentials.filename) < len(currentUserCredentials.dir_list) - 1:
            draw_new_users(currentUserCredentials.dir_list[currentUserCredentials.dir_list.index(currentUserCredentials.filename) + 1])
        print("Button right was pushed!")

    def draw_output():
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
            draw_new_users(currentUserCredentials.filename)
        else:
            if currentUserCredentials.activated == True:
                GPIO.remove_event_detect(18)
                GPIO.remove_event_detect(27)
                currentUserCredentials.activated = False
            draw_default_output()

    def handler(signum, frame):
        draw_output()



    signal.signal(signal.SIGHUP, handler)


    draw_default_output()

    while True:
        new_ip = get_ip()
        if ip != new_ip:
            ip = new_ip
            status.ip_str = "Host: " + ip
            draw_output()


        # set_offset_position()
        continue
except KeyboardInterrupt:
    print("KeyboardInterrupt\n")
finally:
    GPIO.cleanup()
GPIO.cleanup()