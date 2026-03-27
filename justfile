set dotenv-load := true

# Lancer tous les services (Background)
up:
	docker compose up -d

# Arrêter tous les services
down:
	docker compose down

# Reconstruire et lancer les services
build:
	docker compose up -d --build

# Voir les logs de tous les services
logs:
	docker compose logs -f

# Injecter les données de test (Seed) dans la base de données
seed:
	cat diplomind_be/seed/seed.sql | docker exec -i diplomind_db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# Accéder à la console Postgres
psql:
	docker exec -it diplomind_db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# Supprimer les données (Volume) et redémarrer
wipe:
	docker compose down -v && just up

# --- Variantes SUDO ---

sudo_up:
	sudo docker compose up -d

sudo_down:
	sudo docker compose down

sudo_build:
	sudo docker compose up -d --build

sudo_seed:
	cat diplomind_be/seed/seed.sql | sudo docker exec -i diplomind_db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

sudo_psql:
	sudo docker exec -it diplomind_db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}
