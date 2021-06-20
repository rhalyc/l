DOCKER_HUBS="debian ubuntu centos fedora alpine opensuse/leap opensuse/tumbleweed archlinux auchida/freebsd"
TMP="/tmp/metrics"
SAVEHERE="./lists"

get_tags(){
    TAGS=$(wget -q "https://registry.hub.docker.com/v1/repositories/$1/tags" -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}')
}



for h in $DOCKER_HUBS; do
    get_tags "$h"
    if ! [ "$TAGS" ]; then echo "NO TAGS IN $h"; fi
done

for h in $DOCKER_HUBS; do
    get_tags "$h"
    for t in $TAGS; do
        echo "$h:$t"
        NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        CMD="find / -type f -not -path '/proc/*' -not -path '/dev/*' -not -path '/sys/kernel/slab/*' -not -path '/sys/devices/*' -not -path '/sys/fs/cgroup/*' -not -path '/sys/module/*' -not -path '/sys/kernel/irq/*' -exec md5sum {} \; >> $TMP/$NEW_UUID 2>/dev/null"
        sudo docker run -t --rm -v $SAVEHERE:$TMP "$h:$t" /bin/bash -c "$CMD; sleep 30; $CMD; cat $TMP/$NEW_UUID | sort | uniq -d > $TMP/${NEW_UUID}_final; rm $TMP/$NEW_UUID"
        sudo docker image rm "$h:$t"
    done
done

