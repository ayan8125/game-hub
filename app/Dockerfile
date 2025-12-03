# -------------------------
# 1. Base Image
# -------------------------
FROM python:3.11-slim

# -------------------------
# 2. Set Work Directory
# -------------------------
WORKDIR /app

# -------------------------
# 3. Install Debian Dependencies (optional but useful)
# -------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# 4. Copy Project Files
# -------------------------
COPY . /app

# -------------------------
# 5. Install Python Packages
# -------------------------
RUN pip install --no-cache-dir -r requirements.txt

# -------------------------
# 6. Expose Port
# -------------------------
EXPOSE 5000

# -------------------------
# 7. Run Flask App
# -------------------------
CMD ["python", "app.py"]
