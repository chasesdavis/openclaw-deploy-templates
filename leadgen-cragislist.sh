#!/bin/bash
TOKEN=$1
if [ -z "$TOKEN" ]; then echo "No token"; exit 1; fi

echo "🔧 Setting up Craigslist LeadGen Beast..."

# Update & install basics
apt update && apt upgrade -y
apt install -y docker.io docker-compose git curl

# Decode config
CONFIG=$(echo $TOKEN | base64 -d)

# Clone OpenClaw
git clone https://github.com/openclaw/openclaw.git /opt/openclaw
cd /opt/openclaw

# Clone YOUR skills
git clone https://github.com/YOURUSERNAME/leadgen-claw-skills.git /opt/leadgen-skills

# Docker setup
cat > docker-compose.yml <<EOF
$(cat /opt/leadgen-skills/docker-compose.yml)
EOF

# Inject config
echo "OPENCLAW_TOKEN=$TOKEN" >> .env
echo "PROXIES_JSON=$(echo $CONFIG | jq -r '.proxies | tojson')" >> .env

docker-compose up -d --build

# Start services
systemctl enable docker
echo "✅ DONE! Dashboard live at http://$(curl -s ifconfig.me):3000"
echo "Login with your main Gmail. Swarm is running Craigslist only."
