# AswadXen-OS
#!/usr/bin/env bash
set -euo pipefail

# 1. Variables
WORKDIR="$HOME/branding-xenos"
REPO="git@github.com:AswadXenOS/AswdXen-OS.git"
IMAGE_SRC="$HOME/image.png"

# 2. Create project folder
echo "→ Creating project folder at $WORKDIR"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 3. Frontend: Vite + React + TailwindCSS
echo "→ Scaffolding frontend (Vite + React + Tailwind)"
npx create-vite@latest frontend -- --template react
cd frontend
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Tailwind config
tee tailwind.config.js > /dev/null <<EOF
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: "#1E40AF",
        secondary: "#22C55E",
        accent: "#FBBF24",
      },
      fontFamily: {
        sans: ["Inter", "sans-serif"],
        heading: ["Poppins", "sans-serif"],
      },
    },
  },
  plugins: [],
};
EOF

# Globals.css
mkdir -p src/styles
tee src/styles/globals.css > /dev/null <<EOF
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom styles */
EOF

# Copy image.png as logo
mkdir -p public
if [ -f "$IMAGE_SRC" ]; then
  echo "→ Copying image.png into public/logo.png"
  cp "$IMAGE_SRC" public/logo.png
else
  echo "⚠️  Warning: $IMAGE_SRC not found. Please place your image.png in home directory."
fi

# Update App.jsx to display the logo
sed -i "1i import logo from '../public/logo.png';" src/App.jsx
sed -i "2i import './styles/globals.css';" src/App.jsx
sed -i "3i " src/App.jsx
sed -i "4i function App() {" src/App.jsx
sed -i "5i   return (" src/App.jsx
sed -i "6i     <div className=\"min-h-screen flex flex-col items-center justify-center bg-gray-50\"> " src/App.jsx
sed -i "7i       <img src={logo} className=\"w-32 h-32 mb-4\" alt=\"Logo\" />" src/App.jsx
sed -i "8i       <h1 className=\"text-3xl font-heading text-primary\">Welcome to XenOS Branding</h1>" src/App.jsx
sed -i "9i     </div>" src/App.jsx
sed -i "10i   );" src/App.jsx
sed -i "11i }" src/App.jsx
sed -i "12i export default App;" src/App.jsx

cd ..

# 4. Backend: Node.js + Express + SQLite + bcryptjs + JWT
echo "→ Scaffolding backend (Express + SQLite + bcryptjs + JWT)"
mkdir backend && cd backend
npm init -y
npm install express sqlite bcryptjs jsonwebtoken cors dotenv
tee index.js > /dev/null <<'EOF'
require('dotenv').config();
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Database = require('sqlite');
const sqlite3 = require('sqlite3');
const cors = require('cors');

const app = express();
app.use(cors(), express.json());

let db;
(async () => {
  db = await Database.open({ filename: './data.db', driver: sqlite3.Database });
  await db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT
  )`);
})();

app.post('/api/auth/register', async (req, res) => {
  const { username, password } = req.body;
  const hash = await bcrypt.hash(password, 10);
  try {
    await db.run('INSERT INTO users (username, password) VALUES (?, ?)', [username, hash]);
    res.json({ success: true });
  } catch (e) {
    res.status(400).json({ error: 'Username taken' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  const user = await db.get('SELECT * FROM users WHERE username = ?', [username]);
  if (user && await bcrypt.compare(password, user.password)) {
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'secret', { expiresIn: '1h' });
    return res.json({ token });
  }
  res.status(401).json({ error: 'Invalid credentials' });
});

app.get('/api/hello', (req, res) => {
  res.json({ msg: 'Hello from XenOS API!' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Backend running on http://localhost:${PORT}`));
EOF

# .env
tee .env > /dev/null <<EOF
JWT_SECRET=supersecretkey
EOF

cd ..

# 5. Bot: GPT CLI
echo "→ Scaffolding bot (OpenAI GPT CLI)"
mkdir bot && cd bot
npm init -y
npm install openai
tee bot.js > /dev/null <<'EOF'
const { Configuration, OpenAIApi } = require("openai");
const readline = require("readline");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const cfg = new Configuration({ apiKey: process.env.OPENAI_API_KEY });
const openai = new OpenAIApi(cfg);

async function main() {
  rl.question("You: ", async (q) => {
    const resp = await openai.createChatCompletion({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: q }]
    });
    console.log("GPT:", resp.data.choices[0].message.content);
    main();
  });
}

main();
EOF

cd ..

# 6. Git init, commit & push
echo "→ Initializing Git and pushing to GitHub"
git init
git remote add origin "$REPO"
git add .
git commit -m "Initial full setup: frontend, backend, bot & logo"
git branch -M main
git push -u origin main

echo "🎉 Setup lengkap!  
→ Frontend:   $WORKDIR/frontend (run: cd frontend && npm run dev)  
→ Backend:    $WORKDIR/backend (run: cd backend && node index.js)  
→ Bot:        $WORKDIR/bot     (run: cd bot && OPENAI_API_KEY=… node bot.js)"
