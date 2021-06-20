DOCKER_HUBS="debian ubuntu"
TMP="/tmp/metrics"
SAVEHERE="./lists"

for i in $DOCKER_HUBS; do
    tags=$(wget -q https://registry.hub.docker.com/v1/repositories/$i/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}')
    for t in $tags; do
        echo "$i:$t"
        NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        CMD="find / -type f -not -path '/proc/*' -not -path '/dev/*' -not -path '/sys/kernel/slab/*' -not -path '/sys/devices/*' -not -path '/sys/fs/cgroup/*' -not -path '/sys/module/*' -not -path '/sys/kernel/irq/*' -exec md5sum {} \; >> $TMP/$NEW_UUID 2>/dev/null"
        sudo docker run -t --rm -v $SAVEHERE:$TMP "$i:$t" /bin/bash -c "$CMD; sleep 30; $CMD; cat $TMP/$NEW_UUID | sort | uniq -d > $TMP/${NEW_UUID}_final; rm $TMP/$NEW_UUID"
        sudo docker image rm "$i:$t"
    done
done

