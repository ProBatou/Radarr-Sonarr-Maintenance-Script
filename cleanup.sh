#!/bin/bash

source /etc/radarr-sonarr-maintenance.conf

# Récupérer les chemins de fichiers de toutes les séries terminées, telles que surveillées par Sonarr
ended_series_paths=$(curl --silent $SONARR -X GET -H "X-Api-Key: $SONARR_KEY" | jq -r '.[] | select(.status == "ended") | .path')

# Récupérer les IDs de tous les films non surveillés tels que suivis par Radarr
unmonitored_movies_ids=$(curl --silent $RADARR/api/v3/movie -X GET -H "X-Api-Key: $RADARR_KEY" | jq '.[] | select(.monitored == false) | .id')

# Récupérer les identifiants de toutes les séries non surveillées telles que suivies par Sonarr
unmonitored_series_ids=$(curl --silent $SONARR -X GET -H "X-Api-Key: $SONARR_KEY" | jq '.[] | select(.monitored == false) | .id')

#-------------------------------------------------------------------

if [ $(df -P $FILESYSTEM | awk '{gsub("%",""); capacity = $5}; END {print capacity}') -gt $CAPACITY ]; then
  # Itérer à travers tous les fichiers dans la variable `ended_series_paths`
  while read -r file; do
    # Vérifier si le fichier est plus vieux que 180 jours
    if [ ! $(find "$file" -mtime -180 | wc -l) -gt 0 ]; then
      # Supprimer le fichier s'il est plus vieux que 180 jours
      rm -rf "$file"
    fi
  done <<< "$ended_series_paths"
  # Trouver tous les répertoires dans/mnt/NAS/Films/ qui sont plus vieux que 90 jours et les supprimer
  find /mnt/NAS/Films/ -type d -mtime +90 -exec rm -rf {} \;
fi

#-------------------------------------------------------------------

# Itérer à travers la liste des identifiants de séries non surveillés
for id in $unmonitored_series_ids; do
  # Envoyer une demande DELETE à l'API Sonarr pour chaque identifiant
  curl --silent $SONARR/$id -X DELETE -H "X-Api-Key: $SONARR_KEY"
done

#-------------------------------------------------------------------

# Itérer à travers la liste des identifiants de films non surveillés
for id in $unmonitored_movies_ids; do
  # Envoyer une demande DELETE à l'API Radarr pour chaque identifiant
  curl --silent $RADARR/api/v3/movie/$id -X DELETE -H "X-Api-Key: $RADARR_KEY"
done

#-------------------------------------------------------------------

#Flood suppression torrents importé
# Configuration
AUTH_URL="http://localhost:3000/api/auth/authenticate"
TORRENTS_URL="http://localhost:3000/api/torrents"
DELETE_URL="http://localhost:3000/api/torrents/delete"
USERNAME=""
PASSWORD=""

# Authentification et récupération du cookie JWT
auth_response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -D - \
  -d "{\"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\"}" \
  "${AUTH_URL}")

# Extraction du cookie JWT
jwt_cookie=$(echo "$auth_response" | grep -o 'jwt=[^;]*')

# Vérification si le cookie a été extrait correctement
if [ -z "$jwt_cookie" ]; then
    echo "Erreur : Impossible de récupérer le cookie JWT."
    exit 1
fi

# Récupération des hashes et des noms des torrents avec le tag "imported"
torrents_response=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -H "Cookie: $jwt_cookie" \
  "${TORRENTS_URL}")

# Extraction des hashes et des noms des torrents
hashes=$(echo "$torrents_response" | jq -r '.torrents[] | select(.tags[] | contains("imported")) | .hash')
names=$(echo "$torrents_response" | jq -r '.torrents[] | select(.tags[] | contains("imported")) | .name')

# Vérification si des torrents avec le tag "imported" existent
if [ -z "$hashes" ]; then
    echo "Aucun torrent avec le tag 'imported' trouvé."
    exit 0
fi

# Conversion des hashes en tableau JSON
hashes_json=$(echo "$hashes" | jq -R -s -c 'split("\n")[:-1]')

# Suppression des torrents
delete_response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Cookie: $jwt_cookie" \
  -d "{\"hashes\": $hashes_json, \"deleteData\": true}" \
  "${DELETE_URL}")

# Affichage des noms des torrents supprimés
echo "Les torrents suivants ont été supprimés :"
echo "$names"

# Affichage de la réponse de la suppression
echo "Réponse de la suppression : $delete_response"
