FROM node:lts-gallium

WORKDIR /root/app
COPY . .
RUN npm install
RUN npm run build

CMD ["node", ".output/server/index.mjs"]
