#!/data/data/com.termux/files/usr/bin/bash

# ===================== AswadXenOS Full OS Setup =====================
# 1 perintah tunggal: curl -s https://raw.githubusercontent.com/AswadXenOS/AswadXen-OS/main/os-setup.sh | bash
# =====================================================================

echo "\n🚀 Memulakan AswadXenOS Full OS Setup...\n"

# ------ Update & Install Termux Essentials ----
pkg update -y && pkg upgrade -y
pkg install git nodejs-lts curl nano termux-api termux-widget bash-completion -y

# ------ GitHub Config ------
git config --global user.name "AswadXenOS"
git config --global user.email "xenistaswad@gmail.com"

# ------ Create Project Directory ------
WORKDIR=~/AswadXenOS-OS
mkdir -p "$WORKDIR" && cd "$WORKDIR"

# ------ Backend Setup (Express + SQLite) ------
echo "\n⚙️  Setting up Backend...\n"
mkdir -p backend && cd backend
npm init -y
npm install express sqlite bcryptjs cors
cat <<EOF > index.js
const express = require('express');
const app = express();
const cors = require('cors');
const sqlite = require('sqlite');
const sqlite3 = require('sqlite3');
const bcrypt = require('bcryptjs');

app.use(cors());
app.use(express.json());

(async () => {
  const db = await sqlite.open({ filename: './db.sqlite', driver: sqlite3.Database });
  await db.exec('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, email TEXT, password TEXT)');
})();

app.get('/', (req, res) => res.send('AswadXenOS Backend Ready!'));
app.listen(5000, () => console.log('🚀 Backend running on http://localhost:5000'));
EOF
cd "$WORKDIR"

# ------ Frontend Setup (Vite + React + Tailwind) ------
echo "\n⚙️  Setting up Frontend...\n"
npm init vite@latest frontend -- --template react
cd frontend
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
# Configure Tailwind
sed -i 's/content: \[\]/content: [\".\/index.html\", \".\/src\/**\/*.jsx\"]/g' tailwind.config.js
# Create CSS
cat <<EOF > src/index.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF
cd "$WORKDIR"

# ------ GPT CLI Bot Setup ------
echo "\n🤖 Setting up GPT CLI Bot...\n"
mkdir -p bot && cd bot
npm init -y
npm install axios readline
cat <<EOF > bot.js
const readline = require('readline');
const axios = require('axios');
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const apiKey = process.env.OPENAI_API_KEY;
async function ask(question) {
  try {
    const res = await axios.post(
      'https://api.openai.com/v1/chat/completions',
      { model: 'gpt-3.5-turbo', messages: [{ role: 'user', content: question }] },
      { headers: { Authorization: `Bearer ${apiKey}` } }
    );
    console.log('\n🤖', res.data.choices[0].message.content.trim());
  } catch (e) { console.error('\n❌ Error:', e.response?.data || e.message); }
}
rl.on('line', (line) => ask(line));
EOF
cd "$WORKDIR"

# ------ Termux Widget Shortcut ------
echo "\n📱 Creating Termux Shortcut...\n"
mkdir -p ~/.shortcuts
cat <<EOF > ~/.shortcuts/AswadXenOS.sh
#!/data/data/com.termux/files/usr/bin/bash
cd $WORKDIR/bot
node bot.js
EOF
chmod +x ~/.shortcuts/AswadXenOS.sh

echo "👉 Tarik widget Termux ke home, pilih 'AswadXenOS.sh' untuk shortcut GPT Bot"

# ------ OPENAI API Key Placeholder ------
echo "\n🔑 Setting API Key placeholder..."
if ! grep -q OPENAI_API_KEY ~/.bashrc; then
  echo 'export OPENAI_API_KEY="sk-PASTE-YOUR-API-KEY-HERE"' >> ~/.bashrc
  echo "Kemas kini '~/.bashrc' dengan key sebenar sebelum run bot"
fi

# ------ Completion Message ------
echo "\n✅ AswadXenOS OS Setup Selesai!"
echo "Jalankan Backend: cd $WORKDIR/backend && node index.js"
echo "Jalankan Frontend: cd $WORKDIR/frontend && npm run dev"
echo "Jalankan GPT Bot: tekan shortcut 'AswadXenOS' pada homescreen"