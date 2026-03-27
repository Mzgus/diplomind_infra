# Diplomind - Infrastructure d'Orchestration

Ce dépôt centralise l'orchestration du projet Diplomind. Il lie le backend (`diplomind_be`) et le frontend (`diplomind_fe`) via des submodules Git et gère leur exécution conjointe via Docker Compose.

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Git](https://git-scm.com/)
- [Just](https://github.com/casey/just) (Optionnel, facilitateur de commandes)

## 1. Récupération du projet

Clonage initial avec initialisation des submodules :

```bash
git clone --recursive https://github.com/Mzgus/diplomind_infra.git
cd diplomind_infra
```

Si le dépôt a déjà été cloné sans l'option `--recursive`, initialiser les submodules manuellement :

```bash
git submodule update --init --recursive
```

## 2. Configuration de l'environnement

Créer le fichier de variables d'environnement central.

```bash
cp .env.template .env
```

Éditer `.env` avec les valeurs de production appropriées (mots de passe forts, secrets cryptographiques réels).

```env
POSTGRES_USER="user_prod"
POSTGRES_PASSWORD="password_prod_securise"
POSTGRES_DB="diplomind_db_prod"

# Les conteneurs communiquent via le réseau interne Docker, l'URL de la base 
# pour l'API doit pointer vers le service "db" défini dans le docker-compose.yml
DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}"

JWT_SECRET="secret_complexe_unique"
COOKIE_NAME="auth_cookie_prod"
```

## 3. Déploiement en Production

Construire et lancer les services en arrière-plan :

**Avec Docker Compose natif :**
```bash
docker compose up -d --build
```

**Avec Just :**
```bash
just build
```

Vérifier l'état des services :
```bash
docker compose ps
docker compose logs -f
```

## 4. Initialisation de la base de données (Si nécessaire)

Lors du premier lancement, le schéma de la base de données est créé automatiquement via les fichiers dans `diplomind_be/mig/`.

S'il est nécessaire d'injecter des données initiales (seeding) sur l'environnement :

**Avec Docker Compose natif :**
```bash
cat diplomind_be/seed/seed.sql | docker exec -i diplomind_db psql -U <POSTGRES_USER> -d <POSTGRES_DB>
```

**Avec Just :**
```bash
just seed
```

## 5. Mise à jour en Production

Pour déployer une nouvelle version depuis les dépôts distants des submodules :

1. Mettre à jour les références des submodules vers le dernier commit distant :
```bash
git submodule update --remote
```

2. Reconstruire et relancer les conteneurs :
```bash
docker compose up -d --build
```

3. (Optionnel) Commit la nouvelle référence dans ce dépôt d'orchestration :
```bash
git add diplomind_be diplomind_fe
git commit -m "chore: update submodules to latest versions"
git push origin main
```
