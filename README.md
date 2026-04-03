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
cat diplomind_be/seed/seed.sql | docker exec -i diplomind_db psql -U diplomind_user -d diplomind_db
```
*(Remplacez `diplomind_user` et `diplomind_db` par les valeurs de votre `.env`)*
