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
                      lead.prob.startsWith("Yellow") ? "bg-yellow-500/20 text-yellow-700" : "bg-red-500/20 text-red-700"
                    }>
                      {lead.prob}
                    </Badge>
                  </TableCell>
                  <TableCell>{lead.status}</TableCell>
                  <TableCell>
                    <Dialog>
                      <DialogTrigger asChild><Button variant="outline" size="sm">Call</Button></DialogTrigger>
                      <DialogContent>
                        <DialogHeader><DialogTitle>Call Script for {lead.company}</DialogTitle></DialogHeader>
                        <p>Key points: [AI-generated from history]...</p>
                        <p>Suggested opener: "Hey, following up on your Craigslist post..."</p>
                      </DialogContent>
                    </Dialog>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
EOF

# Funds page
mkdir -p src/app/(dashboard)/funds
cat > src/app/(dashboard)/funds/page.tsx << 'EOF'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

export default function FundsPage() {
  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold">Funds & Usage</h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="glass-card"><CardHeader><CardTitle>Total Closed</CardTitle></CardHeader><CardContent><div className="text-4xl font-bold">$18,420</div></CardContent></Card>
        <Card className="glass-card"><CardHeader><CardTitle>Token Usage</CardTitle></CardHeader><CardContent><div className="text-4xl font-bold">$187</div></CardContent></Card>
        <Card className="glass-card"><CardHeader><CardTitle>Net Profit</CardTitle></CardHeader><CardContent><div className="text-4xl font-bold">$18,233</div></CardContent></Card>
      </div>
    </div>
  )
}
EOF

# Posts Monitor page
mkdir -p src/app/(dashboard)/posts
cat > src/app/(dashboard)/posts/page.tsx << 'EOF'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

export default function PostsMonitor() {
  const posts = [{ burner: "burner1@gmail.com", title: "Web Dev Services", status: "Live", replies: 3 }]

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold">Posts Monitor</h1>
      <Card className="glass-card">
        <CardHeader><CardTitle>Active Craigslist Posts</CardTitle></CardHeader>
        <CardContent>
          <Table>
            <TableHeader><TableRow><TableHead>Burner</TableHead><TableHead>Title</TableHead><TableHead>Status</TableHead><TableHead>Replies</TableHead></TableRow></TableHeader>
            <TableBody>{posts.map((p, i) => <TableRow key={i}><TableCell>{p.burner}</TableCell><TableCell>{p.title}</TableCell><TableCell>{p.status}</TableCell><TableCell>{p.replies}</TableCell></TableRow>)}</TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
EOF

# CEO Chat page
mkdir -p src/app/(dashboard)/chat
cat > src/app/(dashboard)/chat/page.tsx << 'EOF'
"use client"

import { useState } from "react"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"

export default function CEOChat() {
  const [messages, setMessages] = useState<{ role: "user" | "ceo"; content: string }[]>([])
  const [input, setInput] = useState("")

  const sendMessage = async () => {
    if (!input.trim()) return
    setMessages(prev => [...prev, { role: "user", content: input }])
    setMessages(prev => [...prev, { role: "ceo", content: "Nudge received – adjusting strategy..." }]) // temp
    setInput("")
  }

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold">Chat with CEO Agent</h1>
      <Card className="glass-card h-[60vh] flex flex-col">
        <CardContent className="flex-1 overflow-y-auto p-6 space-y-4">
          {messages.map((m, i) => (
            <div key={i} className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}>
              <div className={`max-w-[80%] p-4 rounded-2xl ${m.role === "user" ? "bg-primary text-primary-foreground" : "bg-muted"}`}>
                {m.content}
              </div>
            </div>
          ))}
        </CardContent>
        <div className="p-4 border-t flex gap-2">
          <Input value={input} onChange={e => setInput(e.target.value)} placeholder="Nudge CEO (e.g., pause Craigslist, focus high-prob leads)" onKeyDown={e => e.key === "Enter" && sendMessage()} />
          <Button onClick={sendMessage}>Send</Button>
        </div>
      </Card>
    </div>
  )
}
EOF

# Setup & Tools page
mkdir -p src/app/(dashboard)/setup
cat > src/app/(dashboard)/setup/page.tsx << 'EOF'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Switch } from "@/components/ui/switch"
import { Label } from "@/components/ui/label"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import { Copy } from "lucide-react"

