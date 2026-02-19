#!/bin/bash
TOKEN=$1
if [ -z "$TOKEN" ]; then echo "❌ No token – run the wizard again"; exit 1; fi

echo "🔧 Installing Craigslist LeadGen Beast on Bluehost AlmaLinux (full Apple-style dashboard + all sections + post monitor + CEO chat + setup tools)..."

# System setup
dnf update -y
dnf install -y git curl wget jq firewalld docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl start docker firewalld
systemctl enable docker firewalld
firewall-cmd --permanent --add-port=3000/tcp --add-port=8080/tcp
firewall-cmd --reload
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Decode token
CONFIG=$(echo $TOKEN | base64 -d)
MAIN_GMAIL=$(echo $CONFIG | jq -r '.mainGmail')
BURNERS=$(echo $CONFIG | jq -r '.burners | join(",")')
PROXIES=$(echo $CONFIG | jq -r '.proxies | join(",")')
COSTS=$(echo $CONFIG | jq -r '.costs')

# Skills folder + SKILL.md files
mkdir -p /opt/leadgen-skills/skills/{ceo-orchestrator,craigslist-6burner,stealth-layer,humanizer-chain,quote-optimizer}

cat > /opt/leadgen-skills/skills/ceo-orchestrator/SKILL.md << 'EOF'
# CEO Orchestrator
Type: orchestrator
Description: Main brain for Craigslist 6-burner swarm. Listens for nudges via WS/API on /nudge. Logs posts/leads to shared volume for dashboard.
EOF

cat > /opt/leadgen-skills/skills/craigslist-6burner/SKILL.md << 'EOF'
# Craigslist 6-Burner Platform
Type: platform
Description: Posts in gigs/services, monitors 6 burners, spawns human-like replier per lead.
Tools: stealth-layer, humanizer-chain, gmail-oauth (burners + main forward), playwright-browser (human mouse/typing)
Config: max_posts_per_day: 8, cooldown_hours: 48, metro_area_per_account: unique
Sub-agents per lead: Scraper → Qualifier → Replier → Negotiator → Closer
All comms proxied to main Gmail + dashboard.
EOF

cat > /opt/leadgen-skills/skills/stealth-layer/SKILL.md << 'EOF'
# Stealth Layer (used by EVERY action)
- Residential proxy per account (from user config)
- GoLogin/Dolphin-style fingerprint rotation
- Playwright humanize: bezier mouse, typing variance 50-320ms, random pauses 12-95s
- Volume caps + natural sleep windows
- Auto-pause on flag detection
EOF

cat > /opt/leadgen-skills/skills/humanizer-chain/SKILL.md << 'EOF'
# Humanizer Chain (4-step)
1. Persona: "Mike Thompson, 31, Indianapolis freelancer, casual Midwest guy"
2. Base response
3. STRICT HUMAN MODE prompt (contractions, "tbh", light lol, phone-typing imperfections)
4. Self-critique: must score 9+/10 human or rewrite
Never sounds AI.
EOF

cat > /opt/leadgen-skills/skills/quote-optimizer/SKILL.md << 'EOF'
# Quote Optimizer
Reads lead history + your cost inputs → suggests optimal price maximizing (close% × profit)
Learns from closed deals over time.
EOF

# ── Dashboard: Clone starter + full customizations ──
cd /opt/leadgen-skills
git clone https://github.com/Kiranism/next-shadcn-dashboard-starter.git dashboard
cd dashboard

# Install deps (starter prefers pnpm/bun, fallback npm)
npm install || pnpm install || yarn install || bun install

# Inject env (for Gmail stub + future WS)
cat > .env.local << EOF
NEXT_PUBLIC_MAIN_GMAIL=$MAIN_GMAIL
NEXT_PUBLIC_BURNERS=$BURNERS
NEXT_PUBLIC_PROXIES=$PROXIES
NEXT_PUBLIC_COSTS='$COSTS'
OPENCLAW_WS_URL=ws://claw-daemon:8080
NEXT_PUBLIC_APP_NAME="Craigslist LeadGen Beast"
EOF

# Apply Apple-style globals.css (overwrite)
cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --card: 0 0% 100%;
  --card-foreground: 222.2 84% 4.9%;
  --popover: 0 0% 100%;
  --popover-foreground: 222.2 84% 4.9%;
  --primary: 221.2 83.2% 53.3%; /* Apple blue */
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96.1%;
  --secondary-foreground: 222.2 47.4% 11.2%;
  --muted: 210 40% 96.1%;
  --muted-foreground: 215.4 16.3% 46.9%;
  --accent: 210 40% 96.1%;
  --accent-foreground: 222.2 47.4% 11.2%;
  --destructive: 0 84.2% 60.2%;
  --border: 214.3 31.8% 91.4%;
  --input: 214.3 31.8% 91.4%;
  --ring: 221.2 83.2% 53.3%;
  --radius: 1.5rem;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  --card: 222.2 84% 4.9%;
  --card-foreground: 210 40% 98%;
  --primary: 217.2 91.2% 59.8%;
  --primary-foreground: 222.2 84% 4.9%;
  --secondary: 217.2 32.6% 17.5%;
  --secondary-foreground: 210 40% 98%;
  --muted: 217.2 32.6% 17.5%;
  --muted-foreground: 215 20.2% 65.1%;
  --accent: 217.2 32.6% 17.5%;
  --accent-foreground: 210 40% 98%;
  --destructive: 0 62.8% 30.6%;
  --border: 217.2 32.6% 17.5%;
  --input: 217.2 32.6% 17.5%;
  --ring: 224.3 76.3% 48%;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  @apply bg-background text-foreground antialiased;
}

.glass-card {
  @apply bg-card/80 backdrop-blur-xl border border-border/50 shadow-2xl rounded-3xl overflow-hidden;
}
EOF

# Leads page
mkdir -p src/app/(dashboard)/leads
cat > src/app/(dashboard)/leads/page.tsx << 'EOF'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"

export default function LeadsPage() {
  const leads = [
    { id: 1, source: "Craigslist", company: "Local Bakery", quote: "$4800", prob: "Green 92%", status: "Negotiating" },
  ]

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold">Leads</h1>
      <Card className="glass-card">
        <CardHeader><CardTitle>Active Leads</CardTitle></CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Source</TableHead>
                <TableHead>Company</TableHead>
                <TableHead>Quote</TableHead>
                <TableHead>Probability</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {leads.map(lead => (
                <TableRow key={lead.id}>
                  <TableCell>{lead.source}</TableCell>
                  <TableCell>{lead.company}</TableCell>
                  <TableCell>{lead.quote}</TableCell>
                  <TableCell>
                    <Badge variant={lead.prob.startsWith("Green") ? "default" : "secondary"} className={
                      lead.prob.startsWith("Green") ? "bg-green-500/20 text-green-700" :
                      lead.prob.startsWith("Orange") ? "bg-orange-500/20 text-orange-700" :
                      lead.prob.startsWith("Yellow") ? "bg-yellow-500/20 text-yellow-700" : "bg-red-500/20 text-red-
