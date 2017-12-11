#!/bin/sh

mkdir -p ${HLS_TMP_FOLDER} ${SAVE_STORAGE} `dirname ${LOG_FILENAME}`
STREAM_MASK="RTSP_STREAM_"
NGINX_CONFIG='/config/nginx.conf'

TEMP=`env   | grep "${STREAM_MASK}" | tr '\n' ' '`
if [ "${TEMP}" == "" ]; then
   echo "no found any stream..."
   exit 1
fi

EXEC_TEMPLATE='exec_static ffmpeg -loglevel warning -rtsp_transport tcp -i "URL" -vcodec copy -acodec copy -f flv rtmp://localhost:1935/hls/NAME;'
           
NAMES=
for t in ${TEMP}; do
    NAME=`echo "$t"| cut -d'=' -f1 |  sed -e "s/${STREAM_MASK}//g"`
    URL=`echo "$t"| cut -d'=' -f2-`
    if [ "${NAME}" == "" -o "${URL}" == "" ]; then
        continue
    fi
    echo "${NAME} => ${URL}"
    temp=${EXEC_TEMPLATE/NAME/${NAME}}
    echo "${temp/URL/${URL}}" >> ${NGINX_CONFIG}
    NAMES="${NAMES} ${NAME}"
done

echo "}}}" >> ${NGINX_CONFIG}
sed -i "s#HLS_TMP_FOLDER#${HLS_TMP_FOLDER}#g" ${NGINX_CONFIG}
sed -i "s#HLS_FRAGMENT#${HLS_FRAGMENT}#g" ${NGINX_CONFIG}

SAVE_STORAGE_ROOT=`dirname ${SAVE_STORAGE}`
SAVE_STORAGE_NAME=`basename  ${SAVE_STORAGE}`
sed -i "s#SAVE_STORAGE_ROOT#${SAVE_STORAGE_ROOT}#g" ${NGINX_CONFIG}
sed -i "s#SAVE_STORAGE_NAME#${SAVE_STORAGE_NAME}#g" ${NGINX_CONFIG}

/usr/bin/python3.4 /saver.py ${NAMES} &


# while [ 1 == 1 ]; do sleep 1; done
nginx