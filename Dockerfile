# Sử dụng Node.js LTS
FROM node:20-alpine

# Thiết lập thư mục làm việc
WORKDIR /app

# Copy package files
COPY package*.json ./

# Cài đặt dependencies
RUN npm install

# Copy toàn bộ source code
COPY . .

# Expose port 3000
EXPOSE 3000

# Chạy ứng dụng
CMD ["npm", "run", "dev"]
