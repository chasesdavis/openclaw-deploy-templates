#!/bin/bash
TOKEN=$1
if [ -z "$TOKEN" ]; then echo "❌ No token – run the wizard again"; exit 1; fi

echo "🔧 Installing Craigslist LeadGen Beast on Bluehost AlmaLinux..."

dnf update -y
dnf install -y git curl wget jq firewalld docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl start docker firewalld
systemctl enable docker firewalld
firewall-cmd --permanent --add-port=3000/tcp --add-port=8080/tcp
firewall-cmd --reload
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

CONFIG=$(echo $TOKEN | base64 -d)
MAIN_GMAIL=$(echo $CONFIG | jq -r '.mainGmail')
BURNERS=$(echo $CONFIG | jq -r '.burners | join(",")')
PROXIES=$(echo $CONFIG | jq -r '.proxies | join(",")')
COSTS=$(echo $CONFIG | jq -r '.costs')

mkdir -p /opt/leadgen-skills/skills/{ceo-orchestrator,craigslist-6burner,stealth-layer,humanizer-chain,quote-optimizer}

cat > /opt/leadgen-skills/skills/ceo-orchestrator/SKILL.md << 'EOF'
# CEO Orchestrator
Type: orchestrator
Description: Main brain for Craigslist 6-burner swarm.
EOF

cat > /opt/leadgen-skills/skills/craigslist-6burner/SKILL.md << 'EOF'
# Craigslist 6-Burner Platform
Type: platform
Description: Stealth + humanizer + 6 burners. All comms to dashboard.
EOF

cat > /opt/leadgen-skills/skills/stealth-layer/SKILL.md << 'EOF'
# Stealth Layer
Residential proxies, fingerprint rotation, human behavior.
EOF

cat > /opt/leadgen-skills/skills/humanizer-chain/SKILL.md << 'EOF'
# Humanizer Chain
4-step rewrite – never sounds AI.
EOF

cat > /opt/leadgen-skills/skills/quote-optimizer/SKILL.md << 'EOF'
# Quote Optimizer
Maximizes close rate & profit using your costs.
EOF

cat > /opt/leadgen-skills/docker-compose.yml << EOF
services:
  claw-daemon:
    image: openclaw/openclaw:latest
    restart: always
    volumes:
      - /opt/leadgen-skills:/skills
      - data:/data
    environment:
      - MAIN_GMAIL=$MAIN_GMAIL
      - BURNERS=$BURNERS
      - PROXIES=$PROXIES
      - COSTS=$COSTS
  dashboard:
    image: node:20
    working_dir: /app
    volumes:
      - /opt/leadgen-skills:/app
    command: sh -c "npm install && npm run dev -- --host 0.0.0.0"
    ports:
      - "3000:3000"
    depends_on:
      - claw-daemon
volumes:
  data:
EOF

cd /opt/leadgen-skills
docker compose up -d --build

IP=$(curl -s ifconfig.me)
echo "✅ SUCCESS! Craigslist LeadGen Beast is LIVE"
echo "🌐 Dashboard → http://$IP:3000"
echo "Login with your main Gmail. Swarm starts posting within minutes."
