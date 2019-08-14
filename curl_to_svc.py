import os
import signal
import random
import sys
import time
import threading 

shouldExit = False

def sigterm_handler(signal, frame):
    # save the state here or do whatever you want
    print('I die gracefully')
    global shouldExit
    shouldExit = True
    sys.exit(0)

signal.signal(signal.SIGTERM, sigterm_handler)
signal.signal(signal.SIGINT, sigterm_handler)
color_map={}

def send_request ():
	master_ip=os.popen("minikube ip").read().strip()
	svc_port=os.popen("kubectl get svc example-service -o json | jq '.spec.ports | .[] | .nodePort'").read().strip()
	sleep_time=sys.argv[1]
    	global shouldExit
	while not shouldExit:
		curl_output=os.popen("curl -s " + master_ip + ":" + svc_port).read().strip()
       		if curl_output in color_map:
			color = color_map[curl_output]
		else:
 			color=random.randint(1,256)
                	color_map[curl_output]=color
        	command = "\033[38;5;" + str(color) + "m" + curl_output +"\033[0m"
		print command
		time.sleep(float(sleep_time))

for x in range (int(sys.argv[2])):
	t1 = threading.Thread(target=send_request) 
	t1.start() 

while True:
	time.sleep(1)

print("Done!") 
