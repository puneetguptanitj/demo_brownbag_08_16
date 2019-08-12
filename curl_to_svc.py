import os
import signal
import random
import sys
import time

def sigterm_handler(signal, frame):
    # save the state here or do whatever you want
    print('I die gracefully')
    sys.exit(0)

signal.signal(signal.SIGTERM, sigterm_handler)
signal.signal(signal.SIGINT, sigterm_handler)

master_ip=os.popen("minikube ip").read().strip()
svc_port=os.popen("kubectl get svc example-service -o json | jq '.spec.ports | .[] | .nodePort'").read().strip()
color_map={}
sleep_time=sys.argv[1]
while True:
	curl_output=os.popen("curl -s " + master_ip + ":" + svc_port).read().strip()
        if curl_output in color_map:
		color = color_map[curl_output]
	else:
 		color=random.randint(1,256)
                color_map[curl_output]=color
        command = "\033[38;5;" + str(color) + "m" + curl_output +"\033[0m"
	print command
	time.sleep(float(sleep_time))
        
# if [[ $color ]]; then
#     echo -en "\033[38;5;${color}m$curl_output \033[0m";
# else
#     color=$RANDOM % 256
#     color_map["$CURL_OUPUT"]="$RANDOM % 25 -en "\033[38;5;${color}m$curl_output \033[0m";

# fi    # Exists
