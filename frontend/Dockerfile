FROM node:14
COPY . /app
WORKDIR /app/frontend
RUN npm install
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
