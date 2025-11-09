hello_vue() {
    # Colors for output
    local GREEN='\033[0;32m'
    local BLUE='\033[0;34m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local NC='\033[0m' # No Color

    # Check if app name is provided
    if [ -z "$1" ]; then
        echo -e "${RED}❌ Please provide an app name: hello_app <app_name>${NC}"
        return 1
    fi

    local APP_NAME=$1

    echo -e "\n${BLUE}🚀 Creating your app: ${APP_NAME}${NC}\n"

    # Step 1: Create Vite Vue TypeScript app
    echo -e "${GREEN}📦 Step 1: Creating Vite Vue TypeScript app...${NC}"
    npm create vite@latest "$APP_NAME" -- --template vue-ts

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create Vite app${NC}"
        return 1
    fi

    cd "$APP_NAME" || return 1

    # Install dependencies
    echo -e "\n${GREEN}📦 Installing dependencies...${NC}"
    npm install
    npm install --save-dev vitest @vue/test-utils jsdom

    # Step 2: Clean up boilerplate (optional)
    echo -e "\n${YELLOW}🧹 Clean up boilerplate files? (y/n):${NC} "
    read -r CLEANUP

    if [[ "$CLEANUP" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}🧹 Step 2: Cleaning up boilerplate...${NC}"
        
        # Remove unnecessary files
        rm -f src/style.css src/components/HelloWorld.vue
        echo "   Removed: src/style.css, src/components/HelloWorld.vue"
        
        # Simplify App.vue
        cat > src/App.vue << EOF
<script setup lang="ts">
</script>

<template>
  <div style="padding: 2rem; font-family: system-ui">
    <h1>Welcome to ${APP_NAME}! 🎉</h1>
    <p>Your app is ready to go.</p>
  </div>
</template>

<style scoped>
</style>
EOF
        echo "   Simplified: src/App.vue"
        
        # Update main.ts
        cat > src/main.ts << 'EOF'
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
EOF
        echo "   Updated: src/main.ts"
    fi

    # Step 3: Update Vite config for port 3000
    echo -e "\n${GREEN}⚙️  Step 3: Configuring Vite for port 3000...${NC}"
    cat > vite.config.ts << EOF
import { defineConfig } from "vitest/config";
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  test: {
    environment: "jsdom",
    globals: true,
  },
  server: {
    port: 3000
  },
  base: '/${APP_NAME}/'
})
EOF
    echo "   Updated: vite.config.ts"

    # Step 4: Install gh-pages
    echo -e "\n${GREEN}📦 Step 4: Installing gh-pages...${NC}"
    npm install --save-dev gh-pages

    # Update package.json with deploy scripts
    echo "   Adding deploy scripts to package.json..."
    node << 'NODEJS'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = {
  ...pkg.scripts,
  predeploy: 'npm run build',
  deploy: 'gh-pages -d dist',
  test: 'vitest'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));

const tsconfig = JSON.parse(fs.readFileSync('tsconfig.app.json', 'utf8'));
tsconfig.compilerOptions = {
  tsBuildInfoFile: "./node_modules/.tmp/tsconfig.app.tsbuildinfo",
  types: ["vite/client", "vitest/globals"],
  ...tsconfig.compilerOptions
}
fs.writeFileSync('tsconfig.app.json', JSON.stringify(tsconfig, null, 2));
NODEJS
    echo "   Deploy scripts added"

    # Step 5: Create GitHub repo
    echo -e "\n${GREEN}📂 Step 5: Setting up Git repository...${NC}"
    git init
    git add .
    git commit -m "Initial commit"

    echo -e "\n${YELLOW}🌐 Create GitHub repo? (requires gh CLI) (y/n):${NC} "
    read -r CREATE_REPO

    if [[ "$CREATE_REPO" =~ ^[Yy]$ ]]; then
        if command -v gh &> /dev/null; then
            gh repo create "$APP_NAME" --public --source=. --remote=origin
            git push -u origin master
        else
            echo -e "${RED}⚠️  GitHub CLI (gh) not found.${NC}"
            echo "   Install it from: https://cli.github.com/"
            echo "   Or create the repo manually and run:"
            echo "   git remote add origin https://github.com/stjk2513/${APP_NAME}.git"
            echo "   git push -u origin master"
        fi
    else
        echo -e "\n${BLUE}📝 Manual setup required:${NC}"
        echo "   1. Create a new repo on GitHub"
        echo "   2. git remote add origin https://github.com/stjk2513/${APP_NAME}.git"
        echo "   3. git push -u origin master"
    fi

    # Step 6: Deploy to GitHub Pages
    echo -e "\n${YELLOW}🚀 Deploy to GitHub Pages now? (y/n):${NC} "
    read -r DEPLOY

    if [[ "$DEPLOY" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}🚀 Step 6: Deploying to GitHub Pages...${NC}"
        npm run deploy
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}✅ Success! Your app should be live at:${NC}"
            echo "   https://stjk2513.github.io/${APP_NAME}/"
            echo -e "\n${YELLOW}⚠️  Note: Enable GitHub Pages in your repo settings if not already enabled${NC}"
            echo "   Go to: Settings → Pages → Source: gh-pages branch"
        else
            echo -e "\n${YELLOW}⚠️  Deployment failed. You can deploy later with: npm run deploy${NC}"
        fi
    else
        echo -e "\n${BLUE}📝 Deploy later with: npm run deploy${NC}"
    fi

    echo -e "\n${GREEN}✨ All done! Your app is ready in: ${APP_NAME}${NC}"
    echo -e "\n${BLUE}📚 Next steps:${NC}"
    echo "   cd ${APP_NAME}"
    echo "   npm run dev"
    echo ""
}