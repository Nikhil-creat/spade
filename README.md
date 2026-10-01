# SPADE ♠ Coin Exchange (simulation)

Static, installable (PWA) site with offline support. Currency follows the visitor (rupees in India, dollars in the US, plus EUR, GBP, AED) and payment preferences (UPI, cards, net banking, ACH and more) are simulated. Includes rising spade-coin theme, simulated SPADE/USDC pool, buy/sell, portfolio P&L, staking, governance votes, burn counter, plain-language intents, CSV export, tokenomics, architecture and risk matrix. Demo funds only.

Files: `index.html` (the whole app), `contracts/SPADE.sol` (testnet reference), `docs/WHITEPAPER.md`, `.github/workflows/pages.yml` (auto deploy), `404.html`, `.nojekyll`, `sw.js`, `manifest.webmanifest`, `icon.svg`.

## Upload to GitHub (website)
1. Unzip `spade-master.zip`.
2. github.com > New repository > name `spade` > Public > Create repository.
3. Click "uploading an existing file", drag in everything INSIDE the `spade-master` folder (include the `.github` folder; if your phone hides it, use the Termux method) > Commit changes.
4. Settings > Pages > Source: choose "GitHub Actions" (or "Deploy from a branch", main, / root).
5. Open the Actions tab and wait for a green check. Site: https://YOUR-USERNAME.github.io/spade/

## Upload with Termux
```
pkg install git unzip -y
unzip spade-master.zip && cd spade-master
git init && git add -A && git commit -m "SPADE"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/spade.git
git push -u origin main
```
Use a personal access token as the password when asked.