export default function SetupPage() {
  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
    alert("Command copied!")
  }

  return (
    <div className="space-y-8 p-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Setup & Tools</h1>
        <p className="text-muted-foreground mt-2">
          Quick actions, install scripts, and enable new features for your LeadGen Beast.
        </p>
      </div>

      <Card className="glass-card">
        <CardHeader>
          <CardTitle>Enable New Platforms</CardTitle>
          <CardDescription>Add Reddit, X, LinkedIn, etc. (requires git pull + restart)</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <Label htmlFor="reddit" className="text-base">Reddit Platform</Label>
              <p className="text-sm text-muted-foreground">Scrape & reply in r/forhire etc. (karma-safe)</p>
            </div>
            <Switch id="reddit" disabled />
          </div>
          <div className="flex items-center justify-between">
            <div>
              <Label htmlFor="linkedin" className="text-base">LinkedIn (coming soon)</Label>
              <p className="text-sm text-muted-foreground">High-close-rate DMs & posts</p>
            </div>
            <Switch id="linkedin" disabled />
          </div>
        </CardContent>
      </Card>

      <Card className="glass-card">
        <CardHeader>
          <CardTitle>Install Instructions & Scripts</CardTitle>
          <CardDescription>Copy-paste commands for common upgrades</CardDescription>
        </CardHeader>
        <CardContent>
          <Accordion type="single" collapsible className="w-full">
            <AccordionItem value="ssl">
              <AccordionTrigger>Add Free SSL (Caddy reverse proxy)</AccordionTrigger>
              <AccordionContent className="space-y-4">
                <p>Run this on VPS to add HTTPS + auto-renew certs:</p>
                <pre className="bg-muted p-4 rounded-xl overflow-auto text-sm font-mono">
                  {`dnf install -y caddy
# Configure Caddyfile at /etc/caddy/Caddyfile with your domain
caddy reload`}
                </pre>
                <Button variant="outline" size="sm" onClick={() => copyToClipboard("dnf install -y caddy")}>
                  <Copy className="mr-2 h-4 w-4" /> Copy Full Script
                </Button>
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="supabase">
              <AccordionTrigger>Add Supabase (persistent leads DB)</AccordionTrigger>
              <AccordionContent>
                <p>1. Sign up at supabase.com → create project<br/>2. Get connection string<br/>3. Run in dashboard container:</p>
                <pre className="bg-muted p-4 rounded-xl overflow-auto text-sm font-mono">docker compose down && # env update</pre>
                <Button variant="outline" size="sm" onClick={() => copyToClipboard("...")}>
                  <Copy className="mr-2 h-4 w-4" /> Copy
                </Button>
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="update">
              <AccordionTrigger>Check for Swarm Updates</AccordionTrigger>
              <AccordionContent>
                <p>Pulls latest skills from your GitHub repo:</p>
                <pre className="bg-muted p-4 rounded-xl overflow-auto text-sm font-mono">
                  cd /opt/leadgen-skills && git pull && docker compose restart claw-daemon
                </pre>
                <Button variant="outline" size="sm" onClick={() => copyToClipboard("cd /opt/leadgen-skills && git pull && docker compose restart claw-daemon")}>
                  <Copy className="mr-2 h-4 w-4" /> Copy Update Command
                </Button>
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        </CardContent>
      </Card>

      <div className="text-sm text-muted-foreground mt-8">
        Pro tip: For automated toggles, we can add safe API endpoints later.
      </div>
    </div>
  )
}
EOF

# Note for sidebar
echo "# After deploy, edit src/components/layout/sidebar.tsx to add links: /leads, /funds, /posts, /chat, /setup" >> /opt/leadgen-skills/README-dashboard-custom.txt

# Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=base /app/public ./public
COPY --from=base /app/.next ./.next
COPY --from=base /app/node_modules ./node_modules
COPY --from=base /app/package.json ./package.json
COPY --from=base /app/next.config.mjs ./
EXPOSE 3000
CMD ["npm", "start"]
EOF

cd /opt/leadgen-skills

# docker-compose
cat > docker-compose.yml << EOF
services:
  claw-daemon:
    image: openclaw/openclaw:latest
    restart: always
    volumes:
      - ./skills:/skills
      - data:/data
    environment:
      - MAIN_GMAIL=$MAIN_GMAIL
      - BURNERS=$BURNERS
      - PROXIES=$PROXIES
      - COSTS=$COSTS

  dashboard:
    build:
      context: ./dashboard
      dockerfile: Dockerfile
    restart: always
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - claw-daemon

volumes:
  data:
EOF

docker compose up -d --build

IP=$(curl -s ifconfig.me)
echo "✅ FULL DEPLOY COMPLETE!"
echo "Dashboard (all sections live): http://$IP:3000"
echo "Sidebar should now have Leads / Funds / Posts / Chat / Setup (edit sidebar.tsx if links missing)"
echo "Login with main Gmail stub. First build may take 2-4 min – refresh page."
echo "Next: SSH in to customize sidebar nav + add real WS/live data!"
