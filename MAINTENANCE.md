# Guide de Maintenance : Mise à jour des Submodules

Ce guide explique comment modifier le code des sous-projets (`diplomind_be` et `diplomind_fe`) et comment répercuter ces changements dans le dépôt d'infrastructure global.

---

## 1. Modifier le code (BE ou FE)

Lorsque vous souhaitez faire une modification, vous devez travailler directement à l'intérieur du dossier du sous-projet.

### Étapes :
1.  **Entrez dans le dossier** :
    ```bash
    cd diplomind_be  # ou diplomind_fe
    ```
2.  **Vérifiez votre branche** :
    ```bash
    git checkout main  # ou la branche sur laquelle vous travaillez
    ```
3.  **Faites vos modifications** de code.
4.  **Commitez et Pushez** comme un dépôt habituel :
    ```bash
    git add .
    git commit -m "feat: description de ma modif"
    git push origin main
    ```

---

## 2. Mettre à jour l'Infrastructure Globale

Une fois que vous avez poussé vos modifications dans le dépôt distant du backend ou du frontend, votre dépôt global (à la racine) pointe toujours sur l'**ancien commit**. Vous devez "déplacer l'épingle".

### Étapes :
1.  **Revenez à la racine** du projet :
    ```bash
    cd ..
    ```
2.  **Mettez à jour la référence** :
    ```bash
    git submodule update --remote --merge
    ```
    *Cette commande dit au dépôt parent d'aller chercher le tout dernier commit sur GitHub pour chaque sous-projet.*

3.  **Enregistrez ce changement** dans le dépôt global :
    ```bash
    git add diplomind_be diplomind_fe
    git commit -m "chore: mise à jour des submodules"
    git push origin main
    ```

---

## 3. Déploiement en Production (Serveur)

Sur votre machine Debian de production, voici comment récupérer les changements :

1.  **Récupérez les commits du dépôt global** :
    ```bash
    git pull origin main
    ```
2.  **Mettez à jour les dossiers de code** :
    ```bash
    git submodule update --init --recursive
    ```
3.  **Relancez les conteneurs** pour prendre en compte le nouveau code :
    ```bash
    docker compose up -d --build
    ```

---

## Résumé du flux de travail (Workflow)

> [!IMPORTANT]
> **Règle d'or** : Toujours `Push` le sous-projet **AVANT** de commit le dépôt parent. Sinon, le dépôt parent pointera vers un commit qui n'existe pas encore sur GitHub, et personne ne pourra cloner votre projet !

1.  **Modif BE/FE** → `commit` → `push`.
2.  **Root (Infra)** → `submodule update` → `add` → `commit` → `push`.
3.  **Serveur** → `pull` → `submodule update` → `docker build`.
