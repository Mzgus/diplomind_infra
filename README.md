# Déploiement en Production sur Debian

Ce guide détaille pas à pas l'installation depuis une machine Debian vierge. Il suit la documentation officielle de Docker et orchestre l'ensemble du projet Diplomind (Backend + Frontend).

---

## 1. Installation de Docker et Git

Exécutez les commandes suivantes pour installer la dernière version officielle de Docker Engine sur Debian.

### Désinstaller les anciens paquets (Optionnel)
```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

### Ajouter la clé GPG officielle de Docker
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### Ajouter le dépôt Docker aux sources APT
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
```

### Installer Docker et ses plugins (dont Docker Compose)
```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

*(Optionnel)* Permettre l'usage de docker sans `sudo` :
```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

## 2. Récupération du projet (Le Dépôt d'Orchestration)

Le clonage intègre le Frontend et le Backend automatiquement grâce à l'option `--recursive`.

```bash
git clone --recursive https://github.com/Mzgus/diplomind_infra.git
cd diplomind_infra
```

## 3. Configuration de l'environnement

Créez le fichier de variables d'environnement central :

```bash
cp .env.template .env
nano .env
```

**Exemple de contenu pour `.env` :**
```env
POSTGRES_USER="diplomind_user"
POSTGRES_PASSWORD="MotDePasseTresSecuriseEtLong"
POSTGRES_DB="diplomind_db"

# IMPORTANT: Sur l'orchestrateur, le backend cible le service Docker nommé "db"
DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}"

# Sécurité de l'application
JWT_SECRET="CleSecreteComplexePourLesTokens"
COOKIE_NAME="auth_cookie_diplomind"
```

## 4. Lancement de l'Infrastructure

Une fois le `.env` prêt, lancez la construction et le déploiement des 3 conteneurs (Base de données, API Backend, Frontend) :

```bash
docker compose up -d --build
```

Vérifiez que les services tournent sans erreur :
```bash
docker compose ps
docker compose logs -f
```

## 5. (Optionnel) Ajout des données de Base

Au premier lancement, la structure (schéma `01.sql`) de la base de données est créée automatiquement. Si vous souhaitez injecter des données de test existantes dans le conteneur en cours d'exécution :

```bash
cat diplomind_be/seed/seed.sql | docker exec -i diplomind_db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}
```
*(Remplacez `diplomind_user` et `diplomind_db` par les valeurs de votre `.env`)*

---

## 6. Sécurisation du serveur (Pare-feu UFW)

Pour sécuriser votre instance Debian, il est fortement recommandé d'utiliser un pare-feu pour fermer tous les ports non essentiels. Nous utilisons `ufw` (Uncomplicated Firewall).

**Note sur l'architecture** : L'API Backend n'est pas exposée directement sur internet. Elle est accessible via le Frontend qui agit comme un reverse proxy. Seul le port du Frontend doit être ouvert.

### Installation de UFW
```bash
sudo apt-get update
sudo apt-get install ufw
```

### Configuration des règles
Par défaut, nous bloquons tout le trafic entrant et autorisons tout le trafic sortant.

```bash
# Réinitialiser les règles par défaut
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Autoriser SSH (CRUCIAL : ne vous enfermez pas dehors)
sudo ufw allow 22/tcp

# Autoriser uniquement le port du Frontend (React + Proxy API)
sudo ufw allow 5173/tcp
```

### Activation du pare-feu
```bash
sudo ufw enable
```
*(Répondez `y` pour confirmer l'activation)*

### Vérification du statut
```bash
sudo ufw status verbose
```

---

## 7. Procédures de Tests (Serveur de Test / VM)

Ces instructions supposent que vous avez déjà démarré l'infrastructure globale en production ou en développement à l'étape 4 :
```bash
# L'infrastructure complète (db, api, frontend) doit être active
docker compose up -d --build
```
La base de données et l'API tournent donc déjà dans Docker et exposent les ports `5432` et `3000` sur la machine hôte.

### Dépendances système de test à installer (sur la machine de test)
Pour exécuter les tests localement sur la machine hôte, vous devez installer les outils de développement :

#### 1. Installer la Toolchain Rust (rustup et cargo)
```bash
# Télécharger et installer rustup (répondez '1' pour l'installation par défaut)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Charger l'environnement cargo
source $HOME/.cargo/env
```

#### 2. Installer Node.js & npm
```bash
# Ajouter le dépôt NodeSource pour Node.js 22 et installer
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

#### 🛠️ Résolution des erreurs de compilation sous Linux / WSL
Si vous compilez sur Linux (ou WSL) et rencontrez des erreurs de type `linker 'cc' not found` ou `pkg-config could not be found`, installez les outils de compilation C et les en-têtes SSL :
```bash
sudo apt-get update && sudo apt-get install -y build-essential pkg-config libssl-dev
```

---

## 8. Exécution des Tests

### A. Tests du Backend (Unitaires et Intégration)
Les tests d'intégration backend se connectent à la base de données. Comme la base de données tourne dans le conteneur Docker `diplomind_db` (qui mappe le port 5432 de l'hôte), vous devez **explicitement écraser la variable d'environnement `DATABASE_URL`** pour cibler `localhost` à la place de l'hôte interne Docker `db`.

1. Naviguez dans le répertoire backend :
   ```bash
   cd diplomind_be
   ```
2. Lancez les tests en fournissant l'adresse de connexion sur `localhost` :
   *   **Sur Linux / WSL / macOS :**
       ```bash
       DATABASE_URL="postgres://diplomind_user:MotDePasseTresSecuriseEtLong@localhost:5432/diplomind_db" cargo test -- --test-threads=1
       ```
   *   **Sur Windows (PowerShell) :**
       ```powershell
       $env:DATABASE_URL="postgres://diplomind_user:MotDePasseTresSecuriseEtLong@localhost:5432/diplomind_db"; cargo test -- --test-threads=1
       ```
3. **En cas d'échec d'un test** : Isolez le test ciblé avec le drapeau `--nocapture` :
   ```bash
   DATABASE_URL="postgres://diplomind_user:MotDePasseTresSecuriseEtLong@localhost:5432/diplomind_db" cargo test <nom_du_test> -- --nocapture
   ```

### B. Tests Unitaires du Frontend
1. Naviguez dans le répertoire frontend et installez les dépendances :
   ```bash
   cd ../diplomind_fe
   npm ci
   ```
2. Exécutez les tests d'interface via Vitest :
   ```bash
   npm run test
   ```

### C. Tests End-to-End (E2E Playwright)
Les tests Playwright simulent les clics utilisateur sur l'interface graphique. Ils nécessitent que l'API et le frontend tournent en arrière-plan.

1. Assurez-vous d'avoir installé les pilotes de navigateurs Playwright :
   ```bash
   npx playwright install --with-deps
   ```
2. Lancez les tests E2E :
   ```bash
   # Lancement des scénarios en ligne de commande
   npm run test:e2e
   
   # Ou en mode graphique interactif pour déboguer
   npm run test:e2e:ui
   ```
3. **En cas d'échec d'un test E2E** : Ouvrez le rapport généré pour visualiser les captures d'écran et vidéos de l'échec :
   ```bash
   npm run test:e2e:report
   ```
