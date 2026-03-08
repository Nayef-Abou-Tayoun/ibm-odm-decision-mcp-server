FROM nodered/node-red:3.1.10

USER root

RUN npm install \
    node-red-dashboard \
    node-red-node-ui-table \
    ibm-cos-sdk

# 👉 COPY COS helper script
COPY cos_get_base64.js /usr/local/bin/cos_get_base64.js
RUN chmod +x /usr/local/bin/cos_get_base64.js

# Copy bootstrap + settings
COPY bootstrap.sh /usr/local/bin/bootstrap.sh
COPY settings.js /data/settings.js

RUN chmod +x /usr/local/bin/bootstrap.sh \
 && chown -R node-red:node-red /data

USER node-red

EXPOSE 1880

ENTRYPOINT ["/usr/local/bin/bootstrap.sh"]
